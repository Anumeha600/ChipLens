import 'quality.dart';

// ─── CoverageWarningCategory ──────────────────────────────────────────────────

enum CoverageWarningCategory {
  state,
  transition,
  branch,
  toggle,
  condition,
  deadLogic,
}

// ─── CoverageWarning ──────────────────────────────────────────────────────────

/// Typed coverage warning with richer context than [QualityWarning].
class CoverageWarning {
  final CoverageWarningCategory category;

  /// The element that is not covered (state name, signal name, branch label, etc.)
  final String target;
  final String message;

  /// 'critical' | 'warning' | 'info'
  final String severity;
  final String? suggestion;

  const CoverageWarning({
    required this.category,
    required this.target,
    required this.message,
    required this.severity,
    this.suggestion,
  });

  QualityWarning toQualityWarning() => QualityWarning(
        type:     _typeFor(category),
        message:  message,
        severity: severity,
        source:   DiagnosticSource.coverage,
        quickFix: suggestion,
      );

  static String _typeFor(CoverageWarningCategory c) {
    switch (c) {
      case CoverageWarningCategory.state:      return 'coverage_unvisited_state';
      case CoverageWarningCategory.transition: return 'coverage_untaken_transition';
      case CoverageWarningCategory.branch:     return 'coverage_dead_branch';
      case CoverageWarningCategory.toggle:     return 'coverage_untoggled_signal';
      case CoverageWarningCategory.condition:  return 'coverage_unevaluated_condition';
      case CoverageWarningCategory.deadLogic:  return 'coverage_dead_logic';
    }
  }
}

// ─── CoverageMetrics ──────────────────────────────────────────────────────────

/// Raw counts underlying each coverage dimension.
/// Kept separate from [CoverageResult] so callers can build rich tables/charts.
class CoverageMetrics {
  final int totalStates;
  final int visitedStateCount;
  final int totalTransitions;
  final int executedTransitionCount;
  final int totalBranches;
  final int coveredBranchCount;
  final int totalSignals;
  final int toggledSignalCount;
  final int totalConditions;
  final int evaluatedConditionCount;
  final int totalLines;
  final int executedLineCount;

  const CoverageMetrics({
    required this.totalStates,
    required this.visitedStateCount,
    required this.totalTransitions,
    required this.executedTransitionCount,
    required this.totalBranches,
    required this.coveredBranchCount,
    required this.totalSignals,
    required this.toggledSignalCount,
    required this.totalConditions,
    required this.evaluatedConditionCount,
    required this.totalLines,
    required this.executedLineCount,
  });

  int get unvisitedStateCount        => totalStates       - visitedStateCount;
  int get missingTransitionCount     => totalTransitions  - executedTransitionCount;
  int get uncoveredBranchCount       => totalBranches     - coveredBranchCount;
  int get untoggledSignalCount       => totalSignals      - toggledSignalCount;
  int get unevaluatedConditionCount  => totalConditions   - evaluatedConditionCount;
  int get unexecutedLineCount        => totalLines        - executedLineCount;

  static const empty = CoverageMetrics(
    totalStates: 0, visitedStateCount: 0,
    totalTransitions: 0, executedTransitionCount: 0,
    totalBranches: 0, coveredBranchCount: 0,
    totalSignals: 0, toggledSignalCount: 0,
    totalConditions: 0, evaluatedConditionCount: 0,
    totalLines: 0, executedLineCount: 0,
  );

  Map<String, dynamic> toMap() => {
    'totalStates':                totalStates,
    'visitedStateCount':          visitedStateCount,
    'totalTransitions':           totalTransitions,
    'executedTransitionCount':    executedTransitionCount,
    'totalBranches':              totalBranches,
    'coveredBranchCount':         coveredBranchCount,
    'totalSignals':               totalSignals,
    'toggledSignalCount':         toggledSignalCount,
    'totalConditions':            totalConditions,
    'evaluatedConditionCount':    evaluatedConditionCount,
    'totalLines':                 totalLines,
    'executedLineCount':          executedLineCount,
  };
}

// ─── CoverageHeatMapData ──────────────────────────────────────────────────────

/// Normalized heat values (0.0 = completely cold, 1.0 = fully covered).
/// Designed to feed a future heatmap widget without coupling it to [CoverageReport].
class CoverageHeatMapData {
  /// stateName → fraction of times this state was visited out of total timesteps
  final Map<String, double> stateHeat;

  /// signalName → 1.0 if toggled, 0.0 if never toggled
  final Map<String, double> signalHeat;

  /// branch label → 1.0 if covered, 0.0 if not
  final Map<String, double> branchHeat;

  const CoverageHeatMapData({
    required this.stateHeat,
    required this.signalHeat,
    required this.branchHeat,
  });

  static const empty = CoverageHeatMapData(
    stateHeat: {},
    signalHeat: {},
    branchHeat: {},
  );

  Map<String, dynamic> toMap() => {
    'stateHeat':  stateHeat,
    'signalHeat': signalHeat,
    'branchHeat': branchHeat,
  };
}
