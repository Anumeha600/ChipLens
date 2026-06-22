import '../../semantic/semantic_category.dart';
import '../../semantic/semantic_evidence.dart';
import '../candidate_property.dart';
import '../candidate_property_type.dart';
import '../synthesis_rule.dart';

// ─── CounterRule ──────────────────────────────────────────────────────────────

/// Synthesises candidate properties from counter semantic evidence.
///
/// Per counter (always):
/// - **Boundedness** — counter must not exceed its register width ceiling.
///
/// Conditionally:
/// - **Stability (monotonic)** — increment-only counter never decreases.
/// - **Boundedness (wraparound)** — bidirectional counter may wrap at boundaries.
class CounterRule implements SynthesisRule {
  const CounterRule();

  @override
  bool appliesTo(SemanticEvidence evidence) =>
      evidence.category == SemanticCategory.counter;

  @override
  List<CandidateProperty> synthesize(SemanticEvidence evidence) {
    final name        = evidence.metadata['counter']     as String? ?? 'counter';
    final width       = evidence.metadata['width']       as int?    ?? 1;
    final isIncrement = evidence.metadata['isIncrement'] as bool?   ?? false;
    final isDecrement = evidence.metadata['isDecrement'] as bool?   ?? false;
    final maxVal      = (1 << width) - 1;

    final props = <CandidateProperty>[];

    // Boundedness: always emitted.
    props.add(CandidateProperty(
      id:           'synth.counter.$name.bounds',
      title:        '$name within register bounds',
      description:  '$name must remain in [0, $maxVal] given its $width-bit declaration.',
      propertyType: CandidatePropertyType.boundedness,
      evidenceIds:  [evidence.id],
      rationale:    '$name is a $width-bit counter. Values above $maxVal '
                    'indicate overflow — either intentional wraparound (must be '
                    'verified) or an arithmetic error (must be prevented).',
      metadata:     {'maxVal': maxVal, 'width': width},
    ));

    // Stability (monotonic): increment-only.
    if (isIncrement && !isDecrement) {
      props.add(CandidateProperty(
        id:           'synth.counter.$name.monotonic',
        title:        '$name monotonically non-decreasing',
        description:  '$name must not decrease between clock cycles '
                      'except when the design intentionally resets it.',
        propertyType: CandidatePropertyType.stability,
        evidenceIds:  [evidence.id],
        rationale:    'Only increment operations were detected on $name. '
                      'A decrease in value outside of a reset condition indicates '
                      'an unintended control-flow path.',
      ));
    }

    // Boundedness (wraparound): bidirectional.
    if (isIncrement && isDecrement) {
      props.add(CandidateProperty(
        id:           'synth.counter.$name.wraparound',
        title:        '$name boundary behaviour at 0 and $maxVal',
        description:  '$name can both increment and decrement; verify intended '
                      'behaviour at the 0 and $maxVal boundaries.',
        propertyType: CandidatePropertyType.boundedness,
        evidenceIds:  [evidence.id],
        rationale:    'Both increment and decrement operations were detected on $name. '
                      'Underflow (below 0) and overflow (above $maxVal) must each be '
                      'handled intentionally — saturating, wrapping, or prevented.',
        metadata:     {'maxVal': maxVal},
      ));
    }

    return props;
  }
}
