// ─── RepairCategory ───────────────────────────────────────────────────────────

/// Repair domain classification for a [RepairStep].
///
/// Maps from [DiagnosticCategory]:
/// - verification / counterexample → verification
/// - coverage                       → coverage
/// - planning                       → planning
/// - property                       → property
/// - configuration                  → configuration
///
/// Future extension points:
/// - Add [testbench] for testbench improvement recommendations.
/// - Add [environment] for tool-configuration-level repairs.
enum RepairCategory {
  /// Repair targets the formal verification process (engine, strategy, bounds).
  verification,

  /// Repair targets coverage gaps (state, transition, branch, toggle).
  coverage,

  /// Repair targets verification plan quality (ordering, batching, strategy).
  planning,

  /// Repair targets property specification quality (confidence, completeness).
  property,

  /// Repair targets configuration errors (toolchain, settings, prerequisites).
  configuration,
}
