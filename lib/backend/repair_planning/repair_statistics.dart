import 'repair_priority.dart';
import 'repair_step.dart';

// ─── RepairStatistics ─────────────────────────────────────────────────────────

/// Derived metrics summarising a [RepairPlan].
///
/// All fields are non-negative counts computed from the [RepairStep] list.
/// The priority counts must always sum to [repairCount]; the constructor
/// enforces this invariant at construction time.
///
/// Invariants:
/// - All fields are non-negative.
/// - [repairCount] >= 0.
/// - [criticalRepairs] + [highPriorityRepairs] + [mediumPriorityRepairs] +
///   [lowPriorityRepairs] == [repairCount].
///
/// Future extension points:
/// - Add [repairsByCategory] map for per-domain breakdown.
/// - Add [estimatedTotalCost] for sprint planning.
class RepairStatistics {
  /// Total number of repair steps in the [RepairPlan].
  final int repairCount;

  /// Number of [RepairPriority.critical] steps.
  final int criticalRepairs;

  /// Number of [RepairPriority.high] steps.
  final int highPriorityRepairs;

  /// Number of [RepairPriority.medium] steps.
  final int mediumPriorityRepairs;

  /// Number of [RepairPriority.low] steps.
  final int lowPriorityRepairs;

  /// Total number of [RepairDependency] records across all steps.
  final int dependencyCount;

  RepairStatistics({
    required this.repairCount,
    required this.criticalRepairs,
    required this.highPriorityRepairs,
    required this.mediumPriorityRepairs,
    required this.lowPriorityRepairs,
    required this.dependencyCount,
  }) {
    if (repairCount < 0) {
      throw ArgumentError.value(
        repairCount, 'repairCount', 'repairCount must be >= 0',
      );
    }
    final sum =
        criticalRepairs + highPriorityRepairs + mediumPriorityRepairs + lowPriorityRepairs;
    if (sum != repairCount) {
      throw StateError(
        'RepairStatistics: priority counts ($sum) do not sum to '
        'repairCount ($repairCount).',
      );
    }
  }

  /// Zero-value statistics for an empty or disabled plan.
  static final RepairStatistics empty = RepairStatistics(
    repairCount:           0,
    criticalRepairs:       0,
    highPriorityRepairs:   0,
    mediumPriorityRepairs: 0,
    lowPriorityRepairs:    0,
    dependencyCount:       0,
  );

  /// Builds statistics from a step list in O(n).
  factory RepairStatistics.fromSteps(List<RepairStep> steps) {
    int critical = 0, high = 0, medium = 0, low = 0, deps = 0;
    for (final step in steps) {
      switch (step.priority) {
        case RepairPriority.critical: critical++; break;
        case RepairPriority.high:     high++;     break;
        case RepairPriority.medium:   medium++;   break;
        case RepairPriority.low:      low++;      break;
      }
      deps += step.dependencies.length;
    }
    return RepairStatistics(
      repairCount:           steps.length,
      criticalRepairs:       critical,
      highPriorityRepairs:   high,
      mediumPriorityRepairs: medium,
      lowPriorityRepairs:    low,
      dependencyCount:       deps,
    );
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairStatistics &&
          repairCount           == other.repairCount           &&
          criticalRepairs       == other.criticalRepairs       &&
          highPriorityRepairs   == other.highPriorityRepairs   &&
          mediumPriorityRepairs == other.mediumPriorityRepairs &&
          lowPriorityRepairs    == other.lowPriorityRepairs    &&
          dependencyCount       == other.dependencyCount;

  @override
  int get hashCode => Object.hash(
        repairCount, criticalRepairs, highPriorityRepairs,
        mediumPriorityRepairs, lowPriorityRepairs, dependencyCount);

  @override
  String toString() =>
      'RepairStatistics(total=$repairCount, critical=$criticalRepairs, '
      'high=$highPriorityRepairs, medium=$mediumPriorityRepairs, '
      'low=$lowPriorityRepairs, deps=$dependencyCount)';
}
