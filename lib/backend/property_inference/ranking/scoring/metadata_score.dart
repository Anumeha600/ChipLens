// ─── MetadataScore ────────────────────────────────────────────────────────────

/// Scores the richness of a [CandidateProperty.metadata] map.
///
/// Each additional field up to three provides more context for downstream
/// consumers (ranking, emitter, UI).  Saturates at three or more fields.
///
/// | Fields | Score |
/// |--------|-------|
/// | 0      | 0.00  |
/// | 1      | 0.40  |
/// | 2      | 0.70  |
/// | ≥ 3    | 1.00  |
///
/// Stateless and const-constructible — safe to share as a singleton.
class MetadataScore {
  const MetadataScore();

  static const Map<int, double> _countToScore = {0: 0.0, 1: 0.40, 2: 0.70};

  ({double score, String explanation}) compute(Map<String, dynamic> metadata) {
    final count = metadata.length;
    final score = count >= 3 ? 1.0 : _countToScore[count] ?? 0.0;
    if (count == 0) {
      return (score: 0.0, explanation: 'No metadata context');
    }
    final fieldWord = count == 1 ? 'field' : 'fields';
    final verbWord  = count == 1 ? 'provides' : 'provide';
    return (
      score: score,
      explanation: '$count metadata $fieldWord $verbWord semantic context',
    );
  }
}
