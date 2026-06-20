import '../../formal/formal_property.dart';
import '../../formal/formal_property_type.dart';
import '../property_context.dart';
import '../property_models.dart';
import '../property_provider.dart';
import '../property_result.dart';

// ─── FSMPropertyProvider ──────────────────────────────────────────────────────

/// Infers formal properties from finite state machines in [DesignKnowledge].
///
/// Per FSM:
/// - **Safety** — state register never holds a value outside the known state set
///   (legal-state invariant).
/// - **Cover** — every known candidate state is reachable.
/// - **Invariant (candidate)** — one-hot encoding candidate when
///   [FSMInfo.encodingWidth] equals the number of candidate states.
///
/// Transition properties are intentionally deferred to a future provider.
class FSMPropertyProvider implements PropertyProvider {
  const FSMPropertyProvider();

  @override
  String get providerKey => 'fsm';

  @override
  Future<PropertyResult> infer(PropertyContext context) async {
    final dk = context.knowledge;
    if (dk.fsms.isEmpty) return PropertyResult.empty(providerKey);

    final props = <FormalProperty>[];

    for (final fsm in dk.fsms) {
      final fsmId = '${PropertyIdPrefix.fsm}.${fsm.stateRegister}';
      final states = fsm.candidateStates;

      if (states.isEmpty) continue;

      // Safety: legal-state invariant.
      final legalExpr = states
          .map((s) => '${fsm.stateRegister} == $s')
          .join(' || ');
      props.add(FormalProperty(
        id:           '$fsmId.legal_state',
        name:         '${fsm.stateRegister} stays in legal states',
        description:  '${fsm.stateRegister} must never hold a value outside {${states.join(', ')}}.',
        propertyType: FormalPropertyType.safety,
        severity:     'error',
        expression:   'always($legalExpr)',
        metadata: {
          'confidence': PropertyConfidence.definite.name,
          'fsm':        fsm.stateRegister,
          'states':     states,
        },
      ));

      // Cover: each candidate state must be reachable.
      for (final state in states) {
        props.add(FormalProperty(
          id:           '$fsmId.$state.reachable',
          name:         '$state is reachable in ${fsm.stateRegister}',
          description:  'State $state of ${fsm.stateRegister} must be reachable from the initial state.',
          propertyType: FormalPropertyType.cover,
          severity:     'info',
          expression:   '${fsm.stateRegister} == $state',
          metadata: {
            'confidence': PropertyConfidence.definite.name,
            'fsm':        fsm.stateRegister,
            'state':      state,
          },
        ));
      }

      // Invariant candidate: encodingWidth == state count implies one-hot.
      if (fsm.encodingWidth > 1 && fsm.encodingWidth == states.length) {
        props.add(FormalProperty(
          id:           '$fsmId.one_hot_candidate',
          name:         '${fsm.stateRegister} one-hot encoding candidate',
          description:
              'State register width (${fsm.encodingWidth}) equals state count — '
              'possibly one-hot encoded.',
          propertyType: FormalPropertyType.invariant,
          severity:     'info',
          expression:   'onehot(${fsm.stateRegister})',
          metadata: {
            'confidence':    PropertyConfidence.candidate.name,
            'fsm':           fsm.stateRegister,
            'encodingWidth': fsm.encodingWidth,
          },
        ));
      }
    }

    return PropertyResult(providerKey: providerKey, properties: props);
  }
}
