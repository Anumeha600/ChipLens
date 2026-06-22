import '../synthesizer/candidate_property.dart';
import 'ranking_explanation.dart';
import 'ranking_score.dart';

// ─── RankingResult ────────────────────────────────────────────────────────────

/// Immutable pairing of a [CandidateProperty] with its computed [RankingScore].
///
/// [rank] is 1-based: rank 1 is the highest-priority property.
/// [explanation] provides a human-readable breakdown for the UI.
///
/// [RankingEngine] never modifies the original [CandidateProperty].
class RankingResult {
  final CandidateProperty property;
  final RankingScore score;
  final int rank;
  final RankingExplanation explanation;

  const RankingResult({
    required this.property,
    required this.score,
    required this.rank,
    required this.explanation,
  });

  @override
  String toString() =>
      'RankingResult(rank=$rank, score=${score.value.toStringAsFixed(4)}, '
      'id=${property.id})';
}
