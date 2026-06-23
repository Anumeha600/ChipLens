// ─── OrchestratorContext ──────────────────────────────────────────────────────

/// Immutable configuration that drives [VerificationOrchestrator].
///
/// All fields have sensible defaults so a bare `OrchestratorContext()` runs
/// the full pipeline with all optional stages enabled.
///
/// Invariants:
/// - All fields are `final` — use [copyWith] to derive variants.
/// - A [timeout] of [Duration.zero] means no timeout.
///
/// Optional stages:
/// - [enableExplainability]  — controls the explainability stage.
/// - [enableCoverage]        — controls the coverage-intelligence stage.
/// - [enableDiagnostics]     — controls the diagnostics stage.
/// - [enableRepairPlanning]  — controls the repair-planning stage.
///
/// Future extension points:
/// - Add [parallelStages] for concurrent stage execution.
/// - Add [checkpointDir] for resume-from-checkpoint support.
/// - Add [progressCallback] for real-time progress reporting.
class OrchestratorContext {
  /// When `true`, the explainability stage generates [VerificationExplanationSet].
  ///
  /// When `false`, an empty [VerificationExplanationSet] is used downstream.
  final bool enableExplainability;

  /// When `true`, the coverage-intelligence stage produces a [CoverageAssessment].
  ///
  /// When `false`, a default healthy [CoverageAssessment] is used downstream.
  final bool enableCoverage;

  /// When `true`, the diagnostics stage produces a [DiagnosticReport].
  ///
  /// When `false`, an empty [DiagnosticReport] (informational severity) is used.
  final bool enableDiagnostics;

  /// When `true`, the repair-planning stage produces a [RepairPlan].
  ///
  /// When `false`, an empty [RepairPlan] is used.
  final bool enableRepairPlanning;

  /// When `true`, [VerificationSessionResult.statistics] is populated with
  /// stage counts and timing.
  ///
  /// When `false`, [OrchestratorStatistics.empty] is stored instead.
  final bool collectStatistics;

  /// Maximum wall-clock duration for the entire pipeline.
  ///
  /// A value of [Duration.zero] means no timeout.  When the timeout elapses
  /// the session is cancelled and [VerificationStatus.cancelled] is reported.
  final Duration timeout;

  const OrchestratorContext({
    this.enableExplainability = true,
    this.enableCoverage       = true,
    this.enableDiagnostics    = true,
    this.enableRepairPlanning = true,
    this.collectStatistics    = true,
    this.timeout              = Duration.zero,
  });

  /// Returns a copy with only the specified fields overridden.
  OrchestratorContext copyWith({
    bool?     enableExplainability,
    bool?     enableCoverage,
    bool?     enableDiagnostics,
    bool?     enableRepairPlanning,
    bool?     collectStatistics,
    Duration? timeout,
  }) =>
      OrchestratorContext(
        enableExplainability: enableExplainability ?? this.enableExplainability,
        enableCoverage:       enableCoverage       ?? this.enableCoverage,
        enableDiagnostics:    enableDiagnostics    ?? this.enableDiagnostics,
        enableRepairPlanning: enableRepairPlanning ?? this.enableRepairPlanning,
        collectStatistics:    collectStatistics    ?? this.collectStatistics,
        timeout:              timeout              ?? this.timeout,
      );

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrchestratorContext &&
          enableExplainability == other.enableExplainability &&
          enableCoverage       == other.enableCoverage       &&
          enableDiagnostics    == other.enableDiagnostics    &&
          enableRepairPlanning == other.enableRepairPlanning &&
          collectStatistics    == other.collectStatistics    &&
          timeout              == other.timeout;

  @override
  int get hashCode => Object.hash(
        enableExplainability, enableCoverage, enableDiagnostics,
        enableRepairPlanning, collectStatistics, timeout);

  @override
  String toString() =>
      'OrchestratorContext('
      'explainability=$enableExplainability, '
      'coverage=$enableCoverage, '
      'diagnostics=$enableDiagnostics, '
      'repair=$enableRepairPlanning, '
      'timeout=${timeout.inMilliseconds}ms)';
}
