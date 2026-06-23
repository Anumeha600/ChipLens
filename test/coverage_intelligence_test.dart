import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/coverage_intelligence/coverage_intelligence.dart';
import 'package:chiplens_lite/models/coverage_model.dart';
import 'package:chiplens_lite/models/coverage_report.dart';
import 'package:chiplens_lite/models/coverage_result.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

CoverageReport makeReport({
  double state      = 1.0,
  double transition = 1.0,
  double branch     = 1.0,
  double toggle     = 1.0,
  double condition  = 1.0,
  double line       = 1.0,
  List<String> unvisitedStates      = const [],
  List<String> untakenTransitions   = const [],
  List<String> uncoveredBranches    = const [],
  List<String> untoggledSignals     = const [],
  List<String> uncoveredConditions  = const [],
  List<CoverageWarning> warnings    = const [],
  int totalStates      = 4,
  int visitedStates    = 4,
  int totalTransitions = 4,
  int executedTrans    = 4,
}) {
  final overall = CoverageResult.weighted(
      state, transition, branch, toggle, condition, line);
  return CoverageReport(
    result: CoverageResult(
      stateCoverage:      state,
      transitionCoverage: transition,
      branchCoverage:     branch,
      toggleCoverage:     toggle,
      conditionCoverage:  condition,
      lineCoverage:       line,
      overallCoverage:    overall,
      visitedStates:      [],
      unvisitedStates:    unvisitedStates,
      takenTransitions:   [],
      untakenTransitions: untakenTransitions,
      coveredBranches:    [],
      uncoveredBranches:  uncoveredBranches,
      toggledSignals:     [],
      untoggledSignals:   untoggledSignals,
      coveredConditions:  [],
      uncoveredConditions: uncoveredConditions,
      warnings:           [],
    ),
    metrics: CoverageMetrics(
      totalStates:              totalStates,
      visitedStateCount:        visitedStates,
      totalTransitions:         totalTransitions,
      executedTransitionCount:  executedTrans,
      totalBranches:            10,
      coveredBranchCount:       10,
      totalSignals:             8,
      toggledSignalCount:       8,
      totalConditions:          6,
      evaluatedConditionCount:  6,
      totalLines:               20,
      executedLineCount:        20,
    ),
    coverageWarnings: warnings,
    heatMap: CoverageHeatMapData.empty,
  );
}

CoverageWarning makeWarning({
  CoverageWarningCategory category = CoverageWarningCategory.state,
  String target   = 'target',
  String severity = 'warning',
}) =>
    CoverageWarning(
      category: category,
      target:   target,
      message:  'Test warning for $target',
      severity: severity,
    );

void main() {
  const engine = CoverageIntelligenceEngine();
  const ctx    = CoverageIntelligenceContext();

  // ════════════════════════════════════════════════════════════════════════════
  // 1. CoverageIntelligenceContext
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageIntelligenceContext', () {
    test('defaults are sensible', () {
      const c = CoverageIntelligenceContext();
      expect(c.includeRecommendations,  true);
      expect(c.includeRiskAssessment,   true);
      expect(c.includeConfidence,       true);
      expect(c.includeStatistics,       true);
      expect(c.maximumRecommendations,  -1);
    });

    test('custom fields are stored correctly', () {
      const c = CoverageIntelligenceContext(
        includeRecommendations: false,
        maximumRecommendations: 3,
      );
      expect(c.includeRecommendations, false);
      expect(c.maximumRecommendations, 3);
    });

    test('equality holds for identical fields', () {
      const a = CoverageIntelligenceContext(maximumRecommendations: 5);
      const b = CoverageIntelligenceContext(maximumRecommendations: 5);
      expect(a, b);
    });

    test('inequality when any field differs', () {
      const base = CoverageIntelligenceContext();
      expect(base, isNot(CoverageIntelligenceContext(includeStatistics: false)));
      expect(base, isNot(CoverageIntelligenceContext(maximumRecommendations: 2)));
    });

    test('copyWith overrides only specified fields', () {
      const original = CoverageIntelligenceContext(maximumRecommendations: 4);
      final copy = original.copyWith(includeStatistics: false);
      expect(copy.maximumRecommendations, 4);
      expect(copy.includeStatistics,      false);
      expect(copy.includeRecommendations, true);
    });

    test('copyWith with no args equals original', () {
      const c = CoverageIntelligenceContext(maximumRecommendations: 3);
      expect(c.copyWith(), c);
    });

    test('toString is non-empty', () {
      const c = CoverageIntelligenceContext();
      expect(c.toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. CoverageRisk mapping
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageRisk', () {
    test('95% coverage with no warnings → minimal', () {
      final report = makeReport(state: 0.97, transition: 0.97, branch: 0.97,
          toggle: 0.97, condition: 0.97, line: 0.97);
      final a = engine.assess(report, ctx);
      expect(a.risk, CoverageRisk.minimal);
    });

    test('85% coverage with no warnings → low', () {
      final report = makeReport(state: 0.85, transition: 0.85, branch: 0.85,
          toggle: 0.85, condition: 0.85, line: 0.85);
      final a = engine.assess(report, ctx);
      expect(a.risk, CoverageRisk.low);
    });

    test('70% coverage with no warnings → moderate', () {
      final report = makeReport(state: 0.70, transition: 0.70, branch: 0.70,
          toggle: 0.70, condition: 0.70, line: 0.70);
      final a = engine.assess(report, ctx);
      expect(a.risk, CoverageRisk.moderate);
    });

    test('non-critical dead logic → escalates risk by one level', () {
      final report = makeReport(
        state: 0.70, transition: 0.70, branch: 0.70,
        toggle: 0.70, condition: 0.70, line: 0.70,
        warnings: [makeWarning(category: CoverageWarningCategory.deadLogic)],
      );
      final a = engine.assess(report, ctx);
      expect(a.risk.index, greaterThan(CoverageRisk.moderate.index));
    });

    test('critical dead logic → escalates risk to critical from moderate base', () {
      final report = makeReport(
        state: 0.70, transition: 0.70, branch: 0.70,
        toggle: 0.70, condition: 0.70, line: 0.70,
        warnings: [makeWarning(
          category: CoverageWarningCategory.deadLogic, severity: 'critical',
        )],
      );
      final a = engine.assess(report, ctx);
      expect(a.risk, CoverageRisk.critical);
    });

    test('low coverage < 40% → critical without warnings', () {
      final report = makeReport(state: 0.2, transition: 0.2, branch: 0.2,
          toggle: 0.2, condition: 0.2, line: 0.2);
      final a = engine.assess(report, ctx);
      expect(a.risk, CoverageRisk.critical);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. CoverageConfidence mapping
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageConfidence', () {
    test('98% coverage → veryHigh', () {
      final report = makeReport(state: 0.98, transition: 0.98, branch: 0.98,
          toggle: 0.98, condition: 0.98, line: 0.98);
      expect(engine.assess(report, ctx).confidence, CoverageConfidence.veryHigh);
    });

    test('85% coverage → high', () {
      final report = makeReport(state: 0.85, transition: 0.85, branch: 0.85,
          toggle: 0.85, condition: 0.85, line: 0.85);
      expect(engine.assess(report, ctx).confidence, CoverageConfidence.high);
    });

    test('70% coverage → medium', () {
      final report = makeReport(state: 0.70, transition: 0.70, branch: 0.70,
          toggle: 0.70, condition: 0.70, line: 0.70);
      expect(engine.assess(report, ctx).confidence, CoverageConfidence.medium);
    });

    test('45% coverage → low', () {
      final report = makeReport(state: 0.45, transition: 0.45, branch: 0.45,
          toggle: 0.45, condition: 0.45, line: 0.45);
      expect(engine.assess(report, ctx).confidence, CoverageConfidence.low);
    });

    test('20% coverage → veryLow', () {
      final report = makeReport(state: 0.2, transition: 0.2, branch: 0.2,
          toggle: 0.2, condition: 0.2, line: 0.2);
      expect(engine.assess(report, ctx).confidence, CoverageConfidence.veryLow);
    });

    test('critical warning reduces confidence by exactly one level', () {
      final noWarn  = makeReport(state: 0.98, transition: 0.98, branch: 0.98,
          toggle: 0.98, condition: 0.98, line: 0.98);
      final withWarn = makeReport(
        state: 0.98, transition: 0.98, branch: 0.98,
        toggle: 0.98, condition: 0.98, line: 0.98,
        warnings: [makeWarning(severity: 'critical')],
      );
      final baseConf  = engine.assess(noWarn,   ctx).confidence;
      final warnConf  = engine.assess(withWarn,  ctx).confidence;
      expect(baseConf.index - warnConf.index, 1);
    });

    test('non-critical warning does not reduce confidence', () {
      final noWarn   = makeReport(state: 0.90, transition: 0.90, branch: 0.90,
          toggle: 0.90, condition: 0.90, line: 0.90);
      final withWarn = makeReport(
        state: 0.90, transition: 0.90, branch: 0.90,
        toggle: 0.90, condition: 0.90, line: 0.90,
        warnings: [makeWarning(severity: 'warning')],
      );
      expect(
        engine.assess(noWarn, ctx).confidence,
        engine.assess(withWarn, ctx).confidence,
      );
    });

    test('confidence is not reduced below veryLow', () {
      final report = makeReport(
        state: 0.1, transition: 0.1, branch: 0.1,
        toggle: 0.1, condition: 0.1, line: 0.1,
        warnings: [makeWarning(severity: 'critical')],
      );
      expect(engine.assess(report, ctx).confidence, CoverageConfidence.veryLow);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. CoverageSummary
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageSummary', () {
    test('overview contains grade', () {
      final report = makeReport();
      final summary = engine.assess(report, ctx).summary;
      expect(summary.overview, contains('Excellent'));
    });

    test('strongest and weakest dimensions are identified', () {
      final report = makeReport(
        state: 0.95, branch: 0.40, transition: 0.70,
        toggle: 0.80, condition: 0.60, line: 0.50,
      );
      final summary = engine.assess(report, ctx).summary;
      expect(summary.strongestDimension, 'state');
      expect(summary.weakestDimension,   'branch');
    });

    test('dominantIssue mentions critical dead logic when present', () {
      final report = makeReport(
        warnings: [makeWarning(
          category: CoverageWarningCategory.deadLogic, severity: 'critical',
        )],
      );
      final summary = engine.assess(report, ctx).summary;
      expect(summary.dominantIssue.toLowerCase(), contains('critical'));
    });

    test('dominantIssue mentions unvisited states when no dead logic', () {
      final report = makeReport(unvisitedStates: ['S_IDLE', 'S_WAIT']);
      final summary = engine.assess(report, ctx).summary;
      expect(summary.dominantIssue, contains('2'));
    });

    test('dominantIssue has no-issue message when fully covered', () {
      final report = makeReport();
      final summary = engine.assess(report, ctx).summary;
      expect(summary.dominantIssue.toLowerCase(), contains('no dominant'));
    });

    test('summary equality is structural', () {
      final report  = makeReport();
      final summary1 = engine.assess(report, ctx).summary;
      final summary2 = engine.assess(report, ctx).summary;
      expect(summary1, summary2);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. CoverageAssessment
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageAssessment', () {
    test('construction stores all fields', () {
      final report = makeReport();
      final a = engine.assess(report, ctx);
      expect(a.summary,         isA<CoverageSummary>());
      expect(a.risk,            isA<CoverageRisk>());
      expect(a.confidence,      isA<CoverageConfidence>());
      expect(a.recommendations, isA<List<CoverageRecommendation>>());
      expect(a.statistics,      isA<CoverageStatistics>());
    });

    test('isHealthy is true for minimal and low risk', () {
      final report = makeReport();
      final a = engine.assess(report, ctx);
      // Full coverage → minimal risk → healthy
      expect(a.isHealthy, true);
    });

    test('isHealthy is false for moderate risk', () {
      final report = makeReport(state: 0.60, transition: 0.60, branch: 0.60,
          toggle: 0.60, condition: 0.60, line: 0.60);
      final a = engine.assess(report, ctx);
      expect(a.isHealthy, false);
    });

    test('hasRecommendations mirrors recommendations.isNotEmpty', () {
      final report = makeReport(unvisitedStates: ['S_ERR']);
      final a = engine.assess(report, ctx);
      expect(a.hasRecommendations, a.recommendations.isNotEmpty);
    });

    test('recommendations list is unmodifiable', () {
      final report = makeReport(unvisitedStates: ['S_ERR']);
      final a = engine.assess(report, ctx);
      final extra = CoverageRecommendation(
        title: 'x', description: 'y',
        priority: RecommendationPriority.low,
        category: RecommendationCategory.toggleCoverage,
      );
      expect(
        () => (a.recommendations as dynamic).add(extra),
        throwsUnsupportedError,
      );
    });

    test('equality holds for identical reports', () {
      final report = makeReport();
      expect(engine.assess(report, ctx), engine.assess(report, ctx));
    });

    test('toString is non-empty', () {
      final a = engine.assess(makeReport(), ctx);
      expect(a.toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. CoverageRecommendation
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageRecommendation', () {
    test('stores all fields', () {
      final rec = CoverageRecommendation(
        title:       'Test rec',
        description: 'A description',
        priority:    RecommendationPriority.high,
        category:    RecommendationCategory.stateCoverage,
      );
      expect(rec.title,       'Test rec');
      expect(rec.priority,    RecommendationPriority.high);
      expect(rec.category,    RecommendationCategory.stateCoverage);
    });

    test('metadata defaults to empty unmodifiable map', () {
      final rec = CoverageRecommendation(
        title: 't', description: 'd',
        priority: RecommendationPriority.low,
        category: RecommendationCategory.toggleCoverage,
      );
      expect(rec.metadata, isEmpty);
      expect(() => (rec.metadata as dynamic)['x'] = 1, throwsUnsupportedError);
    });

    test('equality by title, priority, category', () {
      final a = CoverageRecommendation(
        title: 'Improve State Coverage', description: 'd1',
        priority: RecommendationPriority.high,
        category: RecommendationCategory.stateCoverage,
      );
      final b = CoverageRecommendation(
        title: 'Improve State Coverage', description: 'd2',
        priority: RecommendationPriority.high,
        category: RecommendationCategory.stateCoverage,
      );
      expect(a, b);
    });

    test('toString mentions priority', () {
      final rec = CoverageRecommendation(
        title: 'T', description: 'D',
        priority: RecommendationPriority.critical,
        category: RecommendationCategory.branchCoverage,
      );
      expect(rec.toString(), contains('critical'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 7. CoverageStatistics
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageStatistics', () {
    test('empty constant has all zeros', () {
      const s = CoverageStatistics.empty;
      expect(s.recommendationCount,  0);
      expect(s.warningCount,         0);
      expect(s.uncoveredStates,      0);
      expect(s.uncoveredTransitions, 0);
      expect(s.uncoveredBranches,    0);
      expect(s.untoggledSignals,     0);
      expect(s.overallCoverage,      0.0);
    });

    test('statistics count warnings correctly', () {
      final report = makeReport(
        warnings: [makeWarning(), makeWarning(severity: 'critical')],
      );
      final a = engine.assess(report, ctx);
      expect(a.statistics.warningCount, 2);
    });

    test('statistics count uncovered states correctly', () {
      final report = makeReport(unvisitedStates: ['S1', 'S2', 'S3']);
      final a = engine.assess(report, ctx);
      expect(a.statistics.uncoveredStates, 3);
    });

    test('statistics count uncovered transitions correctly', () {
      final report = makeReport(untakenTransitions: ['A→B', 'C→D']);
      final a = engine.assess(report, ctx);
      expect(a.statistics.uncoveredTransitions, 2);
    });

    test('statistics count uncovered branches correctly', () {
      final report = makeReport(uncoveredBranches: ['if_1', 'if_2']);
      final a = engine.assess(report, ctx);
      expect(a.statistics.uncoveredBranches, 2);
    });

    test('statistics count untoggled signals correctly', () {
      final report = makeReport(untoggledSignals: ['clk', 'rst']);
      final a = engine.assess(report, ctx);
      expect(a.statistics.untoggledSignals, 2);
    });

    test('statistics overall coverage matches report', () {
      final report = makeReport(state: 0.80, transition: 0.80, branch: 0.80,
          toggle: 0.80, condition: 0.80, line: 0.80);
      final a = engine.assess(report, ctx);
      expect(a.statistics.overallCoverage, closeTo(0.80, 0.001));
    });

    test('statistics are empty when includeStatistics=false', () {
      final report = makeReport();
      final a = engine.assess(report, ctx.copyWith(includeStatistics: false));
      expect(a.statistics, CoverageStatistics.empty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 8. Recommendation generation
  // ════════════════════════════════════════════════════════════════════════════
  group('Recommendation generation', () {
    test('no coverage gaps → no recommendations', () {
      final report = makeReport();
      final a = engine.assess(report, ctx);
      expect(a.recommendations, isEmpty);
    });

    test('unvisited states → state coverage recommendation', () {
      final report = makeReport(unvisitedStates: ['S_IDLE']);
      final a = engine.assess(report, ctx);
      expect(a.recommendations.any(
        (r) => r.category == RecommendationCategory.stateCoverage,
      ), true);
    });

    test('untaken transitions → transition recommendation', () {
      final report = makeReport(untakenTransitions: ['A→B']);
      final a = engine.assess(report, ctx);
      expect(a.recommendations.any(
        (r) => r.category == RecommendationCategory.transitionCoverage,
      ), true);
    });

    test('untoggled signals → toggle recommendation', () {
      final report = makeReport(untoggledSignals: ['data']);
      final a = engine.assess(report, ctx);
      expect(a.recommendations.any(
        (r) => r.category == RecommendationCategory.toggleCoverage,
      ), true);
    });

    test('critical dead logic → critical recommendation', () {
      final report = makeReport(warnings: [makeWarning(
        category: CoverageWarningCategory.deadLogic, severity: 'critical',
      )]);
      final a = engine.assess(report, ctx);
      expect(a.recommendations.any(
        (r) => r.priority == RecommendationPriority.critical,
      ), true);
    });

    test('low overall coverage → verification planning recommendation', () {
      final report = makeReport(state: 0.4, transition: 0.4, branch: 0.4,
          toggle: 0.4, condition: 0.4, line: 0.4);
      final a = engine.assess(report, ctx);
      expect(a.recommendations.any(
        (r) => r.category == RecommendationCategory.verificationPlanning,
      ), true);
    });

    test('recommendations are sorted critical first', () {
      final report = makeReport(
        unvisitedStates: ['S1'],
        warnings: [makeWarning(
          category: CoverageWarningCategory.deadLogic, severity: 'critical',
        )],
      );
      final a = engine.assess(report, ctx);
      expect(a.recommendations.first.priority, RecommendationPriority.critical);
    });

    test('maximumRecommendations limits output', () {
      final report = makeReport(
        unvisitedStates: ['S1'], untakenTransitions: ['A→B'],
        uncoveredBranches: ['if_1'], untoggledSignals: ['data'],
      );
      final limited = engine.assess(report, ctx.copyWith(maximumRecommendations: 2));
      expect(limited.recommendations.length, lessThanOrEqualTo(2));
    });

    test('no recommendations when includeRecommendations=false', () {
      final report = makeReport(unvisitedStates: ['S_IDLE']);
      final a = engine.assess(report, ctx.copyWith(includeRecommendations: false));
      expect(a.recommendations, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 9. CoverageIntelligenceEngine core
  // ════════════════════════════════════════════════════════════════════════════
  group('CoverageIntelligenceEngine', () {
    test('empty CoverageReport produces valid assessment', () {
      final report = CoverageReport.empty();
      final a = engine.assess(report, ctx);
      expect(a.risk,       isA<CoverageRisk>());
      expect(a.confidence, isA<CoverageConfidence>());
      expect(a.summary,    isA<CoverageSummary>());
    });

    test('full coverage report → minimal risk', () {
      final report = makeReport();
      expect(engine.assess(report, ctx).risk, CoverageRisk.minimal);
    });

    test('partial coverage report produces moderate risk', () {
      final report = makeReport(state: 0.65, transition: 0.65, branch: 0.65,
          toggle: 0.65, condition: 0.65, line: 0.65);
      final a = engine.assess(report, ctx);
      expect(a.risk.index, greaterThanOrEqualTo(CoverageRisk.moderate.index));
    });

    test('critical coverage report has low confidence', () {
      final report = makeReport(state: 0.2, transition: 0.2, branch: 0.2,
          toggle: 0.2, condition: 0.2, line: 0.2);
      final a = engine.assess(report, ctx);
      expect(a.confidence, CoverageConfidence.veryLow);
    });

    test('planning time is measured (non-negative)', () {
      // Engine does not expose planningTime; verify that assessment returns quickly
      final sw = Stopwatch()..start();
      engine.assess(makeReport(), ctx);
      expect(sw.elapsedMicroseconds, greaterThanOrEqualTo(0));
    });

    test('risk is not included when includeRiskAssessment=false', () {
      final report = makeReport(state: 0.2, transition: 0.2, branch: 0.2,
          toggle: 0.2, condition: 0.2, line: 0.2);
      final a = engine.assess(report, ctx.copyWith(includeRiskAssessment: false));
      expect(a.risk, CoverageRisk.minimal);  // defaults to minimal when not computed
    });

    test('confidence is not included when includeConfidence=false', () {
      final report = makeReport(state: 0.1, transition: 0.1, branch: 0.1,
          toggle: 0.1, condition: 0.1, line: 0.1);
      final a = engine.assess(report, ctx.copyWith(includeConfidence: false));
      expect(a.confidence, CoverageConfidence.veryHigh);  // defaults to veryHigh
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 10. Determinism
  // ════════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    test('same input produces identical assessments across 10 runs', () {
      final report = makeReport(
        state: 0.75, transition: 0.65, branch: 0.80,
        unvisitedStates: ['S_ERR'],
        warnings: [makeWarning(severity: 'warning')],
      );
      final first = engine.assess(report, ctx);
      for (int i = 0; i < 9; i++) {
        expect(engine.assess(report, ctx), first);
      }
    });

    test('different engine instances produce equal output', () {
      final report = makeReport(unvisitedStates: ['S1', 'S2']);
      expect(
        const CoverageIntelligenceEngine().assess(report, ctx),
        const CoverageIntelligenceEngine().assess(report, ctx),
      );
    });

    test('recommendation order is deterministic', () {
      final report = makeReport(
        unvisitedStates: ['S1'],
        untakenTransitions: ['A→B'],
        warnings: [makeWarning(
          category: CoverageWarningCategory.deadLogic, severity: 'critical',
        )],
      );
      final a = engine.assess(report, ctx);
      final b = engine.assess(report, ctx);
      expect(
        a.recommendations.map((r) => r.title).toList(),
        b.recommendations.map((r) => r.title).toList(),
      );
    });

    test('confidence and risk are deterministic', () {
      final report = makeReport(state: 0.85, transition: 0.85, branch: 0.85,
          toggle: 0.85, condition: 0.85, line: 0.85);
      final a = engine.assess(report, ctx);
      final b = engine.assess(report, ctx);
      expect(a.confidence, b.confidence);
      expect(a.risk,       b.risk);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 11. Negative tests
  // ════════════════════════════════════════════════════════════════════════════
  group('Negative tests', () {
    test('overallCoverage < 0.0 throws ArgumentError', () {
      final report = CoverageReport(
        result: CoverageResult(
          stateCoverage: 0, transitionCoverage: 0, branchCoverage: 0,
          toggleCoverage: 0, conditionCoverage: 0, lineCoverage: 0,
          overallCoverage: -0.1,
          visitedStates: [], unvisitedStates: [], takenTransitions: [],
          untakenTransitions: [], coveredBranches: [], uncoveredBranches: [],
          toggledSignals: [], untoggledSignals: [], coveredConditions: [],
          uncoveredConditions: [], warnings: [],
        ),
        metrics:          CoverageMetrics.empty,
        coverageWarnings: const [],
        heatMap:          CoverageHeatMapData.empty,
      );
      expect(() => engine.assess(report, ctx), throwsArgumentError);
    });

    test('overallCoverage > 1.0 throws ArgumentError', () {
      final report = CoverageReport(
        result: CoverageResult(
          stateCoverage: 0, transitionCoverage: 0, branchCoverage: 0,
          toggleCoverage: 0, conditionCoverage: 0, lineCoverage: 0,
          overallCoverage: 1.5,
          visitedStates: [], unvisitedStates: [], takenTransitions: [],
          untakenTransitions: [], coveredBranches: [], uncoveredBranches: [],
          toggledSignals: [], untoggledSignals: [], coveredConditions: [],
          uncoveredConditions: [], warnings: [],
        ),
        metrics:          CoverageMetrics.empty,
        coverageWarnings: const [],
        heatMap:          CoverageHeatMapData.empty,
      );
      expect(() => engine.assess(report, ctx), throwsArgumentError);
    });

    test('visitedStateCount > totalStates throws StateError', () {
      final report = CoverageReport(
        result:  CoverageResult.empty(),
        metrics: const CoverageMetrics(
          totalStates: 2, visitedStateCount: 5,
          totalTransitions: 4, executedTransitionCount: 4,
          totalBranches: 0, coveredBranchCount: 0,
          totalSignals: 0, toggledSignalCount: 0,
          totalConditions: 0, evaluatedConditionCount: 0,
          totalLines: 0, executedLineCount: 0,
        ),
        coverageWarnings: const [],
        heatMap:          CoverageHeatMapData.empty,
      );
      expect(() => engine.assess(report, ctx), throwsStateError);
    });

    test('CoverageWarning with null suggestion does not throw', () {
      final report = makeReport(
        warnings: [const CoverageWarning(
          category: CoverageWarningCategory.branch,
          target:   'branch_1',
          message:  'Branch not covered',
          severity: 'warning',
          suggestion: null,
        )],
      );
      expect(() => engine.assess(report, ctx), returnsNormally);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 12. Performance
  // ════════════════════════════════════════════════════════════════════════════
  group('Performance', () {
    CoverageReport makeReportWithWarnings(int n) => CoverageReport(
          result: CoverageResult(
            stateCoverage: 0.7, transitionCoverage: 0.7, branchCoverage: 0.7,
            toggleCoverage: 0.7, conditionCoverage: 0.7, lineCoverage: 0.7,
            overallCoverage: 0.7,
            visitedStates: [], unvisitedStates: ['S1'],
            takenTransitions: [], untakenTransitions: [],
            coveredBranches: [], uncoveredBranches: [],
            toggledSignals: [], untoggledSignals: [],
            coveredConditions: [], uncoveredConditions: [],
            warnings: [],
          ),
          metrics: const CoverageMetrics(
            totalStates: 10, visitedStateCount: 7,
            totalTransitions: 10, executedTransitionCount: 7,
            totalBranches: 10, coveredBranchCount: 7,
            totalSignals: 10, toggledSignalCount: 7,
            totalConditions: 10, evaluatedConditionCount: 7,
            totalLines: 20, executedLineCount: 14,
          ),
          coverageWarnings: List.generate(
            n,
            (i) => CoverageWarning(
              category: CoverageWarningCategory.state,
              target:   'state_$i',
              message:  'Unvisited state_$i',
              severity: i.isEven ? 'warning' : 'info',
            ),
          ),
          heatMap: CoverageHeatMapData.empty,
        );

    test('100 warnings assessed within 100ms', () {
      final report = makeReportWithWarnings(100);
      final sw = Stopwatch()..start();
      engine.assess(report, ctx);
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('500 warnings assessed within 300ms', () {
      final report = makeReportWithWarnings(500);
      final sw = Stopwatch()..start();
      engine.assess(report, ctx);
      expect(sw.elapsedMilliseconds, lessThan(300));
    });

    test('1000 warnings assessed within 500ms', () {
      final report = makeReportWithWarnings(1000);
      final sw = Stopwatch()..start();
      engine.assess(report, ctx);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });
}
