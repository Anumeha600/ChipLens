// ─── RepairContext ────────────────────────────────────────────────────────────

/// Immutable configuration that drives [RepairPlanner].
///
/// All fields have sensible defaults so callers only override what they need.
///
/// Invariants:
/// - [maximumRepairSteps] must be >= -1 (-1 means no limit).
///
/// Future extension points:
/// - Add [minimumPriority] to suppress low-priority steps.
/// - Add [categoryFilter] to restrict which [RepairCategory] values appear.
/// - Add [dependencyDepthLimit] to prevent deep dependency chains.
class RepairContext {
  /// When `true`, [RepairPlan.statistics] is populated from the step list.
  final bool includeStatistics;

  /// When `true`, [RepairStep.dependencies] are generated based on the
  /// configured dependency rules.
  final bool includeDependencies;

  /// When `true`, [RepairStep.complexity] and [RepairPlan.overallComplexity]
  /// are computed from the repair category.
  final bool includeComplexity;

  /// When `true`, steps appear in the same order as their source
  /// [DiagnosticIssue]s (diagnostic engine ordering).  When `false`,
  /// steps are sorted by priority (descending), then dependency level
  /// (ascending), then category, then title.
  final bool preserveDiagnosticOrdering;

  /// Maximum number of steps to include in [RepairPlan.steps].
  /// -1 means no limit.
  final int maximumRepairSteps;

  RepairContext({
    this.includeStatistics         = true,
    this.includeDependencies       = true,
    this.includeComplexity         = true,
    this.preserveDiagnosticOrdering = false,
    this.maximumRepairSteps        = -1,
  }) {
    if (maximumRepairSteps < -1) {
      throw ArgumentError.value(
        maximumRepairSteps,
        'maximumRepairSteps',
        'maximumRepairSteps must be >= -1 (-1 means no limit)',
      );
    }
  }

  /// Returns a copy with only the specified fields overridden.
  RepairContext copyWith({
    bool? includeStatistics,
    bool? includeDependencies,
    bool? includeComplexity,
    bool? preserveDiagnosticOrdering,
    int?  maximumRepairSteps,
  }) =>
      RepairContext(
        includeStatistics:          includeStatistics         ?? this.includeStatistics,
        includeDependencies:        includeDependencies        ?? this.includeDependencies,
        includeComplexity:          includeComplexity          ?? this.includeComplexity,
        preserveDiagnosticOrdering: preserveDiagnosticOrdering ?? this.preserveDiagnosticOrdering,
        maximumRepairSteps:         maximumRepairSteps         ?? this.maximumRepairSteps,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairContext &&
          includeStatistics          == other.includeStatistics          &&
          includeDependencies        == other.includeDependencies        &&
          includeComplexity          == other.includeComplexity          &&
          preserveDiagnosticOrdering == other.preserveDiagnosticOrdering &&
          maximumRepairSteps         == other.maximumRepairSteps;

  @override
  int get hashCode => Object.hash(
        includeStatistics, includeDependencies, includeComplexity,
        preserveDiagnosticOrdering, maximumRepairSteps);

  @override
  String toString() =>
      'RepairContext(maxSteps=$maximumRepairSteps, '
      'preserveOrder=$preserveDiagnosticOrdering)';
}
