// ─── FormalPropertyType ───────────────────────────────────────────────────────

/// Classifies the logical role of a [FormalProperty].
///
/// Designed for future expansion — new types can be added without touching any
/// other class in the property system.
enum FormalPropertyType {
  /// `assert(...)` — a safety property that must hold in every reachable state.
  assertion,

  /// `assume(...)` — constrains the input space; the engine treats violations
  /// as unreachable rather than as failures.
  assumption,

  /// `cover(...)` — a reachability check; the engine must find at least one
  /// trace that satisfies the condition.
  cover,

  /// Holds in every reachable state by definition (stronger than [assertion]):
  /// typically derived from a global design contract rather than a local check.
  invariant,

  /// Linear-time safety: a bad thing never happens.  Often compiled to
  /// `assert` by backends; kept separate for semantic clarity.
  safety,

  /// Linear-time liveness: a good thing eventually happens.  Requires
  /// temporal-logic or k-induction support in the backend.
  liveness,
}
