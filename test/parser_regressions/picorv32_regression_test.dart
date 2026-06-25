import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// Regression tests derived from Sprint H Task 4: evaluation of the
// picorv32_regs module (YosysHQ/picorv32, ISC License).
//
// These tests lock in the improved post-Task-5 behaviour for the exact RTL
// that exposed three parser bugs:
//   1. 's' false positive from regs[…] expressions  (keyword boundary)
//   2. Memory array depth not captured               (memory array recognition)
//   3. rdata1/rdata2 width=1 instead of 32           (width inference)
//
// RTL source: picorv32.v, module picorv32_regs
// License: ISC — Copyright (c) 2015-2016 Claire Wolf <claire@clairexen.net>
// Preprocessing: `ifndef PICORV32_REGS / `endif guard removed.

// Exact RTL as evaluated (16 lines, preprocessed):
const _picorv32RegsRtl = '''
module picorv32_regs (
\tinput clk, wen,
\tinput [5:0] waddr,
\tinput [5:0] raddr1,
\tinput [5:0] raddr2,
\tinput [31:0] wdata,
\toutput [31:0] rdata1,
\toutput [31:0] rdata2
);
\treg [31:0] regs [0:31];
\talways @(posedge clk)
\t\tif (wen) regs[waddr[4:0]] <= wdata;
\tassign rdata1 = regs[raddr1[4:0]];
\tassign rdata2 = regs[raddr2[4:0]];
endmodule
''';

// Minimal RTL snippets exercising specific patterns from picorv32:

// Pattern: regs used in multiple expressions on the same line
const _regsMultiExprRtl = '''
module m(input clk, input wen, input [4:0] wa, input [4:0] ra1, input [4:0] ra2,
         input [31:0] wd, output [31:0] rd1, output [31:0] rd2);
  reg [31:0] regs [0:31];
  always @(posedge clk)
    if (wen) regs[wa] <= wd;
  assign rd1 = regs[ra1];
  assign rd2 = regs[ra2];
endmodule
''';

// Pattern: reg_ prefixed signals (common in larger PicoRV32 core)
const _regPrefixedSignalsRtl = '''
module m(input clk);
  reg [31:0] reg_op1;
  reg [31:0] reg_op2;
  reg [31:0] reg_pc;
  reg        reg_wren;
  always @(posedge clk) begin
    reg_op1 <= 32'h0;
    reg_op2 <= 32'h0;
    reg_pc  <= 32'h0;
    reg_wren <= 1'b0;
  end
endmodule
''';

DesignContext _ctx(String rtl) => DesignContext(rtlSource: rtl);
Set<String> _names(List<RegisterInfo> rs) => rs.map((r) => r.name).toSet();

void main() {
  const provider = RegisterProvider();

  // ── Group 1: picorv32_regs — false positive elimination ──────────────────

  group('picorv32_regs — false positive elimination', () {
    test('no register named s in picorv32_regs', () async {
      final r = await provider.analyze(_ctx(_picorv32RegsRtl));
      expect(_names(r.registers), isNot(contains('s')));
    });

    test('register list contains regs, rdata1, rdata2 and nothing else', () async {
      final r = await provider.analyze(_ctx(_picorv32RegsRtl));
      expect(_names(r.registers), equals({'regs', 'rdata1', 'rdata2'}));
    });

    test('registers.length is 3 (was 4 before fix)', () async {
      final r = await provider.analyze(_ctx(_picorv32RegsRtl));
      expect(r.registers.length, 3);
    });
  });

  // ── Group 2: picorv32_regs — memory array detection ──────────────────────

  group('picorv32_regs — memory array detection', () {
    test('regs is detected as a memory array', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.isMemoryArray, isTrue);
    });

    test('regs has depth=32 (entries 0..31)', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.depth, 32);
    });

    test('regs has width=32 (packed [31:0])', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.width, 32);
    });

    test('regs is sequential (posedge write)', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.isSequential, isTrue);
    });
  });

  // ── Group 3: picorv32_regs — width inference ──────────────────────────────

  group('picorv32_regs — width inference', () {
    test('rdata1 has width=32 (inferred from output [31:0])', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'rdata1');
      expect(reg.width, 32);
    });

    test('rdata2 has width=32 (inferred from output [31:0])', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'rdata2');
      expect(reg.width, 32);
    });

    test('rdata1 is combinational (from assign)', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'rdata1');
      expect(reg.isCombinational, isTrue);
      expect(reg.isSequential,    isFalse);
    });

    test('rdata2 is combinational (from assign)', () async {
      final r   = await provider.analyze(_ctx(_picorv32RegsRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'rdata2');
      expect(reg.isCombinational, isTrue);
    });
  });

  // ── Group 4: picorv32_regs — full pipeline via DesignRunner ──────────────

  group('picorv32_regs — full pipeline', () {
    test('hasClock is true', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.hasClock, isTrue);
    });

    test('primaryClocks contains clk', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.primaryClocks.map((c) => c.name), contains('clk'));
    });

    test('hasReset is false (no reset in register file — correct)', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.hasReset, isFalse);
    });

    test('hasFSM is false', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.hasFSM, isFalse);
    });

    test('hasCounter is false', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.hasCounter, isFalse);
    });

    test('hasHandshake is false', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.hasHandshake, isFalse);
    });

    test('registers.length is 3 after all fixes', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.registers.length, 3);
    });

    test('modules contains picorv32_regs', () async {
      final k = await DesignRunner.analyze(_ctx(_picorv32RegsRtl));
      expect(k.modules.map((m) => m.name), contains('picorv32_regs'));
    });
  });

  // ── Group 5: regs in multiple expressions ────────────────────────────────

  group('regs in multiple assign expressions — no duplicates', () {
    test('two assign expressions using regs[] produce no false positive', () async {
      final r = await provider.analyze(_ctx(_regsMultiExprRtl));
      expect(_names(r.registers), isNot(contains('s')));
    });

    test('two assign read ports: rd1 and rd2 both have width=32', () async {
      final r   = await provider.analyze(_ctx(_regsMultiExprRtl));
      final rd1 = r.registers.firstWhere((r) => r.name == 'rd1');
      final rd2 = r.registers.firstWhere((r) => r.name == 'rd2');
      expect(rd1.width, 32);
      expect(rd2.width, 32);
    });

    test('regs appears only once in register list (deduplication)', () async {
      final r     = await provider.analyze(_ctx(_regsMultiExprRtl));
      final regsL = r.registers.where((r) => r.name == 'regs').toList();
      expect(regsL.length, 1);
    });
  });

  // ── Group 6: reg_-prefixed signals (larger PicoRV32 patterns) ────────────

  group('reg_-prefixed signals — no false positives', () {
    test('reg_op1 declared as reg: detected with correct name', () async {
      final r = await provider.analyze(_ctx(_regPrefixedSignalsRtl));
      expect(_names(r.registers), contains('reg_op1'));
      expect(_names(r.registers), isNot(contains('_op1')));
    });

    test('reg_op2: no _op2 false positive', () async {
      final r = await provider.analyze(_ctx(_regPrefixedSignalsRtl));
      expect(_names(r.registers), isNot(contains('_op2')));
    });

    test('reg_pc: no _pc false positive', () async {
      final r = await provider.analyze(_ctx(_regPrefixedSignalsRtl));
      expect(_names(r.registers), isNot(contains('_pc')));
    });

    test('reg_wren: no _wren false positive', () async {
      final r = await provider.analyze(_ctx(_regPrefixedSignalsRtl));
      expect(_names(r.registers), isNot(contains('_wren')));
    });

    test('all four reg_ signals detected correctly', () async {
      final r = await provider.analyze(_ctx(_regPrefixedSignalsRtl));
      expect(_names(r.registers),
          containsAll(['reg_op1', 'reg_op2', 'reg_pc', 'reg_wren']));
      expect(r.registers.length, 4);
    });

    test('all reg_ registers are sequential', () async {
      final r = await provider.analyze(_ctx(_regPrefixedSignalsRtl));
      expect(r.registers.every((r) => r.isSequential), isTrue);
    });
  });
}
