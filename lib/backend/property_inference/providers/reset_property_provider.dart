import '../../formal/formal_property.dart';
import '../../formal/formal_property_type.dart';
import '../property_context.dart';
import '../property_models.dart';
import '../property_provider.dart';
import '../property_result.dart';

// ─── ResetPropertyProvider ────────────────────────────────────────────────────

/// Infers formal properties from reset signals in [DesignKnowledge].
///
/// Per reset signal:
/// - **Liveness** — reset must eventually deassert.
/// - **Safety (per sequential register)** — while reset active, register holds
///   its reset value (modelled as 0).
/// - **Safety (per FSM)** — while reset active, state register is in the first
///   known candidate state.
class ResetPropertyProvider implements PropertyProvider {
  const ResetPropertyProvider();

  @override
  String get providerKey => 'reset';

  @override
  Future<PropertyResult> infer(PropertyContext context) async {
    final dk = context.knowledge;
    if (dk.resets.isEmpty) return PropertyResult.empty(providerKey);

    final props = <FormalProperty>[];

    for (final rst in dk.resets) {
      final activeExpr = rst.isActiveLow ? '!${rst.name}' : rst.name;
      final resetId    = '${PropertyIdPrefix.reset}.${rst.name}';

      // Liveness: reset must eventually deassert.
      props.add(FormalProperty(
        id:           '$resetId.releases',
        name:         '${rst.name} eventually releases',
        description:  'Reset signal must deassert within a bounded number of cycles.',
        propertyType: FormalPropertyType.liveness,
        severity:     'warning',
        expression:   'eventually(!($activeExpr))',
        metadata: {
          'confidence': PropertyConfidence.likely.name,
          'reset':      rst.name,
        },
      ));

      // Safety: reset initialises sequential registers to their reset value.
      for (final reg in dk.registers.where((r) => r.isSequential)) {
        props.add(FormalProperty(
          id:           '$resetId.initializes.${reg.name}',
          name:         '${rst.name} initialises ${reg.name}',
          description:  'While ${rst.name} is active, ${reg.name} must hold its reset value.',
          propertyType: FormalPropertyType.safety,
          severity:     'error',
          expression:   '$activeExpr |-> (${reg.name} == 0)',
          metadata: {
            'confidence': PropertyConfidence.likely.name,
            'reset':      rst.name,
            'register':   reg.name,
          },
        ));
      }

      // Safety: reset drives each FSM to its initial (first candidate) state.
      for (final fsm in dk.fsms) {
        if (fsm.candidateStates.isEmpty) continue;
        final initialState = fsm.candidateStates.first;
        props.add(FormalProperty(
          id:           '$resetId.fsm.${fsm.stateRegister}.initial',
          name:         '${rst.name} drives ${fsm.stateRegister} to $initialState',
          description:
              'While ${rst.name} is active, ${fsm.stateRegister} must be in state $initialState.',
          propertyType: FormalPropertyType.safety,
          severity:     'error',
          expression:   '$activeExpr |-> (${fsm.stateRegister} == $initialState)',
          metadata: {
            'confidence': PropertyConfidence.likely.name,
            'reset':      rst.name,
            'fsm':        fsm.stateRegister,
          },
        ));
      }
    }

    return PropertyResult(providerKey: providerKey, properties: props);
  }
}
