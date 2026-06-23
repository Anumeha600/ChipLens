// ─── CoverageStatistics ───────────────────────────────────────────────────────

/// Derived statistics summarising a [CoverageAssessment].
///
/// All fields are read-only counts and fractions computed from the source
/// [CoverageReport] and the generated [CoverageRecommendation] list.
///
/// Invariants:
/// - All integer counts are non-negative.
/// - [overallCoverage] is in [0.0, 1.0].
class CoverageStatistics {
  /// Number of recommendations generated for the assessed report.
  final int recommendationCount;

  /// Number of [CoverageWarning]s in the source [CoverageReport].
  final int warningCount;

  /// Number of unvisited FSM states.
  final int uncoveredStates;

  /// Number of untaken FSM transitions.
  final int uncoveredTransitions;

  /// Number of uncovered RTL branches.
  final int uncoveredBranches;

  /// Number of signals that never toggled.
  final int untoggledSignals;

  /// Composite coverage fraction from [CoverageResult.overallCoverage].
  final double overallCoverage;

  const CoverageStatistics({
    required this.recommendationCount,
    required this.warningCount,
    required this.uncoveredStates,
    required this.uncoveredTransitions,
    required this.uncoveredBranches,
    required this.untoggledSignals,
    required this.overallCoverage,
  });

  /// Zero-value statistics for an empty or skipped assessment.
  static const CoverageStatistics empty = CoverageStatistics(
    recommendationCount: 0,
    warningCount:        0,
    uncoveredStates:     0,
    uncoveredTransitions: 0,
    uncoveredBranches:   0,
    untoggledSignals:    0,
    overallCoverage:     0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverageStatistics &&
          recommendationCount  == other.recommendationCount  &&
          warningCount         == other.warningCount         &&
          uncoveredStates      == other.uncoveredStates      &&
          uncoveredTransitions == other.uncoveredTransitions &&
          uncoveredBranches    == other.uncoveredBranches    &&
          untoggledSignals     == other.untoggledSignals     &&
          (overallCoverage - other.overallCoverage).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(
        recommendationCount, warningCount, uncoveredStates,
        uncoveredTransitions, uncoveredBranches, untoggledSignals);

  @override
  String toString() =>
      'CoverageStatistics(recs=$recommendationCount, warnings=$warningCount, '
      'overall=${(overallCoverage * 100).toStringAsFixed(1)}%)';
}
