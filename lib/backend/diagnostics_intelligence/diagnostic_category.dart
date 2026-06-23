// ─── DiagnosticCategory ───────────────────────────────────────────────────────

/// Problem domain classification for a [DiagnosticIssue].
///
/// Each [DiagnosticIssue] belongs to exactly one category.  The category
/// identifies which verification sub-system the issue originates from.
///
/// Future extension points:
/// - Add [timeline] for historical trend analysis.
/// - Add [integration] for CI/CD system issues.
enum DiagnosticCategory {
  /// Formal verification process failure (engine errors, timeouts).
  verification,

  /// Coverage deficiency (insufficient state/transition/branch coverage).
  coverage,

  /// Verification planning problems (ordering, batching, strategy selection).
  planning,

  /// Property quality problems (low confidence, weak specifications).
  property,

  /// Counterexample analysis results (failed assertions, traces).
  counterexample,

  /// Configuration errors (invalid settings, missing prerequisites).
  configuration,
}
