// ─── CounterexampleClassification ────────────────────────────────────────────

/// Category of failure determined from [FormalResult].
///
/// Applied with the following priority (highest to lowest):
/// engineFailure > timeout > assertionFailure > assumptionViolation > unknown.
///
/// When no failure is present and all properties are proven, the classification
/// is [unknown] (no counterexample is known to exist).
enum CounterexampleClassification {
  /// At least one property has a counterexample trace.
  assertionFailure,

  /// The engine found a case where an `assume()` constraint was violated.
  assumptionViolation,

  /// The engine reached its resource limit (detected via exit code 124).
  timeout,

  /// The engine could not determine a result (inconclusive run).
  unknown,

  /// The engine binary was unavailable or crashed (exit code < 0).
  engineFailure,
}

// ─── CounterexampleConfidence ─────────────────────────────────────────────────

/// Confidence in the counterexample analysis, derived from [FormalResult]
/// property outcomes and engine status.
///
/// Values are ordered from least to most confident so that
/// [CounterexampleConfidence.values] can be indexed for adjustment.
enum CounterexampleConfidence {
  /// Engine failure, or no properties checked.
  veryLow,

  /// Most properties are unknown or failed.
  low,

  /// Mixed results — some proven, some failed or unknown.
  medium,

  /// Single failure; all other properties proven.
  high,

  /// All properties formally proven; no failures or unknowns.
  veryHigh,
}
