import '../semantic/semantic_evidence.dart';
import 'candidate_property.dart';

// ─── SynthesisRule ────────────────────────────────────────────────────────────

/// Abstract interface for a single-responsibility property synthesis unit.
///
/// Rules:
/// - Each rule owns exactly one semantic category.
/// - Rules must not import or depend on one another.
/// - Rules must not import DesignKnowledge, RTL parsers, or the Formal Framework.
/// - [appliesTo] acts as a guard — [PropertySynthesizer] calls it before [synthesize].
/// - [synthesize] must never throw.
abstract class SynthesisRule {
  const SynthesisRule();

  /// Returns `true` when this rule can reason over [evidence].
  bool appliesTo(SemanticEvidence evidence);

  /// Returns zero or more [CandidateProperty] objects derived from [evidence].
  List<CandidateProperty> synthesize(SemanticEvidence evidence);
}
