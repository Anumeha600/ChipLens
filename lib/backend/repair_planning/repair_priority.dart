// ─── RepairPriority ───────────────────────────────────────────────────────────

/// Priority level of a [RepairStep].
///
/// Maps directly from [DiagnosticSeverity]:
/// critical → critical · high → high · medium → medium · low → low.
/// Informational diagnostics produce no repair step.
///
/// Overall priority aggregation:
/// - Any critical step → overall critical.
/// - Any high step    → overall high.
/// - Any medium step  → overall medium.
/// - Else             → overall low.
enum RepairPriority {
  /// Repair is urgent — verification cannot proceed reliably without it.
  critical,

  /// Repair significantly improves verification quality.
  high,

  /// Repair reduces known quality gaps.
  medium,

  /// Minor improvement; deferrable.
  low,
}

// ─── RepairComplexity ─────────────────────────────────────────────────────────

/// Estimated effort required to complete a [RepairStep].
///
/// Derived deterministically from [RepairCategory]:
/// - configuration / planning → low
/// - coverage / property      → medium
/// - verification             → high
///
/// Overall complexity aggregation:
/// - Any high step    → overall high.
/// - Any medium step  → overall medium.
/// - Else             → overall low.
enum RepairComplexity {
  /// Trivial fix — automated or single-line change.
  trivial,

  /// Low effort — a few targeted edits.
  low,

  /// Medium effort — multiple coordinated changes.
  medium,

  /// High effort — significant rework or re-architecture required.
  high,
}
