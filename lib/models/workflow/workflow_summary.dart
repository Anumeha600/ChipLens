/// Immutable aggregate counts across all [WorkflowStep]s in a
/// [VerificationWorkflow].
///
/// [WorkflowSummary] is a pure value object — it stores counts and carries
/// no derivation or interpretation logic.
///
/// Future extension points (not yet implemented):
/// - elapsed wall-clock time
/// - per-stage timing breakdown
/// - benchmark deltas
class WorkflowSummary {
  /// Total number of steps in the workflow.
  final int totalSteps;

  /// Number of steps that reached [WorkflowStatus.completed].
  final int completedSteps;

  /// Number of steps that reached [WorkflowStatus.failed].
  final int failedSteps;

  /// Number of steps that were [WorkflowStatus.skipped].
  final int skippedSteps;

  const WorkflowSummary({
    required this.totalSteps,
    required this.completedSteps,
    required this.failedSteps,
    required this.skippedSteps,
  });

  /// Returns a copy with selected fields replaced.
  WorkflowSummary copyWith({
    int? totalSteps,
    int? completedSteps,
    int? failedSteps,
    int? skippedSteps,
  }) {
    return WorkflowSummary(
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      failedSteps: failedSteps ?? this.failedSteps,
      skippedSteps: skippedSteps ?? this.skippedSteps,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowSummary &&
          totalSteps == other.totalSteps &&
          completedSteps == other.completedSteps &&
          failedSteps == other.failedSteps &&
          skippedSteps == other.skippedSteps;

  @override
  int get hashCode =>
      Object.hash(totalSteps, completedSteps, failedSteps, skippedSteps);
}
