import 'dart:io';

import '../verification/verification_result.dart';
import '../verification/verification_tool.dart';
import '../verification/process_utilities.dart';

// ──────────────────────────────────────────────────────────────────────────────
// VerilatorResult
// ──────────────────────────────────────────────────────────────────────────────

class VerilatorResult {
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;

  const VerilatorResult({
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  @override
  String toString() =>
      'VerilatorResult(success: $success, exitCode: $exitCode)';
}

// ──────────────────────────────────────────────────────────────────────────────
// VerilatorService
// ──────────────────────────────────────────────────────────────────────────────

/// Runs Verilator lint analysis on a Verilog source string.
///
/// On Windows, `verilator` is a Perl wrapper script that must be launched
/// inside an MSYS2 bash shell:
/// ```
///   bash.exe -c "PATH='/ucrt64/bin:/usr/bin' '<verilator>' --lint-only '<file>'"
/// ```
class VerilatorService implements VerificationTool {
  /// Absolute path to the `verilator` wrapper script.
  final String verilatorPath;

  /// Absolute path to the MSYS2 bash executable.
  final String bashPath;

  const VerilatorService({
    this.verilatorPath = r'E:\msys64\ucrt64\bin\verilator',
    this.bashPath      = r'E:\msys64\usr\bin\bash.exe',
  });

  @override
  String get toolName => 'verilator';

  @override
  Future<bool> isAvailable() async =>
      File(bashPath).existsSync() && File(verilatorPath).existsSync();

  /// Implements [VerificationTool.run]: write a temp `.v` file, invoke
  /// Verilator via bash, and return a [VerificationResult].
  @override
  Future<VerificationResult> run(VerificationContext context) async {
    final sw       = Stopwatch()..start();
    final tempFile = await ProcessUtilities.writeTempFile(
      context.rtlSource,
      prefix:    'chiplens_lint',
      extension: 'v',
    );
    try {
      final scriptPosix = _toForwardSlashes(verilatorPath);
      final filePosix   = _toForwardSlashes(tempFile.path);
      const pathPrefix  = '/ucrt64/bin:/usr/bin';
      final cmd =
          "PATH='$pathPrefix:\$PATH' '$scriptPosix' --lint-only '$filePosix'";

      final result = await ProcessUtilities.runProcess(bashPath, ['-c', cmd]);
      sw.stop();

      return VerificationResult(
        success:       result.exitCode == 0,
        exitCode:      result.exitCode,
        stdout:        result.stdout.toString(),
        stderr:        result.stderr.toString(),
        executionTime: sw.elapsed,
      );
    } finally {
      await ProcessUtilities.deleteFile(tempFile);
    }
  }

  /// Backward-compatible API: lint [source] and return a [VerilatorResult].
  Future<VerilatorResult> lint(String source) async {
    final vr = await run(VerificationContext(rtlSource: source));
    return VerilatorResult(
      success:  vr.success,
      exitCode: vr.exitCode,
      stdout:   vr.stdout,
      stderr:   vr.stderr,
    );
  }

  static String _toForwardSlashes(String path) => path.replaceAll(r'\', '/');
}
