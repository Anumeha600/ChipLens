import 'dart:io';

import '../verification/verification_result.dart';
import '../verification/verification_tool.dart';
import '../verification/process_utilities.dart';

// ──────────────────────────────────────────────────────────────────────────────
// SimulationResult
// ──────────────────────────────────────────────────────────────────────────────

class SimulationResult {
  final bool compileSuccess;
  final bool simulationSuccess;
  final int exitCode;
  final String stdout;
  final String stderr;

  const SimulationResult({
    required this.compileSuccess,
    required this.simulationSuccess,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  @override
  String toString() => 'SimulationResult('
      'compileSuccess: $compileSuccess, '
      'simulationSuccess: $simulationSuccess, '
      'exitCode: $exitCode)';
}

// ──────────────────────────────────────────────────────────────────────────────
// IcarusService
// ──────────────────────────────────────────────────────────────────────────────

/// Compiles and simulates Verilog using Icarus Verilog (iverilog + vvp).
///
/// On Windows, iverilog.exe and vvp.exe are MSYS2 binaries whose transitive
/// DLL dependencies are not always visible to the Dart process's inherited
/// PATH.  To guarantee DLL resolution, both steps are executed via bash.exe
/// with an explicit MSYS2 PATH prefix — the same approach used by
/// [VerilatorService].
///
/// Workflow:
/// 1. Write RTL → `design.v` and testbench → `testbench.v` in a temp dir.
/// 2. Compile: bash -c "PATH='…' iverilog -Wall -o sim.out design.v testbench.v"
/// 3. If compile succeeds, simulate: bash -c "PATH='…' vvp sim.out"
/// 4. Return a [VerificationResult]; `metadata['compileSuccess']` carries the
///    compile-step flag used by the backward-compat [simulate] wrapper.
class IcarusService implements VerificationTool {
  /// Absolute path to the `iverilog` compiler executable.
  final String iverilogPath;

  /// Absolute path to the `vvp` simulation runtime executable.
  final String vvpPath;

  /// Absolute path to the MSYS2 bash executable.
  final String bashPath;

  const IcarusService({
    this.iverilogPath = r'E:\msys64\ucrt64\bin\iverilog.exe',
    this.vvpPath      = r'E:\msys64\ucrt64\bin\vvp.exe',
    this.bashPath     = r'E:\msys64\usr\bin\bash.exe',
  });

  static const _pathPrefix = '/ucrt64/bin:/usr/bin';

  @override
  String get toolName => 'icarus';

  @override
  Future<bool> isAvailable() async =>
      File(bashPath).existsSync() &&
      File(iverilogPath).existsSync() &&
      File(vvpPath).existsSync();

  /// Implements [VerificationTool.run]: compile then simulate.
  ///
  /// `metadata['compileSuccess']` is set to `true` only when compilation
  /// succeeds; the [simulate] wrapper reads it to populate [SimulationResult].
  @override
  Future<VerificationResult> run(VerificationContext context) async {
    final sw      = Stopwatch()..start();
    final tempDir = await ProcessUtilities.makeTempDir('chiplens_icarus');
    try {
      final sep    = Platform.pathSeparator;
      final vFile  = File('${tempDir.path}${sep}design.v');
      final tbFile = File('${tempDir.path}${sep}testbench.v');
      final simOut = '${tempDir.path}${sep}sim.out';

      await vFile.writeAsString(context.rtlSource);
      await tbFile.writeAsString(context.testbenchSource ?? '');

      final iverilogPosix = _posix(iverilogPath);
      final vvpPosix      = _posix(vvpPath);
      final simOutPosix   = _posix(simOut);
      final vFilePosix    = _posix(vFile.path);
      final tbFilePosix   = _posix(tbFile.path);

      // ── Compile ────────────────────────────────────────────────────────────
      final compileCmd = "PATH='$_pathPrefix:\$PATH' "
          "'$iverilogPosix' -Wall -o '$simOutPosix' "
          "'$vFilePosix' '$tbFilePosix'";

      final compile = await ProcessUtilities.runProcess(
        bashPath, ['-c', compileCmd],
      );

      final compileSuccess = compile.exitCode == 0;
      final compileStdout  = compile.stdout.toString();
      final compileStderr  = compile.stderr.toString();

      if (!compileSuccess) {
        sw.stop();
        return VerificationResult(
          success:       false,
          exitCode:      compile.exitCode,
          stdout:        compileStdout,
          stderr:        compileStderr,
          executionTime: sw.elapsed,
          metadata:      const <String, Object>{'compileSuccess': false},
        );
      }

      // ── Simulate ───────────────────────────────────────────────────────────
      final simCmd = "PATH='$_pathPrefix:\$PATH' '$vvpPosix' '$simOutPosix'";

      final sim = await ProcessUtilities.runProcess(
        bashPath, ['-c', simCmd],
      );
      sw.stop();

      final stdout = [compileStdout, sim.stdout.toString()]
          .where((s) => s.isNotEmpty)
          .join('\n');
      final stderr = [compileStderr, sim.stderr.toString()]
          .where((s) => s.isNotEmpty)
          .join('\n');

      return VerificationResult(
        success:       sim.exitCode == 0,
        exitCode:      sim.exitCode,
        stdout:        stdout,
        stderr:        stderr,
        executionTime: sw.elapsed,
        metadata:      const <String, Object>{'compileSuccess': true},
      );
    } finally {
      await ProcessUtilities.cleanupDir(tempDir);
    }
  }

  /// Backward-compatible API: compile and simulate, returning a
  /// [SimulationResult] with separate [compileSuccess] / [simulationSuccess].
  Future<SimulationResult> simulate(
    String designSource,
    String testbenchSource,
  ) async {
    final vr = await run(VerificationContext(
      rtlSource:       designSource,
      testbenchSource: testbenchSource,
    ));
    return SimulationResult(
      compileSuccess:    vr.metadata['compileSuccess'] == true,
      simulationSuccess: vr.success,
      exitCode:          vr.exitCode,
      stdout:            vr.stdout,
      stderr:            vr.stderr,
    );
  }

  static String _posix(String path) => path.replaceAll(r'\', '/');
}
