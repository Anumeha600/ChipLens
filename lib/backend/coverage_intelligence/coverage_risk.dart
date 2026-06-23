// ─── CoverageRisk ─────────────────────────────────────────────────────────────

/// Overall verification risk level derived from a [CoverageReport].
///
/// Computed deterministically by [CoverageIntelligenceEngine] from coverage
/// fractions, dead-logic warnings, and critical-severity warning counts.
///
/// Values are ordered from least to most severe; [CoverageRisk.values] can be
/// indexed to escalate risk by integer steps.
enum CoverageRisk {
  /// ≥ 95 % coverage, no dead-logic, no critical warnings.
  minimal,

  /// 80–94 % coverage with at most minor issues.
  low,

  /// 60–79 % coverage or non-critical dead-logic present.
  moderate,

  /// 40–59 % coverage or dead-logic warnings present.
  high,

  /// < 40 % coverage or critical dead-logic detected.
  critical,
}
