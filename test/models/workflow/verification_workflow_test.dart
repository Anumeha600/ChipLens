import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/workflow/workflow.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _summaryA = WorkflowSummary(
  totalSteps: 3,
  completedSteps: 2,
  failedSteps: 0,
  skippedSteps: 1,
);

const _summaryB = WorkflowSummary(
  totalSteps: 8,
  completedSteps: 8,
  failedSteps: 0,
  skippedSteps: 0,
);

const _stepPending = WorkflowStep(
  stage: WorkflowStage.verification,
  status: WorkflowStatus.pending,
);

const _stepDone = WorkflowStep(
  stage: WorkflowStage.coverage,
  status: WorkflowStatus.completed,
);

const _stepSkipped = WorkflowStep(
  stage: WorkflowStage.repair,
  status: WorkflowStatus.skipped,
);

const _stepsA = [_stepPending, _stepDone, _stepSkipped];

VerificationWorkflow _workflow({
  String sessionId = 'session_001',
  List<WorkflowStep> steps = _stepsA,
  WorkflowSummary summary = _summaryA,
}) =>
    VerificationWorkflow(
      sessionId: sessionId,
      steps: steps,
      summary: summary,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('VerificationWorkflow — field storage', () {
    test('sessionId is stored', () {
      expect(_workflow().sessionId, 'session_001');
    });

    test('steps are stored', () {
      expect(_workflow().steps, _stepsA);
    });

    test('summary is stored', () {
      expect(_workflow().summary, _summaryA);
    });

    test('empty steps list is valid', () {
      final wf = _workflow(steps: []);
      expect(wf.steps, isEmpty);
    });

    test('single step list is valid', () {
      final wf = _workflow(steps: [_stepPending]);
      expect(wf.steps.length, 1);
    });

    test('steps are ordered as provided', () {
      final wf = _workflow(steps: [_stepSkipped, _stepPending, _stepDone]);
      expect(wf.steps[0], _stepSkipped);
      expect(wf.steps[1], _stepPending);
      expect(wf.steps[2], _stepDone);
    });

    test('all stages can appear in steps', () {
      final steps = WorkflowStage.values
          .map((s) => WorkflowStep(
                stage: s,
                status: WorkflowStatus.pending,
              ))
          .toList();
      final wf = _workflow(steps: steps);
      expect(wf.steps.length, WorkflowStage.values.length);
    });
  });

  group('VerificationWorkflow — equality', () {
    test('same values → equal', () {
      expect(_workflow(), _workflow());
    });

    test('identical instance → equal', () {
      final wf = _workflow();
      expect(wf, wf);
    });

    test('different sessionId → not equal', () {
      expect(
        _workflow(sessionId: 'a'),
        isNot(_workflow(sessionId: 'b')),
      );
    });

    test('different summary → not equal', () {
      expect(
        _workflow(summary: _summaryA),
        isNot(_workflow(summary: _summaryB)),
      );
    });

    test('different step count → not equal', () {
      expect(
        _workflow(steps: [_stepPending]),
        isNot(_workflow(steps: [_stepPending, _stepDone])),
      );
    });

    test('different step content → not equal', () {
      expect(
        _workflow(steps: [_stepPending]),
        isNot(_workflow(steps: [_stepDone])),
      );
    });

    test('step order matters for equality', () {
      expect(
        _workflow(steps: [_stepPending, _stepDone]),
        isNot(_workflow(steps: [_stepDone, _stepPending])),
      );
    });

    test('empty steps == empty steps', () {
      expect(_workflow(steps: []), _workflow(steps: []));
    });

    test('not equal to non-VerificationWorkflow', () {
      expect(_workflow(), isNot('session_001'));
    });
  });

  group('VerificationWorkflow — hashCode', () {
    test('same values → same hashCode', () {
      expect(_workflow().hashCode, _workflow().hashCode);
    });

    test('different sessionId → different hashCode (likely)', () {
      expect(
        _workflow(sessionId: 'a').hashCode,
        isNot(_workflow(sessionId: 'b').hashCode),
      );
    });

    test('different summary → different hashCode (likely)', () {
      expect(
        _workflow(summary: _summaryA).hashCode,
        isNot(_workflow(summary: _summaryB).hashCode),
      );
    });

    test('different steps → different hashCode (likely)', () {
      expect(
        _workflow(steps: [_stepPending]).hashCode,
        isNot(_workflow(steps: [_stepDone]).hashCode),
      );
    });
  });

  group('VerificationWorkflow — copyWith', () {
    test('copyWith with no arguments returns equal instance', () {
      expect(_workflow().copyWith(), _workflow());
    });

    test('copyWith does not mutate original', () {
      final original = _workflow();
      original.copyWith(sessionId: 'changed');
      expect(original.sessionId, 'session_001');
    });

    test('copyWith(sessionId:) updates sessionId', () {
      expect(_workflow().copyWith(sessionId: 'new_id').sessionId, 'new_id');
    });

    test('copyWith(sessionId:) preserves steps and summary', () {
      final updated = _workflow().copyWith(sessionId: 'new_id');
      expect(updated.steps, _stepsA);
      expect(updated.summary, _summaryA);
    });

    test('copyWith(steps:) updates steps', () {
      final updated = _workflow().copyWith(steps: [_stepDone]);
      expect(updated.steps, [_stepDone]);
    });

    test('copyWith(steps:) to empty list', () {
      final updated = _workflow().copyWith(steps: []);
      expect(updated.steps, isEmpty);
    });

    test('copyWith(summary:) updates summary', () {
      final updated = _workflow().copyWith(summary: _summaryB);
      expect(updated.summary, _summaryB);
    });

    test('successive copyWith calls are independent', () {
      final a = _workflow().copyWith(sessionId: 'a');
      final b = _workflow().copyWith(sessionId: 'b');
      expect(a.sessionId, 'a');
      expect(b.sessionId, 'b');
    });
  });
}
