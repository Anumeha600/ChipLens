import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// ─── clock_detection_test ─────────────────────────────────────────────────────
//
// Verifies that ClockProvider correctly classifies clocks as primary or
// candidate across all supported naming conventions, including the direction-
// prefix/suffix forms added to resolve the wb2axip skidbuffer false negative.

String _rtlWithClock(String clockName) => '''
module dut (input wire $clockName, input wire d, output reg q);
  always @(posedge $clockName)
    q <= d;
endmodule
''';

String _rtlWithTwoClocks(String primary, String candidate) => '''
module dut (input wire $primary, input wire $candidate,
            output reg q1, output reg q2);
  always @(posedge $primary)   q1 <= 0;
  always @(posedge $candidate) q2 <= 0;
endmodule
''';

Future<List<ClockInfo>> _clocks(String rtl) async {
  final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
  return k.clocks;
}

void main() {
  // ── Original primary names (preserved behaviour) ──────────────────────────

  group('primary — original set', () {
    for (final name in ['clk', 'clock', 'sys_clk', 'ref_clk', 'pclk',
                        'aclk', 'hclk', 'mclk', 'sclk', 'osc_clk']) {
      test('$name is primary clock', () async {
        final clocks = await _clocks(_rtlWithClock(name));
        expect(clocks, isNotEmpty);
        final c = clocks.firstWhere((c) => c.name == name);
        expect(c.isPrimaryClock, isTrue, reason: '$name should be primary');
        expect(c.isCandidate, isFalse);
      });
    }
  });

  // ── Direction-prefix i_ (new) ─────────────────────────────────────────────

  group('primary — direction prefix i_ (ZipCPU / AXI convention)', () {
    test('i_clk is primary clock', () async {
      final clocks = await _clocks(_rtlWithClock('i_clk'));
      expect(clocks, isNotEmpty);
      final c = clocks.firstWhere((c) => c.name == 'i_clk');
      expect(c.isPrimaryClock, isTrue,
          reason: 'i_clk was a candidate before the fix; must now be primary');
      expect(c.isCandidate, isFalse);
    });

    test('i_clock is primary clock', () async {
      final clocks = await _clocks(_rtlWithClock('i_clock'));
      final c = clocks.firstWhere((c) => c.name == 'i_clock');
      expect(c.isPrimaryClock, isTrue);
    });
  });

  // ── Direction-suffix _i (new) ─────────────────────────────────────────────

  group('primary — direction suffix _i (AMBA / lowRISC convention)', () {
    test('clk_i is primary clock', () async {
      final clocks = await _clocks(_rtlWithClock('clk_i'));
      final c = clocks.firstWhere((c) => c.name == 'clk_i');
      expect(c.isPrimaryClock, isTrue);
      expect(c.isCandidate, isFalse);
    });

    test('clock_i is primary clock', () async {
      final clocks = await _clocks(_rtlWithClock('clock_i'));
      final c = clocks.firstWhere((c) => c.name == 'clock_i');
      expect(c.isPrimaryClock, isTrue);
    });
  });

  // ── Domain-qualified names (new) ──────────────────────────────────────────

  group('primary — domain-qualified (SoC conventions)', () {
    test('core_clk is primary clock', () async {
      final clocks = await _clocks(_rtlWithClock('core_clk'));
      final c = clocks.firstWhere((c) => c.name == 'core_clk');
      expect(c.isPrimaryClock, isTrue);
    });

    test('system_clock is primary clock', () async {
      final clocks = await _clocks(_rtlWithClock('system_clock'));
      final c = clocks.firstWhere((c) => c.name == 'system_clock');
      expect(c.isPrimaryClock, isTrue);
    });
  });

  // ── hasClock and primaryClocks ────────────────────────────────────────────

  test('hasClock is true for i_clk', () async {
    final k = await DesignRunner.analyze(
        DesignContext(rtlSource: _rtlWithClock('i_clk')));
    expect(k.hasClock, isTrue);
  });

  test('primaryClocks is non-empty for i_clk', () async {
    final k = await DesignRunner.analyze(
        DesignContext(rtlSource: _rtlWithClock('i_clk')));
    expect(k.primaryClocks, isNotEmpty,
        reason: 'i_clk must appear in primaryClocks after the fix');
    expect(k.primaryClocks.first.name, 'i_clk');
  });

  test('primaryClocks is non-empty for clk_i', () async {
    final k = await DesignRunner.analyze(
        DesignContext(rtlSource: _rtlWithClock('clk_i')));
    expect(k.primaryClocks, isNotEmpty);
  });

  // ── Candidate — non-standard names still classified as candidate ──────────

  group('candidate — non-primary names remain as candidate', () {
    for (final name in ['fast_clk', 'slow_clk', 'wr_clk', 'rd_clk',
                        'div_clk', 'tb_clk']) {
      test('$name remains candidate (not primary)', () async {
        final clocks = await _clocks(_rtlWithClock(name));
        expect(clocks, isNotEmpty);
        final c = clocks.firstWhere((c) => c.name == name);
        expect(c.isCandidate, isTrue, reason: '$name should stay as candidate');
        expect(c.isPrimaryClock, isFalse);
      });
    }
  });

  // ── Mixed design — primary and candidate coexist ──────────────────────────

  test('design with i_clk (primary) and slow_clk (candidate)', () async {
    final clocks = await _clocks(_rtlWithTwoClocks('i_clk', 'slow_clk'));
    expect(clocks.length, 2);
    final primary = clocks.firstWhere((c) => c.name == 'i_clk');
    final candidate = clocks.firstWhere((c) => c.name == 'slow_clk');
    expect(primary.isPrimaryClock, isTrue);
    expect(candidate.isCandidate, isTrue);
  });

  test('design with clk (primary) and wr_clk (candidate)', () async {
    final clocks = await _clocks(_rtlWithTwoClocks('clk', 'wr_clk'));
    final primary = clocks.firstWhere((c) => c.name == 'clk');
    final candidate = clocks.firstWhere((c) => c.name == 'wr_clk');
    expect(primary.isPrimaryClock, isTrue);
    expect(candidate.isCandidate, isTrue);
  });

  // ── No posedge → no clock ────────────────────────────────────────────────

  test('combinational-only module has no clocks', () async {
    const rtl = '''
module comb (input wire a, b, output wire y);
  assign y = a & b;
endmodule
''';
    final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
    expect(k.hasClock, isFalse);
    expect(k.clocks, isEmpty);
  });

  // ── Generated flag is always false ───────────────────────────────────────

  test('isGenerated is always false', () async {
    final clocks = await _clocks(_rtlWithClock('i_clk'));
    for (final c in clocks) {
      expect(c.isGenerated, isFalse);
    }
  });
}
