import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// Regression tests for the \breg(?!\w) keyword boundary fix.
//
// Root cause: the old regex \breg matched 'reg' as a word-boundary prefix
// inside longer identifiers like 'regs', 'register', 'regfile', 'reg_data'.
// The fix adds a negative lookahead (?!\w) so 'reg' only matches when it is
// not followed by any word character ([a-zA-Z0-9_]).
//
// Discovered during Sprint H Task 4 (picorv32_regs evaluation):
//   regs[waddr[4:0]] <= wdata  →  false positive register 's'

DesignContext _ctx(String rtl) => DesignContext(rtlSource: rtl);

Set<String> _names(List<RegisterInfo> rs) => rs.map((r) => r.name).toSet();

void main() {
  const provider = RegisterProvider();

  // ── Group 1: identifiers that MUST NOT produce false positives ────────────

  group('keyword boundary — identifiers starting with reg must not match', () {
    test('regs (memory array access) does not produce register s', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] regs [0:31];
  always @(posedge clk) regs[0] <= 32'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), isNot(contains('s')));
    });

    test('regs used in expression does not produce register s', () async {
      const rtl = '''
module m(input clk, input [4:0] wa, input [31:0] wd);
  reg [31:0] regs [0:31];
  always @(posedge clk) regs[wa] <= wd;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), isNot(contains('s')));
    });

    test('register (identifier) does not produce false positive', () async {
      const rtl = '''
module m(input clk, input [7:0] register);
  always @(posedge clk) begin end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), isNot(contains('ister')));
      expect(_names(r.registers), isNot(contains('r')));
    });

    test('regfile signal does not produce register ile', () async {
      const rtl = '''
module m(input clk, input regfile);
  always @(posedge clk) begin end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), isNot(contains('ile')));
    });

    test('reg_data (underscore suffix) does not match as reg keyword', () async {
      const rtl = '''
module m(input clk, input [7:0] reg_data);
  always @(posedge clk) begin end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), isNot(contains('_data')));
    });

    test('reg_op1 (RISC-V style) does not produce false positive', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] reg_op1;
  always @(posedge clk) reg_op1 <= 32'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      // reg_op1 is a genuine reg declaration — it SHOULD be detected
      expect(_names(r.registers), contains('reg_op1'));
      // but should not produce '_op1' as a separate entry
      expect(_names(r.registers), isNot(contains('_op1')));
    });

    test('reg_pc (RISC-V style) declared as reg is detected, no suffix FP', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] reg_pc;
  always @(posedge clk) reg_pc <= 32'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), contains('reg_pc'));
      expect(_names(r.registers), isNot(contains('_pc')));
    });

    test('regfile_we in expression does not produce register ile_we', () async {
      const rtl = '''
module m(input clk, input regfile_we);
  always @(posedge clk) begin end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), isNot(contains('ile_we')));
    });

    test('registered (keyword in comment, already stripped) produces no FP', () async {
      // Comment stripping removes the word before providers run.
      // This is a belt-and-suspenders check.
      const rtl = '''
module m(input clk, output reg q);
  // This output is registered
  always @(posedge clk) q <= ~q;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), isNot(contains('istered')));
    });

    test('module name starting with reg does not produce false positive', () async {
      const rtl = '''
module reg_test(input clk, input [7:0] d, output reg [7:0] q);
  always @(posedge clk) q <= d;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      // 'q' must be detected
      expect(_names(r.registers), contains('q'));
      // module name 'reg_test' must not produce '_test'
      expect(_names(r.registers), isNot(contains('_test')));
    });

    test('multiple regs-style identifiers in one RTL produce no FPs', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] regs [0:31];
  reg [7:0]  reg_buf;
  always @(posedge clk) begin
    regs[0]   <= 32'h0;
    reg_buf   <= 8'h0;
  end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      // Real registers
      expect(_names(r.registers), contains('regs'));
      expect(_names(r.registers), contains('reg_buf'));
      // False positives from old bug
      expect(_names(r.registers), isNot(contains('s')));
      expect(_names(r.registers), isNot(contains('_buf')));
    });
  });

  // ── Group 2: valid 'reg' declarations that MUST still match ──────────────

  group('keyword boundary — valid reg declarations must still be detected', () {
    test('bare reg declaration: reg q', () async {
      const rtl = '''
module m(input clk, output reg q);
  always @(posedge clk) q <= ~q;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), contains('q'));
    });

    test('reg with packed width: reg [7:0] cnt', () async {
      const rtl = '''
module m(input clk, output reg [7:0] cnt);
  always @(posedge clk) cnt <= cnt + 1;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'cnt');
      expect(reg.width, 8);
    });

    test('reg in port declaration: output reg [7:0] q', () async {
      const rtl = '''
module m(input clk, input [7:0] d, output reg [7:0] q);
  always @(posedge clk) q <= d;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), contains('q'));
      final q = r.registers.firstWhere((r) => r.name == 'q');
      expect(q.width, 8);
      expect(q.isSequential, isTrue);
    });

    test('multiple reg declarations all detected', () async {
      const rtl = '''
module m(input clk);
  reg [7:0] a;
  reg [15:0] b;
  reg c;
  always @(posedge clk) begin
    a <= 8'h0; b <= 16'h0; c <= 1'b0;
  end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), containsAll(['a', 'b', 'c']));
      final a = r.registers.firstWhere((r) => r.name == 'a');
      final b = r.registers.firstWhere((r) => r.name == 'b');
      expect(a.width, 8);
      expect(b.width, 16);
    });

    test('reg with depth dimension: reg [31:0] mem [0:15]', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] mem [0:15];
  always @(posedge clk) mem[0] <= 32'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(_names(r.registers), contains('mem'));
    });

    test('only one entry per register name (no duplicates)', () async {
      const rtl = '''
module m(input clk, output reg [7:0] q, output reg [7:0] p);
  always @(posedge clk) begin q <= 8'h0; p <= 8'hFF; end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final names = r.registers.map((r) => r.name).toList();
      expect(names.toSet().length, names.length); // no duplicates
    });

    test('single-bit reg with no width brackets', () async {
      const rtl = '''
module m(input clk, output reg flag);
  always @(posedge clk) flag <= ~flag;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'flag');
      expect(reg.width, 1);
      expect(reg.isSequential, isTrue);
    });
  });

  // ── Group 3: combinational / no-reg cases ─────────────────────────────────

  group('keyword boundary — combinational and no-reg cases', () {
    test('assign target without reg declaration: no false sequential', () async {
      const rtl = 'module m(input a, output b); assign b = ~a; endmodule';
      final r = await provider.analyze(_ctx(rtl));
      expect(r.registers.any((r) => r.isSequential), isFalse);
    });

    test('empty module: no registers', () async {
      const rtl = 'module m; endmodule';
      final r = await provider.analyze(_ctx(rtl));
      expect(r.registers, isEmpty);
    });

    test('module with only ports: no registers', () async {
      const rtl = 'module m(input a, input b, output c); endmodule';
      final r = await provider.analyze(_ctx(rtl));
      expect(r.registers, isEmpty);
    });
  });
}
