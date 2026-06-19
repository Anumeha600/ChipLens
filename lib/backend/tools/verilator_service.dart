import 'dart:io';

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
/// On Windows, `verilator` is a Perl wrapper script that in turn calls
/// `verilator_bin.exe`.  The script relies on MSYS2 path translation and
/// POSIX-style PATH entries, so it must be launched inside an MSYS2 bash
/// shell rather than called via Perl or cmd.exe directly:
///
/// ```
///   bash.exe -c "PATH='/ucrt64/bin:/usr/bin' '<verilator>' --lint-only '<file>'"
/// ```
///
/// Both paths are constructor-configurable for alternate MSYS2 installs.
class VerilatorService {
  /// Absolute path to the `verilator` wrapper script (backslashes are fine).
  final String verilatorPath;

  /// Absolute path to the MSYS2 bash executable.
  final String bashPath;

  const VerilatorService({
    this.verilatorPath = r'E:\msys64\ucrt64\bin\verilator',
    this.bashPath      = r'E:\msys64\usr\bin\bash.exe',
  });

  /// Lint [source] with `verilator --lint-only`.
  ///
  /// Writes the source to a temporary `.v` file, invokes Verilator, and
  /// deletes the temp file regardless of the outcome.
  Future<VerilatorResult> lint(String source) async {
    final tempFile = await _writeTempFile(source);
    try {
      // Convert Windows backslashes to forward slashes so bash can resolve
      // both E:/msys64/... and C:/Users/... style paths without cygpath.
      final scriptPosix = _toForwardSlashes(verilatorPath);
      final filePosix   = _toForwardSlashes(tempFile.path);

      // Prepend the MSYS2 ucrt64 bin dir (POSIX style) so that bash can
      // locate verilator_bin alongside the wrapper script.
      const pathPrefix  = '/ucrt64/bin:/usr/bin';
      final cmd = "PATH='$pathPrefix:\$PATH' '$scriptPosix' --lint-only '$filePosix'";

      final result = await Process.run(bashPath, ['-c', cmd]);

      return VerilatorResult(
        success:  result.exitCode == 0,
        exitCode: result.exitCode,
        stdout:   result.stdout.toString(),
        stderr:   result.stderr.toString(),
      );
    } finally {
      await _deleteTempFile(tempFile);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<File> _writeTempFile(String source) async {
    final ts   = DateTime.now().microsecondsSinceEpoch;
    final sep  = Platform.pathSeparator;
    final path = '${Directory.systemTemp.path}${sep}chiplens_lint_$ts.v';
    final file = File(path);
    await file.writeAsString(source);
    return file;
  }

  Future<void> _deleteTempFile(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // best-effort — do not mask the original result
    }
  }

  static String _toForwardSlashes(String path) => path.replaceAll(r'\', '/');
}
