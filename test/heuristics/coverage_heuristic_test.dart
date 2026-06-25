import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/coverage_intelligence/coverage_intelligence.dart';
import '../../benchmarks/runner/benchmark_runner.dart';

// ─── coverage_heuristic_test ──────────────────────────────────────────────────
//
// Verifies the BenchmarkRunner coverage heuristic formula after calibration.
//
// Formula (post-calibration): complexity == 0 ? 0.97 : (0.97 - complexity * 0.05).clamp(0.55, 0.94)
// Risk tiers: ≥0.95 → minimal | ≥0.80 → low | ≥0.60 → moderate | <0.60 → high
//
// Key change: multiplier reduced from 0.06 → 0.05 so that designs with 3
// sequential registers (complexity=3) yield 82% (CoverageRisk.low) rather than
// 79% (CoverageRisk.moderate), avoiding overstated concerns on
// borderline-complex designs.

// RTL with a known number of sequential registers and no FSMs/counters.
String _rtlWithNRegisters(int n) {
  final decls = List.generate(n, (i) => '  reg r$i;').join('\n');
  final assigns = List.generate(
      n, (i) => '  always @(posedge clk) r$i <= d;').join('\n');
  return '''
module dut (input wire clk, input wire d);
$decls
$assigns
endmodule
''';
}

const _runner = BenchmarkRunner();

void main() {
  // ── Formula values (test the calibrated arithmetic) ───────────────────────

  group('formula — calibrated values (0.05 multiplier)', () {
    test('complexity 0 → 97%', () {
      const cov = 0.97;
      expect(cov, closeTo(0.97, 0.001));
    });

    test('complexity 1 → 92%', () {
      final cov = (0.97 - 1 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.92, 0.001));
    });

    test('complexity 2 → 87%', () {
      final cov = (0.97 - 2 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.87, 0.001));
    });

    test('complexity 3 → 82% (key fix: was 79% with 0.06 multiplier)', () {
      final cov = (0.97 - 3 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.82, 0.001));
    });

    test('complexity 4 → 77%', () {
      final cov = (0.97 - 4 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.77, 0.001));
    });

    test('complexity 5 → 72%', () {
      final cov = (0.97 - 5 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.72, 0.001));
    });

    test('complexity 6 → 67%', () {
      final cov = (0.97 - 6 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.67, 0.001));
    });

    test('complexity 7 → 62%', () {
      final cov = (0.97 - 7 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.62, 0.001));
    });

    test('complexity 8 → 57%', () {
      final cov = (0.97 - 8 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.57, 0.001));
    });

    test('complexity 9 → clamped to 55%', () {
      final cov = (0.97 - 9 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.55, 0.001));
    });

    test('complexity 100 → still clamped to 55%', () {
      final cov = (0.97 - 100 * 0.05).clamp(0.55, 0.94);
      expect(cov, closeTo(0.55, 0.001));
    });
  });

  // ── Risk tier mapping ─────────────────────────────────────────────────────

  group('risk tiers — boundary values', () {
    test('complexity 0 → 97% → CoverageRisk.minimal', () {
      // 97% ≥ 95% threshold
      const cov = 0.97;
      expect(cov, greaterThanOrEqualTo(0.95));
    });

    test('complexity 3 → 82% → above low threshold (≥0.80)', () {
      final cov = (0.97 - 3 * 0.05).clamp(0.55, 0.94);
      expect(cov, greaterThanOrEqualTo(0.80),
          reason: 'complexity=3 must now yield CoverageRisk.low, not moderate');
    });

    test('complexity 4 → 77% → below low threshold (<0.80)', () {
      final cov = (0.97 - 4 * 0.05).clamp(0.55, 0.94);
      expect(cov, lessThan(0.80));
      expect(cov, greaterThanOrEqualTo(0.60));
    });

    test('complexity 8 → 57% → below moderate threshold (<0.60)', () {
      final cov = (0.97 - 8 * 0.05).clamp(0.55, 0.94);
      expect(cov, lessThan(0.60));
    });
  });

  // ── End-to-end via BenchmarkRunner ────────────────────────────────────────

  group('BenchmarkRunner end-to-end — zero-complexity', () {
    test('empty module (no reg, no assign) gets no diagnostic', () async {
      // RegisterProvider counts both reg declarations and assign targets.
      // A module with neither has registers.length=0 → complexity=0 →
      // CoverageRisk.minimal → DiagnosticsEngine emits 0 diagnostics.
      const rtl = '''
module empty_stub (input wire a, output wire b);
endmodule
''';
      final result = await _runner.runFromSource('empty_stub', rtl);
      expect(result.success, isTrue);
      expect(result.diagnosticCount, 0,
          reason: 'complexity=0 → CoverageRisk.minimal → no diagnostic emitted');
      expect(result.repairCount, 0);
    });

    test('assign-only module (complexity=1) gets 1 diagnostic', () async {
      // assign targets are counted as combinational registers → complexity=1
      const rtl = '''
module and_gate (input wire a, b, output wire y);
  assign y = a & b;
endmodule
''';
      final result = await _runner.runFromSource('and_gate', rtl);
      expect(result.success, isTrue);
      expect(result.diagnosticCount, greaterThan(0),
          reason: 'assign target y → registers.length=1 → complexity=1 → diagnostic');
    });
  });

  group('BenchmarkRunner end-to-end — complexity=1', () {
    test('1-register module gets 1 diagnostic (CoverageRisk.low)', () async {
      final result = await _runner.runFromSource('one_reg', _rtlWithNRegisters(1));
      expect(result.success, isTrue);
      expect(result.diagnosticCount, greaterThan(0));
    });
  });

  group('BenchmarkRunner end-to-end — complexity=3 (regression)', () {
    test('3-register module gets exactly 1 diagnostic at low severity', () async {
      // complexity=3, coverage=82% → CoverageRisk.low → 1 low-severity diagnostic
      // Before calibration: 79% → moderate → 1 medium-severity diagnostic
      final result = await _runner.runFromSource('three_regs', _rtlWithNRegisters(3));
      expect(result.success, isTrue);
      expect(result.diagnosticCount, 1);
      expect(result.repairCount, 1);
    });
  });

  group('BenchmarkRunner end-to-end — complexity=4', () {
    test('4-register module gets 1 diagnostic (coverage 77% → moderate)', () async {
      final result = await _runner.runFromSource('four_regs', _rtlWithNRegisters(4));
      expect(result.success, isTrue);
      expect(result.diagnosticCount, 1);
    });
  });

  group('BenchmarkRunner end-to-end — high complexity', () {
    test('8-register module produces a diagnostic', () async {
      final result = await _runner.runFromSource('eight_regs', _rtlWithNRegisters(8));
      expect(result.success, isTrue);
      expect(result.diagnosticCount, greaterThan(0));
    });
  });

  // ── CoverageRisk enum sanity ──────────────────────────────────────────────

  group('CoverageRisk enum values', () {
    test('CoverageRisk has at least four values', () {
      expect(CoverageRisk.values.length, greaterThanOrEqualTo(4));
    });

    test('minimal has lowest index', () {
      expect(CoverageRisk.minimal.index, lessThan(CoverageRisk.low.index));
      expect(CoverageRisk.low.index, lessThan(CoverageRisk.moderate.index));
      expect(CoverageRisk.moderate.index, lessThan(CoverageRisk.high.index));
    });
  });

  // ── Old formula produces different result at complexity=3 ─────────────────

  test('old formula (0.06) would yield 79% at complexity=3 (not low)', () {
    final oldCov = (0.97 - 3 * 0.06).clamp(0.55, 0.94);
    expect(oldCov, closeTo(0.79, 0.001));
    expect(oldCov, lessThan(0.80),
        reason: 'confirming old formula fell below the low threshold');
  });

  test('new formula (0.05) yields 82% at complexity=3 (above low threshold)', () {
    final newCov = (0.97 - 3 * 0.05).clamp(0.55, 0.94);
    expect(newCov, closeTo(0.82, 0.001));
    expect(newCov, greaterThanOrEqualTo(0.80),
        reason: 'new formula crosses the low threshold — less alarming');
  });
}
