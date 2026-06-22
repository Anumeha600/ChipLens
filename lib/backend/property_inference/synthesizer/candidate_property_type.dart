// ─── CandidatePropertyType ────────────────────────────────────────────────────

/// Classifies the semantic intent of a [CandidateProperty].
///
/// Intentionally decoupled from [FormalPropertyType] — the mapping between
/// these two type systems belongs to the future emitter layer (Task 1C).
///
/// New values may be added without modifying existing synthesis rules.
enum CandidatePropertyType {
  /// The design must never enter a forbidden state or produce a forbidden value.
  safetyInvariant,

  /// A good thing must eventually happen — deadlock prevention, reset release, etc.
  livenessCondition,

  /// A specific state or value must be reachable in at least one execution.
  reachability,

  /// A signal must remain stable across a bounded time window.
  stability,

  /// A value must remain within its declared or logical bounds.
  boundedness,

  /// A constraint on the input space — not a check on the design itself.
  assumption,

  /// User-defined or catch-all type for extension.
  custom,
}
