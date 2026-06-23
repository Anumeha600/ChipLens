import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/diagnostics_intelligence/diagnostics_intelligence.dart';
import 'package:chiplens_lite/backend/repair_planning/repair_planning.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

DiagnosticIssue makeIssue({
  String title = 'Test issue',
  String description = 'Description',
  DiagnosticCategory category = DiagnosticCategory.verification,
  DiagnosticSeverity severity = DiagnosticSeverity.high,
  List<String> evidence = const ['ev1'],
}) =>
    DiagnosticIssue(
      title:       title,
      description: description,
      category:    category,
      severity:    severity,
      evidence:    evidence,
    );

DiagnosticReport makeReport({
  List<DiagnosticIssue> issues = const [],
  DiagnosticSeverity severity   = DiagnosticSeverity.informational,
}) =>
    DiagnosticReport(
      summary: DiagnosticSummary(
        overview:           'test',
        primaryIssue:       issues.isEmpty ? 'None' : issues.first.title,
        dominantCategory:   'none',
        verificationHealth: 'healthy',
      ),
      issues:            issues,
      statistics:        DiagnosticStatistics.fromIssues(issues),
      overallSeverity:   severity,
      overallConfidence: DiagnosticConfidence.veryHigh,
    );

DiagnosticReport singleIssueReport({
  DiagnosticSeverity severity = DiagnosticSeverity.high,
  DiagnosticCategory category = DiagnosticCategory.verification,
  String title = 'Issue',
}) =>
    makeReport(
      issues: [makeIssue(title: title, category: category, severity: severity)],
      severity: severity,
    );

DiagnosticReport mixedReport() => makeReport(
      issues: [
        makeIssue(title: 'Config error',  category: DiagnosticCategory.configuration, severity: DiagnosticSeverity.critical),
        makeIssue(title: 'Verify fails',  category: DiagnosticCategory.verification,  severity: DiagnosticSeverity.high),
        makeIssue(title: 'Low coverage',  category: DiagnosticCategory.coverage,      severity: DiagnosticSeverity.medium),
        makeIssue(title: 'Weak property', category: DiagnosticCategory.property,      severity: DiagnosticSeverity.low),
      ],
      severity: DiagnosticSeverity.critical,
    );

void main() {
  const planner = RepairPlanner();
  final ctx = RepairContext();

  // ════════════════════════════════════════════════════════════════════════════
  // 1. RepairContext
  // ════════════════════════════════════════════════════════════════════════════
  group('RepairContext', () {
    test('defaults are sensible', () {
      final c = RepairContext();
      expect(c.includeStatistics,          true);
      expect(c.includeDependencies,        true);
      expect(c.includeComplexity,          true);
      expect(c.preserveDiagnosticOrdering, false);
      expect(c.maximumRepairSteps,         -1);
    });

    test('custom fields are stored', () {
      final c = RepairContext(includeStatistics: false, maximumRepairSteps: 5);
      expect(c.includeStatistics,  false);
      expect(c.maximumRepairSteps, 5);
    });

    test('equality holds for identical fields', () {
      expect(RepairContext(maximumRepairSteps: 3), RepairContext(maximumRepairSteps: 3));
    });

    test('inequality when any field differs', () {
      final base = RepairContext();
      expect(base, isNot(RepairContext(includeDependencies: false)));
      expect(base, isNot(RepairContext(maximumRepairSteps: 2)));
    });

    test('copyWith overrides only specified fields', () {
      final original = RepairContext(maximumRepairSteps: 4);
      final copy = original.copyWith(includeStatistics: false);
      expect(copy.maximumRepairSteps, 4);
      expect(copy.includeStatistics,  false);
      expect(copy.includeComplexity,  true);
    });

    test('copyWith with no args equals original', () {
      final c = RepairContext(maximumRepairSteps: 2);
      expect(c.copyWith(), c);
    });

    test('toString is non-empty', () {
      expect(RepairContext().toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. RepairDependency
  // ════════════════════════════════════════════════════════════════════════════
  group('RepairDependency', () {
    test('stores all fields', () {
      const d = RepairDependency(repairId: 'a', dependsOn: 'b', reason: 'config first');
      expect(d.repairId,  'a');
      expect(d.dependsOn, 'b');
      expect(d.reason,    'config first');
    });

    test('equality by all fields', () {
      const a = RepairDependency(repairId: 'x', dependsOn: 'y', reason: 'r');
      const b = RepairDependency(repairId: 'x', dependsOn: 'y', reason: 'r');
      expect(a, b);
    });

    test('inequality when dependsOn differs', () {
      const a = RepairDependency(repairId: 'x', dependsOn: 'y', reason: 'r');
      const b = RepairDependency(repairId: 'x', dependsOn: 'z', reason: 'r');
      expect(a, isNot(b));
    });

    test('toString contains both IDs', () {
      const d = RepairDependency(repairId: 'step_a', dependsOn: 'step_b', reason: '');
      expect(d.toString(), contains('step_a'));
      expect(d.toString(), contains('step_b'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. RepairStep
  // ════════════════════════════════════════════════════════════════════════════
  group('RepairStep', () {
    test('stores all fields', () {
      final s = RepairStep(
        id: 's1', title: 'T', description: 'D',
        priority: RepairPriority.high, category: RepairCategory.coverage,
        complexity: RepairComplexity.medium,
        dependencies: const [], supportingEvidence: const ['ev'],
      );
      expect(s.id,       's1');
      expect(s.priority, RepairPriority.high);
      expect(s.category, RepairCategory.coverage);
    });

    test('dependencies are unmodifiable', () {
      final s = RepairStep(
        id: 's', title: '', description: '',
        priority: RepairPriority.low, category: RepairCategory.planning,
        complexity: RepairComplexity.low,
        dependencies: [], supportingEvidence: [],
      );
      const dep = RepairDependency(repairId: 's', dependsOn: 'x', reason: '');
      expect(() => (s.dependencies as dynamic).add(dep), throwsUnsupportedError);
    });

    test('supportingEvidence is unmodifiable', () {
      final s = RepairStep(
        id: 's', title: '', description: '',
        priority: RepairPriority.low, category: RepairCategory.planning,
        complexity: RepairComplexity.low,
        dependencies: [], supportingEvidence: ['a'],
      );
      expect(() => (s.supportingEvidence as dynamic).add('b'), throwsUnsupportedError);
    });

    test('input list mutation does not affect stored dependencies', () {
      final deps = <RepairDependency>[
        const RepairDependency(repairId: 's', dependsOn: 'x', reason: ''),
      ];
      final s = RepairStep(
        id: 's', title: '', description: '',
        priority: RepairPriority.low, category: RepairCategory.planning,
        complexity: RepairComplexity.low,
        dependencies: deps, supportingEvidence: [],
      );
      deps.clear();
      expect(s.dependencies.length, 1);
    });

    test('equality by all fields', () {
      final a = RepairStep(id: 'a', title: 't', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []);
      final b = RepairStep(id: 'a', title: 't', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []);
      expect(a, b);
    });

    test('toString contains id and category', () {
      final s = RepairStep(
        id: 'ver_0', title: '', description: '',
        priority: RepairPriority.critical, category: RepairCategory.verification,
        complexity: RepairComplexity.high,
        dependencies: [], supportingEvidence: [],
      );
      expect(s.toString(), contains('ver_0'));
      expect(s.toString(), contains('verification'));
    });

    test('toString contains priority', () {
      final s = RepairStep(
        id: 's', title: '', description: '',
        priority: RepairPriority.high, category: RepairCategory.coverage,
        complexity: RepairComplexity.medium,
        dependencies: [], supportingEvidence: [],
      );
      expect(s.toString(), contains('high'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. RepairStatistics
  // ════════════════════════════════════════════════════════════════════════════
  group('RepairStatistics', () {
    test('empty constant has all zeros', () {
      expect(RepairStatistics.empty.repairCount,           0);
      expect(RepairStatistics.empty.criticalRepairs,       0);
      expect(RepairStatistics.empty.highPriorityRepairs,   0);
      expect(RepairStatistics.empty.mediumPriorityRepairs, 0);
      expect(RepairStatistics.empty.lowPriorityRepairs,    0);
      expect(RepairStatistics.empty.dependencyCount,       0);
    });

    test('fromSteps counts correctly', () {
      final steps = [
        RepairStep(id: 'a', title: '', description: '', priority: RepairPriority.critical, category: RepairCategory.verification, complexity: RepairComplexity.high, dependencies: [], supportingEvidence: []),
        RepairStep(id: 'b', title: '', description: '', priority: RepairPriority.high,     category: RepairCategory.coverage,     complexity: RepairComplexity.medium, dependencies: [], supportingEvidence: []),
        RepairStep(id: 'c', title: '', description: '', priority: RepairPriority.medium,   category: RepairCategory.planning,     complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []),
        RepairStep(id: 'd', title: '', description: '', priority: RepairPriority.low,      category: RepairCategory.property,     complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []),
      ];
      final stats = RepairStatistics.fromSteps(steps);
      expect(stats.repairCount,           4);
      expect(stats.criticalRepairs,       1);
      expect(stats.highPriorityRepairs,   1);
      expect(stats.mediumPriorityRepairs, 1);
      expect(stats.lowPriorityRepairs,    1);
    });

    test('dependency count is summed across steps', () {
      final dep = const RepairDependency(repairId: 'b', dependsOn: 'a', reason: '');
      final steps = [
        RepairStep(id: 'a', title: '', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []),
        RepairStep(id: 'b', title: '', description: '', priority: RepairPriority.low, category: RepairCategory.coverage, complexity: RepairComplexity.medium, dependencies: [dep], supportingEvidence: []),
      ];
      expect(RepairStatistics.fromSteps(steps).dependencyCount, 1);
    });

    test('equality by all fields', () {
      final a = RepairStatistics(repairCount: 2, criticalRepairs: 1, highPriorityRepairs: 1, mediumPriorityRepairs: 0, lowPriorityRepairs: 0, dependencyCount: 0);
      final b = RepairStatistics(repairCount: 2, criticalRepairs: 1, highPriorityRepairs: 1, mediumPriorityRepairs: 0, lowPriorityRepairs: 0, dependencyCount: 0);
      expect(a, b);
    });

    test('fromSteps with empty list produces empty statistics', () {
      expect(RepairStatistics.fromSteps([]), RepairStatistics.empty);
    });

    test('statistics match plan output', () {
      final report = singleIssueReport(severity: DiagnosticSeverity.high);
      final plan = planner.plan(report, ctx);
      expect(plan.statistics.repairCount,         1);
      expect(plan.statistics.highPriorityRepairs, 1);
    });

    test('toString is non-empty', () {
      expect(RepairStatistics.empty.toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. RepairPlan helpers
  // ════════════════════════════════════════════════════════════════════════════
  group('RepairPlan', () {
    test('isEmpty for empty step list', () {
      final plan = planner.plan(makeReport(), ctx);
      expect(plan.isEmpty,    true);
      expect(plan.hasRepairs, false);
    });

    test('hasRepairs when steps exist', () {
      final plan = planner.plan(singleIssueReport(), ctx);
      expect(plan.hasRepairs, true);
      expect(plan.isEmpty,    false);
    });

    test('steps list is unmodifiable', () {
      final plan = planner.plan(singleIssueReport(), ctx);
      final step = RepairStep(id: 'x', title: '', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []);
      expect(() => (plan.steps as dynamic).add(step), throwsUnsupportedError);
    });

    test('equality for identical reports', () {
      final r = singleIssueReport();
      expect(planner.plan(r, ctx), planner.plan(r, ctx));
    });

    test('toString is non-empty', () {
      expect(planner.plan(singleIssueReport(), ctx).toString(), isNotEmpty);
    });

    test('overallPriority is low for empty plan', () {
      expect(planner.plan(makeReport(), ctx).overallPriority, RepairPriority.low);
    });

    test('overallComplexity is low for empty plan', () {
      expect(planner.plan(makeReport(), ctx).overallComplexity, RepairComplexity.low);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. RepairPlanner — healthy session
  // ════════════════════════════════════════════════════════════════════════════
  group('RepairPlanner healthy session', () {
    test('all-informational report produces empty plan', () {
      final report = makeReport(
        issues: [makeIssue(severity: DiagnosticSeverity.informational)],
        severity: DiagnosticSeverity.informational,
      );
      expect(planner.plan(report, ctx).isEmpty, true);
    });

    test('empty report produces empty plan', () {
      expect(planner.plan(makeReport(), ctx).isEmpty, true);
    });

    test('empty plan has informational-equivalent overall priority', () {
      final plan = planner.plan(makeReport(), ctx);
      expect(plan.overallPriority, RepairPriority.low);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 7. Priority mapping
  // ════════════════════════════════════════════════════════════════════════════
  group('Priority mapping', () {
    test('critical diagnostic → critical repair', () {
      final plan = planner.plan(singleIssueReport(severity: DiagnosticSeverity.critical), ctx);
      expect(plan.steps.first.priority, RepairPriority.critical);
    });

    test('high diagnostic → high repair', () {
      final plan = planner.plan(singleIssueReport(severity: DiagnosticSeverity.high), ctx);
      expect(plan.steps.first.priority, RepairPriority.high);
    });

    test('medium diagnostic → medium repair', () {
      final plan = planner.plan(singleIssueReport(severity: DiagnosticSeverity.medium), ctx);
      expect(plan.steps.first.priority, RepairPriority.medium);
    });

    test('low diagnostic → low repair', () {
      final plan = planner.plan(singleIssueReport(severity: DiagnosticSeverity.low), ctx);
      expect(plan.steps.first.priority, RepairPriority.low);
    });

    test('informational diagnostic → no repair step', () {
      final report = makeReport(
        issues: [makeIssue(severity: DiagnosticSeverity.informational)],
        severity: DiagnosticSeverity.informational,
      );
      expect(planner.plan(report, ctx).steps, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 8. Category mapping
  // ════════════════════════════════════════════════════════════════════════════
  group('Category mapping', () {
    test('verification diagnostic → verification repair', () {
      final plan = planner.plan(singleIssueReport(category: DiagnosticCategory.verification), ctx);
      expect(plan.steps.first.category, RepairCategory.verification);
    });

    test('coverage diagnostic → coverage repair', () {
      final plan = planner.plan(singleIssueReport(category: DiagnosticCategory.coverage), ctx);
      expect(plan.steps.first.category, RepairCategory.coverage);
    });

    test('planning diagnostic → planning repair', () {
      final plan = planner.plan(singleIssueReport(category: DiagnosticCategory.planning), ctx);
      expect(plan.steps.first.category, RepairCategory.planning);
    });

    test('property diagnostic → property repair', () {
      final plan = planner.plan(singleIssueReport(category: DiagnosticCategory.property), ctx);
      expect(plan.steps.first.category, RepairCategory.property);
    });

    test('counterexample diagnostic → verification repair', () {
      final plan = planner.plan(singleIssueReport(category: DiagnosticCategory.counterexample), ctx);
      expect(plan.steps.first.category, RepairCategory.verification);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 9. Complexity estimation
  // ════════════════════════════════════════════════════════════════════════════
  group('Complexity estimation', () {
    test('configuration repair has low complexity', () {
      final plan = planner.plan(
        singleIssueReport(category: DiagnosticCategory.configuration), ctx,
      );
      expect(plan.steps.first.complexity, RepairComplexity.low);
    });

    test('planning repair has low complexity', () {
      final plan = planner.plan(
        singleIssueReport(category: DiagnosticCategory.planning), ctx,
      );
      expect(plan.steps.first.complexity, RepairComplexity.low);
    });

    test('coverage repair has medium complexity', () {
      final plan = planner.plan(
        singleIssueReport(category: DiagnosticCategory.coverage), ctx,
      );
      expect(plan.steps.first.complexity, RepairComplexity.medium);
    });

    test('property repair has medium complexity', () {
      final plan = planner.plan(
        singleIssueReport(category: DiagnosticCategory.property), ctx,
      );
      expect(plan.steps.first.complexity, RepairComplexity.medium);
    });

    test('verification repair has high complexity', () {
      final plan = planner.plan(
        singleIssueReport(category: DiagnosticCategory.verification), ctx,
      );
      expect(plan.steps.first.complexity, RepairComplexity.high);
    });

    test('complexity is low when includeComplexity=false', () {
      final noComplexCtx = ctx.copyWith(includeComplexity: false);
      final plan = planner.plan(
        singleIssueReport(category: DiagnosticCategory.verification), noComplexCtx,
      );
      expect(plan.steps.first.complexity, RepairComplexity.low);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 10. Dependency generation
  // ════════════════════════════════════════════════════════════════════════════
  group('Dependency generation', () {
    test('configuration repair precedes verification repair', () {
      final plan = planner.plan(mixedReport(), ctx);
      final verStep = plan.steps.firstWhere((s) => s.category == RepairCategory.verification);
      final configStep = plan.steps.firstWhere((s) => s.category == RepairCategory.configuration);
      expect(verStep.dependencies.any((d) => d.dependsOn == configStep.id), true);
    });

    test('property repair precedes coverage repair', () {
      final report = makeReport(
        issues: [
          makeIssue(title: 'Low coverage', category: DiagnosticCategory.coverage, severity: DiagnosticSeverity.high),
          makeIssue(title: 'Weak prop',    category: DiagnosticCategory.property, severity: DiagnosticSeverity.medium),
        ],
        severity: DiagnosticSeverity.high,
      );
      final plan = planner.plan(report, ctx);
      final covStep  = plan.steps.firstWhere((s) => s.category == RepairCategory.coverage);
      final propStep = plan.steps.firstWhere((s) => s.category == RepairCategory.property);
      expect(covStep.dependencies.any((d) => d.dependsOn == propStep.id), true);
    });

    test('planning repair has no dependencies', () {
      final report = makeReport(
        issues: [makeIssue(category: DiagnosticCategory.planning, severity: DiagnosticSeverity.medium)],
        severity: DiagnosticSeverity.medium,
      );
      final plan = planner.plan(report, ctx);
      expect(plan.steps.first.dependencies, isEmpty);
    });

    test('no dependencies when includeDependencies=false', () {
      final noDepsCtx = ctx.copyWith(includeDependencies: false);
      final plan = planner.plan(mixedReport(), noDepsCtx);
      expect(plan.steps.every((s) => s.dependencies.isEmpty), true);
    });

    test('dependency count matches statistics', () {
      final plan = planner.plan(mixedReport(), ctx);
      final totalDeps = plan.steps.fold(0, (sum, s) => sum + s.dependencies.length);
      expect(plan.statistics.dependencyCount, totalDeps);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 11. Step ordering
  // ════════════════════════════════════════════════════════════════════════════
  group('Step ordering', () {
    test('steps are sorted highest priority first', () {
      final plan = planner.plan(mixedReport(), ctx);
      // critical=0, low=3 — ascending index = highest priority first
      for (int i = 0; i < plan.steps.length - 1; i++) {
        expect(
          plan.steps[i].priority.index,
          lessThanOrEqualTo(plan.steps[i + 1].priority.index),
        );
      }
    });

    test('within same priority, independent steps come before dependent ones', () {
      final report = makeReport(
        issues: [
          makeIssue(title: 'Config fix',   category: DiagnosticCategory.configuration, severity: DiagnosticSeverity.critical),
          makeIssue(title: 'Verify fix',   category: DiagnosticCategory.verification,  severity: DiagnosticSeverity.critical),
        ],
        severity: DiagnosticSeverity.critical,
      );
      final plan = planner.plan(report, ctx);
      final firstStep = plan.steps.first;
      expect(firstStep.category, RepairCategory.configuration);
    });

    test('maximumRepairSteps limits output', () {
      final limitCtx = ctx.copyWith(maximumRepairSteps: 2);
      expect(planner.plan(mixedReport(), limitCtx).steps.length, 2);
    });

    test('maximumRepairSteps=0 produces empty plan', () {
      final limitCtx = ctx.copyWith(maximumRepairSteps: 0);
      expect(planner.plan(mixedReport(), limitCtx).isEmpty, true);
    });

    test('preserveDiagnosticOrdering keeps diagnostic issue order', () {
      final preserveCtx = ctx.copyWith(preserveDiagnosticOrdering: true);
      final report = makeReport(
        issues: [
          makeIssue(title: 'Low',      severity: DiagnosticSeverity.low),
          makeIssue(title: 'Critical', severity: DiagnosticSeverity.critical),
        ],
        severity: DiagnosticSeverity.critical,
      );
      final plan = planner.plan(report, preserveCtx);
      expect(plan.steps.first.title, contains('Low'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 12. Overall priority aggregation
  // ════════════════════════════════════════════════════════════════════════════
  group('Overall priority aggregation', () {
    test('any critical step → overall critical', () {
      expect(
        planner.plan(singleIssueReport(severity: DiagnosticSeverity.critical), ctx).overallPriority,
        RepairPriority.critical,
      );
    });

    test('any high step (no critical) → overall high', () {
      expect(
        planner.plan(singleIssueReport(severity: DiagnosticSeverity.high), ctx).overallPriority,
        RepairPriority.high,
      );
    });

    test('medium-only steps → overall medium', () {
      expect(
        planner.plan(singleIssueReport(severity: DiagnosticSeverity.medium), ctx).overallPriority,
        RepairPriority.medium,
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 13. Overall complexity aggregation
  // ════════════════════════════════════════════════════════════════════════════
  group('Overall complexity aggregation', () {
    test('any verification step → overall high complexity', () {
      expect(
        planner.plan(singleIssueReport(category: DiagnosticCategory.verification), ctx).overallComplexity,
        RepairComplexity.high,
      );
    });

    test('coverage-only → overall medium complexity', () {
      expect(
        planner.plan(singleIssueReport(category: DiagnosticCategory.coverage), ctx).overallComplexity,
        RepairComplexity.medium,
      );
    });

    test('planning-only → overall low complexity', () {
      expect(
        planner.plan(singleIssueReport(category: DiagnosticCategory.planning), ctx).overallComplexity,
        RepairComplexity.low,
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 14. Enum tests
  // ════════════════════════════════════════════════════════════════════════════
  group('RepairPriority enum', () {
    test('has all 4 values', () {
      expect(RepairPriority.values.length, 4);
      expect(RepairPriority.values, containsAll([RepairPriority.critical, RepairPriority.high, RepairPriority.medium, RepairPriority.low]));
    });

    test('critical has lower index than high (higher priority, spec ordering)', () {
      expect(RepairPriority.critical.index, lessThan(RepairPriority.high.index));
    });
  });

  group('RepairCategory enum', () {
    test('has all 5 values', () {
      expect(RepairCategory.values.length, 5);
      expect(RepairCategory.values, containsAll([
        RepairCategory.verification, RepairCategory.coverage,
        RepairCategory.planning, RepairCategory.property,
        RepairCategory.configuration,
      ]));
    });
  });

  group('RepairComplexity enum', () {
    test('has all 4 values', () {
      expect(RepairComplexity.values.length, 4);
      expect(RepairComplexity.values, containsAll([
        RepairComplexity.trivial, RepairComplexity.low,
        RepairComplexity.medium, RepairComplexity.high,
      ]));
    });

    test('high has higher index than medium', () {
      expect(RepairComplexity.high.index, greaterThan(RepairComplexity.medium.index));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 15. Determinism
  // ════════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    test('same input produces identical plans across 10 runs', () {
      final report = mixedReport();
      final first = planner.plan(report, ctx);
      for (int i = 0; i < 9; i++) {
        expect(planner.plan(report, ctx), first);
      }
    });

    test('different planner instances produce equal output', () {
      final report = mixedReport();
      expect(
        const RepairPlanner().plan(report, ctx),
        const RepairPlanner().plan(report, ctx),
      );
    });

    test('step ordering is deterministic', () {
      final report = mixedReport();
      final a = planner.plan(report, ctx).steps.map((s) => s.id).toList();
      final b = planner.plan(report, ctx).steps.map((s) => s.id).toList();
      expect(a, b);
    });

    test('overall priority is deterministic', () {
      final report = mixedReport();
      final p1 = planner.plan(report, ctx).overallPriority;
      final p2 = planner.plan(report, ctx).overallPriority;
      expect(p1, p2);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 16. Negative tests
  // ════════════════════════════════════════════════════════════════════════════
  group('Negative tests', () {
    test('RepairContext maximumRepairSteps < -1 throws ArgumentError', () {
      expect(() => RepairContext(maximumRepairSteps: -2), throwsArgumentError);
    });

    test('RepairStatistics with negative repairCount throws ArgumentError', () {
      expect(
        () => RepairStatistics(
          repairCount: -1, criticalRepairs: 0,
          highPriorityRepairs: 0, mediumPriorityRepairs: 0,
          lowPriorityRepairs: 0, dependencyCount: 0,
        ),
        throwsArgumentError,
      );
    });

    test('RepairStatistics with inconsistent counts throws StateError', () {
      expect(
        () => RepairStatistics(
          repairCount: 3, criticalRepairs: 1,  // sum = 1 ≠ 3
          highPriorityRepairs: 0, mediumPriorityRepairs: 0,
          lowPriorityRepairs: 0, dependencyCount: 0,
        ),
        throwsStateError,
      );
    });

    test('RepairPlan with duplicate step IDs throws StateError', () {
      final stepA = RepairStep(id: 'dup', title: 'A', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []);
      final stepB = RepairStep(id: 'dup', title: 'B', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [], supportingEvidence: []);
      expect(
        () => RepairPlan(
          steps: [stepA, stepB],
          statistics: RepairStatistics.empty,
          overallPriority: RepairPriority.low,
          overallComplexity: RepairComplexity.low,
        ),
        throwsStateError,
      );
    });

    test('RepairPlan with invalid dependency target throws StateError', () {
      const badDep = RepairDependency(repairId: 'a', dependsOn: 'nonexistent', reason: '');
      final step = RepairStep(id: 'a', title: '', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [badDep], supportingEvidence: []);
      expect(
        () => RepairPlan(
          steps: [step],
          statistics: RepairStatistics.empty,
          overallPriority: RepairPriority.low,
          overallComplexity: RepairComplexity.low,
        ),
        throwsStateError,
      );
    });

    test('RepairPlan with circular dependency throws StateError', () {
      final depAonB = const RepairDependency(repairId: 'a', dependsOn: 'b', reason: '');
      final depBonA = const RepairDependency(repairId: 'b', dependsOn: 'a', reason: '');
      final stepA = RepairStep(id: 'a', title: '', description: '', priority: RepairPriority.low, category: RepairCategory.planning, complexity: RepairComplexity.low, dependencies: [depAonB], supportingEvidence: []);
      final stepB = RepairStep(id: 'b', title: '', description: '', priority: RepairPriority.low, category: RepairCategory.coverage, complexity: RepairComplexity.medium, dependencies: [depBonA], supportingEvidence: []);
      expect(
        () => RepairPlan(
          steps: [stepA, stepB],
          statistics: RepairStatistics.empty,
          overallPriority: RepairPriority.low,
          overallComplexity: RepairComplexity.low,
        ),
        throwsStateError,
      );
    });

    test('copyWith with maximumRepairSteps < -1 throws ArgumentError', () {
      expect(
        () => RepairContext().copyWith(maximumRepairSteps: -5),
        throwsArgumentError,
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 17. Supporting evidence
  // ════════════════════════════════════════════════════════════════════════════
  group('Supporting evidence', () {
    test('repair step copies evidence from diagnostic issue', () {
      final report = makeReport(
        issues: [makeIssue(evidence: ['a', 'b'])],
        severity: DiagnosticSeverity.high,
      );
      final plan = planner.plan(report, ctx);
      expect(plan.steps.first.supportingEvidence, ['a', 'b']);
    });

    test('empty evidence issue produces empty supporting evidence', () {
      final report = makeReport(
        issues: [makeIssue(evidence: [])],
        severity: DiagnosticSeverity.high,
      );
      final plan = planner.plan(report, ctx);
      expect(plan.steps.first.supportingEvidence, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 18. Performance
  // ════════════════════════════════════════════════════════════════════════════
  group('Performance', () {
    test('100 diagnostic issues planned within 100ms', () {
      final issues = List.generate(
        100,
        (i) => makeIssue(title: 'Issue $i', severity: DiagnosticSeverity.values[i % 4]),
      );
      final report = makeReport(issues: issues, severity: DiagnosticSeverity.critical);
      final sw = Stopwatch()..start();
      planner.plan(report, ctx);
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('500 diagnostic issues planned within 200ms', () {
      final issues = List.generate(
        500,
        (i) => makeIssue(title: 'Issue $i', severity: DiagnosticSeverity.values[i % 4]),
      );
      final report = makeReport(issues: issues, severity: DiagnosticSeverity.critical);
      final sw = Stopwatch()..start();
      planner.plan(report, ctx);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('1000 diagnostic issues planned within 400ms', () {
      final issues = List.generate(
        1000,
        (i) => makeIssue(title: 'Issue $i', severity: DiagnosticSeverity.values[i % 4]),
      );
      final report = makeReport(issues: issues, severity: DiagnosticSeverity.critical);
      final sw = Stopwatch()..start();
      planner.plan(report, ctx);
      expect(sw.elapsedMilliseconds, lessThan(400));
    });
  });
}
