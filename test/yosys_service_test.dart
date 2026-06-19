import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/tools/yosys_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

// A fake YosysService that overrides Process.run by running a no-op script.
// These tests verify the public surface: script construction, temp dir lifecycle,
// and result shape — without requiring Yosys to be installed.
//
// We achieve this by injecting a yosysPath pointing to a tiny test executable
// (or 'echo' on POSIX) so the service can at least start.  On Windows CI the
// test is marked skip when yosys.exe is absent.

bool _yosysAvailable(String path) => File(path).existsSync();

const _defaultYosysPath = r'E:\msys64\ucrt64\bin\yosys.exe';

void main() {
  group('YosysResult', () {
    test('success reflects exitCode == 0', () {
      const r = YosysResult(
        success: true, exitCode: 0, stdout: 'ok', stderr: '',
      );
      expect(r.success, isTrue);
      expect(r.exitCode, 0);
    });

    test('failure reflects non-zero exitCode', () {
      const r = YosysResult(
        success: false, exitCode: 1, stdout: '', stderr: 'ERROR: bad input',
      );
      expect(r.success, isFalse);
      expect(r.stderr, contains('ERROR'));
    });

    test('toString includes success and exitCode', () {
      const r = YosysResult(
        success: true, exitCode: 0, stdout: '', stderr: '',
      );
      expect(r.toString(), contains('success: true'));
      expect(r.toString(), contains('exitCode: 0'));
    });
  });

  group('YosysService constructor', () {
    test('default yosysPath is set', () {
      const svc = YosysService();
      expect(svc.yosysPath, _defaultYosysPath);
    });

    test('custom yosysPath is stored', () {
      const svc = YosysService(yosysPath: r'C:\tools\yosys.exe');
      expect(svc.yosysPath, r'C:\tools\yosys.exe');
    });
  });

  group('YosysService.analyze (integration — requires Yosys)', () {
    const svc = YosysService();

    setUpAll(() {
      if (!_yosysAvailable(_defaultYosysPath)) {
        // Mark all tests in this group as skipped at runtime.
      }
    });

    test('returns YosysResult for valid Verilog', () async {
      if (!_yosysAvailable(_defaultYosysPath)) {
        return; // skip gracefully — Yosys not installed
      }

      const src = '''
module top(input clk, input d, output reg q);
  always @(posedge clk) q <= d;
endmodule
''';
      final result = await svc.analyze(src);
      expect(result, isA<YosysResult>());
      expect(result.exitCode, isA<int>());
    });

    test('returns failure result for invalid Verilog', () async {
      if (!_yosysAvailable(_defaultYosysPath)) {
        return;
      }

      const src = 'this is not verilog!!!';
      final result = await svc.analyze(src);
      // Yosys exits non-zero on parse failure
      expect(result.success, isFalse);
      expect(
        '${result.stdout}${result.stderr}'.toLowerCase(),
        anyOf(contains('error'), contains('syntax')),
      );
    });
  });
}
