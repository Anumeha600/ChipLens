// ─── RepairDependency ─────────────────────────────────────────────────────────

/// Represents a directed prerequisite relationship between two [RepairStep]s.
///
/// A dependency `(repairId, dependsOn)` means: the repair step identified by
/// [repairId] cannot be safely performed until the repair step identified by
/// [dependsOn] has been completed.
///
/// Invariants:
/// - [repairId] != [dependsOn] (no self-dependency).
/// - All referenced IDs must exist in the enclosing [RepairPlan].
/// - No cycles are permitted across all dependencies in a [RepairPlan].
///
/// Dependency Rules (applied by [RepairPlanner]):
/// - configuration repairs must complete before verification repairs.
/// - property repairs should complete before coverage repairs.
/// - planning repairs are independent.
///
/// Future extension points:
/// - Add [dependencyType] (hard/soft) for flexible scheduling.
/// - Add [estimatedDelay] for critical-path analysis.
class RepairDependency {
  /// Identifier of the [RepairStep] that has this prerequisite.
  final String repairId;

  /// Identifier of the [RepairStep] that must complete first.
  final String dependsOn;

  /// Human-readable justification for this dependency.
  final String reason;

  const RepairDependency({
    required this.repairId,
    required this.dependsOn,
    required this.reason,
  });

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairDependency &&
          repairId  == other.repairId  &&
          dependsOn == other.dependsOn &&
          reason    == other.reason;

  @override
  int get hashCode => Object.hash(repairId, dependsOn, reason);

  @override
  String toString() =>
      'RepairDependency($repairId → $dependsOn)';
}
