// ─── ExplanationTrace ─────────────────────────────────────────────────────────

/// Immutable provenance record for one [VerificationExplanation].
///
/// Carries all information needed to answer "why does this property exist?"
/// at every stage of the pipeline:
/// - which semantic evidence contributed ([semanticEvidenceIds])
/// - how the property was ranked ([rankingExplanation], [confidence])
/// - why it was emitted ([emissionReason])
/// - which type it has ([propertyType])
/// - which engine will verify it ([verificationEngine] — filled in later)
///
/// [futureMetadata] holds fields reserved for downstream pipeline stages
/// (counterexample links, repair references, verification outcomes).
///
/// Invariants:
/// - [semanticEvidenceIds] is unmodifiable.
/// - [futureMetadata] is unmodifiable.
/// - [confidence] is typically in [0.0, 1.0] but is not clamped here.
class ExplanationTrace {
  /// IDs of the [SemanticEvidence] items that motivated the property.
  final List<String> semanticEvidenceIds;

  /// Human-readable explanation of why this property received its ranking score.
  final String rankingExplanation;

  /// Composite ranking confidence score copied from [RankingScore.value].
  final double confidence;

  /// Human-readable reason why this property was selected for emission.
  final String emissionReason;

  /// Name of the [FormalPropertyType] this property was emitted as.
  final String propertyType;

  /// Name of the verification engine that will check this property.
  ///
  /// Empty string at explanation-generation time; filled in by the engine
  /// adapter once a backend is selected.
  final String verificationEngine;

  /// Reserved for downstream stages: counterexamples, repair links, etc.
  final Map<String, dynamic> futureMetadata;

  ExplanationTrace({
    required List<String> semanticEvidenceIds,
    required this.rankingExplanation,
    required this.confidence,
    required this.emissionReason,
    required this.propertyType,
    this.verificationEngine = '',
    this.futureMetadata     = const {},
  }) : semanticEvidenceIds = List.unmodifiable(List.of(semanticEvidenceIds));
}
