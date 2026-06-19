import 'dart:io';

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
/// be invoked directly via [Process.run] — no bash wrapper is needed.
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
class YosysService {
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

  /// Analyze [source] with Yosys synthesis/check passes.
  ///
  /// Writes the source to a temp `.v` file alongside a Yosys script, invokes
  /// `yosys -s script.ys`, and cleans up regardless of outcome.
  Future<YosysResult> analyze(String source) async {
    final tempDir = await _makeTempDir();
    try {
      final vFile     = File('${tempDir.path}${Platform.pathSeparator}design.v');
      final scriptFile = File('${tempDir.path}${Platform.pathSeparator}script.ys');

      await vFile.writeAsString(source);
      await scriptFile.writeAsString(_script);

      final result = await Process.run(
        yosysPath,
        ['-s', scriptFile.path],
        workingDirectory: tempDir.path,
      );

      return YosysResult(
        success:  result.exitCode == 0,
        exitCode: result.exitCode,
        stdout:   result.stdout.toString(),
        stderr:   result.stderr.toString(),
      );
    } finally {
      await _cleanup(tempDir);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<Directory> _makeTempDir() async {
    final ts  = DateTime.now().microsecondsSinceEpoch;
    final dir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}chiplens_yosys_$ts',
    );
    return dir.create(recursive: true);
  }

  Future<void> _cleanup(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // best-effort — do not mask the original result
    }
  }
}
