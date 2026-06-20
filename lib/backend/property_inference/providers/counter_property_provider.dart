import '../../formal/formal_property.dart';
import '../../formal/formal_property_type.dart';
import '../property_context.dart';
import '../property_models.dart';
import '../property_provider.dart';
import '../property_result.dart';

// ─── CounterPropertyProvider ──────────────────────────────────────────────────

/// Infers formal properties from counter registers in [DesignKnowledge].
///
/// Per counter:
/// - **Safety** — counter is bounded by its register width (always present).
/// - **Invariant** — counter is monotonically non-decreasing (increment-only).
/// - **Safety (candidate)** — bidirectional counter may wrap; flag for review.
class CounterPropertyProvider implements PropertyProvider {
  const CounterPropertyProvider();

  @override
  String get providerKey => 'counter';

  @override
  Future<PropertyResult> infer(PropertyContext context) async {
    final dk = context.knowledge;
    if (dk.counters.isEmpty) return PropertyResult.empty(providerKey);

    final props = <FormalProperty>[];

    for (final ctr in dk.counters) {
      final counterId = '${PropertyIdPrefix.counter}.${ctr.name}';
      final maxVal    = (1 << ctr.width) - 1;

      // Safety: bounded by register width — always emitted.
      props.add(FormalProperty(
        id:           '$counterId.bounds',
        name:         '${ctr.name} within register bounds',
        description:  '${ctr.name} must not exceed $maxVal (${ctr.width}-bit register).',
        propertyType: FormalPropertyType.safety,
        severity:     'error',
        expression:   'always(${ctr.name} <= $maxVal)',
        metadata: {
          'confidence': PropertyConfidence.definite.name,
          'counter':    ctr.name,
          'maxVal':     maxVal,
        },
      ));

      // Invariant: increment-only counter never decreases (except at rollover).
      if (ctr.isIncrement && !ctr.isDecrement) {
        props.add(FormalProperty(
          id:           '$counterId.monotonic',
          name:         '${ctr.name} monotonically increases',
          description:  '${ctr.name} must not decrease unless it rolls over from $maxVal.',
          propertyType: FormalPropertyType.invariant,
          severity:     'warning',
          expression:   'always(${ctr.name} <= next(${ctr.name}) || ${ctr.name} == $maxVal)',
          metadata: {
            'confidence': PropertyConfidence.likely.name,
            'counter':    ctr.name,
          },
        ));
      }

      // Safety (candidate): bidirectional counter may wrap — flag for review.
      if (ctr.isIncrement && ctr.isDecrement) {
        props.add(FormalProperty(
          id:           '$counterId.wraparound_candidate',
          name:         '${ctr.name} wraparound candidate',
          description:
              '${ctr.name} can increment and decrement — verify wrap-around '
              'behaviour is intentional.',
          propertyType: FormalPropertyType.safety,
          severity:     'warning',
          expression:   'always(${ctr.name} <= $maxVal)',
          metadata: {
            'confidence': PropertyConfidence.candidate.name,
            'counter':    ctr.name,
          },
        ));
      }
    }

    return PropertyResult(providerKey: providerKey, properties: props);
  }
}
