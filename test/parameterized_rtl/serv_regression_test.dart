// SERV ALU regression test — validates all four Task-7 priorities on real RTL.
//
// Before Task 7: 3 registers detected (cmp_r, o_cmp, o_rd).
//   FN: add_cy_r (symbolic [B:0] reg silently dropped)
//   FN: add_cy, result_add (concatenation assign LHS not parsed)
//
// After Task 7: 6 registers expected.
//   Priority 1 fix: add_cy_r now detected (symbolic reg width)
//   Priority 2 fix: o_rd.widthIsKnown=false (symbolic output port)
//   Priority 4 fix: add_cy + result_add now detected (concat assign)
//
// serv_alu.v — SERV RISC-V (github.com/olofk/serv)
// SPDX-FileCopyrightText: 2018 Olof Kindgren <olof@award-winning.me>
// SPDX-License-Identifier: ISC
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

const _servAluRtl = r'''
`default_nettype none
module serv_alu
  #(
   parameter W = 1,
   parameter B = W-1
  )
  (
   input wire       clk,
   input wire       i_en,
   input wire       i_cnt0,
   output wire      o_cmp,
   input wire       i_sub,
   input wire [1:0] i_bool_op,
   input wire       i_cmp_eq,
   input wire       i_cmp_sig,
   input wire [2:0] i_rd_sel,
   input wire  [B:0] i_rs1,
   input wire  [B:0] i_op_b,
   input wire  [B:0] i_buf,
   output wire [B:0] o_rd);

   wire [B:0] result_add;
   wire [B:0] result_slt;

   reg        cmp_r;

   wire       add_cy;
   reg [B:0]  add_cy_r;

   wire rs1_sx  = i_rs1[B] & i_cmp_sig;
   wire op_b_sx = i_op_b[B] & i_cmp_sig;

   wire [B:0] add_b = i_op_b^{W{i_sub}};

   assign {add_cy,result_add}   = i_rs1+add_b+add_cy_r;

   wire result_lt = rs1_sx + ~op_b_sx + add_cy;
   wire result_eq = !(|result_add) & (cmp_r | i_cnt0);

   assign o_cmp = i_cmp_eq ? result_eq : result_lt;

   wire [B:0] result_bool =
     ((i_rs1 ^ i_op_b) & ~{W{i_bool_op[0]}}) |
     ({W{i_bool_op[1]}} & i_op_b & i_rs1);

   assign result_slt[0] = cmp_r & i_cnt0;

   assign o_rd = i_buf |
                 ({W{i_rd_sel[0]}} & result_add) |
                 ({W{i_rd_sel[1]}} & result_slt) |
                 ({W{i_rd_sel[2]}} & result_bool);

   always @(posedge clk) begin
      add_cy_r    <= {W{1'b0}};
      add_cy_r[0] <= i_en ? add_cy : i_sub;
      if (i_en)
        cmp_r <= o_cmp;
   end

endmodule
''';

DesignContext _ctx(String src) => DesignContext(rtlSource: src);

Future<List<RegisterInfo>> _regs(String src) async {
  final result = await const RegisterProvider().analyze(_ctx(src));
  return result.registers;
}

void main() {
  late List<RegisterInfo> regs;

  setUpAll(() async {
    regs = await _regs(_servAluRtl);
  });

  // ── total register count ──────────────────────────────────────────────────

  test('exactly 6 registers detected (was 3 before Task 7)', () {
    expect(regs.length, 6);
  });

  // ── sequential registers ──────────────────────────────────────────────────

  group('Sequential registers', () {
    test('cmp_r is sequential (bare reg, no bracket)', () {
      final r = regs.firstWhere((r) => r.name == 'cmp_r');
      expect(r.isSequential, isTrue);
    });

    test('cmp_r.widthIsKnown is true (scalar)', () {
      final r = regs.firstWhere((r) => r.name == 'cmp_r');
      expect(r.widthIsKnown, isTrue);
      expect(r.width, 1);
    });

    test('add_cy_r is sequential (Priority 1 fix — was silently dropped)', () {
      final r = regs.firstWhere((r) => r.name == 'add_cy_r');
      expect(r.isSequential, isTrue);
    });

    test('add_cy_r.widthIsKnown is false (symbolic [B:0])', () {
      final r = regs.firstWhere((r) => r.name == 'add_cy_r');
      expect(r.widthIsKnown, isFalse);
      expect(r.width, 1);
    });

    test('add_cy_r.isMemoryArray is false', () {
      expect(regs.firstWhere((r) => r.name == 'add_cy_r').isMemoryArray, isFalse);
    });

    test('exactly 2 sequential registers', () {
      expect(regs.where((r) => r.isSequential).length, 2);
    });
  });

  // ── combinational registers ────────────────────────────────────────────────

  group('Combinational signals', () {
    test('o_cmp is combinational (simple assign)', () {
      final r = regs.firstWhere((r) => r.name == 'o_cmp');
      expect(r.isCombinational, isTrue);
    });

    test('o_cmp.widthIsKnown is true (bare wire, no bracket)', () {
      final r = regs.firstWhere((r) => r.name == 'o_cmp');
      expect(r.widthIsKnown, isTrue);
      expect(r.width, 1);
    });

    test('o_rd is combinational (simple assign)', () {
      final r = regs.firstWhere((r) => r.name == 'o_rd');
      expect(r.isCombinational, isTrue);
    });

    test('o_rd.widthIsKnown is false (Priority 2 fix — symbolic [B:0] port)', () {
      final r = regs.firstWhere((r) => r.name == 'o_rd');
      expect(r.widthIsKnown, isFalse);
    });

    test('add_cy is combinational (Priority 4 fix — concat assign LHS)', () {
      final r = regs.firstWhere((r) => r.name == 'add_cy');
      expect(r.isCombinational, isTrue);
    });

    test('add_cy.widthIsKnown is true (bare wire add_cy)', () {
      final r = regs.firstWhere((r) => r.name == 'add_cy');
      expect(r.widthIsKnown, isTrue);
      expect(r.width, 1);
    });

    test('result_add is combinational (Priority 4 fix — concat assign LHS)', () {
      final r = regs.firstWhere((r) => r.name == 'result_add');
      expect(r.isCombinational, isTrue);
    });

    test('result_add.widthIsKnown is false (declared wire [B:0])', () {
      final r = regs.firstWhere((r) => r.name == 'result_add');
      expect(r.widthIsKnown, isFalse);
    });

    test('exactly 4 combinational signals', () {
      expect(regs.where((r) => r.isCombinational).length, 4);
    });
  });

  // ── false negatives that should remain absent ─────────────────────────────

  group('Intermediate wires remain absent (not misdetected)', () {
    test('result_slt not detected (indexed assign LHS — known limitation)', () {
      expect(regs.any((r) => r.name == 'result_slt'), isFalse);
    });

    test('result_eq not detected (implicit wire assign)', () {
      expect(regs.any((r) => r.name == 'result_eq'), isFalse);
    });

    test('result_lt not detected (implicit wire assign)', () {
      expect(regs.any((r) => r.name == 'result_lt'), isFalse);
    });

    test('result_bool not detected (implicit wire assign)', () {
      expect(regs.any((r) => r.name == 'result_bool'), isFalse);
    });
  });

  // ── no false positives from identifiers ──────────────────────────────────

  group('No false positives from signal or module names', () {
    test('clk is not detected as a register', () {
      expect(regs.any((r) => r.name == 'clk'), isFalse);
    });

    test('serv_alu is not detected as a register', () {
      expect(regs.any((r) => r.name == 'serv_alu'), isFalse);
    });

    test('W is not detected as a register', () {
      expect(regs.any((r) => r.name == 'W'), isFalse);
    });

    test('B is not detected as a register', () {
      expect(regs.any((r) => r.name == 'B'), isFalse);
    });
  });

  // ── full DesignRunner pipeline ─────────────────────────────────────────────

  group('DesignRunner full pipeline', () {
    late DesignKnowledge knowledge;

    setUpAll(() async {
      knowledge = await DesignRunner.analyze(_ctx(_servAluRtl));
    });

    test('hasClock is true', () {
      expect(knowledge.hasClock, isTrue);
    });

    test('hasReset is false (SERV ALU has no reset)', () {
      expect(knowledge.hasReset, isFalse);
    });

    test('hasFSM is false', () {
      expect(knowledge.hasFSM, isFalse);
    });

    test('hasCounter is false', () {
      expect(knowledge.hasCounter, isFalse);
    });

    test('complexity == 6 (6 detected registers)', () {
      final complexity = knowledge.fsms.length +
          knowledge.counters.length +
          knowledge.registers.length;
      expect(complexity, 6);
    });

    test('registers.length == 6', () {
      expect(knowledge.registers.length, 6);
    });

    test('sequential registers == {cmp_r, add_cy_r}', () {
      final seqNames = knowledge.registers
          .where((r) => r.isSequential)
          .map((r) => r.name)
          .toSet();
      expect(seqNames, containsAll(['cmp_r', 'add_cy_r']));
      expect(seqNames.length, 2);
    });
  });
}
