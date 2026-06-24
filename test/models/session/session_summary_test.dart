import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/session/session_summary.dart';

// ── Fixture ───────────────────────────────────────────────────────────────────

const _base = SessionSummary(
  rtlModules: 3,
  diagnosticCount: 2,
  repairCount: 1,
  coveragePercent: 87.5,
);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('SessionSummary — field storage', () {
    test('rtlModules is stored', () {
      expect(_base.rtlModules, 3);
    });

    test('diagnosticCount is stored', () {
      expect(_base.diagnosticCount, 2);
    });

    test('repairCount is stored', () {
      expect(_base.repairCount, 1);
    });

    test('coveragePercent is stored', () {
      expect(_base.coveragePercent, 87.5);
    });

    test('zero values are valid', () {
      const zero = SessionSummary(
        rtlModules: 0,
        diagnosticCount: 0,
        repairCount: 0,
        coveragePercent: 0.0,
      );
      expect(zero.rtlModules, 0);
      expect(zero.diagnosticCount, 0);
      expect(zero.repairCount, 0);
      expect(zero.coveragePercent, 0.0);
    });

    test('100% coverage is valid', () {
      const full = SessionSummary(
        rtlModules: 1,
        diagnosticCount: 0,
        repairCount: 0,
        coveragePercent: 100.0,
      );
      expect(full.coveragePercent, 100.0);
    });

    test('const constructible', () {
      const s = SessionSummary(
        rtlModules: 5,
        diagnosticCount: 3,
        repairCount: 2,
        coveragePercent: 65.0,
      );
      expect(s.rtlModules, 5);
    });
  });

  group('SessionSummary — equality', () {
    test('same values → equal', () {
      const a = SessionSummary(
        rtlModules: 3,
        diagnosticCount: 2,
        repairCount: 1,
        coveragePercent: 87.5,
      );
      const b = SessionSummary(
        rtlModules: 3,
        diagnosticCount: 2,
        repairCount: 1,
        coveragePercent: 87.5,
      );
      expect(a, b);
    });

    test('identical instance → equal', () {
      expect(_base, _base);
    });

    test('different rtlModules → not equal', () {
      const other = SessionSummary(
        rtlModules: 99,
        diagnosticCount: 2,
        repairCount: 1,
        coveragePercent: 87.5,
      );
      expect(_base, isNot(other));
    });

    test('different diagnosticCount → not equal', () {
      const other = SessionSummary(
        rtlModules: 3,
        diagnosticCount: 99,
        repairCount: 1,
        coveragePercent: 87.5,
      );
      expect(_base, isNot(other));
    });

    test('different repairCount → not equal', () {
      const other = SessionSummary(
        rtlModules: 3,
        diagnosticCount: 2,
        repairCount: 99,
        coveragePercent: 87.5,
      );
      expect(_base, isNot(other));
    });

    test('different coveragePercent → not equal', () {
      const other = SessionSummary(
        rtlModules: 3,
        diagnosticCount: 2,
        repairCount: 1,
        coveragePercent: 50.0,
      );
      expect(_base, isNot(other));
    });

    test('not equal to non-SessionSummary', () {
      expect(_base, isNot(42));
    });
  });

  group('SessionSummary — hashCode', () {
    test('same values → same hashCode', () {
      const a = SessionSummary(
        rtlModules: 3,
        diagnosticCount: 2,
        repairCount: 1,
        coveragePercent: 87.5,
      );
      const b = SessionSummary(
        rtlModules: 3,
        diagnosticCount: 2,
        repairCount: 1,
        coveragePercent: 87.5,
      );
      expect(a.hashCode, b.hashCode);
    });

    test('different rtlModules → different hashCode (likely)', () {
      const a = SessionSummary(
          rtlModules: 1, diagnosticCount: 0, repairCount: 0, coveragePercent: 0);
      const b = SessionSummary(
          rtlModules: 2, diagnosticCount: 0, repairCount: 0, coveragePercent: 0);
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('different coveragePercent → different hashCode (likely)', () {
      const a = SessionSummary(
          rtlModules: 1, diagnosticCount: 0, repairCount: 0, coveragePercent: 50.0);
      const b = SessionSummary(
          rtlModules: 1, diagnosticCount: 0, repairCount: 0, coveragePercent: 99.9);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('SessionSummary — copyWith', () {
    test('copyWith with no arguments returns equal instance', () {
      expect(_base.copyWith(), _base);
    });

    test('copyWith does not mutate the original', () {
      _base.copyWith(rtlModules: 999);
      expect(_base.rtlModules, 3);
    });

    test('copyWith(rtlModules:) updates rtlModules', () {
      expect(_base.copyWith(rtlModules: 10).rtlModules, 10);
    });

    test('copyWith(rtlModules:) preserves other fields', () {
      final u = _base.copyWith(rtlModules: 10);
      expect(u.diagnosticCount, 2);
      expect(u.repairCount, 1);
      expect(u.coveragePercent, 87.5);
    });

    test('copyWith(diagnosticCount:) updates diagnosticCount', () {
      expect(_base.copyWith(diagnosticCount: 7).diagnosticCount, 7);
    });

    test('copyWith(repairCount:) updates repairCount', () {
      expect(_base.copyWith(repairCount: 5).repairCount, 5);
    });

    test('copyWith(coveragePercent:) updates coveragePercent', () {
      expect(_base.copyWith(coveragePercent: 95.0).coveragePercent, 95.0);
    });

    test('successive copyWith calls are independent', () {
      final a = _base.copyWith(rtlModules: 10);
      final b = _base.copyWith(rtlModules: 20);
      expect(a.rtlModules, 10);
      expect(b.rtlModules, 20);
      expect(_base.rtlModules, 3);
    });
  });
}
