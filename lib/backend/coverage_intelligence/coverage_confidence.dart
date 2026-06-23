// ─── CoverageConfidence ───────────────────────────────────────────────────────

/// Overall confidence in verification quality derived from a [CoverageReport].
///
/// Mapped deterministically from [CoverageResult.overallCoverage]; critical
/// warnings reduce the computed level by exactly one step.
///
/// Values are ordered from least to most confident so that
/// [CoverageConfidence.values] can be indexed for adjustment.
enum CoverageConfidence {
  /// < 40 % coverage or heavily warned.
  veryLow,

  /// 40–59 % coverage.
  low,

  /// 60–79 % coverage.
  medium,

  /// 80–94 % coverage.
  high,

  /// ≥ 95 % coverage with no critical warnings.
  veryHigh,
}
