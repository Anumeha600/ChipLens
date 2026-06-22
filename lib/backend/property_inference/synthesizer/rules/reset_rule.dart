import '../../semantic/semantic_category.dart';
import '../../semantic/semantic_evidence.dart';
import '../candidate_property.dart';
import '../candidate_property_type.dart';
import '../synthesis_rule.dart';

// ─── ResetRule ────────────────────────────────────────────────────────────────

/// Synthesises candidate properties from reset semantic evidence.
///
/// Per reset:
/// - **Liveness** — reset must eventually deassert.
/// - **Assumption** — formal tools must be constrained to the correct polarity.
class ResetRule implements SynthesisRule {
  const ResetRule();

  @override
  bool appliesTo(SemanticEvidence evidence) =>
      evidence.category == SemanticCategory.reset;

  @override
  List<CandidateProperty> synthesize(SemanticEvidence evidence) {
    final name       = evidence.metadata['signal']        as String? ?? 'reset';
    final isAsync    = evidence.metadata['isAsynchronous'] as bool?  ?? false;
    final isActiveLow = evidence.metadata['isActiveLow']  as bool?  ?? false;
    final polarity   = isActiveLow ? 'active-low' : 'active-high';
    final kind       = isAsync ? 'asynchronous' : 'synchronous';

    return [
      // Liveness: reset eventually deasserts.
      CandidateProperty(
        id:           'synth.reset.$name.releases',
        title:        '$name eventually deasserts',
        description:  'The $kind reset $name must deassert within a bounded '
                      'number of cycles after power-on.',
        propertyType: CandidatePropertyType.livenessCondition,
        evidenceIds:  [evidence.id],
        rationale:    '$name was identified as a $kind $polarity reset. '
                      'A reset that never deasserts leaves the design permanently '
                      'in its reset state, preventing normal operation.',
        metadata:     {'kind': kind, 'polarity': polarity},
      ),

      // Assumption: polarity constraint for formal tools.
      CandidateProperty(
        id:           'synth.reset.$name.polarity',
        title:        '$name polarity assumption',
        description:  'Formal input space must be constrained to respect '
                      'the $polarity polarity of $name.',
        propertyType: CandidatePropertyType.assumption,
        evidenceIds:  [evidence.id],
        rationale:    '$name was detected as $polarity. Without a polarity '
                      'assumption, a formal engine may drive the signal with '
                      'incorrect sense and produce vacuously passing results.',
        metadata:     {'polarity': polarity},
      ),
    ];
  }
}
