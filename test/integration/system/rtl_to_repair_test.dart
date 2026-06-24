import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/coverage_intelligence/coverage_intelligence.dart';
import 'package:chiplens_lite/backend/counterexample/counterexample.dart';
import 'package:chiplens_lite/backend/diagnostics_intelligence/diagnostics_intelligence.dart';
import 'package:chiplens_lite/backend/explainability/explainability.dart';
import 'package:chiplens_lite/backend/planning/planning.dart';
import 'package:chiplens_lite/backend/repair_planning/repair_planning.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

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
    dominantIssue: 'Uncovered FSM states.',
  ),
  risk: CoverageRisk.critical,
  confidence: CoverageConfidence.veryLow,
  recommendations: <CoverageRecommendation>[],
  statistics: const CoverageStatistics(
    recommendationCount: 0,
    warningCount: 2,
    uncoveredStates: 4,
    uncoveredTransitions: 4,
    uncoveredBranches: 6,
    untoggledSignals: 2,
    overallCoverage: 0.30,
  ),
);

final _successCounterexample = CounterexampleReport(
  summary: const CounterexampleSummary(
    overview: 'All properties proven.',
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
    overview: '1 property failed.',
    primaryFailure: 'prop_check',
    earliestFailure: 'prop_check',
    dominantCategory: 'assertionFailure',
  ),
  trace: CounterexampleTrace(
    signals: const [],
    failedProperties: const ['prop_check'],
    firstFailure: 'prop_check',
    estimatedDepth: 3,
  ),
  classification: CounterexampleClassification.assertionFailure,
  confidence: CounterexampleConfidence.high,
  statistics: const CounterexampleStatistics(
    failedPropertyCount: 1,
    unknownPropertyCount: 0,
    signalCount: 0,
    changedSignalCount: 0,
    estimatedDepth: 3,
  ),
);

final _emptyExplanations = VerificationExplanationSet();
final _emptyPlan = VerificationPlan();

const _diagnostics = DiagnosticsEngine();
const _planner = RepairPlanner();

DiagnosticReport _diagnose({
  CoverageAssessment? coverage,
  CounterexampleReport? counterexample,
  DiagnosticContext? context,
}) =>
    _diagnostics.analyze(
      coverage ?? _healthyCoverage,
      counterexample ?? _successCounterexample,
      _emptyExplanations,
      _emptyPlan,
      context ?? DiagnosticContext(),
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Healthy diagnostic → empty repair plan ───────────────────────────────────

  group('RepairPlanner — healthy diagnostic report', () {
    test('no diagnostic issues → plan isEmpty', () {
      final report = _diagnose();
      final plan = _planner.plan(report, RepairContext());
      expect(plan.isEmpty, isTrue);
    });

    test('no diagnostic issues → hasRepairs is false', () {
      final report = _diagnose();
      final plan = _planner.plan(report, RepairContext());
      expect(plan.hasRepairs, isFalse);
    });

    test('no diagnostic issues → overallPriority is low', () {
      final report = _diagnose();
      final plan = _planner.plan(report, RepairContext());
      expect(plan.overallPriority, RepairPriority.low);
    });

    test('no diagnostic issues → statistics.repairCount is 0', () {
      final report = _diagnose();
      final plan = _planner.plan(report, RepairContext());
      expect(plan.statistics.repairCount, 0);
    });

    test('no diagnostic issues → steps list is empty', () {
      final report = _diagnose();
      final plan = _planner.plan(report, RepairContext());
      expect(plan.steps, isEmpty);
    });
  });

  // ── Coverage issues → repair steps ──────────────────────────────────────────

  group('RepairPlanner — coverage diagnostic issues', () {
    test('critical coverage → plan has repair steps', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(report, RepairContext());
      expect(plan.hasRepairs, isTrue);
    });

    test('critical coverage issue → critical overall priority', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(report, RepairContext());
      expect(plan.overallPriority, RepairPriority.critical);
    });

    test('coverage issue → coverage repair category step generated', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(report, RepairContext());
      expect(
        plan.steps.any((s) => s.category == RepairCategory.coverage),
        isTrue,
      );
    });

    test('statistics.repairCount matches steps.length', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(report, RepairContext());
      expect(plan.statistics.repairCount, plan.steps.length);
    });

    test('coverage step has title and description', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(report, RepairContext());
      final coverageStep =
          plan.steps.firstWhere((s) => s.category == RepairCategory.coverage);
      expect(coverageStep.title, isNotEmpty);
      expect(coverageStep.description, isNotEmpty);
    });
  });

  // ── Counterexample failures → repair steps ───────────────────────────────────

  group('RepairPlanner — counterexample diagnostic issues', () {
    test('assertion failure → plan has repair steps', () {
      final report = _diagnose(counterexample: _assertionFailure);
      final plan = _planner.plan(report, RepairContext());
      expect(plan.hasRepairs, isTrue);
    });

    test('assertion failure → verification repair category step', () {
      final report = _diagnose(counterexample: _assertionFailure);
      final plan = _planner.plan(report, RepairContext());
      expect(
        plan.steps.any((s) => s.category == RepairCategory.verification),
        isTrue,
      );
    });

    test('assertion failure → high priority step', () {
      final report = _diagnose(counterexample: _assertionFailure);
      final plan = _planner.plan(report, RepairContext());
      expect(plan.overallPriority, RepairPriority.high);
    });
  });

  // ── Context configuration ────────────────────────────────────────────────────

  group('RepairPlanner — context configuration', () {
    test('maximumRepairSteps=0 → empty steps', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(report, RepairContext(maximumRepairSteps: 0));
      expect(plan.steps, isEmpty);
    });

    test('maximumRepairSteps=1 → at most 1 step', () {
      final report = _diagnose(
        coverage: _poorCoverage,
        counterexample: _assertionFailure,
      );
      final plan =
          _planner.plan(report, RepairContext(maximumRepairSteps: 1));
      expect(plan.steps.length, lessThanOrEqualTo(1));
    });

    test('preserveDiagnosticOrdering=true is accepted', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(
        report,
        RepairContext(preserveDiagnosticOrdering: true),
      );
      expect(plan, isNotNull);
    });

    test('includeDependencies=false produces plan without deps', () {
      final report = _diagnose(coverage: _poorCoverage);
      final plan = _planner.plan(
        report,
        RepairContext(includeDependencies: false),
      );
      for (final step in plan.steps) {
        expect(step.dependencies, isEmpty);
      }
    });
  });

  // ── Determinism ──────────────────────────────────────────────────────────────

  group('RepairPlanner — determinism', () {
    test('identical inputs produce equal plans', () {
      final report = _diagnose(coverage: _poorCoverage);
      final p1 = _planner.plan(report, RepairContext());
      final p2 = _planner.plan(report, RepairContext());
      expect(p1, p2);
    });

    test('each step has a unique id', () {
      final report = _diagnose(
        coverage: _poorCoverage,
        counterexample: _assertionFailure,
      );
      final plan = _planner.plan(report, RepairContext());
      final ids = plan.steps.map((s) => s.id).toSet();
      expect(ids.length, plan.steps.length);
    });
  });

  // ── Full pipeline: RTL diagnostics → repair ──────────────────────────────────

  group('RepairPlanner — full pipeline (diagnostics → repair)', () {
    test('pipeline produces non-null repair plan', () {
      final diagnosticReport = _diagnose(
        coverage: _poorCoverage,
        counterexample: _assertionFailure,
      );
      final repairPlan = _planner.plan(diagnosticReport, RepairContext());
      expect(repairPlan, isNotNull);
    });

    test('repair step count equals non-informational diagnostic issue count', () {
      final diagnosticReport = _diagnose(
        coverage: _poorCoverage,
        counterexample: _assertionFailure,
      );
      final nonInfoCount = diagnosticReport.issues
          .where((i) => i.severity != DiagnosticSeverity.informational)
          .length;
      final repairPlan = _planner.plan(diagnosticReport, RepairContext());
      expect(repairPlan.statistics.repairCount, nonInfoCount);
    });

    test('overall priority matches highest-priority diagnostic issue severity', () {
      final diagnosticReport = _diagnose(
        coverage: _poorCoverage,
        counterexample: _assertionFailure,
      );
      final repairPlan = _planner.plan(diagnosticReport, RepairContext());
      // critical coverage + high counterexample → overall priority is critical
      expect(repairPlan.overallPriority, RepairPriority.critical);
    });

    test('repair plan steps are non-empty when diagnostic has issues', () {
      final diagnosticReport = _diagnose(
        coverage: _poorCoverage,
        counterexample: _assertionFailure,
      );
      final repairPlan = _planner.plan(diagnosticReport, RepairContext());
      expect(repairPlan.steps, isNotEmpty);
    });
  });
}
