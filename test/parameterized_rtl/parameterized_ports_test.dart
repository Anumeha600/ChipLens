// Priority 2 — parameterized port/wire/logic width detection.
//
// When an assign-target signal is declared with a symbolic width bracket
// (e.g. output [B:0] o_rd), the provider cannot evaluate the width statically.
// widthIsKnown should be false for such signals; numeric-bracket declarations
// must continue to infer widths correctly.
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/providers/register_provider.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_context.dart';
import 'package:chiplens_lite/backend/design_intelligence/knowledge_models.dart';

DesignContext _ctx(String src) => DesignContext(rtlSource: src);

Future<List<RegisterInfo>> _regs(String src) async {
  final result = await const RegisterProvider().analyze(_ctx(src));
  return result.registers;
}

void main() {
  // ── output wire [B:0] — symbolic output port ──────────────────────────────

  group('output wire [B:0] — symbolic output', () {
    const src = '''
module m #(parameter B = 0) (
  input  wire       clk,
  output wire [B:0] o_rd
);
  assign o_rd = 1;
endmodule''';

    test('o_rd detected as combinational', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'o_rd'), isTrue);
      expect(regs.firstWhere((r) => r.name == 'o_rd').isCombinational, isTrue);
    });

    test('o_rd.widthIsKnown is false', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'o_rd').widthIsKnown, isFalse);
    });

    test('o_rd.width defaults to 1', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'o_rd').width, 1);
    });
  });

  // ── wire [WIDTH-1:0] — symbolic internal wire ─────────────────────────────

  group('wire [WIDTH-1:0] followed by assign', () {
    const src = '''
module m #(parameter WIDTH = 8) (input wire clk);
  wire [WIDTH-1:0] result;
  assign result = 0;
endmodule''';

    test('result detected as combinational', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'result'), isTrue);
    });

    test('result.widthIsKnown is false', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'result').widthIsKnown, isFalse);
    });

    test('result.width defaults to 1', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'result').width, 1);
    });
  });

  // ── logic [DataWidth-1:0] — symbolic logic declaration ───────────────────

  group('logic [DataWidth-1:0] assign target', () {
    const src = '''
module m #(parameter DataWidth = 32) (input wire clk);
  logic [DataWidth-1:0] bus;
  assign bus = 0;
endmodule''';

    test('bus detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'bus'), isTrue);
    });

    test('bus.widthIsKnown is false', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'bus').widthIsKnown, isFalse);
    });
  });

  // ── numeric output [31:0] — regression guard ──────────────────────────────

  group('Numeric output [31:0] — regression guard', () {
    const src = '''
module m (
  input  wire        clk,
  input  wire [31:0] d,
  output wire [31:0] q
);
  assign q = d;
endmodule''';

    test('q detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'q'), isTrue);
    });

    test('q.width == 32', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'q').width, 32);
    });

    test('q.widthIsKnown is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'q').widthIsKnown, isTrue);
    });
  });

  // ── 1-bit output (no bracket) — regression guard ─────────────────────────

  group('1-bit output no bracket — regression guard', () {
    const src = '''
module m (input wire clk, output wire flag);
  assign flag = 1;
endmodule''';

    test('flag detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'flag'), isTrue);
    });

    test('flag.width == 1', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'flag').width, 1);
    });

    test('flag.widthIsKnown is true (no bracket → 1-bit is known)', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'flag').widthIsKnown, isTrue);
    });
  });

  // ── mixed numeric + symbolic in same module ────────────────────────────────

  group('Mixed numeric and symbolic outputs', () {
    const src = '''
module m #(parameter B = 0) (
  input  wire       clk,
  output wire [7:0] fixed_out,
  output wire [B:0] param_out
);
  assign fixed_out = 8'hFF;
  assign param_out = 1'b1;
endmodule''';

    test('fixed_out.width == 8, widthIsKnown=true', () async {
      final regs = await _regs(src);
      final r = regs.firstWhere((r) => r.name == 'fixed_out');
      expect(r.width, 8);
      expect(r.widthIsKnown, isTrue);
    });

    test('param_out.width == 1, widthIsKnown=false', () async {
      final regs = await _regs(src);
      final r = regs.firstWhere((r) => r.name == 'param_out');
      expect(r.width, 1);
      expect(r.widthIsKnown, isFalse);
    });

    test('both signals are detected', () async {
      final regs = await _regs(src);
      expect(regs.where((r) => r.isCombinational).length, 2);
    });
  });

  // ── input [B:0] does not generate a false-positive register ───────────────

  test('input [B:0] with no assign → no register emitted', () async {
    const src = '''
module m #(parameter B = 0) (
  input wire [B:0] data,
  input wire       clk
);
  reg [7:0] cnt;
  always @(posedge clk) cnt <= cnt + 1;
endmodule''';
    final regs = await _regs(src);
    expect(regs.any((r) => r.name == 'data'), isFalse);
    expect(regs.any((r) => r.name == 'cnt'),  isTrue);
  });

  // ── inout [B:0] — bidirectional symbolic port ─────────────────────────────

  test('inout [B:0] assign target gets widthIsKnown=false', () async {
    const src = '''
module m #(parameter B = 0) (inout wire [B:0] bidir);
  assign bidir = 0;
endmodule''';
    final regs = await _regs(src);
    expect(regs.any((r) => r.name == 'bidir'), isTrue);
    expect(regs.firstWhere((r) => r.name == 'bidir').widthIsKnown, isFalse);
  });
}
