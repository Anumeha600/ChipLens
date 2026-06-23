import 'repair_priority.dart';
import 'repair_statistics.dart';
import 'repair_step.dart';

// ─── RepairPlan ───────────────────────────────────────────────────────────────

/// Immutable repair strategy produced by [RepairPlanner.plan].
///
/// Contains an ordered list of [RepairStep]s, summary statistics,
/// an overall priority, and an overall complexity estimate.
///
/// The constructor validates all structural invariants:
/// - All step [id]s are unique.
/// - All [RepairDependency.dependsOn] targets exist in [steps].
/// - No circular dependencies.
///
/// Invariants:
/// - [steps] is unmodifiable.
/// - Every dependency target exists in [steps].
/// - No circular dependency graph exists.
///
/// Future extension points:
/// - Add [estimatedDuration] for timeline-aware tooling.
/// - Add [repairHistory] for incremental re-planning.
/// - Add [approvalGates] for interactive repair workflows.
class RepairPlan {
  /// Ordered repair steps — highest priority first, then by dependency level,
  /// then by category, then by title.
  final List<RepairStep> steps;

  /// Derived counts summarising priority distribution and dependencies.
  final RepairStatistics statistics;

  /// Highest priority among all steps, or [RepairPriority.low] when empty.
  final RepairPriority overallPriority;

  /// Highest complexity among all steps, or [RepairComplexity.low] when empty.
  final RepairComplexity overallComplexity;

  RepairPlan({
    required List<RepairStep> steps,
    required this.statistics,
    required this.overallPriority,
    required this.overallComplexity,
  }) : steps = List.unmodifiable(List.of(steps)) {
    _validate(this.steps);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// `true` when at least one repair step exists.
  bool get hasRepairs => steps.isNotEmpty;

  /// `true` when no repair steps exist.
  bool get isEmpty => steps.isEmpty;

  // ── Validation ────────────────────────────────────────────────────────────

  static void _validate(List<RepairStep> steps) {
    final ids = <String>{};
    for (final s in steps) {
      if (!ids.add(s.id)) {
        throw StateError(
          'RepairPlan: duplicate step id "${s.id}".',
        );
      }
    }
    for (final s in steps) {
      for (final d in s.dependencies) {
        if (!ids.contains(d.dependsOn)) {
          throw StateError(
            'RepairPlan: dependency target "${d.dependsOn}" in step '
            '"${s.id}" does not exist in the plan.',
          );
        }
      }
    }
    _detectCycles(steps, ids);
  }

  static void _detectCycles(List<RepairStep> steps, Set<String> ids) {
    final graph = <String, List<String>>{
      for (final s in steps)
        s.id: s.dependencies.map((d) => d.dependsOn).toList(),
    };
    final visited = <String>{};
    final onStack = <String>{};

    void dfs(String node) {
      if (onStack.contains(node)) {
        throw StateError(
          'RepairPlan: circular dependency detected involving step "$node".',
        );
      }
      if (visited.contains(node)) return;
      onStack.add(node);
      visited.add(node);
      for (final next in (graph[node] ?? const [])) {
        dfs(next);
      }
      onStack.remove(node);
    }

    for (final id in ids) {
      dfs(id);
    }
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairPlan &&
          overallPriority   == other.overallPriority   &&
          overallComplexity == other.overallComplexity &&
          statistics        == other.statistics        &&
          _stepsEqual(steps, other.steps);

  static bool _stepsEqual(List<RepairStep> a, List<RepairStep> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(overallPriority, overallComplexity, statistics, steps.length);

  @override
  String toString() =>
      'RepairPlan(steps=${steps.length}, priority=${overallPriority.name}, '
      'complexity=${overallComplexity.name})';
}
