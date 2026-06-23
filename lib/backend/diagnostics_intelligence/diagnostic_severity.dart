// ─── DiagnosticSeverity ───────────────────────────────────────────────────────

/// Severity of a [DiagnosticIssue].
///
/// Values are ordered from least to most severe.  [DiagnosticSeverity.values]
/// can be indexed to escalate severity by integer steps.
///
/// Severity Aggregation Policy (used by [DiagnosticsEngine]):
/// - Any critical issue → overall critical.
/// - Any high issue   → overall high.
/// - Any medium issue → overall medium.
/// - Any low issue    → overall low.
/// - No issues        → overall informational.
enum DiagnosticSeverity {
  /// Observation only — no action required.
  informational,

  /// Minor issue — low impact on verification quality.
  low,

  /// Verification quality is reduced.
  medium,

  /// Verification quality is severely affected.
  high,

  /// Verification cannot continue reliably.
  critical,
}

// ─── DiagnosticConfidence ─────────────────────────────────────────────────────

/// Confidence in the completeness and correctness of a [DiagnosticReport].
///
/// Derived deterministically from [CoverageAssessment], [CounterexampleReport],
/// and [VerificationExplanationSet].  No AI or randomness is used.
///
/// Confidence Mapping:
/// - High coverage + no failures + no critical issues → [veryHigh].
/// - Coverage issues only (no counterexample failures)  → [high].
/// - Mixed evidence                                      → [medium].
/// - Counterexamples dominate                           → [low].
/// - Engine or configuration failure                    → [veryLow].
enum DiagnosticConfidence {
  veryLow,
  low,
  medium,
  high,
  veryHigh,
}
