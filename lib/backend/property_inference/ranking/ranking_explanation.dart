// ─── RankingExplanation ───────────────────────────────────────────────────────

/// Human-readable explanation for why a property received its score.
///
/// Designed for display in the UI (emitter layer).
/// [reasons] lists each factor that meaningfully raised the score.
class RankingExplanation {
  final double score;
  final List<String> reasons;

  const RankingExplanation({required this.score, required this.reasons});

  /// Multi-line summary suitable for display or logging.
  String get formatted {
    final buf = StringBuffer('Score: ${score.toStringAsFixed(4)}\nReasons:');
    for (final r in reasons) {
      buf.write('\n  - $r');
    }
    return buf.toString();
  }
}
