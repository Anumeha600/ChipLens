// Tests for always_ff sequential block recognition in RegisterProvider.
//
// always_ff is the SystemVerilog keyword for clocked sequential logic.
// Without support, reg declarations inside always_ff modules would be
// misclassified as combinational (hasSeqBlock=false).
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

RegisterInfo _reg(List<RegisterInfo> regs, String name) =>
    regs.firstWhere((r) => r.name == name);

void main() {
  // ── Group 1: always_ff blocks set hasSeqBlock ─────────────────────────────
  group('always_ff sets sequential context', () {
    test('reg in always_ff block is classified sequential', () async {
      const rtl = r'''
module counter(input logic clk, output logic [7:0] q);
  reg [7:0] state;
  always_ff @(posedge clk) begin
    state <= state + 1;
  end
  assign q = state;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final state = _reg(k.registers, 'state');
      expect(state.isSequential, isTrue,
          reason: 'reg inside always_ff block should be sequential');
      expect(state.isCombinational, isFalse);
    });

    test('reg that is also assign target is combinational despite always_ff', () async {
      const rtl = r'''
module m(input logic clk);
  reg flag;
  always_ff @(posedge clk) begin
    flag <= 1'b0;
  end
  assign flag = 1'b1;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final flag = _reg(k.registers, 'flag');
      // assign target overrides sequential classification
      expect(flag.isCombinational, isTrue);
      expect(flag.isSequential, isFalse);
    });

    test('always_ff with async negedge reset: reg is sequential', () async {
      const rtl = r'''
module ff_with_rst(input logic clk, input logic rst_n);
  reg [3:0] cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cnt <= 4'h0;
    else        cnt <= cnt + 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final cnt = _reg(k.registers, 'cnt');
      expect(cnt.isSequential, isTrue);
      expect(cnt.isCombinational, isFalse);
    });

    test('1-bit scalar reg in always_ff is sequential', () async {
      const rtl = r'''
module latch_free(input logic clk, input logic d);
  reg q;
  always_ff @(posedge clk) q <= d;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final q = _reg(k.registers, 'q');
      expect(q.isSequential, isTrue);
      expect(q.width, equals(1));
    });

    test('symbolic-width reg in always_ff is sequential with widthIsKnown=false', () async {
      const rtl = r'''
module sv_param #(parameter W = 8) (input logic clk);
  reg [W-1:0] data_r;
  always_ff @(posedge clk) data_r <= '0;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final d = _reg(k.registers, 'data_r');
      expect(d.isSequential, isTrue);
      expect(d.widthIsKnown, isFalse);
    });
  });

  // ── Group 2: always @(posedge) regression guard ───────────────────────────
  group('always @(posedge) regression — Verilog blocks still work', () {
    test('reg in always @(posedge clk) block is sequential', () async {
      const rtl = r'''
module classic(input clk);
  reg [7:0] cnt;
  always @(posedge clk) cnt <= cnt + 1;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final cnt = _reg(k.registers, 'cnt');
      expect(cnt.isSequential, isTrue);
    });

    test('always @(posedge clk or negedge rst_n) with reg is sequential', () async {
      const rtl = r'''
module rst_flop(input clk, input rst_n);
  reg flag;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) flag <= 0;
    else        flag <= 1;
  end
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final flag = _reg(k.registers, 'flag');
      expect(flag.isSequential, isTrue);
    });
  });

  // ── Group 3: mixed always and always_ff ───────────────────────────────────
  group('mixed always and always_ff in same module', () {
    test('both kinds of blocks set hasSeqBlock; regs are sequential', () async {
      const rtl = r'''
module mixed(input logic clk);
  reg [3:0] verilog_reg;
  reg [3:0] sv_reg;
  always @(posedge clk)    verilog_reg <= 4'h0;
  always_ff @(posedge clk) sv_reg      <= 4'hF;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.registers.where((r) => r.isSequential).length, equals(2));
    });

    test('assign target overrides sequential even with both always types', () async {
      const rtl = r'''
module mixed2(input logic clk);
  reg sel;
  always @(posedge clk)    sel <= 0;
  always_ff @(posedge clk) sel <= 1;
  assign sel = 1'b0;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sel = _reg(k.registers, 'sel');
      expect(sel.isCombinational, isTrue);
    });
  });

  // ── Group 4: no false positives ───────────────────────────────────────────
  group('no false positives from always_ff', () {
    test('always_ff keyword alone without posedge does not set hasSeqBlock', () async {
      // always_ff without @(posedge ...) is malformed but should not crash
      const rtl = r'''
module m;
  reg data;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      // With no always blocks at all, data should be combinational
      final data = _reg(k.registers, 'data');
      expect(data.isSequential, isFalse);
    });

    test('always_comb block does not set sequential context for reg', () async {
      const rtl = r'''
module comb_mod(input logic a, input logic b, output logic y);
  reg result;
  always_comb result = a & b;
  assign y = result;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final result = _reg(k.registers, 'result');
      // always_comb has no @(posedge) — hasSeqBlock=false
      // result is NOT an assign target (assign y = result; targets y, not result)
      expect(result.isSequential, isFalse);
    });

    test('module without any always block: assign-target reg is combinational', () async {
      const rtl = r'''
module pure_assign(input logic [7:0] a, output logic [7:0] y);
  reg [7:0] buf_r;
  assign buf_r = a;
  assign y = buf_r;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final buf = _reg(k.registers, 'buf_r');
      // No posedge block anywhere — hasSeqBlock=false
      // buf_r is an assign target — combinational
      expect(buf.isSequential, isFalse);
      expect(buf.isCombinational, isTrue);
    });
  });
}
