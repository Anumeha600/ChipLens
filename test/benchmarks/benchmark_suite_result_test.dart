import 'package:flutter_test/flutter_test.dart';
import '../../benchmarks/models/benchmark_models.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

const _r1 = BenchmarkResult(
  designName: 'counter', runtimeMs: 30,
  diagnosticCount: 1, repairCount: 1, success: true,
);
const _r2 = BenchmarkResult(
  designName: 'fsm', runtimeMs: 45,
  diagnosticCount: 2, repairCount: 2, success: true,
);
const _r3 = BenchmarkResult(
  designName: 'alu', runtimeMs: 20,
  diagnosticCount: 0, repairCount: 0, success: true,
);
const _rfailed = BenchmarkResult(
  designName: 'bad', runtimeMs: 0,
  diagnosticCount: 0, repairCount: 0, success: false,
  notes: 'File error.',
);

BenchmarkSuiteResult _suite3() => BenchmarkSuiteResult(
      results:           [_r1, _r2, _r3],
      totalDesigns:      3,
      successfulDesigns: 3,
      failedDesigns:     0,
    );

BenchmarkSuiteResult _suiteWithFailure() => BenchmarkSuiteResult(
      results:           [_r1, _rfailed],
      totalDesigns:      2,
      successfulDesigns: 1,
      failedDesigns:     1,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Field storage ────────────────────────────────────────────────────────────

  group('BenchmarkSuiteResult — field storage', () {
    test('results are stored', () {
      expect(_suite3().results.length, 3);
    });

    test('totalDesigns is stored', () {
      expect(_suite3().totalDesigns, 3);
    });

    test('successfulDesigns is stored', () {
      expect(_suite3().successfulDesigns, 3);
    });

    test('failedDesigns is stored', () {
      expect(_suite3().failedDesigns, 0);
    });

    test('results can be accessed by index', () {
      expect(_suite3().results[0].designName, 'counter');
      expect(_suite3().results[1].designName, 'fsm');
      expect(_suite3().results[2].designName, 'alu');
    });

    test('failed run is stored in results', () {
      expect(_suiteWithFailure().results[1].success, isFalse);
    });

    test('empty results list is valid', () {
      final suite = BenchmarkSuiteResult(
        results: [], totalDesigns: 0,
        successfulDesigns: 0, failedDesigns: 0,
      );
      expect(suite.results, isEmpty);
    });

    test('successfulDesigns + failedDesigns can equal totalDesigns', () {
      final s = _suiteWithFailure();
      expect(s.successfulDesigns + s.failedDesigns, s.totalDesigns);
    });
  });

  // ── Immutability ─────────────────────────────────────────────────────────────

  group('BenchmarkSuiteResult — immutability', () {
    test('results list is unmodifiable', () {
      final suite = _suite3();
      expect(
        () => (suite.results as dynamic).add(_rfailed),
        throwsUnsupportedError,
      );
    });

    test('mutating source list does not affect suite', () {
      final source = [_r1, _r2];
      final suite = BenchmarkSuiteResult(
        results: source, totalDesigns: 2,
        successfulDesigns: 2, failedDesigns: 0,
      );
      source.add(_r3);
      expect(suite.results.length, 2);
    });
  });

  // ── Equality ─────────────────────────────────────────────────────────────────

  group('BenchmarkSuiteResult — equality', () {
    test('same values → equal', () {
      expect(_suite3(), _suite3());
    });

    test('identical instance → equal', () {
      final s = _suite3();
      expect(s, s);
    });

    test('different totalDesigns → not equal', () {
      final a = _suite3();
      final b = BenchmarkSuiteResult(
        results: [_r1, _r2, _r3], totalDesigns: 99,
        successfulDesigns: 3, failedDesigns: 0,
      );
      expect(a, isNot(b));
    });

    test('different results → not equal', () {
      final a = BenchmarkSuiteResult(
        results: [_r1], totalDesigns: 1,
        successfulDesigns: 1, failedDesigns: 0,
      );
      final b = BenchmarkSuiteResult(
        results: [_r2], totalDesigns: 1,
        successfulDesigns: 1, failedDesigns: 0,
      );
      expect(a, isNot(b));
    });

    test('different result order → not equal', () {
      final a = BenchmarkSuiteResult(
        results: [_r1, _r2], totalDesigns: 2,
        successfulDesigns: 2, failedDesigns: 0,
      );
      final b = BenchmarkSuiteResult(
        results: [_r2, _r1], totalDesigns: 2,
        successfulDesigns: 2, failedDesigns: 0,
      );
      expect(a, isNot(b));
    });

    test('different successfulDesigns → not equal', () {
      final a = _suiteWithFailure();
      final b = BenchmarkSuiteResult(
        results: [_r1, _rfailed], totalDesigns: 2,
        successfulDesigns: 2, failedDesigns: 0,
      );
      expect(a, isNot(b));
    });
  });

  // ── hashCode ─────────────────────────────────────────────────────────────────

  group('BenchmarkSuiteResult — hashCode', () {
    test('same values → same hashCode', () {
      expect(_suite3().hashCode, _suite3().hashCode);
    });

    test('different totalDesigns → different hashCode (likely)', () {
      final a = _suite3();
      final b = BenchmarkSuiteResult(
        results: [_r1, _r2, _r3], totalDesigns: 9,
        successfulDesigns: 3, failedDesigns: 0,
      );
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────────

  group('BenchmarkSuiteResult — copyWith', () {
    test('copyWith with no args returns equal instance', () {
      expect(_suite3().copyWith(), _suite3());
    });

    test('copyWith(totalDesigns:) updates totalDesigns', () {
      expect(_suite3().copyWith(totalDesigns: 10).totalDesigns, 10);
    });

    test('copyWith(successfulDesigns:) updates successfulDesigns', () {
      expect(_suite3().copyWith(successfulDesigns: 2).successfulDesigns, 2);
    });

    test('copyWith(failedDesigns:) updates failedDesigns', () {
      expect(_suite3().copyWith(failedDesigns: 1).failedDesigns, 1);
    });

    test('copyWith(results:) updates results', () {
      final updated = _suite3().copyWith(results: [_r1]);
      expect(updated.results.length, 1);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = _suite3().copyWith(totalDesigns: 5);
      expect(updated.successfulDesigns, 3);
      expect(updated.failedDesigns,     0);
      expect(updated.results.length,    3);
    });
  });
}
