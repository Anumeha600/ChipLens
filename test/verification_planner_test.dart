import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/explainability/explainability.dart';
import 'package:chiplens_lite/backend/formal/formal_property.dart';
import 'package:chiplens_lite/backend/formal/formal_property_set.dart';
import 'package:chiplens_lite/backend/formal/formal_property_type.dart';
import 'package:chiplens_lite/backend/planning/planning.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

FormalProperty makeProp({
  String id = 'test.prop',
  String name = 'Test Property',
  FormalPropertyType type = FormalPropertyType.assertion,
  double score = 0.8,
  int rank = 1,
  List<String> evidenceIds = const [],
}) =>
    FormalProperty(
      id:           id,
      name:         name,
      propertyType: type,
      expression:   '',
      metadata: {
        'candidateId': id,
        'rank':        rank,
        'score':       score,
        'explanation': 'Score: ${score.toStringAsFixed(4)}',
        'source':      'PropertyEmitter',
        'evidenceIds': List<String>.unmodifiable(evidenceIds),
      },
    );

FormalPropertySet makeSet(List<FormalProperty> props) {
  final set = FormalPropertySet();
  for (final p in props) { set.add(p); }
  return set;
}

VerificationExplanationSet makeExplanations(List<FormalProperty> props) {
  final exps = props.map((p) => VerificationExplanation(
        propertyId: p.id,
        title:      p.name,
        trace: ExplanationTrace(
          semanticEvidenceIds: const [],
          rankingExplanation:  'Test ranking',
          confidence:          (p.metadata['score'] as double),
          emissionReason:      'Emitted at rank ${p.metadata['rank']} by PropertyEmitter',
          propertyType:        p.propertyType.name,
        ),
      )).toList();
  return VerificationExplanationSet(exps);
}

void main() {
  // ════════════════════════════════════════════════════════════════════════════
  // 1. PlanningContext
  // ════════════════════════════════════════════════════════════════════════════
  group('PlanningContext', () {
    test('defaults are sensible', () {
      const ctx = PlanningContext();
      expect(ctx.maximumBatchSize,  -1);
      expect(ctx.batchStrategy,     BatchStrategy.sequential);
      expect(ctx.preserveRanking,   true);
      expect(ctx.includeStatistics, true);
      expect(ctx.planningPolicy,    isA<DefaultPlanningPolicy>());
    });

    test('custom fields are stored correctly', () {
      const ctx = PlanningContext(
        maximumBatchSize:  4,
        batchStrategy:     BatchStrategy.fixedSize,
        preserveRanking:   false,
        includeStatistics: false,
      );
      expect(ctx.maximumBatchSize,  4);
      expect(ctx.batchStrategy,     BatchStrategy.fixedSize);
      expect(ctx.preserveRanking,   false);
      expect(ctx.includeStatistics, false);
    });

    test('equality holds for identical scalar fields', () {
      const a = PlanningContext(maximumBatchSize: 3, batchStrategy: BatchStrategy.propertyType);
      const b = PlanningContext(maximumBatchSize: 3, batchStrategy: BatchStrategy.propertyType);
      expect(a, b);
    });

    test('inequality when any scalar field differs', () {
      const base = PlanningContext();
      expect(base, isNot(PlanningContext(maximumBatchSize: 5)));
      expect(base, isNot(PlanningContext(batchStrategy: BatchStrategy.fixedSize)));
      expect(base, isNot(PlanningContext(preserveRanking: false)));
      expect(base, isNot(PlanningContext(includeStatistics: false)));
    });

    test('copyWith overrides only specified fields', () {
      const original = PlanningContext(maximumBatchSize: 2, preserveRanking: false);
      final copy = original.copyWith(maximumBatchSize: 10);
      expect(copy.maximumBatchSize, 10);
      expect(copy.preserveRanking, false);
      expect(copy.batchStrategy,   BatchStrategy.sequential);
    });

    test('copyWith with no args equals original', () {
      const ctx = PlanningContext(maximumBatchSize: 3, batchStrategy: BatchStrategy.confidence);
      expect(ctx.copyWith(), ctx);
    });

    test('toString mentions batchStrategy', () {
      const ctx = PlanningContext(batchStrategy: BatchStrategy.propertyType);
      expect(ctx.toString(), contains('propertyType'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. VerificationPlanItem
  // ════════════════════════════════════════════════════════════════════════════
  group('VerificationPlanItem', () {
    VerificationPlanItem makeItem({
      String propertyId    = 'p1',
      int executionOrder   = 0,
      int batchId          = 0,
      VerificationStrategy strategy = VerificationStrategy.boundedModelChecking,
      double estimatedCost = 2.0,
    }) =>
        VerificationPlanItem(
          propertyId:     propertyId,
          executionOrder: executionOrder,
          batchId:        batchId,
          strategy:       strategy,
          estimatedCost:  estimatedCost,
        );

    test('stores all fields', () {
      final item = makeItem(propertyId: 'x', executionOrder: 3, batchId: 1,
          strategy: VerificationStrategy.induction, estimatedCost: 4.0);
      expect(item.propertyId,     'x');
      expect(item.executionOrder, 3);
      expect(item.batchId,        1);
      expect(item.strategy,       VerificationStrategy.induction);
      expect(item.estimatedCost,  4.0);
    });

    test('metadata defaults to empty unmodifiable map', () {
      final item = makeItem();
      expect(item.metadata, isEmpty);
      expect(() => (item.metadata as dynamic)['x'] = 1, throwsUnsupportedError);
    });

    test('metadata is stored as unmodifiable', () {
      final m = {'key': 'value'};
      final item = VerificationPlanItem(
        propertyId: 'p', executionOrder: 0, batchId: 0,
        strategy: VerificationStrategy.cover, estimatedCost: 1.0,
        metadata: m,
      );
      expect(() => (item.metadata as dynamic)['extra'] = 1, throwsUnsupportedError);
    });

    test('equality by value', () {
      final a = makeItem(propertyId: 'p', executionOrder: 0, batchId: 0);
      final b = makeItem(propertyId: 'p', executionOrder: 0, batchId: 0);
      expect(a, b);
    });

    test('inequality when propertyId differs', () {
      expect(makeItem(propertyId: 'a'), isNot(makeItem(propertyId: 'b')));
    });

    test('toString contains propertyId and strategy', () {
      final item = makeItem(propertyId: 'fsm.state', strategy: VerificationStrategy.cover);
      expect(item.toString(), contains('fsm.state'));
      expect(item.toString(), contains('cover'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. VerificationPlan
  // ════════════════════════════════════════════════════════════════════════════
  group('VerificationPlan', () {
    VerificationPlanItem item(String id, int order) => VerificationPlanItem(
          propertyId:     id,
          executionOrder: order,
          batchId:        0,
          strategy:       VerificationStrategy.boundedModelChecking,
          estimatedCost:  2.0,
        );

    test('empty plan has length 0', () {
      expect(VerificationPlan().isEmpty, true);
      expect(VerificationPlan().length,  0);
    });

    test('isNotEmpty for non-empty plan', () {
      expect(VerificationPlan([item('p1', 0)]).isNotEmpty, true);
    });

    test('operator[] returns correct element', () {
      final plan = VerificationPlan([item('p1', 0), item('p2', 1)]);
      expect(plan[0].propertyId, 'p1');
      expect(plan[1].propertyId, 'p2');
    });

    test('operator[] throws RangeError out of bounds', () {
      final plan = VerificationPlan([item('p1', 0)]);
      expect(() => plan[5], throwsRangeError);
    });

    test('jobs list is unmodifiable', () {
      final plan = VerificationPlan([item('p1', 0)]);
      expect(() => (plan.jobs as dynamic).add(item('p2', 1)), throwsUnsupportedError);
    });

    test('equality for identical plans', () {
      final a = VerificationPlan([item('p1', 0), item('p2', 1)]);
      final b = VerificationPlan([item('p1', 0), item('p2', 1)]);
      expect(a, b);
    });

    test('inequality for different plans', () {
      final a = VerificationPlan([item('p1', 0)]);
      final b = VerificationPlan([item('p2', 0)]);
      expect(a, isNot(b));
    });

    test('toString contains length', () {
      final plan = VerificationPlan([item('p1', 0), item('p2', 1)]);
      expect(plan.toString(), contains('2'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. PlanningStatistics
  // ════════════════════════════════════════════════════════════════════════════
  group('PlanningStatistics', () {
    test('empty constant has all zeros', () {
      const s = PlanningStatistics.empty;
      expect(s.plannedJobs,            0);
      expect(s.batches,                0);
      expect(s.largestBatch,           0);
      expect(s.smallestBatch,          0);
      expect(s.averageBatchSize,       0.0);
      expect(s.estimatedExecutionCost, 0.0);
    });

    test('fromPlan on empty plan returns empty', () {
      final s = PlanningStatistics.fromPlan(VerificationPlan());
      expect(s, PlanningStatistics.empty);
    });

    test('fromPlan counts planned jobs correctly', () {
      final planner = VerificationPlanner();
      final props = makeSet([
        makeProp(id: 'p1'), makeProp(id: 'p2'), makeProp(id: 'p3'),
      ]);
      final result = planner.plan(props, makeExplanations([
        makeProp(id: 'p1'), makeProp(id: 'p2'), makeProp(id: 'p3'),
      ]), const PlanningContext());
      expect(result.statistics.plannedJobs, 3);
    });

    test('fromPlan computes correct batch count for fixedSize', () {
      final planner = VerificationPlanner();
      final props = [for (int i = 0; i < 6; i++) makeProp(id: 'p$i', rank: i + 1)];
      final result = planner.plan(
        makeSet(props), makeExplanations(props),
        const PlanningContext(maximumBatchSize: 2, batchStrategy: BatchStrategy.fixedSize),
      );
      expect(result.statistics.batches, 3);
    });

    test('fromPlan computes largest and smallest batch correctly', () {
      final planner = VerificationPlanner();
      final props = [for (int i = 0; i < 5; i++) makeProp(id: 'p$i', rank: i + 1)];
      final result = planner.plan(
        makeSet(props), makeExplanations(props),
        const PlanningContext(maximumBatchSize: 3, batchStrategy: BatchStrategy.fixedSize),
      );
      expect(result.statistics.largestBatch,  3);
      expect(result.statistics.smallestBatch, 2);
    });

    test('fromPlan estimated cost sums correctly', () {
      final planner = VerificationPlanner();
      final props = [makeProp(id: 'p1'), makeProp(id: 'p2')];
      final result = planner.plan(
        makeSet(props), makeExplanations(props), const PlanningContext(),
      );
      expect(result.statistics.estimatedExecutionCost, greaterThan(0.0));
    });

    test('toString contains batch info', () {
      const s = PlanningStatistics(
        plannedJobs: 6, batches: 3, largestBatch: 2, smallestBatch: 2,
        averageBatchSize: 2.0, estimatedExecutionCost: 12.0,
      );
      expect(s.toString(), contains('6'));
      expect(s.toString(), contains('3'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. PlanningResult
  // ════════════════════════════════════════════════════════════════════════════
  group('PlanningResult', () {
    test('isEmpty mirrors plan.isEmpty', () {
      final result = PlanningResult(
        plan:         VerificationPlan(),
        statistics:   PlanningStatistics.empty,
        planningTime: Duration.zero,
      );
      expect(result.isEmpty, true);
    });

    test('isNotEmpty for populated plan', () {
      final planner = VerificationPlanner();
      final props = [makeProp(id: 'p1')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.isNotEmpty, true);
    });

    test('hasWarnings is false when no warnings', () {
      final result = PlanningResult(
        plan: VerificationPlan(), statistics: PlanningStatistics.empty,
        planningTime: Duration.zero,
      );
      expect(result.hasWarnings, false);
    });

    test('hasWarnings is true when warnings present', () {
      final result = PlanningResult(
        plan: VerificationPlan(), statistics: PlanningStatistics.empty,
        warnings: ['something went wrong'],
        planningTime: Duration.zero,
      );
      expect(result.hasWarnings, true);
    });

    test('warnings list is unmodifiable', () {
      final result = PlanningResult(
        plan: VerificationPlan(), statistics: PlanningStatistics.empty,
        warnings: ['w1'], planningTime: Duration.zero,
      );
      expect(() => (result.warnings as dynamic).add('w2'), throwsUnsupportedError);
    });

    test('planningTime is preserved', () {
      const t = Duration(milliseconds: 42);
      final result = PlanningResult(
        plan: VerificationPlan(), statistics: PlanningStatistics.empty,
        planningTime: t,
      );
      expect(result.planningTime, t);
    });

    test('toString includes job count', () {
      final planner = VerificationPlanner();
      final props = [makeProp(id: 'p1'), makeProp(id: 'p2')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.toString(), contains('2'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. DefaultPlanningPolicy — sequential
  // ════════════════════════════════════════════════════════════════════════════
  group('DefaultPlanningPolicy sequential', () {
    final planner = VerificationPlanner();

    test('all items in batchId=0', () {
      final props = [makeProp(id: 'a'), makeProp(id: 'b'), makeProp(id: 'c')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.plan.jobs.every((j) => j.batchId == 0), true);
    });

    test('execution order matches input order', () {
      final props = [makeProp(id: 'a'), makeProp(id: 'b'), makeProp(id: 'c')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      final ids = result.plan.jobs.map((j) => j.propertyId).toList();
      expect(ids, ['a', 'b', 'c']);
    });

    test('executionOrder is 0-based consecutive', () {
      final props = [makeProp(id: 'a'), makeProp(id: 'b')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.plan[0].executionOrder, 0);
      expect(result.plan[1].executionOrder, 1);
    });

    test('statistics show one batch for sequential', () {
      final props = [makeProp(id: 'a'), makeProp(id: 'b'), makeProp(id: 'c')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.statistics.batches, 1);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 7. DefaultPlanningPolicy — fixedSize
  // ════════════════════════════════════════════════════════════════════════════
  group('DefaultPlanningPolicy fixedSize', () {
    final planner = VerificationPlanner();
    const ctx = PlanningContext(maximumBatchSize: 3, batchStrategy: BatchStrategy.fixedSize);

    test('first 3 properties are in batch 0', () {
      final props = [for (int i = 0; i < 6; i++) makeProp(id: 'p$i', rank: i + 1)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[0].batchId, 0);
      expect(result.plan[1].batchId, 0);
      expect(result.plan[2].batchId, 0);
    });

    test('properties 4-6 are in batch 1', () {
      final props = [for (int i = 0; i < 6; i++) makeProp(id: 'p$i', rank: i + 1)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[3].batchId, 1);
      expect(result.plan[4].batchId, 1);
      expect(result.plan[5].batchId, 1);
    });

    test('partial last batch is created', () {
      final props = [for (int i = 0; i < 7; i++) makeProp(id: 'p$i', rank: i + 1)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[6].batchId, 2);
      expect(result.statistics.batches, 3);
      expect(result.statistics.largestBatch,  3);
      expect(result.statistics.smallestBatch, 1);
    });

    test('plan length equals property count', () {
      final props = [for (int i = 0; i < 10; i++) makeProp(id: 'p$i', rank: i + 1)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan.length, 10);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 8. DefaultPlanningPolicy — propertyType
  // ════════════════════════════════════════════════════════════════════════════
  group('DefaultPlanningPolicy propertyType', () {
    final planner = VerificationPlanner();
    const ctx = PlanningContext(batchStrategy: BatchStrategy.propertyType);

    test('properties of same type share a batchId', () {
      final props = [
        makeProp(id: 'a1', type: FormalPropertyType.assertion),
        makeProp(id: 'a2', type: FormalPropertyType.assertion),
        makeProp(id: 'c1', type: FormalPropertyType.cover),
      ];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[0].batchId, result.plan[1].batchId);
      expect(result.plan[0].batchId, isNot(result.plan[2].batchId));
    });

    test('distinct types get distinct batchIds', () {
      final props = [
        makeProp(id: 'a1', type: FormalPropertyType.assertion),
        makeProp(id: 'l1', type: FormalPropertyType.liveness),
        makeProp(id: 'c1', type: FormalPropertyType.cover),
      ];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      final ids = {result.plan[0].batchId, result.plan[1].batchId, result.plan[2].batchId};
      expect(ids.length, 3);
    });

    test('cover properties get VerificationStrategy.cover', () {
      final props = [makeProp(id: 'c1', type: FormalPropertyType.cover)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[0].strategy, VerificationStrategy.cover);
    });

    test('liveness properties get VerificationStrategy.induction', () {
      final props = [makeProp(id: 'l1', type: FormalPropertyType.liveness)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[0].strategy, VerificationStrategy.induction);
    });

    test('assertion properties get boundedModelChecking', () {
      final props = [makeProp(id: 'a1', type: FormalPropertyType.assertion)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[0].strategy, VerificationStrategy.boundedModelChecking);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 9. DefaultPlanningPolicy — confidence
  // ════════════════════════════════════════════════════════════════════════════
  group('DefaultPlanningPolicy confidence', () {
    final planner = VerificationPlanner();
    const ctx = PlanningContext(batchStrategy: BatchStrategy.confidence);

    test('higher confidence appears first', () {
      final props = [
        makeProp(id: 'low',  score: 0.3),
        makeProp(id: 'high', score: 0.9),
        makeProp(id: 'mid',  score: 0.6),
      ];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      final ids = result.plan.jobs.map((j) => j.propertyId).toList();
      expect(ids.first, 'high');
      expect(ids.last,  'low');
    });

    test('confidence ordering is stable for equal scores (alpha tie-break)', () {
      final props = [
        makeProp(id: 'z', score: 0.5),
        makeProp(id: 'a', score: 0.5),
      ];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan[0].propertyId, 'a');
      expect(result.plan[1].propertyId, 'z');
    });

    test('all items in one batch when maxBatchSize is -1', () {
      final props = [
        makeProp(id: 'p1', score: 0.9),
        makeProp(id: 'p2', score: 0.5),
        makeProp(id: 'p3', score: 0.1),
      ];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.statistics.batches, 1);
    });

    test('confidence with fixedSize batching creates multiple batches', () {
      final props = [for (int i = 0; i < 4; i++) makeProp(id: 'p$i', score: i * 0.1)];
      final result = planner.plan(
        makeSet(props), makeExplanations(props),
        const PlanningContext(
          batchStrategy:    BatchStrategy.confidence,
          maximumBatchSize: 2,
        ),
      );
      expect(result.statistics.batches, 2);
    });

    test('plan length equals property count after confidence sort', () {
      final props = [for (int i = 0; i < 5; i++) makeProp(id: 'p$i', score: i * 0.1)];
      final result = planner.plan(makeSet(props), makeExplanations(props), ctx);
      expect(result.plan.length, 5);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 10. VerificationPlanner core
  // ════════════════════════════════════════════════════════════════════════════
  group('VerificationPlanner', () {
    final planner = VerificationPlanner();

    test('empty FormalPropertySet produces empty plan', () {
      final result = planner.plan(
        FormalPropertySet(), VerificationExplanationSet(), const PlanningContext(),
      );
      expect(result.plan.isEmpty, true);
      expect(result.statistics,   PlanningStatistics.empty);
    });

    test('single property produces single plan item', () {
      final props = [makeProp(id: 'solo')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.plan.length, 1);
      expect(result.plan[0].propertyId, 'solo');
    });

    test('plan size equals property count', () {
      final props = [for (int i = 0; i < 7; i++) makeProp(id: 'p$i', rank: i + 1)];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.plan.length, 7);
    });

    test('planning time is non-negative', () {
      final props = [makeProp(id: 'p1')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.planningTime.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('statistics are populated when includeStatistics=true', () {
      final props = [makeProp(id: 'p1'), makeProp(id: 'p2')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.statistics.plannedJobs, 2);
    });

    test('statistics are empty when includeStatistics=false', () {
      final props = [makeProp(id: 'p1')];
      final result = planner.plan(
        makeSet(props), makeExplanations(props),
        const PlanningContext(includeStatistics: false),
      );
      expect(result.statistics, PlanningStatistics.empty);
    });

    test('missing explanation generates a warning', () {
      final props = [makeProp(id: 'p1')];
      final result = planner.plan(
        makeSet(props),
        VerificationExplanationSet(),  // no explanations
        const PlanningContext(),
      );
      expect(result.hasWarnings, true);
      expect(result.warnings.first, contains('p1'));
    });

    test('no warnings when all explanations are present', () {
      final props = [makeProp(id: 'p1')];
      final result = planner.plan(makeSet(props), makeExplanations(props), const PlanningContext());
      expect(result.hasWarnings, false);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 11. Determinism
  // ════════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    final planner = VerificationPlanner();

    test('same input produces identical plans across 10 runs', () {
      final props = [
        makeProp(id: 'a', score: 0.9),
        makeProp(id: 'b', score: 0.5),
        makeProp(id: 'c', score: 0.1),
      ];
      final set  = makeSet(props);
      final exps = makeExplanations(props);
      const ctx  = PlanningContext();

      final first = planner.plan(set, exps, ctx).plan;
      for (int i = 0; i < 9; i++) {
        expect(planner.plan(set, exps, ctx).plan, first);
      }
    });

    test('different planner instances produce equal output', () {
      final props = [makeProp(id: 'p1'), makeProp(id: 'p2')];
      final set   = makeSet(props);
      final exps  = makeExplanations(props);
      const ctx   = PlanningContext();
      expect(
        VerificationPlanner().plan(set, exps, ctx).plan,
        VerificationPlanner().plan(set, exps, ctx).plan,
      );
    });

    test('confidence strategy is deterministic for equal-score tie-break', () {
      final props = [
        makeProp(id: 'z', score: 0.5),
        makeProp(id: 'a', score: 0.5),
        makeProp(id: 'm', score: 0.5),
      ];
      final set  = makeSet(props);
      final exps = makeExplanations(props);
      const ctx  = PlanningContext(batchStrategy: BatchStrategy.confidence);

      final planA = planner.plan(set, exps, ctx).plan;
      final planB = planner.plan(set, exps, ctx).plan;
      expect(planA, planB);
    });

    test('propertyType strategy is deterministic', () {
      final props = [
        makeProp(id: 'a1', type: FormalPropertyType.assertion),
        makeProp(id: 'c1', type: FormalPropertyType.cover),
        makeProp(id: 'a2', type: FormalPropertyType.assertion),
      ];
      final set  = makeSet(props);
      final exps = makeExplanations(props);
      const ctx  = PlanningContext(batchStrategy: BatchStrategy.propertyType);

      expect(planner.plan(set, exps, ctx).plan, planner.plan(set, exps, ctx).plan);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 12. Negative tests
  // ════════════════════════════════════════════════════════════════════════════
  group('Negative tests', () {
    final planner = VerificationPlanner();

    test('fixedSize with maximumBatchSize=0 throws ArgumentError', () {
      final props = [makeProp(id: 'p1')];
      expect(
        () => planner.plan(
          makeSet(props), makeExplanations(props),
          const PlanningContext(maximumBatchSize: 0, batchStrategy: BatchStrategy.fixedSize),
        ),
        throwsArgumentError,
      );
    });

    test('fixedSize with maximumBatchSize=-1 throws ArgumentError', () {
      final props = [makeProp(id: 'p1')];
      expect(
        () => planner.plan(
          makeSet(props), makeExplanations(props),
          const PlanningContext(maximumBatchSize: -1, batchStrategy: BatchStrategy.fixedSize),
        ),
        throwsArgumentError,
      );
    });

    test('policy returning wrong count throws StateError', () {
      // Custom policy that always returns an empty plan regardless of input
      final brokenPolicy = _BrokenPolicy();
      final props = [makeProp(id: 'p1')];
      expect(
        () => planner.plan(
          makeSet(props), makeExplanations(props),
          PlanningContext(planningPolicy: brokenPolicy),
        ),
        throwsStateError,
      );
    });

    test('malformed metadata score produces graceful fallback — no throw', () {
      // Property with non-numeric 'score' key
      final badProp = FormalProperty(
        id: 'bad', name: 'Bad', propertyType: FormalPropertyType.assertion,
        expression: '',
        metadata: const {'score': 'not-a-number', 'source': 'PropertyEmitter'},
      );
      expect(
        () => planner.plan(
          makeSet([badProp]), VerificationExplanationSet(),
          const PlanningContext(batchStrategy: BatchStrategy.confidence),
        ),
        returnsNormally,
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 13. Performance
  // ════════════════════════════════════════════════════════════════════════════
  group('Performance', () {
    final planner = VerificationPlanner();

    test('100 properties planned within 100ms', () {
      final props = [for (int i = 0; i < 100; i++) makeProp(id: 'p$i', rank: i + 1)];
      final set = makeSet(props);
      final exps = makeExplanations(props);
      final sw = Stopwatch()..start();
      planner.plan(set, exps, const PlanningContext());
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('500 properties planned within 300ms', () {
      final props = [for (int i = 0; i < 500; i++) makeProp(id: 'p$i', rank: i + 1)];
      final set = makeSet(props);
      final exps = makeExplanations(props);
      final sw = Stopwatch()..start();
      planner.plan(set, exps, const PlanningContext());
      expect(sw.elapsedMilliseconds, lessThan(300));
    });

    test('1000 properties planned within 500ms', () {
      final props = [for (int i = 0; i < 1000; i++) makeProp(id: 'p$i', rank: i + 1)];
      final set = makeSet(props);
      final exps = makeExplanations(props);
      final sw = Stopwatch()..start();
      planner.plan(set, exps, const PlanningContext());
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('5000 properties planned within 2000ms', () {
      final props = [for (int i = 0; i < 5000; i++) makeProp(id: 'p$i', rank: i + 1)];
      final set = makeSet(props);
      final exps = makeExplanations(props);
      final sw = Stopwatch()..start();
      planner.plan(set, exps, const PlanningContext());
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}

// ── Test-only policy that always returns an empty plan (integrity violation) ──
class _BrokenPolicy implements PlanningPolicy {
  @override
  VerificationPlan createPlan(
    FormalPropertySet properties,
    VerificationExplanationSet explanations, {
    required int maxBatchSize,
    required BatchStrategy strategy,
    required bool preserveRanking,
  }) =>
      VerificationPlan(const []);
}
