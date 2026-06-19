import 'dart:io';

import '../verification/verification_result.dart';
import '../verification/verification_tool.dart';
import '../verification/process_utilities.dart';

// ──────────────────────────────────────────────────────────────────────────────
// YosysResult
// ──────────────────────────────────────────────────────────────────────────────

class YosysResult {
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;

  const YosysResult({
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  @override
  String toString() => 'YosysResult(success: $success, exitCode: $exitCode)';
}

// ──────────────────────────────────────────────────────────────────────────────
// YosysService
// ──────────────────────────────────────────────────────────────────────────────

/// Runs Yosys synthesis analysis on a Verilog source string.
///
/// Unlike Verilator, Yosys on MSYS2 ships as a native Windows `.exe` and can
/// be invoked directly — no bash wrapper is needed.
///
/// The analysis script runs:
/// ```
/// read_verilog design.v
/// hierarchy -check
/// proc
/// opt
/// check
/// stat
/// ```
class YosysService implements VerificationTool {
  /// Absolute path to the `yosys.exe` binary.
  final String yosysPath;

  const YosysService({
    this.yosysPath = r'E:\msys64\ucrt64\bin\yosys.exe',
  });

  static const _script = 'read_verilog design.v\n'
      'hierarchy -check\n'
      'proc\n'
      'opt\n'
      'check\n'
      'stat\n';

  @override
  String get toolName => 'yosys';

  @override
  Future<bool> isAvailable() async => File(yosysPath).existsSync();

  /// Implements [VerificationTool.run]: write design + script to a temp dir,
  /// invoke `yosys -s script.ys`, and return a [VerificationResult].
  @override
  Future<VerificationResult> run(VerificationContext context) async {
    final sw      = Stopwatch()..start();
    final tempDir = await ProcessUtilities.makeTempDir('chiplens_yosys');
    try {
      final vFile      = File('${tempDir.path}${Platform.pathSeparator}design.v');
      final scriptFile = File('${tempDir.path}${Platform.pathSeparator}script.ys');

      await vFile.writeAsString(context.rtlSource);
      await scriptFile.writeAsString(_script);

      final result = await ProcessUtilities.runProcess(
        yosysPath,
        ['-s', scriptFile.path],
        workingDirectory: tempDir.path,
      );
      sw.stop();

      return VerificationResult(
        success:       result.exitCode == 0,
        exitCode:      result.exitCode,
        stdout:        result.stdout.toString(),
        stderr:        result.stderr.toString(),
        executionTime: sw.elapsed,
      );
    } finally {
      await ProcessUtilities.cleanupDir(tempDir);
    }
  }

  /// Backward-compatible API: analyze [source] and return a [YosysResult].
  Future<YosysResult> analyze(String source) async {
    final vr = await run(VerificationContext(rtlSource: source));
    return YosysResult(
      success:  vr.success,
      exitCode: vr.exitCode,
      stdout:   vr.stdout,
      stderr:   vr.stderr,
    );
  }
}
