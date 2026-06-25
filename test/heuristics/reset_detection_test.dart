import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// ─── reset_detection_test ─────────────────────────────────────────────────────
//
// Verifies that ResetProvider correctly detects reset signals across all
// supported naming conventions, including the direction-prefix `i_` form that
// was the source of the wb2axip skidbuffer false negative.

// Minimal RTL shell for injecting a sync or async reset pattern.
String _syncHighRtl(String signalName) => '''
module dut (input wire clk, input wire $signalName, input wire d, output reg q);
  always @(posedge clk)
    if ($signalName) q <= 0;
    else             q <= d;
endmodule
''';

String _syncLowRtl(String signalName) => '''
module dut (input wire clk, input wire $signalName, input wire d, output reg q);
  always @(posedge clk)
    if (!$signalName) q <= 0;
    else              q <= d;
endmodule
''';

String _asyncLowRtl(String signalName) => '''
module dut (input wire clk, input wire $signalName, output reg q);
  always @(posedge clk or negedge $signalName)
    if (!$signalName) q <= 0;
    else              q <= 1;
endmodule
''';

String _asyncHighRtl(String signalName) => '''
module dut (input wire clk, input wire $signalName, output reg q);
  always @(posedge clk or posedge $signalName)
    if ($signalName) q <= 0;
    else             q <= 1;
endmodule
''';

Future<List<ResetInfo>> _resets(String rtl) async {
  final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
  return k.resets;
}

void main() {
  // ── Bare names (original behaviour preserved) ─────────────────────────────

  group('sync active-high — bare names', () {
    for (final name in ['rst', 'reset', 'arst', 'srst', 'nrst', 'areset', 'sreset']) {
      test('$name detected as sync active-high', () async {
        final resets = await _resets(_syncHighRtl(name));
        expect(resets, isNotEmpty, reason: 'expected $name to be detected');
        final r = resets.firstWhere((r) => r.name == name);
        expect(r.isSynchronous, isTrue);
        expect(r.isActiveHigh, isTrue);
      });
    }
  });

  group('sync active-low — bare names', () {
    for (final name in ['rst_n', 'reset_n', 'resetn', 'rst', 'arst_n']) {
      test('$name detected as sync active-low', () async {
        final resets = await _resets(_syncLowRtl(name));
        expect(resets, isNotEmpty, reason: 'expected $name to be detected');
        final r = resets.firstWhere((r) => r.name == name);
        expect(r.isSynchronous, isTrue);
        expect(r.isActiveLow, isTrue);
      });
    }
  });

  group('async — bare names', () {
    test('negedge rst_n detected as async active-low', () async {
      final resets = await _resets(_asyncLowRtl('rst_n'));
      final r = resets.firstWhere((r) => r.name == 'rst_n');
      expect(r.isAsynchronous, isTrue);
      expect(r.isActiveLow, isTrue);
    });

    test('posedge arst detected as async active-high', () async {
      final resets = await _resets(_asyncHighRtl('arst'));
      final r = resets.firstWhere((r) => r.name == 'arst');
      expect(r.isAsynchronous, isTrue);
      expect(r.isActiveHigh, isTrue);
    });
  });

  // ── Direction-prefix `i_` names (new) ────────────────────────────────────

  group('sync active-high — i_ prefix (ZipCPU / AXI convention)', () {
    test('i_reset detected as sync active-high', () async {
      final resets = await _resets(_syncHighRtl('i_reset'));
      expect(resets.map((r) => r.name), contains('i_reset'),
          reason: 'i_reset must be detected (was a false negative)');
      final r = resets.firstWhere((r) => r.name == 'i_reset');
      expect(r.isSynchronous, isTrue);
      expect(r.isActiveHigh, isTrue);
    });

    test('i_rst detected as sync active-high', () async {
      final resets = await _resets(_syncHighRtl('i_rst'));
      expect(resets.map((r) => r.name), contains('i_rst'));
      final r = resets.firstWhere((r) => r.name == 'i_rst');
      expect(r.isSynchronous, isTrue);
      expect(r.isActiveHigh, isTrue);
    });

    test('i_arst detected as sync active-high', () async {
      final resets = await _resets(_syncHighRtl('i_arst'));
      expect(resets.map((r) => r.name), contains('i_arst'));
    });

    test('i_srst detected as sync active-high', () async {
      final resets = await _resets(_syncHighRtl('i_srst'));
      expect(resets.map((r) => r.name), contains('i_srst'));
    });
  });

  group('sync active-low — i_ prefix', () {
    test('i_rst_n detected as sync active-low', () async {
      final resets = await _resets(_syncLowRtl('i_rst_n'));
      expect(resets.map((r) => r.name), contains('i_rst_n'));
      final r = resets.firstWhere((r) => r.name == 'i_rst_n');
      expect(r.isActiveLow, isTrue);
    });

    test('i_resetn detected as sync active-low', () async {
      final resets = await _resets(_syncLowRtl('i_resetn'));
      expect(resets.map((r) => r.name), contains('i_resetn'));
    });
  });

  // ── Direction-suffix `_i` names (already matched — no regex change needed) ─

  group('direction suffix _i — already supported', () {
    test('rst_i detected as sync active-high', () async {
      final resets = await _resets(_syncHighRtl('rst_i'));
      expect(resets.map((r) => r.name), contains('rst_i'),
          reason: 'rst_i starts with rst — should match bare-name prefix');
    });

    test('reset_i detected as sync active-high', () async {
      final resets = await _resets(_syncHighRtl('reset_i'));
      expect(resets.map((r) => r.name), contains('reset_i'));
    });
  });

  // ── async with i_ prefix ─────────────────────────────────────────────────

  test('async negedge i_rst detected (from sensitivity list)', () async {
    // Async resets are detected purely from sensitivity-list syntax,
    // independent of the name heuristic.  This test verifies that the
    // i_ prefix does not block async detection.
    final rtl = '''
module dut (input wire i_clk, input wire i_rst, output reg q);
  always @(posedge i_clk or negedge i_rst)
    if (!i_rst) q <= 0;
    else        q <= 1;
endmodule
''';
    final resets = await _resets(rtl);
    expect(resets.map((r) => r.name), contains('i_rst'));
    final r = resets.firstWhere((r) => r.name == 'i_rst');
    expect(r.isAsynchronous, isTrue);
  });

  // ── Negative cases — non-reset signals must NOT be matched ───────────────

  group('non-reset signals not matched', () {
    for (final name in ['i_data', 'i_valid', 'i_ready', 'i_enable', 'i_address', 'i_select']) {
      test('$name is NOT detected as a reset', () async {
        final rtl = '''
module dut (input wire clk, input wire $name, output reg q);
  always @(posedge clk)
    if ($name) q <= 1;
    else       q <= 0;
endmodule
''';
        final resets = await _resets(rtl);
        expect(resets.map((r) => r.name), isNot(contains(name)),
            reason: '$name is not a reset signal');
      });
    }

    test('i_result is NOT detected as a reset', () async {
      final resets = await _resets(_syncHighRtl('i_result'));
      expect(resets.map((r) => r.name), isNot(contains('i_result')));
    });

    test('ireset (no underscore) is NOT detected as a reset', () async {
      // "ireset" does not start with any reset prefix and does not have i_ separator
      final resets = await _resets(_syncHighRtl('ireset'));
      expect(resets.map((r) => r.name), isNot(contains('ireset')));
    });
  });

  // ── hasReset flag ─────────────────────────────────────────────────────────

  test('hasReset is true when i_reset is present', () async {
    final k = await DesignRunner.analyze(
      DesignContext(rtlSource: _syncHighRtl('i_reset')),
    );
    expect(k.hasReset, isTrue);
  });

  test('hasReset is false when no reset signal is present', () async {
    const rtl = 'module dut; reg q; always @(*) q = 0; endmodule';
    final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
    expect(k.hasReset, isFalse);
  });
}
