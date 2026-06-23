import '../../models/coverage_model.dart';
import '../../models/coverage_report.dart';
import 'coverage_assessment.dart';
import 'coverage_confidence.dart';
import 'coverage_recommendation.dart';
import 'coverage_risk.dart';
import 'coverage_statistics.dart';
import 'coverage_summary.dart';

// ─── CoverageIntelligenceContext ──────────────────────────────────────────────

/// Immutable configuration that drives [CoverageIntelligenceEngine].
///
/// All fields have sensible defaults so callers only override what they need.
///
/// Future extension points:
/// - [minimumConfidenceThreshold] for CI/CD quality gates.
/// - [historicalReport] for coverage delta analysis.
class CoverageIntelligenceContext {
  /// When `true`, [CoverageAssessment.recommendations] is populated.
  final bool includeRecommendations;

  /// When `true`, [CoverageAssessment.risk] is computed from the report.
  final bool includeRiskAssessment;

  /// When `true`, [CoverageAssessment.confidence] is computed from the report.
  final bool includeConfidence;

  /// When `true`, [CoverageAssessment.statistics] is populated.
  final bool includeStatistics;

  /// Maximum number of recommendations to include.  -1 = no limit.
  final int maximumRecommendations;

  const CoverageIntelligenceContext({
    this.includeRecommendations  = true,
    this.includeRiskAssessment   = true,
    this.includeConfidence       = true,
    this.includeStatistics       = true,
    this.maximumRecommendations  = -1,
  });

  /// Returns a copy with only the specified fields overridden.
  CoverageIntelligenceContext copyWith({
    bool? includeRecommendations,
    bool? includeRiskAssessment,
    bool? includeConfidence,
    bool? includeStatistics,
    int?  maximumRecommendations,
  }) =>
      CoverageIntelligenceContext(
        includeRecommendations: includeRecommendations ?? this.includeRecommendations,
        includeRiskAssessment:  includeRiskAssessment  ?? this.includeRiskAssessment,
        includeConfidence:      includeConfidence      ?? this.includeConfidence,
        includeStatistics:      includeStatistics      ?? this.includeStatistics,
        maximumRecommendations: maximumRecommendations ?? this.maximumRecommendations,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverageIntelligenceContext &&
          includeRecommendations == other.includeRecommendations &&
          includeRiskAssessment  == other.includeRiskAssessment  &&
          includeConfidence      == other.includeConfidence      &&
          includeStatistics      == other.includeStatistics      &&
          maximumRecommendations == other.maximumRecommendations;

  @override
  int get hashCode => Object.hash(
        includeRecommendations, includeRiskAssessment,
        includeConfidence, includeStatistics, maximumRecommendations);

  @override
  String toString() =>
      'CoverageIntelligenceContext(maxRecs=$maximumRecommendations)';
}

// ─── CoverageIntelligenceEngine ───────────────────────────────────────────────

/// Interprets a [CoverageReport] and produces a [CoverageAssessment].
///
/// Responsibilities:
/// - Validates [CoverageReport] integrity before any reasoning.
/// - Computes [CoverageRisk], [CoverageConfidence], and [CoverageSummary].
/// - Generates deterministic [CoverageRecommendation]s.
/// - Assembles [CoverageStatistics].
///
/// Invariants:
/// - Does NOT compute coverage (that is [CoverageAnalyzer]'s responsibility).
/// - Does NOT modify [CoverageReport] or any upstream model.
/// - Stateless: every call is fully independent.
/// - Output is deterministic for identical [CoverageReport] inputs.
class CoverageIntelligenceEngine {
  /// Creates a [CoverageIntelligenceEngine].  Stateless — no configuration stored.
  const CoverageIntelligenceEngine();

  /// Produces a [CoverageAssessment] from [report] and [context].
  ///
  /// Throws [ArgumentError] when [CoverageReport.overallCoverage] is outside
  /// [0.0, 1.0] (including NaN).
  ///
  /// Throws [StateError] when [CoverageMetrics] are internally inconsistent
  /// (e.g. [CoverageMetrics.visitedStateCount] > [CoverageMetrics.totalStates]).
  CoverageAssessment assess(
    CoverageReport report,
    CoverageIntelligenceContext context,
  ) {
    _validateReport(report);

    final risk = context.includeRiskAssessment
        ? _computeRisk(report)
        : CoverageRisk.minimal;

    final confidence = context.includeConfidence
        ? _computeConfidence(report)
        : CoverageConfidence.veryHigh;

    final summary = _buildSummary(report, risk, confidence);

    final recommendations = context.includeRecommendations
        ? _buildRecommendations(report, context)
        : const <CoverageRecommendation>[];

    final statistics = context.includeStatistics
        ? _buildStatistics(report, recommendations)
        : CoverageStatistics.empty;

    return CoverageAssessment(
      summary:         summary,
      risk:            risk,
      confidence:      confidence,
      recommendations: recommendations,
      statistics:      statistics,
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  static void _validateReport(CoverageReport report) {
    final overall = report.overallCoverage;
    if (overall.isNaN || overall < 0.0 || overall > 1.0) {
      throw ArgumentError.value(
        overall,
        'report.overallCoverage',
        'Coverage fraction must be a finite value in [0.0, 1.0]',
      );
    }
    final m = report.metrics;
    if (m.visitedStateCount > m.totalStates) {
      throw StateError(
        'CoverageMetrics integrity violation: visitedStateCount '
        '(${m.visitedStateCount}) exceeds totalStates (${m.totalStates}).',
      );
    }
    if (m.executedTransitionCount > m.totalTransitions) {
      throw StateError(
        'CoverageMetrics integrity violation: executedTransitionCount '
        '(${m.executedTransitionCount}) exceeds totalTransitions '
        '(${m.totalTransitions}).',
      );
    }
  }

  // ── Risk ─────────────────────────────────────────────────────────────────

  static CoverageRisk _computeRisk(CoverageReport report) {
    final overall  = report.overallCoverage;
    final warnings = report.coverageWarnings;

    // Base risk level from coverage percentage
    int level = switch (true) {
      _ when overall >= 0.95 => CoverageRisk.minimal.index,
      _ when overall >= 0.80 => CoverageRisk.low.index,
      _ when overall >= 0.60 => CoverageRisk.moderate.index,
      _ when overall >= 0.40 => CoverageRisk.high.index,
      _                      => CoverageRisk.critical.index,
    };

    // Escalate for dead-logic warnings
    final hasCriticalDead = warnings.any((w) =>
        w.category == CoverageWarningCategory.deadLogic &&
        w.severity  == 'critical');
    final hasAnyDead = warnings.any(
        (w) => w.category == CoverageWarningCategory.deadLogic);

    if (hasCriticalDead) {
      level += 2;
    } else if (hasAnyDead) {
      level += 1;
    }

    // Escalate for high volume of critical warnings
    final criticalCount = warnings.where((w) => w.severity == 'critical').length;
    if (criticalCount >= 3) level += 1;

    return CoverageRisk.values[level.clamp(0, CoverageRisk.values.length - 1)];
  }

  // ── Confidence ────────────────────────────────────────────────────────────

  static CoverageConfidence _computeConfidence(CoverageReport report) {
    final overall = report.overallCoverage;

    // Base confidence from coverage percentage
    CoverageConfidence conf = switch (true) {
      _ when overall >= 0.95 => CoverageConfidence.veryHigh,
      _ when overall >= 0.80 => CoverageConfidence.high,
      _ when overall >= 0.60 => CoverageConfidence.medium,
      _ when overall >= 0.40 => CoverageConfidence.low,
      _                      => CoverageConfidence.veryLow,
    };

    // Critical warnings reduce confidence by exactly one level
    final hasCritical =
        report.coverageWarnings.any((w) => w.severity == 'critical');
    if (hasCritical && conf != CoverageConfidence.veryLow) {
      conf = CoverageConfidence.values[conf.index - 1];
    }

    return conf;
  }

  // ── Summary ───────────────────────────────────────────────────────────────

  static CoverageSummary _buildSummary(
    CoverageReport report,
    CoverageRisk risk,
    CoverageConfidence confidence,
  ) {
    final r = report.result;

    // Find strongest and weakest coverage dimension (alphabetical tie-break)
    final dims = {
      'branch':     r.branchCoverage,
      'condition':  r.conditionCoverage,
      'line':       r.lineCoverage,
      'state':      r.stateCoverage,
      'toggle':     r.toggleCoverage,
      'transition': r.transitionCoverage,
    };

    final sorted = dims.entries.toList()
      ..sort((a, b) {
          final cmp = b.value.compareTo(a.value);
          return cmp != 0 ? cmp : a.key.compareTo(b.key);
        });

    final strongest = sorted.first.key;
    final weakest   = sorted.last.key;

    // Dominant issue — checked in severity order
    final String dominantIssue;
    final hasCriticalDead = report.coverageWarnings.any((w) =>
        w.category == CoverageWarningCategory.deadLogic &&
        w.severity  == 'critical');
    final hasAnyDead = report.coverageWarnings.any(
        (w) => w.category == CoverageWarningCategory.deadLogic);

    if (hasCriticalDead) {
      dominantIssue = 'Critical dead logic detected';
    } else if (hasAnyDead) {
      dominantIssue = 'Dead logic detected';
    } else if (r.unvisitedStates.isNotEmpty) {
      dominantIssue = '${r.unvisitedStates.length} unvisited state(s)';
    } else if (r.untakenTransitions.isNotEmpty) {
      dominantIssue = '${r.untakenTransitions.length} untaken transition(s)';
    } else if (r.uncoveredBranches.isNotEmpty) {
      dominantIssue = '${r.uncoveredBranches.length} uncovered branch(es)';
    } else if (r.untoggledSignals.isNotEmpty) {
      dominantIssue = '${r.untoggledSignals.length} untoggled signal(s)';
    } else {
      dominantIssue =
          'No dominant issue — coverage is ${report.grade.toLowerCase()}';
    }

    final pct     = (r.overallCoverage * 100).toStringAsFixed(1);
    final overview =
        'Overall verification coverage is $pct% (${report.grade}). '
        'Risk: ${risk.name}. Confidence: ${confidence.name}.';

    return CoverageSummary(
      overview:           overview,
      strongestDimension: strongest,
      weakestDimension:   weakest,
      dominantIssue:      dominantIssue,
    );
  }

  // ── Recommendations ───────────────────────────────────────────────────────

  static List<CoverageRecommendation> _buildRecommendations(
    CoverageReport report,
    CoverageIntelligenceContext context,
  ) {
    final r    = report.result;
    final recs = <CoverageRecommendation>[];

    // Dead-logic (critical) — checked first; escalates priority
    final criticalDead = report.coverageWarnings
        .where((w) =>
            w.category == CoverageWarningCategory.deadLogic &&
            w.severity  == 'critical')
        .toList();
    if (criticalDead.isNotEmpty) {
      recs.add(CoverageRecommendation(
        title:       'Resolve Critical Dead Logic',
        description: '${criticalDead.length} critical dead-logic warning(s) detected. '
            'First: ${criticalDead.first.target}.',
        priority: RecommendationPriority.critical,
        category: RecommendationCategory.branchCoverage,
      ));
    }

    // Non-critical dead logic
    final nonCriticalDead = report.coverageWarnings
        .where((w) =>
            w.category == CoverageWarningCategory.deadLogic &&
            w.severity  != 'critical')
        .toList();
    if (nonCriticalDead.isNotEmpty) {
      recs.add(CoverageRecommendation(
        title:       'Investigate Dead Logic',
        description: '${nonCriticalDead.length} dead-logic warning(s) detected.',
        priority: RecommendationPriority.high,
        category: RecommendationCategory.branchCoverage,
      ));
    }

    // State coverage
    if (r.unvisitedStates.isNotEmpty) {
      final prio = r.stateCoverage < 0.5
          ? RecommendationPriority.high
          : RecommendationPriority.medium;
      recs.add(CoverageRecommendation(
        title:       'Improve State Coverage',
        description: '${r.unvisitedStates.length} FSM state(s) unvisited. '
            'Consider adding test scenarios for: '
            '${r.unvisitedStates.take(3).join(", ")}.',
        priority: prio,
        category: RecommendationCategory.stateCoverage,
      ));
    }

    // Transition coverage
    if (r.untakenTransitions.isNotEmpty) {
      recs.add(CoverageRecommendation(
        title:       'Improve Transition Coverage',
        description: '${r.untakenTransitions.length} FSM transition(s) not exercised.',
        priority: RecommendationPriority.medium,
        category: RecommendationCategory.transitionCoverage,
      ));
    }

    // Branch coverage
    if (r.uncoveredBranches.isNotEmpty) {
      recs.add(CoverageRecommendation(
        title:       'Improve Branch Coverage',
        description: '${r.uncoveredBranches.length} RTL branch(es) not covered.',
        priority: RecommendationPriority.medium,
        category: RecommendationCategory.branchCoverage,
      ));
    }

    // Condition coverage
    if (r.uncoveredConditions.isNotEmpty) {
      recs.add(CoverageRecommendation(
        title:       'Improve Condition Coverage',
        description: '${r.uncoveredConditions.length} condition(s) not fully evaluated.',
        priority: RecommendationPriority.medium,
        category: RecommendationCategory.conditionCoverage,
      ));
    }

    // Toggle coverage
    if (r.untoggledSignals.isNotEmpty) {
      recs.add(CoverageRecommendation(
        title:       'Improve Toggle Coverage',
        description: '${r.untoggledSignals.length} signal(s) never toggled.',
        priority: RecommendationPriority.low,
        category: RecommendationCategory.toggleCoverage,
      ));
    }

    // Low overall coverage → verification planning
    if (r.overallCoverage < 0.60) {
      final prio = r.overallCoverage < 0.40
          ? RecommendationPriority.high
          : RecommendationPriority.medium;
      recs.add(CoverageRecommendation(
        title:       'Expand Verification Coverage',
        description: 'Overall coverage is '
            '${(r.overallCoverage * 100).toStringAsFixed(1)}%. '
            'Review and expand the verification plan to achieve ≥ 60%.',
        priority: prio,
        category: RecommendationCategory.verificationPlanning,
      ));
    }

    // Sort: critical first (descending priority index)
    recs.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Apply limit
    final max = context.maximumRecommendations;
    final limited = (max >= 0 && recs.length > max) ? recs.take(max).toList() : recs;

    return List.unmodifiable(limited);
  }

  // ── Statistics ────────────────────────────────────────────────────────────

  static CoverageStatistics _buildStatistics(
    CoverageReport report,
    List<CoverageRecommendation> recs,
  ) =>
      CoverageStatistics(
        recommendationCount:  recs.length,
        warningCount:         report.coverageWarnings.length,
        uncoveredStates:      report.result.unvisitedStates.length,
        uncoveredTransitions: report.result.untakenTransitions.length,
        uncoveredBranches:    report.result.uncoveredBranches.length,
        untoggledSignals:     report.result.untoggledSignals.length,
        overallCoverage:      report.overallCoverage,
      );
}
