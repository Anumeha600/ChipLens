import 'planning_policy.dart';

// ─── PlanningContext ──────────────────────────────────────────────────────────

/// Immutable configuration that drives [VerificationPlanner].
///
/// All fields have sensible defaults so callers only override what they need.
///
/// Future extension points:
/// - timeout per job
/// - engine hints
/// - resource budget
class PlanningContext {
  /// Maximum number of properties per batch.
  ///
  /// Ignored for [BatchStrategy.sequential] and [BatchStrategy.propertyType].
  /// Must be >= 1 when using [BatchStrategy.fixedSize].
  /// Use -1 to signal "no limit" for strategies that support it.
  final int maximumBatchSize;

  /// Algorithm for grouping properties into batches.
  final BatchStrategy batchStrategy;

  /// Policy object that converts a [FormalPropertySet] into a [VerificationPlan].
  final PlanningPolicy planningPolicy;

  /// When `true`, the plan preserves the input ordering of [FormalPropertySet].
  ///
  /// Strategies that reorder (e.g. [BatchStrategy.confidence]) still honour
  /// the confidence sort but keep within-confidence ordering stable.
  final bool preserveRanking;

  /// When `true`, [PlanningResult] includes a populated [PlanningStatistics].
  final bool includeStatistics;

  const PlanningContext({
    this.maximumBatchSize = -1,
    this.batchStrategy    = BatchStrategy.sequential,
    this.planningPolicy   = const DefaultPlanningPolicy(),
    this.preserveRanking  = true,
    this.includeStatistics = true,
  });

  /// Returns a copy with only the specified fields overridden.
  PlanningContext copyWith({
    int?            maximumBatchSize,
    BatchStrategy?  batchStrategy,
    PlanningPolicy? planningPolicy,
    bool?           preserveRanking,
    bool?           includeStatistics,
  }) =>
      PlanningContext(
        maximumBatchSize:  maximumBatchSize  ?? this.maximumBatchSize,
        batchStrategy:     batchStrategy     ?? this.batchStrategy,
        planningPolicy:    planningPolicy    ?? this.planningPolicy,
        preserveRanking:   preserveRanking   ?? this.preserveRanking,
        includeStatistics: includeStatistics ?? this.includeStatistics,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanningContext &&
          maximumBatchSize  == other.maximumBatchSize  &&
          batchStrategy     == other.batchStrategy     &&
          preserveRanking   == other.preserveRanking   &&
          includeStatistics == other.includeStatistics;

  @override
  int get hashCode => Object.hash(
        maximumBatchSize, batchStrategy, preserveRanking, includeStatistics);

  @override
  String toString() =>
      'PlanningContext(maxBatch=$maximumBatchSize, '
      'strategy=${batchStrategy.name})';
}
