// Priority 4 — concatenation assign LHS awareness.
//
// `assign {a, b} = expr` should detect both `a` and `b` as combinational
// signals.  Simple assigns and reg declarations must not regress.
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
  // ── two-signal concatenation ───────────────────────────────────────────────

  group('assign {carry, result} = expr — two signals', () {
    const src = '''
module m (input [7:0] a, input [7:0] b);
  wire       carry;
  wire [7:0] result;
  assign {carry, result} = a + b;
endmodule''';

    test('carry detected as combinational', () async {
      final regs = await _regs(src);
      final r = regs.firstWhere((r) => r.name == 'carry');
      expect(r.isCombinational, isTrue);
      expect(r.isSequential,    isFalse);
    });

    test('result detected as combinational', () async {
      final regs = await _regs(src);
      final r = regs.firstWhere((r) => r.name == 'result');
      expect(r.isCombinational, isTrue);
      expect(r.isSequential,    isFalse);
    });

    test('exactly two registers emitted', () async {
      final regs = await _regs(src);
      expect(regs.length, 2);
    });
  });

  // ── three-signal concatenation ────────────────────────────────────────────

  group('assign {a, b, c} = expr — three signals', () {
    const src = '''
module m (input [9:0] data);
  wire a, b, c;
  assign {a, b, c} = data[9:7];
endmodule''';

    test('a detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'a'), isTrue);
    });

    test('b detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'b'), isTrue);
    });

    test('c detected', () async {
      final regs = await _regs(src);
      expect(regs.any((r) => r.name == 'c'), isTrue);
    });

    test('all three are combinational', () async {
      final regs = await _regs(src);
      expect(regs.every((r) => r.isCombinational), isTrue);
    });
  });

  // ── SERV-style: no spaces in concat ──────────────────────────────────────

  test('assign {add_cy,result_add} with no spaces — both captured', () async {
    const src = '''
module m (input clk, input [7:0] a, input [7:0] b);
  wire       add_cy;
  wire [7:0] result_add;
  reg  [7:0] carry_r;
  assign {add_cy,result_add} = a + b + carry_r;
  always @(posedge clk) carry_r <= add_cy;
endmodule''';
    final regs = await _regs(src);
    expect(regs.any((r) => r.name == 'add_cy'),    isTrue);
    expect(regs.any((r) => r.name == 'result_add'), isTrue);
    expect(regs.firstWhere((r) => r.name == 'add_cy').isCombinational,    isTrue);
    expect(regs.firstWhere((r) => r.name == 'result_add').isCombinational, isTrue);
  });

  // ── concat with leading/trailing spaces ───────────────────────────────────

  test('assign { a , b } with extra whitespace — both captured', () async {
    const src = '''
module m (input [7:0] x);
  wire a, b;
  assign { a , b } = x[7:6];
endmodule''';
    final regs = await _regs(src);
    expect(regs.any((r) => r.name == 'a'), isTrue);
    expect(regs.any((r) => r.name == 'b'), isTrue);
  });

  // ── bit-select on LHS element ─────────────────────────────────────────────

  test('assign {carry[3:0], result} — identifiers extracted, numbers ignored', () async {
    const src = '''
module m (input [7:0] x);
  wire [3:0] carry;
  wire [3:0] result;
  assign {carry[3:0], result} = x;
endmodule''';
    final regs = await _regs(src);
    expect(regs.any((r) => r.name == 'carry'),  isTrue);
    expect(regs.any((r) => r.name == 'result'), isTrue);
    expect(regs.any((r) => r.name == '3'),      isFalse);
    expect(regs.any((r) => r.name == '0'),      isFalse);
  });

  // ── simple assign still works alongside concat ────────────────────────────

  test('simple assign and concat assign in same module — all captured', () async {
    const src = '''
module m (input clk, input [7:0] a, input [7:0] b);
  wire       cout;
  wire [7:0] sum;
  wire [7:0] diff;
  assign {cout, sum} = a + b;
  assign diff        = a - b;
endmodule''';
    final regs = await _regs(src);
    expect(regs.any((r) => r.name == 'cout'), isTrue);
    expect(regs.any((r) => r.name == 'sum'),  isTrue);
    expect(regs.any((r) => r.name == 'diff'), isTrue);
    expect(regs.length, 3);
  });

  // ── reg declared AND in concat → isCombinational=true ────────────────────

  test('reg declared as reg but used in concat assign → combinational', () async {
    const src = '''
module m (input clk, input [7:0] a);
  reg [7:0] q;
  wire      cy;
  assign {cy, q} = a + 1;
  always @(posedge clk) q <= q;
endmodule''';
    final regs = await _regs(src);
    final q = regs.firstWhere((r) => r.name == 'q');
    expect(q.isCombinational, isTrue);
  });

  // ── RHS replication {N{expr}} must NOT be matched on LHS ─────────────────

  test('RHS replication {W{bit}} not mistaken for LHS concat', () async {
    const src = '''
module m (input [7:0] a);
  wire [7:0] out;
  assign out = {8{a[0]}};
endmodule''';
    final regs = await _regs(src);
    expect(regs.any((r) => r.name == 'out'), isTrue);
    expect(regs.any((r) => r.name == 'a'),   isFalse);
    expect(regs.length, 1);
  });

  // ── no spurious match when LHS is a plain identifier ─────────────────────

  test('assign o_cmp = expr — no concat false-match', () async {
    const src = '''
module m (output wire o_cmp);
  assign o_cmp = 1;
endmodule''';
    final regs = await _regs(src);
    expect(regs.length, 1);
    expect(regs.first.name, 'o_cmp');
  });

  // ── concat target width: symbolic wire → widthIsKnown=false ──────────────

  test('concat target declared wire [B:0] → widthIsKnown=false', () async {
    const src = '''
module m #(parameter B = 0) (input clk);
  wire [B:0] cy;
  wire [B:0] res;
  reg  [B:0] acc;
  assign {cy, res} = acc;
  always @(posedge clk) acc <= 0;
endmodule''';
    final regs = await _regs(src);
    expect(regs.firstWhere((r) => r.name == 'cy').widthIsKnown,  isFalse);
    expect(regs.firstWhere((r) => r.name == 'res').widthIsKnown, isFalse);
  });

  // ── concat target width: numeric wire → correct width ────────────────────

  test('concat target declared wire [7:0] → width=8, widthIsKnown=true', () async {
    const src = '''
module m (input [8:0] x);
  wire [7:0] lo;
  wire       hi;
  assign {hi, lo} = x;
endmodule''';
    final regs = await _regs(src);
    expect(regs.firstWhere((r) => r.name == 'lo').width, 8);
    expect(regs.firstWhere((r) => r.name == 'lo').widthIsKnown, isTrue);
    expect(regs.firstWhere((r) => r.name == 'hi').width, 1);
    expect(regs.firstWhere((r) => r.name == 'hi').widthIsKnown, isTrue);
  });

  // ── multiple concat assigns in one module ─────────────────────────────────

  test('two separate concat assigns — all four signals captured', () async {
    const src = '''
module m (input [15:0] a, input [15:0] b);
  wire cy1, cy2;
  wire [15:0] r1, r2;
  assign {cy1, r1} = a + b;
  assign {cy2, r2} = a - b;
endmodule''';
    final regs = await _regs(src);
    expect(regs.where((r) => r.isCombinational).length, 4);
    expect(regs.any((r) => r.name == 'cy1'), isTrue);
    expect(regs.any((r) => r.name == 'cy2'), isTrue);
    expect(regs.any((r) => r.name == 'r1'),  isTrue);
    expect(regs.any((r) => r.name == 'r2'),  isTrue);
  });
}
