import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// Regression tests for width inference on assign-target signals.
//
// Root cause (Sprint H Task 4): assign-target signals (driven by 'assign'
// statements) defaulted to width=1 even when their port or wire declaration
// specified a wider type.
//
// Fix: RegisterProvider now builds a width map from port/wire/logic
// declarations before processing assign targets.  The map is keyed by signal
// name; signals with explicit [N:M] ranges get their width from the
// declaration.  Signals without an explicit range still default to 1.
//
// Example from picorv32_regs:
//   output [31:0] rdata1  →  rdata1 width was 1, now 32
//   output [31:0] rdata2  →  rdata2 width was 1, now 32

DesignContext _ctx(String rtl) => DesignContext(rtlSource: rtl);

void main() {
  const provider = RegisterProvider();

  // ── Group 1: output port width inference ─────────────────────────────────

  group('width inference — output port declarations', () {
    test('output [31:0] rdata: assign target gets width=32', () async {
      const rtl = '''
module m(input [31:0] din, output [31:0] rdata);
  assign rdata = din;
endmodule
''';
      final r    = await provider.analyze(_ctx(rtl));
      final rdata = r.registers.firstWhere((r) => r.name == 'rdata');
      expect(rdata.width, 32);
      expect(rdata.isCombinational, isTrue);
    });

    test('output [7:0]: assign target gets width=8', () async {
      const rtl = '''
module m(input [7:0] d, output [7:0] c);
  assign c = d + 1;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final c = r.registers.firstWhere((r) => r.name == 'c');
      expect(c.width, 8);
    });

    test('output [15:0]: assign target gets width=16', () async {
      const rtl = '''
module m(input [15:0] a, output [15:0] b);
  assign b = ~a;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final b = r.registers.firstWhere((r) => r.name == 'b');
      expect(b.width, 16);
    });

    test('picorv32_regs rdata1 and rdata2 both get width=32', () async {
      const rtl = '''
module picorv32_regs(
  input clk, wen,
  input [5:0] waddr, raddr1, raddr2,
  input [31:0] wdata,
  output [31:0] rdata1, output [31:0] rdata2
);
  reg [31:0] regs [0:31];
  always @(posedge clk)
    if (wen) regs[waddr[4:0]] <= wdata;
  assign rdata1 = regs[raddr1[4:0]];
  assign rdata2 = regs[raddr2[4:0]];
endmodule
''';
      final r      = await provider.analyze(_ctx(rtl));
      final rdata1 = r.registers.firstWhere((r) => r.name == 'rdata1');
      final rdata2 = r.registers.firstWhere((r) => r.name == 'rdata2');
      expect(rdata1.width, 32);
      expect(rdata2.width, 32);
    });

    test('two different widths in same module', () async {
      const rtl = '''
module m(input [31:0] a, input [7:0] b, output [31:0] wide, output [7:0] narrow);
  assign wide   = a;
  assign narrow = b[7:0];
endmodule
''';
      final r      = await provider.analyze(_ctx(rtl));
      final wide   = r.registers.firstWhere((r) => r.name == 'wide');
      final narrow = r.registers.firstWhere((r) => r.name == 'narrow');
      expect(wide.width,   32);
      expect(narrow.width,  8);
    });
  });

  // ── Group 2: wire/logic declaration width inference ───────────────────────

  group('width inference — wire and logic declarations', () {
    test('wire [15:0]: assign target gets width=16', () async {
      const rtl = '''
module m(input [15:0] a);
  wire [15:0] bus;
  assign bus = a;
endmodule
''';
      final r   = await provider.analyze(_ctx(rtl));
      final bus = r.registers.firstWhere((r) => r.name == 'bus');
      expect(bus.width, 16);
    });

    test('logic [7:0]: assign target gets width=8', () async {
      const rtl = '''
module m(input [7:0] d);
  logic [7:0] pipeline_stage;
  assign pipeline_stage = d;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final s = r.registers.firstWhere((r) => r.name == 'pipeline_stage');
      expect(s.width, 8);
    });

    test('inout [3:0]: assign target gets width=4', () async {
      const rtl = '''
module m(inout [3:0] bus);
  wire [3:0] local_bus;
  assign bus = local_bus;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final b = r.registers.firstWhere((r) => r.name == 'bus');
      expect(b.width, 4);
    });
  });

  // ── Group 3: fallback to width=1 ─────────────────────────────────────────

  group('width inference — fallback cases', () {
    test('undeclared assign target defaults to width=1', () async {
      const rtl = 'module m(input a); assign b = a; endmodule';
      final r = await provider.analyze(_ctx(rtl));
      final b = r.registers.firstWhere((r) => r.name == 'b');
      expect(b.width, 1);
    });

    test('1-bit declared output: width stays 1', () async {
      const rtl = '''
module m(input a, output b);
  assign b = ~a;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final b = r.registers.firstWhere((r) => r.name == 'b');
      expect(b.width, 1);
    });

    test('parameterized width [WIDTH-1:0] falls back to 1', () async {
      const rtl = '''
module m #(parameter WIDTH = 8) (input [WIDTH-1:0] a, output [WIDTH-1:0] sum);
  assign sum = a + 1;
endmodule
''';
      final r   = await provider.analyze(_ctx(rtl));
      final sum = r.registers.firstWhere((r) => r.name == 'sum');
      // Parameterized widths not yet supported — fall back to 1
      expect(sum.width, 1);
    });
  });

  // ── Group 4: reg declaration width is not overridden by port decl ─────────

  group('width inference — reg declarations take precedence', () {
    test('reg [7:0] q with output reg port: q gets width from reg', () async {
      const rtl = '''
module m(input clk, input [7:0] d, output reg [7:0] q, output [7:0] c);
  always @(posedge clk) q <= d;
  assign c = d + 1;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final q = r.registers.firstWhere((r) => r.name == 'q');
      final c = r.registers.firstWhere((r) => r.name == 'c');
      expect(q.width, 8);
      expect(q.isSequential,   isTrue);
      expect(c.width, 8);           // inferred from output [7:0] c
      expect(c.isCombinational, isTrue);
    });

    test('reg declaration width not stomped by port width when same signal', () async {
      // 'q' is declared as 'output reg [7:0] q' — both the port and reg
      // declaration agree on 8 bits.  The reg path must win for isSequential.
      const rtl = '''
module m(input clk, output reg [7:0] q);
  always @(posedge clk) q <= q + 1;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final q = r.registers.firstWhere((r) => r.name == 'q');
      expect(q.isSequential, isTrue);  // set by reg path, not by port path
      expect(q.width, 8);
    });
  });

  // ── Group 5: combinational classification preserved ───────────────────────

  group('width inference — combinational classification still correct', () {
    test('inferred width does not change isCombinational flag', () async {
      const rtl = '''
module m(input [31:0] a, output [31:0] z);
  assign z = a;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      final z = r.registers.firstWhere((r) => r.name == 'z');
      expect(z.isCombinational, isTrue);
      expect(z.isSequential,    isFalse);
      expect(z.width,           32);
    });

    test('sequential reg width unaffected by assign of same name elsewhere', () async {
      // Contrived: reg declared AND driven combinationally elsewhere.
      // The reg declaration must not be overridden by the port declaration.
      const rtl = '''
module m(input clk, output reg [7:0] out);
  always @(posedge clk) out <= out + 1;
endmodule
''';
      final r   = await provider.analyze(_ctx(rtl));
      final out = r.registers.firstWhere((r) => r.name == 'out');
      expect(out.isSequential, isTrue);
      expect(out.width, 8);
    });
  });
}
