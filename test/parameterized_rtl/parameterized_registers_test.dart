// Priority 1 — parameterized register width detection.
//
// Verifies that reg declarations with symbolic (parameter-expression) widths
// are detected rather than silently dropped.  The detected width is reported
// as 1 (unknown) and widthIsKnown is false.  Numeric-width and scalar regs
// must continue to work exactly as before.
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/providers/register_provider.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_context.dart';
import 'package:chiplens_lite/backend/design_intelligence/knowledge_models.dart';

DesignContext _ctx(String rtl) => DesignContext(rtlSource: rtl);

Future<List<RegisterInfo>> _regs(String rtl) async {
  final result = await const RegisterProvider().analyze(_ctx(rtl));
  return result.registers;
}

void main() {
  // ── single-char parameter [B:0] ───────────────────────────────────────────

  group('Single-char parameter [B:0]', () {
    const seqRtl = '''
module m #(parameter B = 0) (input clk);
  reg [B:0] carry;
  always @(posedge clk) carry <= 0;
endmodule''';

    test('carry is detected', () async {
      final regs = await _regs(seqRtl);
      expect(regs.any((r) => r.name == 'carry'), isTrue);
    });

    test('carry.isSequential is true (posedge block present)', () async {
      final regs = await _regs(seqRtl);
      expect(regs.firstWhere((r) => r.name == 'carry').isSequential, isTrue);
    });

    test('carry.width defaults to 1 (unknown)', () async {
      final regs = await _regs(seqRtl);
      expect(regs.firstWhere((r) => r.name == 'carry').width, 1);
    });

    test('carry.widthIsKnown is false', () async {
      final regs = await _regs(seqRtl);
      expect(regs.firstWhere((r) => r.name == 'carry').widthIsKnown, isFalse);
    });

    test('carry.isMemoryArray is false', () async {
      final regs = await _regs(seqRtl);
      expect(regs.firstWhere((r) => r.name == 'carry').isMemoryArray, isFalse);
    });
  });

  // ── WIDTH-1:0 arithmetic expression ───────────────────────────────────────

  group('Arithmetic expression [WIDTH-1:0]', () {
    const rtl = '''
module m #(parameter WIDTH = 8) (input clk);
  reg [WIDTH-1:0] data;
  always @(posedge clk) data <= 0;
endmodule''';

    test('data is detected', () async {
      final regs = await _regs(rtl);
      expect(regs.any((r) => r.name == 'data'), isTrue);
    });

    test('data.widthIsKnown is false', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'data').widthIsKnown, isFalse);
    });

    test('data.width defaults to 1', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'data').width, 1);
    });
  });

  // ── multi-word parameter ADDR_W-1:0 ──────────────────────────────────────

  group('Multi-word parameter [ADDR_W-1:0]', () {
    const rtl = '''
module m #(parameter ADDR_W = 16) (input clk);
  reg [ADDR_W-1:0] addr;
  always @(posedge clk) addr <= 0;
endmodule''';

    test('addr is detected', () async {
      final regs = await _regs(rtl);
      expect(regs.any((r) => r.name == 'addr'), isTrue);
    });

    test('addr.widthIsKnown is false', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'addr').widthIsKnown, isFalse);
    });
  });

  // ── CamelCase parameter DataWidth-1:0 ────────────────────────────────────

  group('CamelCase parameter [DataWidth-1:0]', () {
    const rtl = '''
module m #(parameter DataWidth = 32) (input clk);
  reg [DataWidth-1:0] payload;
  always @(posedge clk) payload <= 0;
endmodule''';

    test('payload is detected', () async {
      final regs = await _regs(rtl);
      expect(regs.any((r) => r.name == 'payload'), isTrue);
    });

    test('payload.widthIsKnown is false', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'payload').widthIsKnown, isFalse);
    });
  });

  // ── numeric width still works (no regression) ────────────────────────────

  group('Numeric width [7:0] — regression guard', () {
    const rtl = '''
module m (input clk);
  reg [7:0] cnt;
  always @(posedge clk) cnt <= cnt + 1;
endmodule''';

    test('cnt is detected', () async {
      final regs = await _regs(rtl);
      expect(regs.any((r) => r.name == 'cnt'), isTrue);
    });

    test('cnt.width == 8', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'cnt').width, 8);
    });

    test('cnt.widthIsKnown is true', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'cnt').widthIsKnown, isTrue);
    });
  });

  // ── scalar (no bracket) still works ──────────────────────────────────────

  group('Scalar reg (no bracket) — regression guard', () {
    const rtl = '''
module m (input clk);
  reg flag;
  always @(posedge clk) flag <= ~flag;
endmodule''';

    test('flag is detected', () async {
      final regs = await _regs(rtl);
      expect(regs.any((r) => r.name == 'flag'), isTrue);
    });

    test('flag.width == 1', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'flag').width, 1);
    });

    test('flag.widthIsKnown is true (1-bit scalar — width IS known)', () async {
      final regs = await _regs(rtl);
      expect(regs.firstWhere((r) => r.name == 'flag').widthIsKnown, isTrue);
    });
  });

  // ── mixed: numeric + symbolic in same module ──────────────────────────────

  group('Mixed numeric and symbolic widths in same module', () {
    const rtl = '''
module m #(parameter W = 8) (input clk);
  reg [7:0]   fixed;
  reg [W-1:0] dynamic;
  reg         scalar;
  always @(posedge clk) begin
    fixed   <= 0;
    dynamic <= 0;
    scalar  <= 0;
  end
endmodule''';

    test('all three registers are detected', () async {
      final regs = await _regs(rtl);
      expect(regs.any((r) => r.name == 'fixed'),   isTrue);
      expect(regs.any((r) => r.name == 'dynamic'), isTrue);
      expect(regs.any((r) => r.name == 'scalar'),  isTrue);
    });

    test('fixed: widthIsKnown=true, width=8', () async {
      final regs = await _regs(rtl);
      final r = regs.firstWhere((r) => r.name == 'fixed');
      expect(r.widthIsKnown, isTrue);
      expect(r.width, 8);
    });

    test('dynamic: widthIsKnown=false, width=1', () async {
      final regs = await _regs(rtl);
      final r = regs.firstWhere((r) => r.name == 'dynamic');
      expect(r.widthIsKnown, isFalse);
      expect(r.width, 1);
    });

    test('scalar: widthIsKnown=true, width=1', () async {
      final regs = await _regs(rtl);
      final r = regs.firstWhere((r) => r.name == 'scalar');
      expect(r.widthIsKnown, isTrue);
      expect(r.width, 1);
    });
  });

  // ── [W-1:0] with whitespace variants ─────────────────────────────────────

  group('Whitespace between reg keyword and bracket', () {
    test('reg with tab before bracket', () async {
      const rtl = 'module m(input clk); reg\t[B:0] q; always @(posedge clk) q<=0; endmodule';
      final regs = await _regs(rtl);
      final r = regs.firstWhere((r) => r.name == 'q');
      expect(r.widthIsKnown, isFalse);
    });

    test('reg with multiple spaces before bracket', () async {
      const rtl = 'module m(input clk); reg   [WIDTH-1:0] q; always @(posedge clk) q<=0; endmodule';
      final regs = await _regs(rtl);
      final r = regs.firstWhere((r) => r.name == 'q');
      expect(r.widthIsKnown, isFalse);
    });
  });

  // ── no false positive when bracket is absent ──────────────────────────────

  test('no register emitted for bare "reg" keyword in a string', () async {
    const rtl = 'module m; endmodule';
    final regs = await _regs(rtl);
    expect(regs, isEmpty);
  });

  test('register count is exactly 1 for single symbolic reg', () async {
    const rtl = '''
module m #(parameter B = 0) (input clk);
  reg [B:0] cy;
  always @(posedge clk) cy <= 0;
endmodule''';
    final regs = await _regs(rtl);
    expect(regs.length, 1);
  });
}
