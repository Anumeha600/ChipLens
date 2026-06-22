import '../ranking/ranking_result.dart';

// ─── MetadataMapper ───────────────────────────────────────────────────────────

/// Constructs the [FormalProperty.metadata] map from a [RankingResult].
///
/// Produces exactly six keys:
/// - `candidateId`  — original [CandidateProperty.id]
/// - `rank`         — 1-based ranking position
/// - `score`        — composite ranking score (`double`)
/// - `explanation`  — formatted multi-line ranking explanation
/// - `source`       — constant `'PropertyEmitter'`
/// - `evidenceIds`  — deduplicated evidence id list from [EvidenceMapper]
///
/// Invariants:
/// - Does NOT compute new values.
/// - Only transfers information that already exists in [result].
/// - Returns an unmodifiable map.
abstract class MetadataMapper {
  MetadataMapper._();

  /// Source tag written into every emitted property's metadata.
  static const String _sourceTag = 'PropertyEmitter';

  /// Builds the canonical metadata map for [result].
  ///
  /// [evidenceIds] must already be deduplicated (produced by [EvidenceMapper]).
  static Map<String, dynamic> build(
    RankingResult result,
    List<String> evidenceIds,
  ) =>
      Map.unmodifiable({
        'candidateId': result.property.id,
        'rank':        result.rank,
        'score':       result.score.value,
        'explanation': result.explanation.formatted,
        'source':      _sourceTag,
        'evidenceIds': List.unmodifiable(evidenceIds),
      });
}
