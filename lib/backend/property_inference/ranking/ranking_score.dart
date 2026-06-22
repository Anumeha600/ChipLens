// ─── RankingContribution ──────────────────────────────────────────────────────

/// One weighted contribution to a [RankingScore].
///
/// [label] — human-readable name (e.g. 'Evidence confidence').
/// [value] — the already-weighted share; all contributions in a score sum to
///           [RankingScore.value].
class RankingContribution {
  final String label;
  final double value;

  const RankingContribution({required this.label, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingContribution &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => '$label: +${value.toStringAsFixed(4)}';
}

// ─── RankingScore ─────────────────────────────────────────────────────────────

/// Immutable aggregate score for one [RankingResult].
///
/// [value] is clamped to [0.0, 1.0].
/// [contributions] breaks down the total by policy component.
/// [explanation] is a compact human-readable summary of all contributions.
class RankingScore {
  final double value;
  final List<RankingContribution> contributions;
  final String explanation;

  const RankingScore({
    required this.value,
    required this.contributions,
    required this.explanation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingScore && (value - other.value).abs() < 1e-9;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RankingScore(${value.toStringAsFixed(4)})';
}
