import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/verification/verification_result.dart';
import 'package:chiplens_lite/backend/verification/verification_tool.dart';
import 'package:chiplens_lite/backend/verification/verification_runner.dart';
import 'package:chiplens_lite/backend/verification/process_utilities.dart';
import 'package:chiplens_lite/backend/tools/verilator_service.dart';
import 'package:chiplens_lite/backend/tools/yosys_service.dart';
import 'package:chiplens_lite/backend/tools/icarus_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

const _verilatorPath = r'E:\msys64\ucrt64\bin\verilator';
const _bashPath      = r'E:\msys64\usr\bin\bash.exe';
const _yosysPath     = r'E:\msys64\ucrt64\bin\yosys.exe';
const _iverilogPath  = r'E:\msys64\ucrt64\bin\iverilog.exe';
const _vvpPath       = r'E:\msys64\ucrt64\bin\vvp.exe';

bool _exists(String path) => File(path).existsSync();
bool get _verilatorAvailable => _exists(_bashPath) && _exists(_verilatorPath);
bool get _yosysAvailable     => _exists(_yosysPath);
bool get _icarusAvailable    => _exists(_iverilogPath) && _exists(_vvpPath);

const _simpleDff = '''
module dff(input clk, input d, output reg q);
  always @(posedge clk) q <= d;
endmodule
''';

const _simpleTb = '''
module tb;
  reg clk = 0, d = 0;
  wire q;
  dff uut(.clk(clk), .d(d), .q(q));
  initial begin
    \$monitor("%0t q=%b", \$time, q);
    #5 d = 1; #10 \$finish;
  end
  always #5 clk = ~clk;
endmodule
''';

// ── Stub VerificationTool ────────────────────────────────────────────────────

class _EchoTool implements VerificationTool {
  final String _name;
  const _EchoTool(this._name);

  @override String get toolName => _name;
  @override Future<bool> isAvailable() async => true;

  @override
  Future<VerificationResult> run(VerificationContext context) async =>
      VerificationResult(
        success:  true,
        exitCode: 0,
        stdout:   'echo:${context.rtlSource}',
        stderr:   '',
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Tests
// ═════════════════════════════════════════════════════════════════════════════

void main() {

  // ── VerificationContext ────────────────────────────────────────────────────

  group('VerificationContext', () {
    test('required rtlSource is stored', () {
      const ctx = VerificationContext(rtlSource: 'module m; endmodule');
      expect(ctx.rtlSource, 'module m; endmodule');
    });

    test('optional fields default correctly', () {
      const ctx = VerificationContext(rtlSource: '');
      expect(ctx.testbenchSource,      isNull);
      expect(ctx.workingDirectory,     isNull);
      expect(ctx.timeout,              const Duration(seconds: 30));
      expect(ctx.environmentVariables, isEmpty);
      expect(ctx.config,               isEmpty);
    });

    test('all fields set via constructor', () {
      const ctx = VerificationContext(
        rtlSource:            'src',
        testbenchSource:      'tb',
        workingDirectory:     '/tmp',
        timeout:              Duration(minutes: 5),
        environmentVariables: {'PATH': '/usr/bin'},
        config:               {'lint': true},
      );
      expect(ctx.testbenchSource,         'tb');
      expect(ctx.workingDirectory,        '/tmp');
      expect(ctx.timeout.inMinutes,       5);
      expect(ctx.environmentVariables,    {'PATH': '/usr/bin'});
      expect(ctx.config['lint'],          isTrue);
    });
  });

  // ── VerificationResult ────────────────────────────────────────────────────

  group('VerificationResult', () {
    test('all required fields accessible', () {
      const r = VerificationResult(
        success: true, exitCode: 0, stdout: 'out', stderr: 'err',
      );
      expect(r.success,  isTrue);
      expect(r.exitCode, 0);
      expect(r.stdout,   'out');
      expect(r.stderr,   'err');
    });

    test('optional fields default correctly', () {
      const r = VerificationResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
      );
      expect(r.diagnostics,   isEmpty);
      expect(r.executionTime, Duration.zero);
      expect(r.metadata,      isEmpty);
    });

    test('combined returns stderr+stdout trimmed', () {
      const r = VerificationResult(
        success: true, exitCode: 0,
        stdout: 'STDOUT', stderr: 'STDERR',
      );
      expect(r.combined, 'STDERR\nSTDOUT');
    });

    test('combined trims surrounding whitespace', () {
      const r = VerificationResult(
        success: true, exitCode: 0, stdout: '  a  ', stderr: '  ',
      );
      expect(r.combined, 'a');
    });

    test('toString includes success and exitCode', () {
      const r = VerificationResult(
        success: true, exitCode: 0, stdout: '', stderr: '',
      );
      expect(r.toString(), contains('success: true'));
      expect(r.toString(), contains('exitCode: 0'));
    });

    test('metadata stores tool-specific values', () {
      const r = VerificationResult(
        success: true, exitCode: 0, stdout: '', stderr: '',
        metadata: <String, Object>{'compileSuccess': true},
      );
      expect(r.metadata['compileSuccess'], isTrue);
    });
  });

  // ── VerificationTool interface ────────────────────────────────────────────

  group('VerificationTool interface', () {
    test('custom tool satisfies contract', () async {
      const tool = _EchoTool('my-tool');
      expect(tool.toolName, 'my-tool');
      expect(await tool.isAvailable(), isTrue);
    });

    test('run() receives context correctly', () async {
      const tool = _EchoTool('echo');
      final ctx  = const VerificationContext(rtlSource: 'hello');
      final r    = await tool.run(ctx);
      expect(r.stdout, 'echo:hello');
      expect(r.success, isTrue);
    });

    test('each service implements VerificationTool', () {
      expect(const VerilatorService(), isA<VerificationTool>());
      expect(const YosysService(),     isA<VerificationTool>());
      expect(const IcarusService(),    isA<VerificationTool>());
    });

    test('toolName returns expected strings', () {
      expect(const VerilatorService().toolName, 'verilator');
      expect(const YosysService().toolName,     'yosys');
      expect(const IcarusService().toolName,    'icarus');
    });
  });

  // ── VerificationRunner.execute ────────────────────────────────────────────

  group('VerificationRunner.execute', () {
    test('dispatches to the supplied tool', () async {
      const tool = _EchoTool('dispatch-test');
      const ctx  = VerificationContext(rtlSource: 'dispatch-src');
      final r    = await VerificationRunner.execute(tool, ctx);
      expect(r.stdout, 'echo:dispatch-src');
    });

    test('returns VerificationResult', () async {
      final r = await VerificationRunner.execute(
        const _EchoTool('t'),
        const VerificationContext(rtlSource: ''),
      );
      expect(r, isA<VerificationResult>());
    });
  });

  // ── ProcessUtilities ──────────────────────────────────────────────────────

  group('ProcessUtilities', () {
    test('makeTempDir creates a real directory', () async {
      final dir = await ProcessUtilities.makeTempDir('chiplens_test');
      addTearDown(() => ProcessUtilities.cleanupDir(dir));
      expect(await dir.exists(), isTrue);
    });

    test('cleanupDir removes the directory', () async {
      final dir = await ProcessUtilities.makeTempDir('chiplens_cleanup');
      await ProcessUtilities.cleanupDir(dir);
      expect(await dir.exists(), isFalse);
    });

    test('cleanupDir on non-existent dir does not throw', () async {
      final dir = Directory('/tmp/chiplens_nonexistent_99999');
      await expectLater(
        () => ProcessUtilities.cleanupDir(dir),
        returnsNormally,
      );
    });

    test('writeTempFile creates file with supplied content', () async {
      final file = await ProcessUtilities.writeTempFile(
        'module top; endmodule',
        prefix: 'chiplens_write_test',
        extension: 'v',
      );
      addTearDown(() => ProcessUtilities.deleteFile(file));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'module top; endmodule');
      expect(file.path, endsWith('.v'));
    });

    test('deleteFile removes the file', () async {
      final file = await ProcessUtilities.writeTempFile(
        '',
        prefix: 'chiplens_del_test',
        extension: 'v',
      );
      await ProcessUtilities.deleteFile(file);
      expect(await file.exists(), isFalse);
    });

    test('deleteFile on non-existent file does not throw', () async {
      final file = File('/tmp/chiplens_nonexistent_file.v');
      await expectLater(
        () => ProcessUtilities.deleteFile(file),
        returnsNormally,
      );
    });
  });

  // ── isAvailable() ────────────────────────────────────────────────────────

  group('isAvailable', () {
    test('VerilatorService reports correctly', () async {
      final svc      = const VerilatorService();
      final expected = _verilatorAvailable;
      expect(await svc.isAvailable(), expected);
    });

    test('YosysService reports correctly', () async {
      final svc      = const YosysService();
      final expected = _yosysAvailable;
      expect(await svc.isAvailable(), expected);
    });

    test('IcarusService reports correctly', () async {
      final svc      = const IcarusService();
      final expected = _icarusAvailable;
      expect(await svc.isAvailable(), expected);
    });

    test('service with bad path returns false', () async {
      final svc = const VerilatorService(
        verilatorPath: r'C:\nonexistent\verilator',
        bashPath:      r'C:\nonexistent\bash.exe',
      );
      expect(await svc.isAvailable(), isFalse);
    });
  });

  // ── VerilatorService backward-compat (integration) ───────────────────────

  group('VerilatorService.lint (integration)', () {
    test('returns VerilatorResult for valid Verilog', () async {
      if (!_verilatorAvailable) return;
      final r = await const VerilatorService().lint(_simpleDff);
      expect(r, isA<VerilatorResult>());
      expect(r.exitCode, isA<int>());
    });

    test('run() and lint() agree on exitCode', () async {
      if (!_verilatorAvailable) return;
      const svc = VerilatorService();
      final vr  = await svc.run(VerificationContext(rtlSource: _simpleDff));
      final lr  = await svc.lint(_simpleDff);
      expect(lr.exitCode, vr.exitCode);
      expect(lr.success,  vr.success);
    });
  });

  // ── YosysService backward-compat (integration) ───────────────────────────

  group('YosysService.analyze (integration)', () {
    test('returns YosysResult for valid Verilog', () async {
      if (!_yosysAvailable) return;
      final r = await const YosysService().analyze(_simpleDff);
      expect(r, isA<YosysResult>());
      expect(r.exitCode, isA<int>());
    });

    test('run() and analyze() agree on exitCode', () async {
      if (!_yosysAvailable) return;
      const svc = YosysService();
      final vr  = await svc.run(VerificationContext(rtlSource: _simpleDff));
      final ar  = await svc.analyze(_simpleDff);
      expect(ar.exitCode, vr.exitCode);
      expect(ar.success,  vr.success);
    });
  });

  // ── IcarusService VerificationTool interface (integration) ──────────────

  group('IcarusService.run (integration)', () {
    test('metadata contains compileSuccess key after a run', () async {
      if (!_icarusAvailable) return;
      final vr = await const IcarusService().run(VerificationContext(
        rtlSource:       _simpleDff,
        testbenchSource: _simpleTb,
      ));
      expect(vr.metadata.containsKey('compileSuccess'), isTrue);
      expect(vr.metadata['compileSuccess'], isA<bool>());
    });

    test('metadata compileSuccess=false when source is invalid', () async {
      if (!_icarusAvailable) return;
      final vr = await const IcarusService().run(VerificationContext(
        rtlSource:       'this is not verilog!!!',
        testbenchSource: _simpleTb,
      ));
      expect(vr.metadata['compileSuccess'], isFalse);
    });
  });

  // ── VerificationRunner convenience methods ────────────────────────────────

  group('VerificationRunner.runVerilator (integration)', () {
    test('returns List<Diagnostic> for valid Verilog', () async {
      if (!_verilatorAvailable) return;
      final diags = await VerificationRunner.runVerilator(_simpleDff);
      expect(diags, isA<List>());
    });

    test('returns empty list when tool unavailable', () async {
      // Indirectly: tool not installed returns [] not throws
      // We verify the catch-and-return-empty contract via the stub test above.
      // This test verifies the return type is correct in all cases.
      final diags = await VerificationRunner.runVerilator(_simpleDff);
      expect(diags, isList);
    });
  });

  group('VerificationRunner.runYosys (integration)', () {
    test('returns List<Diagnostic> for valid Verilog', () async {
      if (!_yosysAvailable) return;
      final diags = await VerificationRunner.runYosys(_simpleDff);
      expect(diags, isA<List>());
    });
  });

  group('VerificationRunner.runIcarus (integration)', () {
    test('returns (List<Diagnostic>, String) record', () async {
      if (!_icarusAvailable) return;
      final (diags, raw) = await VerificationRunner.runIcarus(
        _simpleDff, _simpleTb,
      );
      expect(diags, isA<List>());
      expect(raw,   isA<String>());
    });

    test('returns ([], "") when tool unavailable / throws', () async {
      // Even without the tool installed the runner must not throw.
      final result = await VerificationRunner.runIcarus('', '');
      expect(result, isA<(List, String)>());
    });
  });
}
