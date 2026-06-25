import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// Regression tests for memory array recognition (RegisterInfo.isMemoryArray
// and RegisterInfo.depth).
//
// Root cause (Sprint H Task 4): reg [31:0] regs [0:31] was treated as a
// scalar register named 'regs' with width=32.  The depth dimension [0:31]
// was silently discarded.
//
// Fix: extended _regDeclRe to capture a second optional [N:M] dimension;
// extended RegisterInfo with isMemoryArray and depth fields.

DesignContext _ctx(String rtl) => DesignContext(rtlSource: rtl);

void main() {
  const provider = RegisterProvider();

  // ── Group 1: basic array detection ───────────────────────────────────────

  group('memory array — basic detection', () {
    test('reg [31:0] regs [0:31] detected as memory array', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] regs [0:31];
  always @(posedge clk) regs[0] <= 32'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.isMemoryArray, isTrue);
    });

    test('memory array depth is correct: [0:31] → 32 entries', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] regs [0:31];
  always @(posedge clk) regs[0] <= 32'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.depth, 32);
    });

    test('memory array packed width is correct: [31:0] → 32 bits', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] regs [0:31];
  always @(posedge clk) regs[0] <= 32'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.width, 32);
    });

    test('[0:15] → depth=16', () async {
      const rtl = '''
module m(input clk);
  reg [7:0] buf [0:15];
  always @(posedge clk) buf[0] <= 8'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'buf');
      expect(reg.isMemoryArray, isTrue);
      expect(reg.depth, 16);
      expect(reg.width, 8);
    });

    test('[0:255] → depth=256', () async {
      const rtl = '''
module m(input clk);
  reg [15:0] ram [0:255];
  always @(posedge clk) ram[0] <= 16'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'ram');
      expect(reg.depth, 256);
      expect(reg.width, 16);
    });

    test('[0:1023] → depth=1024', () async {
      const rtl = '''
module m(input clk);
  reg [7:0] cache [0:1023];
  always @(posedge clk) cache[0] <= 8'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'cache');
      expect(reg.depth, 1024);
    });

    test('[0:0] → depth=1 (single-entry array)', () async {
      const rtl = '''
module m(input clk);
  reg [7:0] singleton [0:0];
  always @(posedge clk) singleton[0] <= 8'h0;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'singleton');
      expect(reg.isMemoryArray, isTrue);
      expect(reg.depth, 1);
    });

    test('picorv32 register file: reg [31:0] regs [0:31]', () async {
      const rtl = '''
module picorv32_regs(input clk, input wen,
  input [4:0] waddr, input [4:0] raddr,
  input [31:0] wdata, output [31:0] rdata);
  reg [31:0] regs [0:31];
  always @(posedge clk)
    if (wen) regs[waddr] <= wdata;
  assign rdata = regs[raddr];
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'regs');
      expect(reg.isMemoryArray, isTrue);
      expect(reg.depth, 32);
      expect(reg.width, 32);
    });
  });

  // ── Group 2: scalar registers must NOT be flagged as arrays ──────────────

  group('memory array — scalar registers remain scalar', () {
    test('reg [7:0] q is NOT a memory array', () async {
      const rtl = '''
module m(input clk, output reg [7:0] q);
  always @(posedge clk) q <= q + 1;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'q');
      expect(reg.isMemoryArray, isFalse);
      expect(reg.depth, 0);
    });

    test('scalar reg: depth is 0', () async {
      const rtl = '''
module m(input clk, output reg flag);
  always @(posedge clk) flag <= ~flag;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'flag');
      expect(reg.depth, 0);
    });

    test('width-only reg is scalar', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] pc;
  always @(posedge clk) pc <= pc + 4;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'pc');
      expect(reg.isMemoryArray, isFalse);
      expect(reg.depth, 0);
      expect(reg.width, 32);
    });
  });

  // ── Group 3: mixed modules with both arrays and scalars ───────────────────

  group('memory array — mixed scalar and array registers', () {
    test('module with both scalar and array registers', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] regs [0:31];
  reg [7:0]  state;
  always @(posedge clk) begin
    regs[0] <= 32'h0;
    state   <= 8'h0;
  end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final arr    = r.registers.firstWhere((r) => r.name == 'regs');
      final scalar = r.registers.firstWhere((r) => r.name == 'state');
      expect(arr.isMemoryArray,    isTrue);
      expect(arr.depth,            32);
      expect(scalar.isMemoryArray, isFalse);
      expect(scalar.depth,         0);
    });

    test('register count includes both scalar and array as separate entries', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] regs [0:31];
  reg [7:0]  ctrl;
  always @(posedge clk) begin
    regs[0] <= 32'h0;
    ctrl    <= 8'h0;
  end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(r.registers.length, 2);
    });

    test('two different arrays in same module', () async {
      const rtl = '''
module m(input clk);
  reg [31:0] iram [0:63];
  reg [31:0] dram [0:63];
  always @(posedge clk) begin
    iram[0] <= 32'h0;
    dram[0] <= 32'h0;
  end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final iram = r.registers.firstWhere((r) => r.name == 'iram');
      final dram = r.registers.firstWhere((r) => r.name == 'dram');
      expect(iram.depth, 64);
      expect(dram.depth, 64);
    });
  });

  // ── Group 4: sequential classification for arrays ─────────────────────────

  group('memory array — sequential classification', () {
    test('array in posedge block is sequential', () async {
      const rtl = '''
module m(input clk, input wen, input [4:0] wa, input [31:0] wd);
  reg [31:0] mem [0:31];
  always @(posedge clk)
    if (wen) mem[wa] <= wd;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'mem');
      expect(reg.isSequential, isTrue);
    });

    test('read via assign is combinational', () async {
      const rtl = '''
module m(input clk, input wen, input [4:0] wa, input [4:0] ra,
         input [31:0] wd, output [31:0] rd);
  reg [31:0] mem [0:31];
  always @(posedge clk)
    if (wen) mem[wa] <= wd;
  assign rd = mem[ra];
endmodule
''';
      // The memory itself (mem) should be sequential.
      // The assign target (rd) should be combinational.
      final r = await provider.analyze(_ctx(rtl));
      final mem = r.registers.firstWhere((r) => r.name == 'mem');
      final rd  = r.registers.firstWhere((r) => r.name == 'rd');
      expect(mem.isSequential,    isTrue);
      expect(rd.isCombinational,  isTrue);
    });
  });

  // ── Group 5: toString includes array info ─────────────────────────────────

  group('memory array — toString representation', () {
    test('array toString includes depth×width format', () {
      const reg = RegisterInfo(
        name: 'regs', width: 32, isSequential: true,
        isMemoryArray: true, depth: 32,
      );
      expect(reg.toString(), contains('32×32b'));
    });

    test('scalar toString shows width only', () {
      const reg = RegisterInfo(name: 'q', width: 8, isSequential: true);
      expect(reg.toString(), contains('8b'));
      expect(reg.toString(), isNot(contains('×')));
    });
  });
}
