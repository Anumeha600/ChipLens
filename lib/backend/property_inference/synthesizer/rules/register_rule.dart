import '../../semantic/semantic_category.dart';
import '../../semantic/semantic_evidence.dart';
import '../candidate_property.dart';
import '../candidate_property_type.dart';
import '../synthesis_rule.dart';

// ─── RegisterRule ─────────────────────────────────────────────────────────────

/// Synthesises candidate properties from register semantic evidence.
///
/// Applies to [SemanticCategory.sequential] and [SemanticCategory.combinational].
/// Unclassified [SemanticCategory.register] evidence is not handled here —
/// a future rule may address it once clocking is resolved.
///
/// - **Sequential** → stability: must not change outside a clock edge.
/// - **Combinational** → safety invariant: must always hold a defined value.
class RegisterRule implements SynthesisRule {
  const RegisterRule();

  @override
  bool appliesTo(SemanticEvidence evidence) =>
      evidence.category == SemanticCategory.sequential ||
      evidence.category == SemanticCategory.combinational;

  @override
  List<CandidateProperty> synthesize(SemanticEvidence evidence) {
    final name         = evidence.metadata['register']        as String? ?? 'reg';
    final width        = evidence.metadata['width']           as int?    ?? 1;
    final isSequential = evidence.metadata['isSequential']    as bool?   ?? false;
    final isComb       = evidence.metadata['isCombinational'] as bool?   ?? false;

    if (isSequential) {
      return [
        CandidateProperty(
          id:           'synth.register.$name.stable',
          title:        '$name sequential register stability',
          description:  '$name must not change value between clock edges.',
          propertyType: CandidatePropertyType.stability,
          evidenceIds:  [evidence.id],
          rationale:    '$name is a $width-bit sequential register. A value '
                        'change outside of a clock edge indicates a hold-time '
                        'violation, combinational glitch, or missing clock domain '
                        'crossing synchronisation.',
          metadata:     {'width': width},
        ),
      ];
    }

    if (isComb) {
      return [
        CandidateProperty(
          id:           'synth.register.$name.defined',
          title:        '$name combinational output always defined',
          description:  '$name must always be driven to a fully defined value — '
                        'never X or Z.',
          propertyType: CandidatePropertyType.safetyInvariant,
          evidenceIds:  [evidence.id],
          rationale:    '$name is a $width-bit combinational signal. Incomplete '
                        'case statements or undriven default branches can produce '
                        'undefined values that propagate through downstream logic.',
          metadata:     {'width': width},
        ),
      ];
    }

    return const [];
  }
}
