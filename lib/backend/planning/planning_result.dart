import 'planning_statistics.dart';
import 'verification_plan.dart';

// ─── PlanningResult ───────────────────────────────────────────────────────────

/// Immutable result returned by [VerificationPlanner.plan].
///
/// Bundles the [VerificationPlan], optional [PlanningStatistics], a list of
/// non-fatal warnings, and the wall-clock time taken to produce the plan.
///
/// Invariants:
/// - [warnings] is unmodifiable.
/// - [plan] is never null.
/// - [statistics] is never null (use [PlanningStatistics.empty] when statistics
///   are disabled via [PlanningContext.includeStatistics]).
class PlanningResult {
  /// The planned verification jobs.
  final VerificationPlan plan;

  /// Summary statistics derived from [plan].
  final PlanningStatistics statistics;

  /// Non-fatal warnings generated during planning (e.g. missing metadata).
  final List<String> warnings;

  /// Wall-clock time taken to produce the plan.
  final Duration planningTime;

  PlanningResult({
    required this.plan,
    required this.statistics,
    List<String>? warnings,
    required this.planningTime,
  }) : warnings = List.unmodifiable(warnings ?? const []);

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get hasWarnings => warnings.isNotEmpty;

  bool get isEmpty => plan.isEmpty;

  bool get isNotEmpty => plan.isNotEmpty;

  @override
  String toString() =>
      'PlanningResult(jobs=${plan.length}, batches=${statistics.batches}, '
      'warnings=${warnings.length}, time=${planningTime.inMilliseconds}ms)';
}
