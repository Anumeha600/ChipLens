import '../../models/design_spec.dart';

// ─── CoverageResult ───────────────────────────────────────────────────────────

/// Aggregated coverage metrics and per-item detail lists from one simulation run.
///
/// All fraction fields (0.0–1.0) are derived from the simulation trace and RTL
/// structure by [CoverageAnalyzer.analyze].  When simulation output is absent
/// or empty every fraction is 0.0 and all "uncovered" lists reflect the full set.
class CoverageResult {
  /// Fraction of FSM states visited at least once.  0.0–1.0.
  final double stateCoverage;

  /// Fraction of spec-defined FSM transitions observed in the trace.  0.0–1.0.
  final double transitionCoverage;

  /// Fraction of RTL branches (if/else and case items) exercised.  0.0–1.0.
  final double branchCoverage;

  /// Fraction of tracked output signals that changed value at least once.  0.0–1.0.
  final double toggleCoverage;

  /// Fraction of boolean conditions (if-guard expressions) that were both
  /// asserted and de-asserted during simulation.  0.0–1.0.
  final double conditionCoverage;

  /// Fraction of executable RTL lines (statements inside always/initial blocks)
  /// that were reachable given the observed state/branch coverage.  0.0–1.0.
  final double lineCoverage;

  /// Weighted composite:
  /// 30 % state + 25 % transition + 20 % branch + 10 % toggle +
  /// 10 % condition + 5 % line.
  final double overallCoverage;

  // ── Detail lists (used by UI and warning generation) ──────────────────────

  final List<String> visitedStates;
  final List<String> unvisitedStates;

  /// "FROM → TO" strings for observed transitions.
  final List<String> takenTransitions;

  /// "FROM → TO" strings for transitions defined in the spec but never observed.
  final List<String> untakenTransitions;

  final List<String> coveredBranches;
  final List<String> uncoveredBranches;

  final List<String> toggledSignals;
  final List<String> untoggledSignals;

  /// Conditions (if-guard expressions) that toggled both true and false.
  final List<String> coveredConditions;

  /// Conditions that were only ever seen in one direction (or never executed).
  final List<String> uncoveredConditions;

  /// [QualityWarning] objects ready to be added to a [QualityReport].
  final List<QualityWarning> warnings;

  const CoverageResult({
    required this.stateCoverage,
    required this.transitionCoverage,
    required this.branchCoverage,
    required this.toggleCoverage,
    required this.conditionCoverage,
    required this.lineCoverage,
    required this.overallCoverage,
    required this.visitedStates,
    required this.unvisitedStates,
    required this.takenTransitions,
    required this.untakenTransitions,
    required this.coveredBranches,
    required this.uncoveredBranches,
    required this.toggledSignals,
    required this.untoggledSignals,
    required this.coveredConditions,
    required this.uncoveredConditions,
    required this.warnings,
  });

  /// All-zero result for when simulation did not produce usable output.
  factory CoverageResult.empty() => const CoverageResult(
        stateCoverage:      0,
        transitionCoverage: 0,
        branchCoverage:     0,
        toggleCoverage:     0,
        conditionCoverage:  0,
        lineCoverage:       0,
        overallCoverage:    0,
        visitedStates:      [],
        unvisitedStates:    [],
        takenTransitions:   [],
        untakenTransitions: [],
        coveredBranches:    [],
        uncoveredBranches:  [],
        toggledSignals:     [],
        untoggledSignals:   [],
        coveredConditions:  [],
        uncoveredConditions: [],
        warnings:           [],
      );

  /// Weighted overall coverage:
  /// 30 % state + 25 % transition + 20 % branch + 10 % toggle +
  /// 10 % condition + 5 % line.
  static double weighted(double s, double t, double b, double g,
          double c, double l) =>
      s * 0.30 + t * 0.25 + b * 0.20 + g * 0.10 + c * 0.10 + l * 0.05;

  /// Convenience alias — same as [warnings].
  List<QualityWarning> get coverageWarnings => warnings;

  /// Human-readable coverage tier.
  String get grade {
    if (overallCoverage >= 0.95) return 'Excellent';
    if (overallCoverage >= 0.80) return 'Good';
    if (overallCoverage >= 0.60) return 'Fair';
    if (overallCoverage >= 0.40) return 'Poor';
    return 'Critical';
  }

  /// Total number of coverage items that are NOT yet covered.
  int get totalGaps =>
      unvisitedStates.length +
      untakenTransitions.length +
      uncoveredBranches.length +
      untoggledSignals.length +
      uncoveredConditions.length;
}
