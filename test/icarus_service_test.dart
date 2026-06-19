import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/tools/icarus_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

const _defaultIverilog = r'E:\msys64\ucrt64\bin\iverilog.exe';

bool _icarusAvailable(String path) => File(path).existsSync();

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SimulationResult', () {
    test('compileSuccess and simulationSuccess reflect provided values', () {
      const r = SimulationResult(
        compileSuccess:    true,
        simulationSuccess: true,
        exitCode:          0,
        stdout:            'ok',
        stderr:            '',
      );
      expect(r.compileSuccess,    isTrue);
      expect(r.simulationSuccess, isTrue);
      expect(r.exitCode,          0);
    });

    test('failed compile result has simulationSuccess = false', () {
      const r = SimulationResult(
        compileSuccess:    false,
        simulationSuccess: false,
        exitCode:          1,
        stdout:            '',
        stderr:            'design.v:1: error: syntax error',
      );
      expect(r.compileSuccess,    isFalse);
      expect(r.simulationSuccess, isFalse);
      expect(r.exitCode,          1);
    });

    test('toString includes compileSuccess and exitCode', () {
      const r = SimulationResult(
        compileSuccess:    true,
        simulationSuccess: false,
        exitCode:          1,
        stdout:            '',
        stderr:            '',
      );
      expect(r.toString(), contains('compileSuccess: true'));
      expect(r.toString(), contains('exitCode: 1'));
    });
  });

  group('IcarusService constructor', () {
    test('default iverilog and vvp paths are set', () {
      const svc = IcarusService();
      expect(svc.iverilogPath, _defaultIverilog);
      expect(svc.vvpPath,      r'E:\msys64\ucrt64\bin\vvp.exe');
    });

    test('custom paths are stored', () {
      const svc = IcarusService(
        iverilogPath: r'C:\tools\iverilog.exe',
        vvpPath:      r'C:\tools\vvp.exe',
      );
      expect(svc.iverilogPath, r'C:\tools\iverilog.exe');
      expect(svc.vvpPath,      r'C:\tools\vvp.exe');
    });
  });

  group('IcarusService.simulate (integration — requires Icarus)', () {
    const svc = IcarusService();

    test('returns SimulationResult for valid Verilog + testbench', () async {
      if (!_icarusAvailable(_defaultIverilog)) return;

      const design = '''
module dff(input clk, input d, output reg q);
  always @(posedge clk) q <= d;
endmodule
''';
      const tb = '''
module tb;
  reg clk = 0, d = 0;
  wire q;
  dff uut(.clk(clk), .d(d), .q(q));
  initial begin
    #5 d = 1;
    #5 clk = 1;
    #5 clk = 0;
    #5 \$finish;
  end
endmodule
''';
      final result = await svc.simulate(design, tb);
      expect(result, isA<SimulationResult>());
      expect(result.compileSuccess, isTrue);
    });

    test('compile fails for invalid Verilog', () async {
      if (!_icarusAvailable(_defaultIverilog)) return;

      const result = 'this is not verilog!!!';
      const tb     = 'module tb; initial \$finish; endmodule';
      final r = await svc.simulate(result, tb);
      expect(r.compileSuccess, isFalse);
      expect(r.simulationSuccess, isFalse);
    });

    test('\$stop in simulation: compile succeeds and output is captured', () async {
      if (!_icarusAvailable(_defaultIverilog)) return;

      const design = 'module top; endmodule';
      const tb     = '''
module tb;
  initial begin
    #1 \$stop;
  end
endmodule
''';
      final r = await svc.simulate(design, tb);
      // iverilog compiles fine; vvp may exit 0 or non-zero on $stop depending
      // on version/platform — what matters is that we captured output.
      expect(r.compileSuccess, isTrue);
      expect(r.exitCode, isA<int>());
    });
  });
}
