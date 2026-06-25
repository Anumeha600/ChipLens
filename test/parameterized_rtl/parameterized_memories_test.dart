// Priority 3 — parameterized memory array depth detection.
//
// Registers of the form `reg [W:0] mem [DEPTH-1:0]` must be detected as
// memory arrays even when the depth dimension is a symbolic expression.
// Existing numeric-depth arrays must continue to work unchanged.
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
  // ── numeric element width, symbolic depth ─────────────────────────────────

  group('reg [31:0] mem [DEPTH-1:0] — numeric width, symbolic depth', () {
    const src = '''
module m #(parameter DEPTH = 32) (input clk);
  reg [31:0] mem [DEPTH-1:0];
  always @(posedge clk) mem[0] <= 0;
endmodule''';

    test('mem is detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'mem'), isTrue);
    });

    test('mem.isMemoryArray is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').isMemoryArray, isTrue);
    });

    test('mem.depthIsKnown is false', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').depthIsKnown, isFalse);
    });

    test('mem.depth == 0 when unknown', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').depth, 0);
    });

    test('mem.width == 32 (numeric element width still resolved)', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').width, 32);
    });

    test('mem.widthIsKnown is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').widthIsKnown, isTrue);
    });
  });

  // ── symbolic element width, numeric depth ─────────────────────────────────

  group('reg [WIDTH-1:0] mem [0:31] — symbolic width, numeric depth', () {
    const src = '''
module m #(parameter WIDTH = 8) (input clk);
  reg [WIDTH-1:0] mem [0:31];
  always @(posedge clk) mem[0] <= 0;
endmodule''';

    test('mem is detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'mem'), isTrue);
    });

    test('mem.isMemoryArray is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').isMemoryArray, isTrue);
    });

    test('mem.depthIsKnown is true (numeric depth)', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').depthIsKnown, isTrue);
    });

    test('mem.depth == 32', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').depth, 32);
    });

    test('mem.widthIsKnown is false (symbolic element width)', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').widthIsKnown, isFalse);
    });
  });

  // ── fully symbolic: both width and depth symbolic ─────────────────────────

  group('reg [WIDTH-1:0] mem [DEPTH-1:0] — both symbolic', () {
    const src = '''
module m #(parameter WIDTH = 8, parameter DEPTH = 16) (input clk);
  reg [WIDTH-1:0] mem [DEPTH-1:0];
  always @(posedge clk) mem[0] <= 0;
endmodule''';

    test('mem is detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'mem'), isTrue);
    });

    test('mem.isMemoryArray is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').isMemoryArray, isTrue);
    });

    test('mem.widthIsKnown is false', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').widthIsKnown, isFalse);
    });

    test('mem.depthIsKnown is false', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').depthIsKnown, isFalse);
    });

    test('mem.depth == 0 (unknown)', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'mem').depth, 0);
    });
  });

  // ── numeric width + numeric depth — regression guard ─────────────────────

  group('reg [31:0] regs [0:31] — numeric both (regression guard)', () {
    const src = '''
module m (input clk, input [4:0] waddr, input [31:0] wdata, input wen);
  reg [31:0] regs [0:31];
  always @(posedge clk) if (wen) regs[waddr] <= wdata;
endmodule''';

    test('regs is detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'regs'), isTrue);
    });

    test('regs.isMemoryArray is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'regs').isMemoryArray, isTrue);
    });

    test('regs.depth == 32', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'regs').depth, 32);
    });

    test('regs.width == 32', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'regs').width, 32);
    });

    test('regs.widthIsKnown is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'regs').widthIsKnown, isTrue);
    });

    test('regs.depthIsKnown is true', () async {
      final regs = await _regs(src);
      expect(regs.firstWhere((r) => r.name == 'regs').depthIsKnown, isTrue);
    });
  });

  // ── toString format for symbolic arrays ───────────────────────────────────

  test('toString shows ?× for unknown depth', () async {
    const src = '''
module m #(parameter DEPTH = 8) (input clk);
  reg [7:0] cache [DEPTH-1:0];
  always @(posedge clk) cache[0] <= 0;
endmodule''';
    final regs = await _regs(src);
    final r = regs.firstWhere((r) => r.name == 'cache');
    expect(r.toString(), contains('?×'));
  });

  test('toString shows ?b for unknown element width', () async {
    const src = '''
module m #(parameter W = 8) (input clk);
  reg [W-1:0] lut [0:15];
  always @(posedge clk) lut[0] <= 0;
endmodule''';
    final regs = await _regs(src);
    final r = regs.firstWhere((r) => r.name == 'lut');
    expect(r.toString(), contains('?b'));
    expect(r.toString(), contains('16'));
  });
}
