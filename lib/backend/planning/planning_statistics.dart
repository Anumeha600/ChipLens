import 'verification_plan.dart';
import 'verification_plan_item.dart';

// ─── PlanningStatistics ───────────────────────────────────────────────────────

/// Immutable summary of the [VerificationPlan] produced by [VerificationPlanner].
///
/// All values are derived from [VerificationPlan.jobs]; no external data is
/// required.  Computed once at planning time and never recomputed.
///
/// Invariants:
/// - [averageBatchSize] is 0.0 when [batches] == 0.
/// - [largestBatch] and [smallestBatch] are 0 when [plannedJobs] == 0.
/// - [estimatedExecutionCost] is the sum of [VerificationPlanItem.estimatedCost].
class PlanningStatistics {
  /// Total number of planned verification jobs.
  final int plannedJobs;

  /// Number of distinct batches in the plan.
  final int batches;

  /// Size of the largest batch (0 when plan is empty).
  final int largestBatch;

  /// Size of the smallest batch (0 when plan is empty).
  final int smallestBatch;

  /// Mean number of jobs per batch (0.0 when plan is empty).
  final double averageBatchSize;

  /// Sum of [VerificationPlanItem.estimatedCost] across all jobs.
  final double estimatedExecutionCost;

  const PlanningStatistics({
    required this.plannedJobs,
    required this.batches,
    required this.largestBatch,
    required this.smallestBatch,
    required this.averageBatchSize,
    required this.estimatedExecutionCost,
  });

  /// Zero-value statistics for an empty plan.
  static const PlanningStatistics empty = PlanningStatistics(
    plannedJobs:            0,
    batches:                0,
    largestBatch:           0,
    smallestBatch:          0,
    averageBatchSize:       0.0,
    estimatedExecutionCost: 0.0,
  );

  /// Computes [PlanningStatistics] from a [VerificationPlan] in O(n) time.
  static PlanningStatistics fromPlan(VerificationPlan plan) {
    if (plan.isEmpty) return PlanningStatistics.empty;

    final batchSizes = <int, int>{};
    double totalCost = 0.0;

    for (final job in plan.jobs) {
      batchSizes[job.batchId] = (batchSizes[job.batchId] ?? 0) + 1;
      totalCost += job.estimatedCost;
    }

    final sizes   = batchSizes.values.toList();
    final batches = sizes.length;
    int largest  = sizes[0];
    int smallest = sizes[0];
    for (final s in sizes) {
      if (s > largest)  largest  = s;
      if (s < smallest) smallest = s;
    }

    return PlanningStatistics(
      plannedJobs:            plan.length,
      batches:                batches,
      largestBatch:           largest,
      smallestBatch:          smallest,
      averageBatchSize:       plan.length / batches,
      estimatedExecutionCost: totalCost,
    );
  }

  @override
  String toString() =>
      'PlanningStatistics(jobs=$plannedJobs, batches=$batches, '
      'cost=${estimatedExecutionCost.toStringAsFixed(2)})';
}
