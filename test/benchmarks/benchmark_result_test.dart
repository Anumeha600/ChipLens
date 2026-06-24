import 'package:flutter_test/flutter_test.dart';
import '../../benchmarks/models/benchmark_result.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

const _base = BenchmarkResult(
  designName:      'counter',
  runtimeMs:       42,
  diagnosticCount: 2,
  repairCount:     1,
  success:         true,
);

const _failed = BenchmarkResult(
  designName:      'alu',
  runtimeMs:       5,
  diagnosticCount: 0,
  repairCount:     0,
  success:         false,
  notes:           'File not found.',
);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Field storage ────────────────────────────────────────────────────────────

  group('BenchmarkResult — field storage', () {
    test('designName is stored', () => expect(_base.designName, 'counter'));
    test('runtimeMs is stored',  () => expect(_base.runtimeMs, 42));
    test('diagnosticCount is stored', () => expect(_base.diagnosticCount, 2));
    test('repairCount is stored',     () => expect(_base.repairCount, 1));
    test('success is stored',         () => expect(_base.success, isTrue));
    test('notes defaults to null',    () => expect(_base.notes, isNull));

    test('notes is stored when provided', () {
      expect(_failed.notes, 'File not found.');
    });

    test('success=false is stored', () {
      expect(_failed.success, isFalse);
    });

    test('zero runtimeMs is valid', () {
      const r = BenchmarkResult(
        designName: 'x', runtimeMs: 0,
        diagnosticCount: 0, repairCount: 0, success: true,
      );
      expect(r.runtimeMs, 0);
    });

    test('zero diagnosticCount is valid', () {
      const r = BenchmarkResult(
        designName: 'alu', runtimeMs: 10,
        diagnosticCount: 0, repairCount: 0, success: true,
      );
      expect(r.diagnosticCount, 0);
    });

    test('const constructible', () {
      expect(_base, isNotNull);
    });
  });

  // ── Equality ─────────────────────────────────────────────────────────────────

  group('BenchmarkResult — equality', () {
    test('same values → equal', () {
      const a = BenchmarkResult(
        designName: 'counter', runtimeMs: 42,
        diagnosticCount: 2, repairCount: 1, success: true,
      );
      const b = BenchmarkResult(
        designName: 'counter', runtimeMs: 42,
        diagnosticCount: 2, repairCount: 1, success: true,
      );
      expect(a, b);
    });

    test('identical instance → equal', () => expect(_base, _base));

    test('different designName → not equal', () {
      const other = BenchmarkResult(
        designName: 'fsm', runtimeMs: 42,
        diagnosticCount: 2, repairCount: 1, success: true,
      );
      expect(_base, isNot(other));
    });

    test('different runtimeMs → not equal', () {
      const other = BenchmarkResult(
        designName: 'counter', runtimeMs: 99,
        diagnosticCount: 2, repairCount: 1, success: true,
      );
      expect(_base, isNot(other));
    });

    test('different diagnosticCount → not equal', () {
      const other = BenchmarkResult(
        designName: 'counter', runtimeMs: 42,
        diagnosticCount: 9, repairCount: 1, success: true,
      );
      expect(_base, isNot(other));
    });

    test('different repairCount → not equal', () {
      const other = BenchmarkResult(
        designName: 'counter', runtimeMs: 42,
        diagnosticCount: 2, repairCount: 9, success: true,
      );
      expect(_base, isNot(other));
    });

    test('different success → not equal', () {
      const other = BenchmarkResult(
        designName: 'counter', runtimeMs: 42,
        diagnosticCount: 2, repairCount: 1, success: false,
      );
      expect(_base, isNot(other));
    });

    test('with notes != without notes', () {
      expect(_base, isNot(_failed));
    });

    test('not equal to non-BenchmarkResult', () {
      expect(_base, isNot('counter'));
    });
  });

  // ── hashCode ─────────────────────────────────────────────────────────────────

  group('BenchmarkResult — hashCode', () {
    test('same values → same hashCode', () {
      const a = BenchmarkResult(
        designName: 'counter', runtimeMs: 42,
        diagnosticCount: 2, repairCount: 1, success: true,
      );
      const b = BenchmarkResult(
        designName: 'counter', runtimeMs: 42,
        diagnosticCount: 2, repairCount: 1, success: true,
      );
      expect(a.hashCode, b.hashCode);
    });

    test('different designName → different hashCode (likely)', () {
      const a = BenchmarkResult(
        designName: 'counter', runtimeMs: 10,
        diagnosticCount: 0, repairCount: 0, success: true,
      );
      const b = BenchmarkResult(
        designName: 'fsm', runtimeMs: 10,
        diagnosticCount: 0, repairCount: 0, success: true,
      );
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────────

  group('BenchmarkResult — copyWith', () {
    test('copyWith with no args returns equal instance', () {
      expect(_base.copyWith(), _base);
    });

    test('copyWith does not mutate original', () {
      _base.copyWith(runtimeMs: 999);
      expect(_base.runtimeMs, 42);
    });

    test('copyWith(designName:) updates designName', () {
      expect(_base.copyWith(designName: 'fsm').designName, 'fsm');
    });

    test('copyWith(designName:) preserves other fields', () {
      final updated = _base.copyWith(designName: 'fsm');
      expect(updated.runtimeMs,       42);
      expect(updated.diagnosticCount, 2);
      expect(updated.repairCount,     1);
      expect(updated.success,         isTrue);
    });

    test('copyWith(runtimeMs:) updates runtimeMs', () {
      expect(_base.copyWith(runtimeMs: 100).runtimeMs, 100);
    });

    test('copyWith(diagnosticCount:) updates diagnosticCount', () {
      expect(_base.copyWith(diagnosticCount: 5).diagnosticCount, 5);
    });

    test('copyWith(repairCount:) updates repairCount', () {
      expect(_base.copyWith(repairCount: 3).repairCount, 3);
    });

    test('copyWith(success: false) updates success', () {
      expect(_base.copyWith(success: false).success, isFalse);
    });

    test('copyWith(notes:) attaches notes', () {
      expect(_base.copyWith(notes: 'ok').notes, 'ok');
    });

    test('copyWith(clearNotes: true) removes notes', () {
      expect(_failed.copyWith(clearNotes: true).notes, isNull);
    });

    test('copyWith(clearNotes: true) on null notes stays null', () {
      expect(_base.copyWith(clearNotes: true).notes, isNull);
    });

    test('clearNotes does not remove notes when clearNotes=false', () {
      expect(_failed.copyWith(clearNotes: false).notes, 'File not found.');
    });
  });
}
