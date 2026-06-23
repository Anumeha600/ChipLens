import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/counterexample/counterexample.dart';
import 'package:chiplens_lite/backend/coverage_intelligence/coverage_intelligence.dart';
import 'package:chiplens_lite/backend/diagnostics_intelligence/diagnostics_intelligence.dart';
import 'package:chiplens_lite/backend/explainability/explainability.dart';
import 'package:chiplens_lite/backend/planning/planning.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

// ── CoverageAssessment builders ───────────────────────────────────────────────

CoverageSummary _makeCovSummary({
  String overview = 'ok',
  String strongest = 'branch',
  String weakest = 'state',
  String dominant = 'none',
}) =>
    CoverageSummary(
      overview: overview,
      strongestDimension: strongest,
      weakestDimension: weakest,
      dominantIssue: dominant,
    );

CoverageStatistics _makeCovStats({double overall = 0.95}) =>
    CoverageStatistics(
      recommendationCount: 0,
      warningCount: 0,
      uncoveredStates: 0,
      uncoveredTransitions: 0,
      uncoveredBranches: 0,
      untoggledSignals: 0,
      overallCoverage: overall,
    );

CoverageAssessment makeCoverage({
  CoverageRisk risk = CoverageRisk.minimal,
  CoverageConfidence confidence = CoverageConfidence.veryHigh,
  double overall = 0.95,
}) =>
    CoverageAssessment(
      summary: _makeCovSummary(),
      risk: risk,
      confidence: confidence,
      recommendations: const [],
      statistics: _makeCovStats(overall: overall),
    );

// ── CounterexampleReport builders ─────────────────────────────────────────────

CounterexampleSummary _makeCexSummary({
  String overview = 'ok',
  String primary = 'None',
  String earliest = 'None',
  String dominant = 'unknown',
}) =>
    CounterexampleSummary(
      overview: overview,
      primaryFailure: primary,
      earliestFailure: earliest,
      dominantCategory: dominant,
    );

CounterexampleReport makeCounterexample({
  CounterexampleClassification classification = CounterexampleClassification.unknown,
  CounterexampleConfidence confidence = CounterexampleConfidence.veryHigh,
  int failedCount = 0,
  int unknownCount = 0,
}) {
  final stats = CounterexampleStatistics(
    failedPropertyCount: failedCount,
    unknownPropertyCount: unknownCount,
    signalCount: failedCount,
    changedSignalCount: failedCount,
    estimatedDepth: failedCount,
  );
  return CounterexampleReport(
    summary: _makeCexSummary(
      dominant: classification.name,
      primary: failedCount > 0 ? 'prop_0' : 'None',
    ),
    trace: CounterexampleTrace(
      signals: List.generate(
        failedCount,
        (i) => CounterexampleSignal(
          name: 'prop_$i',
          value: 'FAIL',
          step: 0,
          changed: true,
        ),
      ),
      failedProperties: List.generate(failedCount, (i) => 'prop_$i'),
      firstFailure: failedCount > 0 ? 'prop_0' : '',
      estimatedDepth: failedCount,
    ),
    classification: classification,
    confidence: confidence,
    statistics: stats,
  );
}

CounterexampleReport engineFailureReport() => makeCounterexample(
      classification: CounterexampleClassification.engineFailure,
      confidence: CounterexampleConfidence.veryLow,
    );

CounterexampleReport cleanReport() => makeCounterexample(
      classification: CounterexampleClassification.unknown,
      confidence: CounterexampleConfidence.veryHigh,
    );

CounterexampleReport failureReport({int n = 1}) => makeCounterexample(
      classification: CounterexampleClassification.assertionFailure,
      confidence: CounterexampleConfidence.high,
      failedCount: n,
    );

// ── VerificationExplanationSet builders ──────────────────────────────────────

ExplanationTrace makeTrace({double confidence = 0.8}) => ExplanationTrace(
      semanticEvidenceIds: const [],
      rankingExplanation: 'ranked',
      confidence: confidence,
      emissionReason: 'emitted',
      propertyType: 'safety',
    );

VerificationExplanation makeExplanation(String id, {double confidence = 0.8}) =>
    VerificationExplanation(
      propertyId: id,
      title: 'Property $id',
      trace: makeTrace(confidence: confidence),
    );

VerificationExplanationSet makeExplanations(int n, {double confidence = 0.8}) =>
    VerificationExplanationSet(
      List.generate(n, (i) => makeExplanation('p$i', confidence: confidence)),
    );

// ── VerificationPlan builders ─────────────────────────────────────────────────

VerificationPlan makePlan(int n, {VerificationStrategy strategy = VerificationStrategy.boundedModelChecking}) =>
    VerificationPlan(
      List.generate(
        n,
        (i) => VerificationPlanItem(
          propertyId: 'p$i',
          executionOrder: i,
          batchId: 0,
          strategy: strategy,
          estimatedCost: 2.0,
        ),
      ),
    );

void main() {
  const engine = DiagnosticsEngine();
  final ctx = DiagnosticContext();

  // ════════════════════════════════════════════════════════════════════════════
  // 1. DiagnosticContext
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticContext', () {
    test('defaults are sensible', () {
      final c = DiagnosticContext();
      expect(c.includeStatistics,      true);
      expect(c.includeEvidence,        true);
      expect(c.includeRecommendations, true);
      expect(c.includeConfidence,      true);
      expect(c.maximumIssues,          -1);
    });

    test('custom fields are stored', () {
      final c = DiagnosticContext(includeEvidence: false, maximumIssues: 3);
      expect(c.includeEvidence, false);
      expect(c.maximumIssues,   3);
    });

    test('equality holds for identical fields', () {
      expect(DiagnosticContext(maximumIssues: 5), DiagnosticContext(maximumIssues: 5));
    });

    test('inequality when any field differs', () {
      final base = DiagnosticContext();
      expect(base, isNot(DiagnosticContext(includeEvidence: false)));
      expect(base, isNot(DiagnosticContext(maximumIssues: 2)));
    });

    test('copyWith overrides only specified fields', () {
      final original = DiagnosticContext(maximumIssues: 4);
      final copy = original.copyWith(includeStatistics: false);
      expect(copy.maximumIssues,    4);
      expect(copy.includeStatistics, false);
      expect(copy.includeEvidence,   true);
    });

    test('copyWith with no args equals original', () {
      final c = DiagnosticContext(maximumIssues: 2);
      expect(c.copyWith(), c);
    });

    test('toString is non-empty', () {
      expect(DiagnosticContext().toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. DiagnosticIssue
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticIssue', () {
    test('stores all fields', () {
      final issue = DiagnosticIssue(
        title:       'Test issue',
        description: 'Desc',
        category:    DiagnosticCategory.coverage,
        severity:    DiagnosticSeverity.high,
        evidence:    ['ev1', 'ev2'],
      );
      expect(issue.title,       'Test issue');
      expect(issue.category,    DiagnosticCategory.coverage);
      expect(issue.severity,    DiagnosticSeverity.high);
      expect(issue.evidence,    ['ev1', 'ev2']);
    });

    test('equality by all fields', () {
      final a = DiagnosticIssue(
        title: 't', description: 'd',
        category: DiagnosticCategory.planning,
        severity: DiagnosticSeverity.low,
        evidence: ['e'],
      );
      final b = DiagnosticIssue(
        title: 't', description: 'd',
        category: DiagnosticCategory.planning,
        severity: DiagnosticSeverity.low,
        evidence: ['e'],
      );
      expect(a, b);
    });

    test('inequality when title differs', () {
      final a = DiagnosticIssue(title: 'a', description: '', category: DiagnosticCategory.coverage, severity: DiagnosticSeverity.low, evidence: []);
      final b = DiagnosticIssue(title: 'b', description: '', category: DiagnosticCategory.coverage, severity: DiagnosticSeverity.low, evidence: []);
      expect(a, isNot(b));
    });

    test('evidence is unmodifiable', () {
      final issue = DiagnosticIssue(
        title: 't', description: 'd',
        category: DiagnosticCategory.property,
        severity: DiagnosticSeverity.medium,
        evidence: ['ev1'],
      );
      expect(() => (issue.evidence as dynamic).add('ev2'), throwsUnsupportedError);
    });

    test('input evidence list mutation does not affect stored evidence', () {
      final ev = ['a'];
      final issue = DiagnosticIssue(
        title: 't', description: 'd',
        category: DiagnosticCategory.coverage,
        severity: DiagnosticSeverity.low,
        evidence: ev,
      );
      ev.clear();
      expect(issue.evidence, ['a']);
    });

    test('toString contains category and severity', () {
      final issue = DiagnosticIssue(
        title: 'x', description: '', category: DiagnosticCategory.verification,
        severity: DiagnosticSeverity.critical, evidence: [],
      );
      expect(issue.toString(), contains('verification'));
      expect(issue.toString(), contains('critical'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. DiagnosticStatistics
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticStatistics', () {
    test('empty constant has all zeros', () {
      expect(DiagnosticStatistics.empty.issueCount,          0);
      expect(DiagnosticStatistics.empty.criticalIssues,      0);
      expect(DiagnosticStatistics.empty.highIssues,          0);
      expect(DiagnosticStatistics.empty.mediumIssues,        0);
      expect(DiagnosticStatistics.empty.lowIssues,           0);
      expect(DiagnosticStatistics.empty.informationalIssues, 0);
    });

    test('fromIssues counts correctly', () {
      final issues = [
        DiagnosticIssue(title: 'a', description: '', category: DiagnosticCategory.verification, severity: DiagnosticSeverity.critical, evidence: []),
        DiagnosticIssue(title: 'b', description: '', category: DiagnosticCategory.coverage,     severity: DiagnosticSeverity.high,     evidence: []),
        DiagnosticIssue(title: 'c', description: '', category: DiagnosticCategory.planning,     severity: DiagnosticSeverity.medium,   evidence: []),
        DiagnosticIssue(title: 'd', description: '', category: DiagnosticCategory.property,     severity: DiagnosticSeverity.low,      evidence: []),
      ];
      final stats = DiagnosticStatistics.fromIssues(issues);
      expect(stats.issueCount,     4);
      expect(stats.criticalIssues, 1);
      expect(stats.highIssues,     1);
      expect(stats.mediumIssues,   1);
      expect(stats.lowIssues,      1);
      expect(stats.informationalIssues, 0);
    });

    test('fromIssues with empty list produces empty statistics', () {
      expect(DiagnosticStatistics.fromIssues([]), DiagnosticStatistics.empty);
    });

    test('equality by all fields', () {
      final a = DiagnosticStatistics(issueCount: 2, criticalIssues: 1, highIssues: 1, mediumIssues: 0, lowIssues: 0, informationalIssues: 0);
      final b = DiagnosticStatistics(issueCount: 2, criticalIssues: 1, highIssues: 1, mediumIssues: 0, lowIssues: 0, informationalIssues: 0);
      expect(a, b);
    });

    test('toString is non-empty', () {
      expect(DiagnosticStatistics.empty.toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. DiagnosticSummary
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticSummary', () {
    test('healthy session overview', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.summary.overview, contains('good'));
    });

    test('primary issue is first issue title', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.high, overall: 0.45),
        cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.summary.primaryIssue, isNotEmpty);
      expect(report.summary.primaryIssue, isNot('None'));
    });

    test('primary issue is None when no issues', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.summary.primaryIssue, 'None');
    });

    test('dominant category reflects most common category', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.critical, overall: 0.2),
        failureReport(),
        makeExplanations(3, confidence: 0.1),
        VerificationPlan(),
        ctx,
      );
      expect(report.summary.dominantCategory, isNotEmpty);
    });

    test('verificationHealth is healthy when no issues', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.summary.verificationHealth, 'healthy');
    });

    test('verificationHealth is failing on critical issues', () {
      final report = engine.analyze(
        makeCoverage(), engineFailureReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.summary.verificationHealth, 'failing');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. DiagnosticReport helpers
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticReport', () {
    test('isHealthy when no issues', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.isHealthy, true);
      expect(report.hasIssues, false);
    });

    test('hasIssues when issues present', () {
      final report = engine.analyze(
        makeCoverage(), engineFailureReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.hasIssues, true);
      expect(report.isHealthy, false);
    });

    test('issues list is unmodifiable', () {
      final report = engine.analyze(
        makeCoverage(), engineFailureReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      final issue = DiagnosticIssue(title: 'x', description: '', category: DiagnosticCategory.coverage, severity: DiagnosticSeverity.low, evidence: []);
      expect(() => (report.issues as dynamic).add(issue), throwsUnsupportedError);
    });

    test('equality for identical inputs', () {
      final r1 = engine.analyze(makeCoverage(), cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx);
      final r2 = engine.analyze(makeCoverage(), cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx);
      expect(r1, r2);
    });

    test('toString is non-empty', () {
      final report = engine.analyze(makeCoverage(), cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx);
      expect(report.toString(), isNotEmpty);
    });

    test('construction stores all required fields', () {
      final report = engine.analyze(makeCoverage(), failureReport(), makeExplanations(2), makePlan(2), ctx);
      expect(report.summary,           isA<DiagnosticSummary>());
      expect(report.statistics,        isA<DiagnosticStatistics>());
      expect(report.overallSeverity,   isA<DiagnosticSeverity>());
      expect(report.overallConfidence, isA<DiagnosticConfidence>());
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. DiagnosticsEngine — healthy session
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticsEngine healthy session', () {
    test('no issues for fully healthy inputs', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues, isEmpty);
      expect(report.isHealthy, true);
    });

    test('overallSeverity is informational for healthy inputs', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.overallSeverity, DiagnosticSeverity.informational);
    });

    test('confidence is veryHigh for healthy inputs with good coverage', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.minimal, overall: 0.97),
        cleanReport(),
        makeExplanations(3),
        makePlan(3),
        ctx,
      );
      expect(report.overallConfidence, DiagnosticConfidence.veryHigh);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 7. DiagnosticsEngine — coverage-only issues
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticsEngine coverage-only issues', () {
    test('critical coverage risk produces critical issue', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.critical, overall: 0.2),
        cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) => i.severity == DiagnosticSeverity.critical), true);
      expect(report.issues.any((i) => i.category == DiagnosticCategory.coverage), true);
    });

    test('high coverage risk produces high issue', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.high, overall: 0.45),
        cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) => i.severity == DiagnosticSeverity.high && i.category == DiagnosticCategory.coverage), true);
    });

    test('moderate coverage risk produces medium issue', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.moderate, overall: 0.65),
        cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) => i.severity == DiagnosticSeverity.medium && i.category == DiagnosticCategory.coverage), true);
    });

    test('low coverage risk produces low issue', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.low, overall: 0.85),
        cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) => i.severity == DiagnosticSeverity.low && i.category == DiagnosticCategory.coverage), true);
    });

    test('minimal coverage risk produces no coverage issue', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.minimal, overall: 0.97),
        cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) => i.category == DiagnosticCategory.coverage), false);
    });

    test('confidence is high for coverage-only issues (no failures)', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.high, overall: 0.45),
        cleanReport(), VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.overallConfidence, DiagnosticConfidence.high);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 8. DiagnosticsEngine — counterexample-only issues
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticsEngine counterexample-only issues', () {
    test('engine failure produces critical verification issue', () {
      final report = engine.analyze(
        makeCoverage(), engineFailureReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.overallSeverity, DiagnosticSeverity.critical);
      expect(report.issues.any((i) => i.category == DiagnosticCategory.verification), true);
    });

    test('assertion failure produces high counterexample issue', () {
      final report = engine.analyze(
        makeCoverage(), failureReport(n: 2),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.high &&
        i.category == DiagnosticCategory.counterexample), true);
    });

    test('timeout produces high verification issue', () {
      final cex = makeCounterexample(
        classification: CounterexampleClassification.timeout,
        unknownCount: 3,
      );
      final report = engine.analyze(
        makeCoverage(), cex, VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.high &&
        i.category == DiagnosticCategory.verification), true);
    });

    test('assumption violation produces medium verification issue', () {
      final cex = makeCounterexample(
        classification: CounterexampleClassification.assumptionViolation,
      );
      final report = engine.analyze(
        makeCoverage(), cex, VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.medium &&
        i.category == DiagnosticCategory.verification), true);
    });

    test('inconclusive unknowns produce low counterexample issue', () {
      final cex = makeCounterexample(
        classification: CounterexampleClassification.unknown,
        unknownCount: 2,
      );
      final report = engine.analyze(
        makeCoverage(), cex, VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) => i.severity == DiagnosticSeverity.low), true);
    });

    test('confidence is veryLow for engine failure', () {
      final report = engine.analyze(
        makeCoverage(), engineFailureReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.overallConfidence, DiagnosticConfidence.veryLow);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 9. DiagnosticsEngine — planning-only issues
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticsEngine planning-only issues', () {
    test('empty plan with explanations produces medium planning issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(3), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.medium &&
        i.category == DiagnosticCategory.planning), true);
    });

    test('all-induction plan produces low planning issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(3),
        makePlan(3, strategy: VerificationStrategy.induction),
        ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.low &&
        i.category == DiagnosticCategory.planning), true);
    });

    test('normal plan with BMC produces no planning issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(3), makePlan(3), ctx,
      );
      expect(report.issues.any((i) => i.category == DiagnosticCategory.planning), false);
    });

    test('empty plan with empty explanations produces no planning issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) => i.category == DiagnosticCategory.planning), false);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 10. DiagnosticsEngine — explanation-only issues
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticsEngine explanation-only issues', () {
    test('very low confidence with no plan produces medium property issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(3, confidence: 0.1), VerificationPlan(), ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.medium &&
        i.category == DiagnosticCategory.property), true);
    });

    test('very low confidence produces medium property issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(3, confidence: 0.1), makePlan(3), ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.medium &&
        i.category == DiagnosticCategory.property), true);
    });

    test('borderline confidence produces low property issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(3, confidence: 0.4), makePlan(3), ctx,
      );
      expect(report.issues.any((i) =>
        i.severity == DiagnosticSeverity.low &&
        i.category == DiagnosticCategory.property), true);
    });

    test('high confidence explanations produce no property issue', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(3, confidence: 0.9), makePlan(3), ctx,
      );
      expect(report.issues.any((i) => i.category == DiagnosticCategory.property), false);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 11. Evidence fusion tests
  // ════════════════════════════════════════════════════════════════════════════
  group('Evidence fusion', () {
    test('CoverageAssessment + CounterexampleReport: counterexample issue cites coverage', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.high, overall: 0.45),
        failureReport(n: 2),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      final cexIssue = report.issues.firstWhere(
        (i) => i.category == DiagnosticCategory.counterexample,
      );
      expect(cexIssue.evidence.any((e) => e.toLowerCase().contains('coverage')), true);
    });

    test('CoverageAssessment + VerificationExplanation: property issue cites coverage', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.moderate, overall: 0.65),
        cleanReport(),
        makeExplanations(3, confidence: 0.1),
        VerificationPlan(),
        ctx,
      );
      final propIssue = report.issues.firstWhere(
        (i) => i.category == DiagnosticCategory.property,
      );
      expect(propIssue.evidence.any((e) => e.toLowerCase().contains('coverage')), true);
    });

    test('VerificationPlan + VerificationExplanation: planning issue cites explanation count', () {
      final report = engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(5), VerificationPlan(), ctx,
      );
      final planIssue = report.issues.firstWhere(
        (i) => i.category == DiagnosticCategory.planning,
      );
      expect(planIssue.evidence.any((e) => e.contains('5')), true);
    });

    test('Coverage + Counterexample + Explanation produces high or critical severity issue', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.critical, overall: 0.2),
        failureReport(n: 3),
        makeExplanations(3, confidence: 0.1),
        VerificationPlan(),
        ctx,
      );
      expect(
        report.issues.any((i) =>
          i.severity == DiagnosticSeverity.critical ||
          i.severity == DiagnosticSeverity.high),
        true,
      );
    });

    test('coverage issue evidence includes plan length when plan is non-empty', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.high, overall: 0.45),
        cleanReport(),
        makeExplanations(3),
        makePlan(3),
        ctx,
      );
      final covIssue = report.issues.firstWhere(
        (i) => i.category == DiagnosticCategory.coverage,
      );
      expect(covIssue.evidence.any((e) => e.contains('3')), true);
    });

    test('evidence is empty when includeEvidence=false', () {
      final noEvidenceCtx = DiagnosticContext(includeEvidence: false);
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.high, overall: 0.45),
        failureReport(),
        VerificationExplanationSet(), VerificationPlan(),
        noEvidenceCtx,
      );
      expect(report.issues.every((i) => i.evidence.isEmpty), true);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 12. Issue ordering
  // ════════════════════════════════════════════════════════════════════════════
  group('Issue ordering', () {
    test('issues are sorted highest severity first', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.moderate, overall: 0.65),
        failureReport(n: 2),
        makeExplanations(3, confidence: 0.1),
        VerificationPlan(),
        ctx,
      );
      for (int i = 0; i < report.issues.length - 1; i++) {
        expect(
          report.issues[i].severity.index,
          greaterThanOrEqualTo(report.issues[i + 1].severity.index),
        );
      }
    });

    test('within same severity, sorted by category name', () {
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.moderate, overall: 0.65),
        cleanReport(),
        makeExplanations(3, confidence: 0.1),
        VerificationPlan(),
        ctx,
      );
      final mediumIssues = report.issues
          .where((i) => i.severity == DiagnosticSeverity.medium)
          .toList();
      for (int i = 0; i < mediumIssues.length - 1; i++) {
        expect(
          mediumIssues[i].category.name.compareTo(mediumIssues[i + 1].category.name),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('maximumIssues limits output', () {
      final limitCtx = DiagnosticContext(maximumIssues: 1);
      final report = engine.analyze(
        makeCoverage(risk: CoverageRisk.critical, overall: 0.2),
        failureReport(),
        makeExplanations(3, confidence: 0.1),
        VerificationPlan(),
        limitCtx,
      );
      expect(report.issues.length, 1);
    });

    test('maximumIssues=0 produces empty issue list', () {
      final limitCtx = DiagnosticContext(maximumIssues: 0);
      final report = engine.analyze(
        makeCoverage(), engineFailureReport(),
        VerificationExplanationSet(), VerificationPlan(), limitCtx,
      );
      expect(report.issues, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 13. Severity and confidence enums
  // ════════════════════════════════════════════════════════════════════════════
  group('DiagnosticSeverity enum', () {
    test('has all 5 values', () {
      expect(DiagnosticSeverity.values.length, 5);
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.informational));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.low));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.medium));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.high));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.critical));
    });

    test('critical has higher index than high', () {
      expect(DiagnosticSeverity.critical.index, greaterThan(DiagnosticSeverity.high.index));
    });
  });

  group('DiagnosticConfidence enum', () {
    test('has all 5 values', () {
      expect(DiagnosticConfidence.values.length, 5);
      expect(DiagnosticConfidence.values, contains(DiagnosticConfidence.veryLow));
      expect(DiagnosticConfidence.values, contains(DiagnosticConfidence.low));
      expect(DiagnosticConfidence.values, contains(DiagnosticConfidence.medium));
      expect(DiagnosticConfidence.values, contains(DiagnosticConfidence.high));
      expect(DiagnosticConfidence.values, contains(DiagnosticConfidence.veryHigh));
    });
  });

  group('DiagnosticCategory enum', () {
    test('has all 6 values', () {
      expect(DiagnosticCategory.values.length, 6);
      expect(DiagnosticCategory.values, contains(DiagnosticCategory.verification));
      expect(DiagnosticCategory.values, contains(DiagnosticCategory.coverage));
      expect(DiagnosticCategory.values, contains(DiagnosticCategory.planning));
      expect(DiagnosticCategory.values, contains(DiagnosticCategory.property));
      expect(DiagnosticCategory.values, contains(DiagnosticCategory.counterexample));
      expect(DiagnosticCategory.values, contains(DiagnosticCategory.configuration));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 14. Determinism
  // ════════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    test('same inputs produce identical reports across 10 runs', () {
      final cov = makeCoverage(risk: CoverageRisk.moderate, overall: 0.65);
      final cex = failureReport(n: 2);
      final expl = makeExplanations(3, confidence: 0.4);
      final plan = makePlan(3);
      final first = engine.analyze(cov, cex, expl, plan, ctx);
      for (int i = 0; i < 9; i++) {
        expect(engine.analyze(cov, cex, expl, plan, ctx), first);
      }
    });

    test('different engine instances produce equal output', () {
      final cov = makeCoverage(risk: CoverageRisk.high, overall: 0.45);
      final cex = failureReport();
      expect(
        const DiagnosticsEngine().analyze(cov, cex, VerificationExplanationSet(), VerificationPlan(), ctx),
        const DiagnosticsEngine().analyze(cov, cex, VerificationExplanationSet(), VerificationPlan(), ctx),
      );
    });

    test('issue ordering is deterministic', () {
      final cov = makeCoverage(risk: CoverageRisk.moderate, overall: 0.65);
      final cex = failureReport(n: 3);
      final expl = makeExplanations(3, confidence: 0.2);
      final a = engine.analyze(cov, cex, expl, VerificationPlan(), ctx).issues.map((i) => i.title).toList();
      final b = engine.analyze(cov, cex, expl, VerificationPlan(), ctx).issues.map((i) => i.title).toList();
      expect(a, b);
    });

    test('overall severity is deterministic', () {
      final cov = makeCoverage(risk: CoverageRisk.high, overall: 0.45);
      final cex = failureReport(n: 2);
      final s1 = engine.analyze(cov, cex, VerificationExplanationSet(), VerificationPlan(), ctx).overallSeverity;
      final s2 = engine.analyze(cov, cex, VerificationExplanationSet(), VerificationPlan(), ctx).overallSeverity;
      expect(s1, s2);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 15. Negative tests
  // ════════════════════════════════════════════════════════════════════════════
  group('Negative tests', () {
    test('DiagnosticContext maximumIssues < -1 throws ArgumentError', () {
      expect(() => DiagnosticContext(maximumIssues: -2), throwsArgumentError);
    });

    test('DiagnosticStatistics with inconsistent counts throws StateError', () {
      expect(
        () => DiagnosticStatistics(
          issueCount: 5,        // claims 5 total
          criticalIssues: 1,
          highIssues: 1,
          mediumIssues: 1,
          lowIssues: 1,
          informationalIssues: 0,  // sum = 4 ≠ 5
        ),
        throwsStateError,
      );
    });

    test('DiagnosticIssue evidence list is unmodifiable', () {
      final issue = DiagnosticIssue(
        title: 'x', description: '',
        category: DiagnosticCategory.coverage,
        severity: DiagnosticSeverity.low,
        evidence: ['a'],
      );
      expect(() => (issue.evidence as dynamic).add('b'), throwsUnsupportedError);
    });

    test('DiagnosticReport issues list is unmodifiable', () {
      final report = engine.analyze(
        makeCoverage(), engineFailureReport(),
        VerificationExplanationSet(), VerificationPlan(), ctx,
      );
      final issue = DiagnosticIssue(title: 'x', description: '', category: DiagnosticCategory.coverage, severity: DiagnosticSeverity.low, evidence: []);
      expect(() => (report.issues as dynamic).add(issue), throwsUnsupportedError);
    });

    test('copyWith with maximumIssues < -1 throws ArgumentError', () {
      expect(
        () => DiagnosticContext().copyWith(maximumIssues: -5),
        throwsArgumentError,
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 16. Performance
  // ════════════════════════════════════════════════════════════════════════════
  group('Performance', () {
    test('100 explanations analyzed within 100ms', () {
      final sw = Stopwatch()..start();
      engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(100), makePlan(100), ctx,
      );
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('500 explanations analyzed within 200ms', () {
      final sw = Stopwatch()..start();
      engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(500), makePlan(500), ctx,
      );
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('1000 explanations analyzed within 400ms', () {
      final sw = Stopwatch()..start();
      engine.analyze(
        makeCoverage(), cleanReport(),
        makeExplanations(1000), makePlan(1000), ctx,
      );
      expect(sw.elapsedMilliseconds, lessThan(400));
    });
  });
}
