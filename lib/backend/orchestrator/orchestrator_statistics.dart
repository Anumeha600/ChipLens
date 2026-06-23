// ─── OrchestratorStatistics ───────────────────────────────────────────────────

/// Execution statistics for one [VerificationSession].
///
/// Collected by [VerificationOrchestrator] during pipeline execution and
/// included in every [VerificationSessionResult] when
/// [OrchestratorContext.collectStatistics] is `true`.
///
/// When statistics collection is disabled the orchestrator substitutes
/// [OrchestratorStatistics.empty].
///
/// Invariants:
/// - All integer counts are non-negative.
/// - [completedStages] + [skippedStages] + [failedStages] equals the total
///   number of stages that were dispatched during the session.
///
/// Future extension points:
/// - Add per-stage timing breakdown ([Map<OrchestratorStage, Duration>]).
/// - Add [peakMemoryBytes] for resource-budget tracking.
/// - Add [retryCount] when automatic retry is introduced.
class OrchestratorStatistics {
  /// Total wall-clock time from session start to result assembly.
  final Duration totalExecutionTime;

  /// Number of pipeline stages that completed successfully.
  final int completedStages;

  /// Number of pipeline stages that were skipped because the corresponding
  /// [OrchestratorContext] flag was `false`.
  final int skippedStages;

  /// Number of pipeline stages that produced a non-fatal error and fell back
  /// to a default result.
  final int failedStages;

  const OrchestratorStatistics({
    required this.totalExecutionTime,
    required this.completedStages,
    required this.skippedStages,
    required this.failedStages,
  });

  /// Zero-value statistics used when [OrchestratorContext.collectStatistics]
  /// is `false`.
  static const OrchestratorStatistics empty = OrchestratorStatistics(
    totalExecutionTime: Duration.zero,
    completedStages:    0,
    skippedStages:      0,
    failedStages:       0,
  );

  // ── Identity ──────────────────────────────────────────────────────────────

  // Equality compares stage counts only — totalExecutionTime is wall-clock
  // timing and is intentionally excluded so that two statistics objects
  // collected for identical pipelines compare equal regardless of machine speed.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrchestratorStatistics &&
          completedStages == other.completedStages &&
          skippedStages   == other.skippedStages   &&
          failedStages    == other.failedStages;

  @override
  int get hashCode => Object.hash(completedStages, skippedStages, failedStages);

  @override
  String toString() =>
      'OrchestratorStatistics('
      'completed=$completedStages, '
      'skipped=$skippedStages, '
      'failed=$failedStages, '
      'time=${totalExecutionTime.inMilliseconds}ms)';
}
