import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/workflow/workflow_status.dart';

void main() {
  group('WorkflowStatus —', () {
    // ── Value existence ──────────────────────────────────────────────────────

    test('pending exists',   () => expect(WorkflowStatus.pending,   isNotNull));
    test('ready exists',     () => expect(WorkflowStatus.ready,     isNotNull));
    test('running exists',   () => expect(WorkflowStatus.running,   isNotNull));
    test('completed exists', () => expect(WorkflowStatus.completed, isNotNull));
    test('failed exists',    () => expect(WorkflowStatus.failed,    isNotNull));
    test('skipped exists',   () => expect(WorkflowStatus.skipped,   isNotNull));

    // ── Count ────────────────────────────────────────────────────────────────

    test('has exactly 6 values', () {
      expect(WorkflowStatus.values.length, 6);
    });

    // ── Names ────────────────────────────────────────────────────────────────

    test('name: pending',   () => expect(WorkflowStatus.pending.name,   'pending'));
    test('name: ready',     () => expect(WorkflowStatus.ready.name,     'ready'));
    test('name: running',   () => expect(WorkflowStatus.running.name,   'running'));
    test('name: completed', () => expect(WorkflowStatus.completed.name, 'completed'));
    test('name: failed',    () => expect(WorkflowStatus.failed.name,    'failed'));
    test('name: skipped',   () => expect(WorkflowStatus.skipped.name,   'skipped'));

    // ── Identity / equality ──────────────────────────────────────────────────

    test('each value equals itself', () {
      for (final v in WorkflowStatus.values) {
        expect(v, v, reason: '${v.name} should equal itself');
      }
    });

    test('pending != completed', () {
      expect(WorkflowStatus.pending, isNot(WorkflowStatus.completed));
    });

    test('failed != skipped', () {
      expect(WorkflowStatus.failed, isNot(WorkflowStatus.skipped));
    });

    test('no two distinct values are equal', () {
      final values = WorkflowStatus.values;
      for (var i = 0; i < values.length; i++) {
        for (var j = 0; j < values.length; j++) {
          if (i != j) {
            expect(values[i], isNot(values[j]),
                reason: '${values[i].name} != ${values[j].name}');
          }
        }
      }
    });

    // ── Declared order ───────────────────────────────────────────────────────

    test('values are in declared order', () {
      expect(WorkflowStatus.values, [
        WorkflowStatus.pending,
        WorkflowStatus.ready,
        WorkflowStatus.running,
        WorkflowStatus.completed,
        WorkflowStatus.failed,
        WorkflowStatus.skipped,
      ]);
    });

    test('can be looked up by name', () {
      expect(
        WorkflowStatus.values.firstWhere((v) => v.name == 'skipped'),
        WorkflowStatus.skipped,
      );
    });
  });
}
