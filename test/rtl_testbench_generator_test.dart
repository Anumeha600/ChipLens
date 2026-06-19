import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/tools/rtl_testbench_generator.dart';

void main() {
  // ── TestbenchResult ─────────────────────────────────────────────────────────

  group('TestbenchResult', () {
    test('success result carries source', () {
      const r = TestbenchResult(source: '`timescale 1ns/1ps', success: true);
      expect(r.success, isTrue);
      expect(r.source, contains('timescale'));
      expect(r.error, isNull);
    });

    test('failure result carries error message', () {
      const r = TestbenchResult(source: '', success: false, error: 'No module found');
      expect(r.success, isFalse);
      expect(r.source, isEmpty);
      expect(r.error, equals('No module found'));
    });
  });

  // ── Module name extraction ──────────────────────────────────────────────────

  group('module name extraction', () {
    test('extracts name from ANSI-style module', () {
      const src = '''
module dff (
  input clk,
  output reg q
);
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.success, isTrue);
      expect(r.source, contains('module tb_dff'));
    });

    test('extracts name with parameter list', () {
      const src = '''
module counter #(parameter N=8) (
  input clk,
  input [N-1:0] d,
  output [N-1:0] q
);
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.success, isTrue);
      expect(r.source, contains('module tb_counter'));
    });

    test('fails when no module keyword present', () {
      final r = RtlTestbenchGenerator.generate('// empty file');
      expect(r.success, isFalse);
      expect(r.error, isNotNull);
    });

    test('fails when no ports found', () {
      final r = RtlTestbenchGenerator.generate('module empty; endmodule');
      expect(r.success, isFalse);
      expect(r.error, isNotNull);
    });
  });

  // ── Clock inference ─────────────────────────────────────────────────────────

  group('clock inference', () {
    test('detects clk port and generates clock gen block', () {
      const src = '''
module dff (input clk, input d, output reg q);
  always @(posedge clk) q <= d;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('always #5 clk = ~clk'));
    });

    test('detects clock port', () {
      const src = '''
module ctr (input clock, output reg [3:0] cnt);
  always @(posedge clock) cnt <= cnt + 1;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('always #5 clock = ~clock'));
    });

    test('purely combinational module has no clock gen block', () {
      const src = '''
module mux2 (input sel, input a, input b, output y);
  assign y = sel ? a : b;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.success, isTrue);
      expect(r.source, isNot(contains('always #5')));
    });
  });

  // ── Reset inference ─────────────────────────────────────────────────────────

  group('reset inference', () {
    test('active-low reset: asserted low, deasserted high', () {
      const src = '''
module ff (input clk, input rst_n, input d, output reg q);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) q <= 0; else q <= d;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('rst_n = 0'));
      expect(r.source, contains('rst_n = 1'));
    });

    test('active-high reset: asserted high, deasserted low', () {
      const src = '''
module ff (input clk, input reset, input d, output reg q);
  always @(posedge clk) if (reset) q <= 0; else q <= d;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('reset = 1'));
      expect(r.source, contains('reset = 0'));
    });

    test('rstn treated as active-low', () {
      const src = 'module m (input clk, input rstn, output reg o); endmodule';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('rstn = 0')); // assert low
      expect(r.source, contains('rstn = 1')); // deassert high
    });
  });

  // ── Port declarations ───────────────────────────────────────────────────────

  group('port declarations in testbench', () {
    test('input ports become regs, output ports become wires', () {
      const src = '''
module adder (input [7:0] a, input [7:0] b, output [8:0] sum);
  assign sum = a + b;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('reg  [7:0] a'));
      expect(r.source, contains('reg  [7:0] b'));
      expect(r.source, contains('wire [8:0] sum'));
    });

    test('1-bit ports have no width expression', () {
      const src = 'module inv (input a, output b); assign b = ~a; endmodule';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('reg  a'));
      expect(r.source, contains('wire b'));
      // should NOT contain [0:0] or similar
      expect(r.source, isNot(contains('reg  [] a')));
    });

    test('instantiation uses named port connections', () {
      const src = 'module m (input clk, input d, output q); endmodule';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, contains('.clk'));
      expect(r.source, contains('.d'));
      expect(r.source, contains('.q'));
    });
  });

  // ── Testbench structure ─────────────────────────────────────────────────────

  group('testbench structure', () {
    const _simpleSrc = '''
module dff (input clk, input rst_n, input d, output reg q);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) q <= 0; else q <= d;
endmodule
''';

    test('contains timescale directive', () {
      final r = RtlTestbenchGenerator.generate(_simpleSrc);
      expect(r.source, contains('`timescale'));
    });

    test('contains dumpfile and dumpvars', () {
      final r = RtlTestbenchGenerator.generate(_simpleSrc);
      expect(r.source, contains('\$dumpfile'));
      expect(r.source, contains('\$dumpvars'));
    });

    test('contains \$finish', () {
      final r = RtlTestbenchGenerator.generate(_simpleSrc);
      expect(r.source, contains('\$finish'));
    });

    test('contains \$monitor', () {
      final r = RtlTestbenchGenerator.generate(_simpleSrc);
      expect(r.source, contains('\$monitor'));
    });

    test('module wraps with tb_ prefix and endmodule', () {
      final r = RtlTestbenchGenerator.generate(_simpleSrc);
      expect(r.source, contains('module tb_dff'));
      expect(r.source, contains('endmodule'));
    });

    test('DUT is instantiated as uut', () {
      final r = RtlTestbenchGenerator.generate(_simpleSrc);
      expect(r.source, contains('dff uut'));
    });
  });

  // ── Comment stripping ───────────────────────────────────────────────────────

  group('comment stripping', () {
    test('ignores ports mentioned only in comments', () {
      const src = '''
// This module has no extra inputs
module simple (input clk, output reg o);
  // input fake_port is commented out
  always @(posedge clk) o <= ~o;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      // fake_port should NOT appear in the testbench
      expect(r.source, isNot(contains('fake_port')));
      expect(r.source, contains('.clk'));
    });

    test('handles block comments spanning port list', () {
      const src = '''
module m (
  input clk, /* ignored_port */
  output reg o
);
  always @(posedge clk) o <= ~o;
endmodule
''';
      final r = RtlTestbenchGenerator.generate(src);
      expect(r.source, isNot(contains('ignored_port')));
      expect(r.source, contains('.clk'));
    });
  });
}
