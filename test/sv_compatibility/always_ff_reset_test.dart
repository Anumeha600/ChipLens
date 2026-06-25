// Tests for always_ff async reset recognition in ResetProvider.
//
// always_ff @(posedge clk or negedge rst_n) is the canonical SystemVerilog form
// for flip-flops with asynchronous resets. Without support, the reset would be
// misclassified as synchronous (found via the if(!rst_n) fallback scan).
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

ResetInfo _reset(List<ResetInfo> resets, String name) =>
    resets.firstWhere((r) => r.name == name);

void main() {
  // ── Group 1: always_ff with async active-low reset ────────────────────────
  group('always_ff with async active-low reset', () {
    test('negedge rst_n in always_ff sensitivity list → async active-low', () async {
      const rtl = r'''
module flop(input logic clk, input logic rst_n);
  reg q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 1'b0;
    else        q <= 1'b1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets.map((r) => r.name), contains('rst_n'));
      expect(k.syncResets.map((r) => r.name), isNot(contains('rst_n')));
      final reset = _reset(k.asyncResets, 'rst_n');
      expect(reset.isAsynchronous, isTrue);
      expect(reset.isSynchronous, isFalse);
      expect(reset.isActiveLow, isTrue);
      expect(reset.isActiveHigh, isFalse);
    });

    test('negedge rst_ni (lowRISC naming) in always_ff → async active-low', () async {
      const rtl = r'''
module ibex_style(input logic clk_i, input logic rst_ni);
  reg [7:0] data_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) data_q <= 8'h00;
    else         data_q <= data_q + 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets.map((r) => r.name), contains('rst_ni'));
      expect(k.syncResets.map((r) => r.name), isNot(contains('rst_ni')));
      final reset = _reset(k.asyncResets, 'rst_ni');
      expect(reset.isActiveLow, isTrue);
      expect(reset.isAsynchronous, isTrue);
    });

    test('hasReset is true for always_ff async reset module', () async {
      const rtl = r'''
module m(input logic clk, input logic rst_n);
  reg q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 0;
    else        q <= 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.hasReset, isTrue);
    });

    test('syncResets is empty when only always_ff async reset present', () async {
      const rtl = r'''
module m(input logic clk, input logic rst_n);
  reg q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 0;
    else        q <= 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.syncResets, isEmpty);
    });
  });

  // ── Group 2: always_ff with async active-high reset ───────────────────────
  group('always_ff with async active-high reset', () {
    test('posedge arst in always_ff sensitivity list → async active-high', () async {
      const rtl = r'''
module flop_ah(input logic clk, input logic arst);
  reg q;
  always_ff @(posedge clk or posedge arst) begin
    if (arst) q <= 1'b0;
    else      q <= 1'b1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets.map((r) => r.name), contains('arst'));
      final reset = _reset(k.asyncResets, 'arst');
      expect(reset.isActiveHigh, isTrue);
      expect(reset.isActiveLow, isFalse);
      expect(reset.isAsynchronous, isTrue);
    });

    test('posedge reset in always_ff → async active-high', () async {
      const rtl = r'''
module m(input logic clk, input logic reset);
  reg [3:0] cnt;
  always_ff @(posedge clk or posedge reset) begin
    if (reset) cnt <= 4'h0;
    else       cnt <= cnt + 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets.map((r) => r.name), contains('reset'));
      final r = _reset(k.asyncResets, 'reset');
      expect(r.isActiveHigh, isTrue);
      expect(r.isAsynchronous, isTrue);
    });
  });

  // ── Group 3: always @(posedge) regression guard ───────────────────────────
  group('always @(posedge) regression — Verilog async resets still work', () {
    test('negedge rst_n in always @(posedge…or negedge…) → async active-low', () async {
      const rtl = r'''
module classic(input clk, input rst_n);
  reg q;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 0;
    else        q <= 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets.map((r) => r.name), contains('rst_n'));
      final r = _reset(k.asyncResets, 'rst_n');
      expect(r.isAsynchronous, isTrue);
      expect(r.isActiveLow, isTrue);
    });

    test('posedge arst in always @(posedge…or posedge…) → async active-high', () async {
      const rtl = r'''
module classic_ah(input clk, input arst);
  reg q;
  always @(posedge clk or posedge arst) begin
    if (arst) q <= 0;
    else      q <= 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets.map((r) => r.name), contains('arst'));
      final r = _reset(k.asyncResets, 'arst');
      expect(r.isActiveHigh, isTrue);
      expect(r.isAsynchronous, isTrue);
    });
  });

  // ── Group 4: sync reset still works alongside always_ff ───────────────────
  group('sync reset detection unaffected by always_ff changes', () {
    test('if(!rst) in always_ff with only posedge → sync active-low', () async {
      const rtl = r'''
module sync_rst(input logic clk, input logic rst);
  reg q;
  always_ff @(posedge clk) begin
    if (!rst) q <= 1'b0;
    else      q <= 1'b1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      // No negedge in sensitivity list → sync reset only
      expect(k.syncResets.map((r) => r.name), contains('rst'));
      expect(k.asyncResets.map((r) => r.name), isNot(contains('rst')));
      final r = _reset(k.syncResets, 'rst');
      expect(r.isSynchronous, isTrue);
      expect(r.isActiveLow, isTrue);
    });

    test('module with no reset: hasReset=false', () async {
      const rtl = r'''
module no_rst(input logic clk);
  reg [7:0] cnt;
  always_ff @(posedge clk) cnt <= cnt + 1;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.hasReset, isFalse);
    });

    test('always_ff with two separate resets in separate blocks', () async {
      const rtl = r'''
module dual_rst(input logic clk, input logic rst_n, input logic srst);
  reg a;
  reg b;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) a <= 0;
    else        a <= 1;
  end
  always_ff @(posedge clk) begin
    if (!srst) b <= 0;
    else       b <= 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets.map((r) => r.name), contains('rst_n'));
      expect(k.syncResets.map((r) => r.name), contains('srst'));
    });
  });

  // ── Group 5: no false positives ───────────────────────────────────────────
  group('no false positives from always_ff async detection', () {
    test('module with no reset at all: asyncResets and syncResets empty', () async {
      const rtl = r'''
module pure_comb(input logic a, input logic b, output logic y);
  assign y = a & b;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets, isEmpty);
      expect(k.syncResets, isEmpty);
      expect(k.hasReset, isFalse);
    });

    test('always_ff with single posedge only does not produce async reset', () async {
      const rtl = r'''
module no_async(input logic clk);
  reg q;
  always_ff @(posedge clk) q <= 1'b0;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.asyncResets, isEmpty);
    });
  });
}
