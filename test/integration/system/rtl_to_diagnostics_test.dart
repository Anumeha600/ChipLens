import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/coverage_intelligence/coverage_intelligence.dart';
import 'package:chiplens_lite/backend/counterexample/counterexample.dart';
import 'package:chiplens_lite/backend/diagnostics_intelligence/diagnostics_intelligence.dart';
import 'package:chiplens_lite/backend/explainability/explainability.dart';
import 'package:chiplens_lite/backend/planning/planning.dart';

// ── Shared fixtures ────────────────────────────────────────────────────────────

final _healthyCoverage = CoverageAssessment(
  summary: const CoverageSummary(
    overview: 'Coverage is excellent.',
    strongestDimension: 'state',
    weakestDimension: 'branch',
    dominantIssue: 'None',
  ),
  risk: CoverageRisk.minimal,
  confidence: CoverageConfidence.veryHigh,
  recommendations: <CoverageRecommendation>[],
  statistics: const CoverageStatistics(
    recommendationCount: 0,
    warningCount: 0,
    uncoveredStates: 0,
    uncoveredTransitions: 0,
    uncoveredBranches: 0,
    untoggledSignals: 0,
    overallCoverage: 0.97,
  ),
);

final _poorCoverage = CoverageAssessment(
  summary: const CoverageSummary(
    overview: 'Coverage is critically insufficient.',
    strongestDimension: 'line',
    weakestDimension: 'state',
    dominantIssue: 'Uncovered FSM states detected.',
  ),
  risk: CoverageRisk.critical,
  confidence: CoverageConfidence.veryLow,
  recommendations: [
    CoverageRecommendation(
      title: 'Add state coverage tests',
      description: 'Many FSM states are not covered.',
      priority: RecommendationPriority.critical,
      category: RecommendationCategory.stateCoverage,
    ),
  ],
  statistics: const CoverageStatistics(
    recommendationCount: 1,
    warningCount: 3,
    uncoveredStates: 4,
    uncoveredTransitions: 6,
    uncoveredBranches: 8,
    untoggledSignals: 2,
    overallCoverage: 0.35,
  ),
);

final _successCounterexample = CounterexampleReport(
  summary: const CounterexampleSummary(
    overview: 'All properties formally proven.',
    primaryFailure: 'None',
    earliestFailure: 'None',
    dominantCategory: 'unknown',
  ),
  trace: CounterexampleTrace.empty,
  classification: CounterexampleClassification.unknown,
  confidence: CounterexampleConfidence.veryHigh,
  statistics: CounterexampleStatistics.empty,
);

final _assertionFailure = CounterexampleReport(
  summary: const CounterexampleSummary(
    overview: '2 properties failed.',
    primaryFailure: 'prop_overflow',
    earliestFailure: 'prop_overflow',
    dominantCategory: 'assertionFailure',
  ),
  trace: CounterexampleTrace(
    signals: const [],
    failedProperties: const ['prop_overflow', 'prop_reset'],
    firstFailure: 'prop_overflow',
    estimatedDepth: 2,
  ),
  classification: CounterexampleClassification.assertionFailure,
  confidence: CounterexampleConfidence.medium,
  statistics: const CounterexampleStatistics(
    failedPropertyCount: 2,
    unknownPropertyCount: 0,
    signalCount: 0,
    changedSignalCount: 0,
    estimatedDepth: 2,
  ),
);

final _engineFailure = CounterexampleReport(
  summary: const CounterexampleSummary(
    overview: 'Verification engine failed.',
    primaryFailure: 'None',
    earliestFailure: 'None',
    dominantCategory: 'engineFailure',
  ),
  trace: CounterexampleTrace.empty,
  classification: CounterexampleClassification.engineFailure,
  confidence: CounterexampleConfidence.veryLow,
  statistics: CounterexampleStatistics.empty,
);

final _timeoutCounterexample = CounterexampleReport(
  summary: const CounterexampleSummary(
    overview: 'Verification timed out.',
    primaryFailure: 'None',
    earliestFailure: 'None',
    dominantCategory: 'timeout',
  ),
  trace: CounterexampleTrace.empty,
  classification: CounterexampleClassification.timeout,
  confidence: CounterexampleConfidence.low,
  statistics: const CounterexampleStatistics(
    failedPropertyCount: 0,
    unknownPropertyCount: 3,
    signalCount: 0,
    changedSignalCount: 0,
    estimatedDepth: 0,
  ),
);

final _emptyExplanations = VerificationExplanationSet();

final _explanationSet = VerificationExplanationSet([
  VerificationExplanation(
    propertyId: 'prop_counter_overflow',
    title: 'Counter overflow property',
    description: 'Counter does not overflow beyond max value.',
    trace: ExplanationTrace(
      semanticEvidenceIds: const ['clk_detect', 'counter_detect'],
      rankingExplanation: 'High confidence counter property.',
      confidence: 0.85,
      emissionReason: 'Counter overflow boundary condition.',
      propertyType: 'assert',
    ),
  ),
]);

final _lowConfidenceExplanations = VerificationExplanationSet([
  VerificationExplanation(
    propertyId: 'prop_weak_1',
    title: 'Weak property A',
    trace: ExplanationTrace(
      semanticEvidenceIds: const [],
      rankingExplanation: 'Very low confidence.',
      confidence: 0.10,
      emissionReason: 'Threshold borderline.',
      propertyType: 'assert',
    ),
  ),
  VerificationExplanation(
    propertyId: 'prop_weak_2',
    title: 'Weak property B',
    trace: ExplanationTrace(
      semanticEvidenceIds: const [],
      rankingExplanation: 'Very low confidence.',
      confidence: 0.15,
      emissionReason: 'Threshold borderline.',
      propertyType: 'assert',
    ),
  ),
]);

final _emptyPlan = VerificationPlan();

final _plan = VerificationPlan([
  VerificationPlanItem(
    propertyId: 'prop_counter_overflow',
    executionOrder: 0,
    batchId: 0,
    strategy: VerificationStrategy.boundedModelChecking,
    estimatedCost: 2.0,
  ),
]);

const _engine = DiagnosticsEngine();

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Healthy state ────────────────────────────────────────────────────────────

  group('DiagnosticsEngine — healthy state', () {
    test('healthy coverage + no failures → informational severity', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallSeverity, DiagnosticSeverity.informational);
    });

    test('healthy state → isHealthy', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.isHealthy, isTrue);
    });

    test('healthy state → no issues', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.hasIssues, isFalse);
    });

    test('healthy state → veryHigh confidence', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallConfidence, DiagnosticConfidence.veryHigh);
    });

    test('healthy state → verificationHealth label is healthy', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.summary.verificationHealth, 'healthy');
    });

    test('healthy state → statistics has zero issue count', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.statistics.issueCount, 0);
    });
  });

  // ── Coverage issues ──────────────────────────────────────────────────────────

  group('DiagnosticsEngine — coverage issues', () {
    test('critical coverage → report has issues', () {
      final report = _engine.analyze(
        _poorCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.hasIssues, isTrue);
    });

    test('critical coverage → overall severity is critical', () {
      final report = _engine.analyze(
        _poorCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallSeverity, DiagnosticSeverity.critical);
    });

    test('critical coverage → coverage category issue exists', () {
      final report = _engine.analyze(
        _poorCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) => i.category == DiagnosticCategory.coverage),
        isTrue,
      );
    });

    test('critical coverage + no failures → high confidence (coverage-only path)', () {
      final report = _engine.analyze(
        _poorCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallConfidence, DiagnosticConfidence.high);
    });

    test('critical coverage → verificationHealth is failing', () {
      final report = _engine.analyze(
        _poorCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.summary.verificationHealth, 'failing');
    });
  });

  // ── Counterexample failures ──────────────────────────────────────────────────

  group('DiagnosticsEngine — counterexample failures', () {
    test('assertion failure → counterexample category issue generated', () {
      final report = _engine.analyze(
        _healthyCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) => i.category == DiagnosticCategory.counterexample),
        isTrue,
      );
    });

    test('assertion failure + healthy coverage → medium confidence', () {
      final report = _engine.analyze(
        _healthyCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallConfidence, DiagnosticConfidence.medium);
    });

    test('engine failure → critical overall severity', () {
      final report = _engine.analyze(
        _healthyCoverage, _engineFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallSeverity, DiagnosticSeverity.critical);
    });

    test('engine failure → veryLow confidence', () {
      final report = _engine.analyze(
        _healthyCoverage, _engineFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallConfidence, DiagnosticConfidence.veryLow);
    });

    test('engine failure → verificationHealth is failing', () {
      final report = _engine.analyze(
        _healthyCoverage, _engineFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.summary.verificationHealth, 'failing');
    });

    test('timeout → verification category issue generated', () {
      final report = _engine.analyze(
        _healthyCoverage, _timeoutCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) => i.category == DiagnosticCategory.verification),
        isTrue,
      );
    });

    test('coverage + assertion failure → low confidence', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(report.overallConfidence, DiagnosticConfidence.low);
    });
  });

  // ── Context configuration ────────────────────────────────────────────────────

  group('DiagnosticsEngine — context configuration', () {
    test('maximumIssues=0 → empty issue list', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _plan,
        DiagnosticContext(maximumIssues: 0),
      );
      expect(report.issues, isEmpty);
    });

    test('maximumIssues=1 → at most 1 issue', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _plan,
        DiagnosticContext(maximumIssues: 1),
      );
      expect(report.issues.length, lessThanOrEqualTo(1));
    });

    test('includeEvidence=false → all issues have empty evidence', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan,
        DiagnosticContext(includeEvidence: false),
      );
      for (final issue in report.issues) {
        expect(issue.evidence, isEmpty,
            reason: 'Issue "${issue.title}" should have empty evidence');
      }
    });

    test('includeStatistics=false → statistics is empty', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan,
        DiagnosticContext(includeStatistics: false),
      );
      expect(report.statistics, DiagnosticStatistics.empty);
    });

    test('statistics issueCount matches issues.length', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _plan, DiagnosticContext(),
      );
      expect(report.statistics.issueCount, report.issues.length);
    });

    test('includeConfidence=false → overallConfidence is veryHigh', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan,
        DiagnosticContext(includeConfidence: false),
      );
      expect(report.overallConfidence, DiagnosticConfidence.veryHigh);
    });
  });

  // ── Determinism ──────────────────────────────────────────────────────────────

  group('DiagnosticsEngine — determinism and ordering', () {
    test('identical inputs produce equal reports', () {
      final r1 = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _plan, DiagnosticContext(),
      );
      final r2 = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _plan, DiagnosticContext(),
      );
      expect(r1, r2);
    });

    test('issues are sorted highest severity first', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      for (int i = 1; i < report.issues.length; i++) {
        expect(
          report.issues[i].severity.index,
          lessThanOrEqualTo(report.issues[i - 1].severity.index),
          reason: 'Issue at index $i has higher severity than index ${i - 1}',
        );
      }
    });

    test('primaryIssue in summary matches first issue title', () {
      final report = _engine.analyze(
        _poorCoverage, _assertionFailure,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      if (report.hasIssues) {
        expect(report.summary.primaryIssue, report.issues.first.title);
      }
    });
  });

  // ── Planning diagnostics ─────────────────────────────────────────────────────

  group('DiagnosticsEngine — planning diagnostics', () {
    test('empty plan + non-empty explanations → planning issue generated', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _explanationSet, _emptyPlan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) => i.category == DiagnosticCategory.planning),
        isTrue,
      );
    });

    test('non-empty plan + explanations → no empty-plan planning issue', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _explanationSet, _plan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) =>
            i.category == DiagnosticCategory.planning &&
            i.title == 'Empty verification plan'),
        isFalse,
      );
    });

    test('empty plan + empty explanations → no planning issue', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _emptyExplanations, _emptyPlan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) => i.category == DiagnosticCategory.planning),
        isFalse,
      );
    });
  });

  // ── Property quality diagnostics ─────────────────────────────────────────────

  group('DiagnosticsEngine — property quality', () {
    test('high-confidence explanations → no property quality issue', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _explanationSet, _plan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) => i.category == DiagnosticCategory.property),
        isFalse,
      );
    });

    test('critically low confidence explanations → property issue generated', () {
      final report = _engine.analyze(
        _healthyCoverage, _successCounterexample,
        _lowConfidenceExplanations, _plan, DiagnosticContext(),
      );
      expect(
        report.issues.any((i) => i.category == DiagnosticCategory.property),
        isTrue,
      );
    });
  });
}
