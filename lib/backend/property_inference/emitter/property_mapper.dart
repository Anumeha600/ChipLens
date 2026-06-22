import '../../formal/formal_property.dart';
import '../../formal/formal_property_type.dart';
import '../ranking/ranking_result.dart';
import '../synthesizer/candidate_property_type.dart';
import 'evidence_mapper.dart';
import 'metadata_mapper.dart';

// ─── PropertyMapper ───────────────────────────────────────────────────────────

/// Performs a deterministic, information-preserving conversion of one
/// [RankingResult] into one [FormalProperty].
///
/// Responsibilities:
/// - Map [CandidatePropertyType] → [FormalPropertyType] (exhaustive).
/// - Preserve identifier, expression, description, and evidence references.
/// - Delegate metadata construction to [MetadataMapper].
/// - Delegate evidence deduplication to [EvidenceMapper].
///
/// Does NOT:
/// - Infer new information.
/// - Generate formal expressions.
/// - Modify scores, confidence, or ranking.
abstract class PropertyMapper {
  PropertyMapper._();

  /// Exhaustive [CandidatePropertyType] → [FormalPropertyType] mapping.
  ///
  /// Adding a new [CandidatePropertyType] requires adding exactly one arm here.
  static FormalPropertyType mapType(CandidatePropertyType type) =>
      switch (type) {
        CandidatePropertyType.safetyInvariant   => FormalPropertyType.safety,
        CandidatePropertyType.livenessCondition => FormalPropertyType.liveness,
        CandidatePropertyType.reachability      => FormalPropertyType.cover,
        CandidatePropertyType.stability         => FormalPropertyType.assertion,
        CandidatePropertyType.boundedness       => FormalPropertyType.assertion,
        CandidatePropertyType.assumption        => FormalPropertyType.assumption,
        CandidatePropertyType.custom            => FormalPropertyType.assertion,
      };

  /// Converts [result] into an equivalent [FormalProperty].
  ///
  /// - [FormalProperty.id]          ← [CandidateProperty.id]
  /// - [FormalProperty.name]        ← [CandidateProperty.title]
  /// - [FormalProperty.description] ← [CandidateProperty.description]
  /// - [FormalProperty.propertyType]← [mapType]([CandidateProperty.propertyType])
  /// - [FormalProperty.expression]  ← [CandidateProperty.expression] ?? `''`
  /// - [FormalProperty.metadata]    ← [MetadataMapper.build]
  static FormalProperty map(RankingResult result) {
    final candidate   = result.property;
    final evidenceIds = EvidenceMapper.map(candidate.evidenceIds);
    final metadata    = MetadataMapper.build(result, evidenceIds);

    return FormalProperty(
      id:           candidate.id,
      name:         candidate.title,
      description:  candidate.description,
      propertyType: mapType(candidate.propertyType),
      expression:   candidate.expression ?? '',
      metadata:     metadata,
    );
  }
}
