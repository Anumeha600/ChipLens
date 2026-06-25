// Tests for SystemVerilog 'output logic [W:0]' width detection in RegisterProvider.
//
// Before this fix, 'output logic [W:0] sig' was mishandled: the 'logic' keyword
// was consumed as the signal name by the 'output' match in _widthDeclRe, so
// [W:0] and the real signal name 'sig' were never seen as a width declaration.
//
// Fix: add 'logic' to the optional type-qualifier group:
//   (?:(?:logic|wire|reg)\s+)?
// so that 'output logic [W:0] sig' is parsed the same way as 'output wire [W:0] sig'.
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

RegisterInfo _reg(List<RegisterInfo> regs, String name) =>
    regs.firstWhere((r) => r.name == name);

void main() {
  // ── Group 1: output logic with numeric width ──────────────────────────────
  group('output logic [N:0] — numeric width detection', () {
    test('output logic [31:0] produces width=32 for assign target', () async {
      const rtl = r'''
module m(output logic [31:0] q);
  assign q = 32'hDEAD;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'q');
      expect(sig.width, equals(32));
      expect(sig.widthIsKnown, isTrue);
    });

    test('output logic [7:0] produces width=8', () async {
      const rtl = r'''
module m(output logic [7:0] byte_out);
  assign byte_out = 8'hFF;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'byte_out');
      expect(sig.width, equals(8));
      expect(sig.widthIsKnown, isTrue);
    });

    test('input logic [15:0] width stored for downstream inference', () async {
      const rtl = r'''
module m(input logic [15:0] addr, output logic result);
  assign result = addr[0];
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      // result is combinational, addr is an input (not assign target)
      final result = _reg(k.registers, 'result');
      expect(result.isCombinational, isTrue);
      // addr not in registers (not an assign target)
      expect(k.registers.any((r) => r.name == 'addr'), isFalse);
    });
  });

  // ── Group 2: output logic with symbolic (parametric) width ────────────────
  group('output logic [W:0] — symbolic width detection', () {
    test('output logic [DataWidth-1:0] assign target: widthIsKnown=false', () async {
      const rtl = r'''
module m #(parameter int DataWidth = 32) (
  output logic [DataWidth-1:0] rdata_o
);
  assign rdata_o = {DataWidth{1'b0}};
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'rdata_o');
      expect(sig.widthIsKnown, isFalse,
          reason: 'DataWidth is a parameter — width cannot be determined statically');
      expect(sig.isCombinational, isTrue);
    });

    test('output logic [B:0] assign target: widthIsKnown=false', () async {
      const rtl = r'''
module sv_out #(parameter B = 0) (output logic [B:0] o_rd);
  assign o_rd = 1'b0;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'o_rd');
      expect(sig.widthIsKnown, isFalse);
    });

    test('output logic [W-1:0] two assign targets from same param port', () async {
      const rtl = r'''
module dual #(parameter W = 8) (
  output logic [W-1:0] porta,
  output logic [W-1:0] portb
);
  assign porta = {W{1'b0}};
  assign portb = {W{1'b1}};
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final a = _reg(k.registers, 'porta');
      final b = _reg(k.registers, 'portb');
      expect(a.widthIsKnown, isFalse);
      expect(b.widthIsKnown, isFalse);
    });

    test('ibex-style: two output logic [DataWidth-1:0] ports both widthIsKnown=false',
        () async {
      const rtl = r'''
module ibex_rf_stub #(parameter int unsigned DataWidth = 32) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  output logic [DataWidth-1:0] rdata_a_o,
  output logic [DataWidth-1:0] rdata_b_o
);
  assign rdata_a_o = {DataWidth{1'b0}};
  assign rdata_b_o = {DataWidth{1'b1}};
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final a = _reg(k.registers, 'rdata_a_o');
      final b = _reg(k.registers, 'rdata_b_o');
      expect(a.widthIsKnown, isFalse);
      expect(b.widthIsKnown, isFalse);
    });
  });

  // ── Group 3: output logic scalar (no bracket) ─────────────────────────────
  group('output logic (no bracket) — 1-bit scalar', () {
    test('output logic sig: width=1, widthIsKnown=true', () async {
      const rtl = r'''
module m(output logic valid);
  assign valid = 1'b1;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'valid');
      expect(sig.width, equals(1));
      expect(sig.widthIsKnown, isTrue);
    });

    test('input logic clk_i: not in registers (no assign target)', () async {
      const rtl = r'''
module m(input logic clk_i, output logic q);
  assign q = 1'b0;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      expect(k.registers.any((r) => r.name == 'clk_i'), isFalse);
    });
  });

  // ── Group 4: regression — output wire still works ────────────────────────
  group('output wire regression — existing behavior unchanged', () {
    test('output wire [31:0] produces width=32', () async {
      const rtl = r'''
module m(output wire [31:0] q);
  assign q = 32'h0;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'q');
      expect(sig.width, equals(32));
      expect(sig.widthIsKnown, isTrue);
    });

    test('output wire [B:0] produces widthIsKnown=false', () async {
      const rtl = r'''
module m #(parameter B = 0) (output wire [B:0] o);
  assign o = 1'b0;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'o');
      expect(sig.widthIsKnown, isFalse);
    });

    test('wire [15:0] (no direction) produces width=16', () async {
      const rtl = r'''
module m;
  wire [15:0] bus;
  assign bus = 16'hABCD;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'bus');
      expect(sig.width, equals(16));
      expect(sig.widthIsKnown, isTrue);
    });

    test('logic [7:0] (no direction) produces width=8', () async {
      const rtl = r'''
module m;
  logic [7:0] data;
  assign data = 8'hFF;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      final sig = _reg(k.registers, 'data');
      expect(sig.width, equals(8));
      expect(sig.widthIsKnown, isTrue);
    });
  });

  // ── Group 5: output reg regression ────────────────────────────────────────
  group('output reg regression — Verilog registered outputs unchanged', () {
    test('output reg [7:0] q (assign target): width=8, widthIsKnown=true', () async {
      const rtl = r'''
module m(output reg [7:0] q);
  assign q = 8'hAA;
endmodule
''';
      final k = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
      // 'output reg [7:0] q' — q captured in reg decl and in assign target
      final sig = k.registers.firstWhere((r) => r.name == 'q');
      expect(sig.width, equals(8));
      expect(sig.widthIsKnown, isTrue);
    });
  });
}
