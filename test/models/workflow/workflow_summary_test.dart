import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/workflow/workflow_summary.dart';

// ── Fixture ───────────────────────────────────────────────────────────────────

const _base = WorkflowSummary(
  totalSteps: 8,
  completedSteps: 5,
  failedSteps: 1,
  skippedSteps: 2,
);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('WorkflowSummary — field storage', () {
    test('totalSteps is stored',     () => expect(_base.totalSteps,     8));
    test('completedSteps is stored', () => expect(_base.completedSteps, 5));
    test('failedSteps is stored',    () => expect(_base.failedSteps,    1));
    test('skippedSteps is stored',   () => expect(_base.skippedSteps,   2));

    test('zero values are valid', () {
      const zero = WorkflowSummary(
        totalSteps: 0,
        completedSteps: 0,
        failedSteps: 0,
        skippedSteps: 0,
      );
      expect(zero.totalSteps, 0);
      expect(zero.completedSteps, 0);
    });

    test('const constructible', () {
      const s = WorkflowSummary(
        totalSteps: 4,
        completedSteps: 4,
        failedSteps: 0,
        skippedSteps: 0,
      );
      expect(s.totalSteps, 4);
    });
  });

  group('WorkflowSummary — equality', () {
    test('same values → equal', () {
      const a = WorkflowSummary(
          totalSteps: 8, completedSteps: 5, failedSteps: 1, skippedSteps: 2);
      const b = WorkflowSummary(
          totalSteps: 8, completedSteps: 5, failedSteps: 1, skippedSteps: 2);
      expect(a, b);
    });

    test('identical instance → equal', () => expect(_base, _base));

    test('different totalSteps → not equal', () {
      const other = WorkflowSummary(
          totalSteps: 99, completedSteps: 5, failedSteps: 1, skippedSteps: 2);
      expect(_base, isNot(other));
    });

    test('different completedSteps → not equal', () {
      const other = WorkflowSummary(
          totalSteps: 8, completedSteps: 99, failedSteps: 1, skippedSteps: 2);
      expect(_base, isNot(other));
    });

    test('different failedSteps → not equal', () {
      const other = WorkflowSummary(
          totalSteps: 8, completedSteps: 5, failedSteps: 99, skippedSteps: 2);
      expect(_base, isNot(other));
    });

    test('different skippedSteps → not equal', () {
      const other = WorkflowSummary(
          totalSteps: 8, completedSteps: 5, failedSteps: 1, skippedSteps: 99);
      expect(_base, isNot(other));
    });

    test('not equal to non-WorkflowSummary', () {
      expect(_base, isNot(8));
    });
  });

  group('WorkflowSummary — hashCode', () {
    test('same values → same hashCode', () {
      const a = WorkflowSummary(
          totalSteps: 8, completedSteps: 5, failedSteps: 1, skippedSteps: 2);
      const b = WorkflowSummary(
          totalSteps: 8, completedSteps: 5, failedSteps: 1, skippedSteps: 2);
      expect(a.hashCode, b.hashCode);
    });

    test('different totalSteps → different hashCode (likely)', () {
      const a = WorkflowSummary(
          totalSteps: 4, completedSteps: 0, failedSteps: 0, skippedSteps: 0);
      const b = WorkflowSummary(
          totalSteps: 8, completedSteps: 0, failedSteps: 0, skippedSteps: 0);
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('different completedSteps → different hashCode (likely)', () {
      const a = WorkflowSummary(
          totalSteps: 4, completedSteps: 2, failedSteps: 0, skippedSteps: 0);
      const b = WorkflowSummary(
          totalSteps: 4, completedSteps: 3, failedSteps: 0, skippedSteps: 0);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('WorkflowSummary — copyWith', () {
    test('copyWith with no arguments returns equal instance', () {
      expect(_base.copyWith(), _base);
    });

    test('copyWith does not mutate original', () {
      _base.copyWith(totalSteps: 999);
      expect(_base.totalSteps, 8);
    });

    test('copyWith(totalSteps:) updates totalSteps', () {
      expect(_base.copyWith(totalSteps: 10).totalSteps, 10);
    });

    test('copyWith(completedSteps:) updates completedSteps', () {
      expect(_base.copyWith(completedSteps: 8).completedSteps, 8);
    });

    test('copyWith(failedSteps:) updates failedSteps', () {
      expect(_base.copyWith(failedSteps: 0).failedSteps, 0);
    });

    test('copyWith(skippedSteps:) updates skippedSteps', () {
      expect(_base.copyWith(skippedSteps: 0).skippedSteps, 0);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = _base.copyWith(completedSteps: 8);
      expect(updated.totalSteps, 8);
      expect(updated.failedSteps, 1);
      expect(updated.skippedSteps, 2);
    });

    test('successive copyWith calls are independent', () {
      final a = _base.copyWith(totalSteps: 4);
      final b = _base.copyWith(totalSteps: 16);
      expect(a.totalSteps, 4);
      expect(b.totalSteps, 16);
      expect(_base.totalSteps, 8);
    });
  });
}
