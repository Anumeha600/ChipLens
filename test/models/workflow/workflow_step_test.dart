import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/workflow/workflow_step.dart';
import 'package:chiplens_lite/models/workflow/workflow_stage.dart';
import 'package:chiplens_lite/models/workflow/workflow_status.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _base = WorkflowStep(
  stage: WorkflowStage.verification,
  status: WorkflowStatus.pending,
);

final _t0 = DateTime(2026, 1, 15, 10, 0, 0);
final _t1 = DateTime(2026, 1, 15, 10, 5, 0);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('WorkflowStep — field storage', () {
    test('stage is stored', () {
      expect(_base.stage, WorkflowStage.verification);
    });

    test('status is stored', () {
      expect(_base.status, WorkflowStatus.pending);
    });

    test('startedAt defaults to null', () {
      expect(_base.startedAt, isNull);
    });

    test('completedAt defaults to null', () {
      expect(_base.completedAt, isNull);
    });

    test('startedAt is stored when provided', () {
      final step = WorkflowStep(
        stage: WorkflowStage.coverage,
        status: WorkflowStatus.running,
        startedAt: _t0,
      );
      expect(step.startedAt, _t0);
    });

    test('completedAt is stored when provided', () {
      final step = WorkflowStep(
        stage: WorkflowStage.repair,
        status: WorkflowStatus.completed,
        startedAt: _t0,
        completedAt: _t1,
      );
      expect(step.completedAt, _t1);
    });

    test('const constructible without timestamps', () {
      const step = WorkflowStep(
        stage: WorkflowStage.diagnostics,
        status: WorkflowStatus.skipped,
      );
      expect(step.stage, WorkflowStage.diagnostics);
    });

    test('all WorkflowStage values can be stored', () {
      for (final stage in WorkflowStage.values) {
        final step = WorkflowStep(
          stage: stage,
          status: WorkflowStatus.pending,
        );
        expect(step.stage, stage);
      }
    });

    test('all WorkflowStatus values can be stored', () {
      for (final status in WorkflowStatus.values) {
        final step = WorkflowStep(
          stage: WorkflowStage.verification,
          status: status,
        );
        expect(step.status, status);
      }
    });
  });

  group('WorkflowStep — equality', () {
    test('same values → equal', () {
      const a = WorkflowStep(
        stage: WorkflowStage.verification,
        status: WorkflowStatus.pending,
      );
      const b = WorkflowStep(
        stage: WorkflowStage.verification,
        status: WorkflowStatus.pending,
      );
      expect(a, b);
    });

    test('identical instance → equal', () {
      expect(_base, _base);
    });

    test('different stage → not equal', () {
      const other = WorkflowStep(
        stage: WorkflowStage.coverage,
        status: WorkflowStatus.pending,
      );
      expect(_base, isNot(other));
    });

    test('different status → not equal', () {
      const other = WorkflowStep(
        stage: WorkflowStage.verification,
        status: WorkflowStatus.completed,
      );
      expect(_base, isNot(other));
    });

    test('with startedAt != without startedAt', () {
      final withTime = WorkflowStep(
        stage: WorkflowStage.verification,
        status: WorkflowStatus.running,
        startedAt: _t0,
      );
      const withoutTime = WorkflowStep(
        stage: WorkflowStage.verification,
        status: WorkflowStatus.running,
      );
      expect(withTime, isNot(withoutTime));
    });

    test('different startedAt → not equal', () {
      final a = WorkflowStep(
          stage: WorkflowStage.verification,
          status: WorkflowStatus.running,
          startedAt: _t0);
      final b = WorkflowStep(
          stage: WorkflowStage.verification,
          status: WorkflowStatus.running,
          startedAt: _t1);
      expect(a, isNot(b));
    });

    test('different completedAt → not equal', () {
      final a = WorkflowStep(
          stage: WorkflowStage.verification,
          status: WorkflowStatus.completed,
          startedAt: _t0,
          completedAt: _t0);
      final b = WorkflowStep(
          stage: WorkflowStage.verification,
          status: WorkflowStatus.completed,
          startedAt: _t0,
          completedAt: _t1);
      expect(a, isNot(b));
    });
  });

  group('WorkflowStep — hashCode', () {
    test('same values → same hashCode', () {
      const a = WorkflowStep(
          stage: WorkflowStage.verification, status: WorkflowStatus.pending);
      const b = WorkflowStep(
          stage: WorkflowStage.verification, status: WorkflowStatus.pending);
      expect(a.hashCode, b.hashCode);
    });

    test('different stage → different hashCode (likely)', () {
      const a = WorkflowStep(
          stage: WorkflowStage.verification, status: WorkflowStatus.pending);
      const b = WorkflowStep(
          stage: WorkflowStage.coverage, status: WorkflowStatus.pending);
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('different status → different hashCode (likely)', () {
      const a = WorkflowStep(
          stage: WorkflowStage.repair, status: WorkflowStatus.pending);
      const b = WorkflowStep(
          stage: WorkflowStage.repair, status: WorkflowStatus.completed);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('WorkflowStep — copyWith', () {
    test('copyWith with no arguments returns equal instance', () {
      expect(_base.copyWith(), _base);
    });

    test('copyWith does not mutate original', () {
      _base.copyWith(status: WorkflowStatus.completed);
      expect(_base.status, WorkflowStatus.pending);
    });

    test('copyWith(stage:) updates stage', () {
      expect(_base.copyWith(stage: WorkflowStage.repair).stage,
          WorkflowStage.repair);
    });

    test('copyWith(stage:) preserves other fields', () {
      final updated = _base.copyWith(stage: WorkflowStage.coverage);
      expect(updated.status, WorkflowStatus.pending);
      expect(updated.startedAt, isNull);
      expect(updated.completedAt, isNull);
    });

    test('copyWith(status:) updates status', () {
      expect(_base.copyWith(status: WorkflowStatus.running).status,
          WorkflowStatus.running);
    });

    test('copyWith(startedAt:) sets startedAt', () {
      expect(_base.copyWith(startedAt: _t0).startedAt, _t0);
    });

    test('copyWith(completedAt:) sets completedAt', () {
      expect(_base.copyWith(completedAt: _t1).completedAt, _t1);
    });

    test('copyWith(clearStartedAt: true) removes startedAt', () {
      final withTime = WorkflowStep(
          stage: WorkflowStage.verification,
          status: WorkflowStatus.running,
          startedAt: _t0);
      expect(withTime.copyWith(clearStartedAt: true).startedAt, isNull);
    });

    test('copyWith(clearCompletedAt: true) removes completedAt', () {
      final withTime = WorkflowStep(
          stage: WorkflowStage.verification,
          status: WorkflowStatus.completed,
          startedAt: _t0,
          completedAt: _t1);
      expect(withTime.copyWith(clearCompletedAt: true).completedAt, isNull);
    });

    test('copyWith(clearStartedAt: true) on null startedAt stays null', () {
      expect(_base.copyWith(clearStartedAt: true).startedAt, isNull);
    });

    test('copyWith preserves startedAt when clearStartedAt is false', () {
      final withTime = WorkflowStep(
          stage: WorkflowStage.verification,
          status: WorkflowStatus.running,
          startedAt: _t0);
      expect(withTime.copyWith(status: WorkflowStatus.completed).startedAt, _t0);
    });
  });
}
