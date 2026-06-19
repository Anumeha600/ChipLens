import 'dart:io';

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
/// On Windows, both `iverilog.exe` and `vvp.exe` are native executables shipped
/// with MSYS2 — no bash wrapper is required (same pattern as [YosysService]).
///
/// Workflow:
/// 1. Write [designSource] → `design.v` and [testbenchSource] → `testbench.v`
///    in a temporary directory.
/// 2. Compile: `iverilog -Wall -o sim.out design.v testbench.v`
/// 3. If compile succeeds, simulate: `vvp sim.out`
/// 4. Return a [SimulationResult] with combined stdout/stderr and success flags.
class IcarusService {
  /// Absolute path to the `iverilog` compiler executable.
  final String iverilogPath;

  /// Absolute path to the `vvp` simulation runtime executable.
  final String vvpPath;

  const IcarusService({
    this.iverilogPath = r'E:\msys64\ucrt64\bin\iverilog.exe',
    this.vvpPath      = r'E:\msys64\ucrt64\bin\vvp.exe',
  });

  /// Compile [designSource] together with [testbenchSource], then simulate.
  ///
  /// If compilation fails the simulation step is skipped and
  /// [SimulationResult.simulationSuccess] is `false`.
  Future<SimulationResult> simulate(
    String designSource,
    String testbenchSource,
  ) async {
    final tempDir = await _makeTempDir();
    try {
      final sep     = Platform.pathSeparator;
      final vFile   = File('${tempDir.path}${sep}design.v');
      final tbFile  = File('${tempDir.path}${sep}testbench.v');
      final simOut  = '${tempDir.path}${sep}sim.out';

      await vFile.writeAsString(designSource);
      await tbFile.writeAsString(testbenchSource);

      // ── Compile ─────────────────────────────────────────────────────────────
      final compile = await Process.run(
        iverilogPath,
        ['-Wall', '-o', simOut, vFile.path, tbFile.path],
        workingDirectory: tempDir.path,
      );

      final compileSuccess = compile.exitCode == 0;
      final compileStdout  = compile.stdout.toString();
      final compileStderr  = compile.stderr.toString();

      if (!compileSuccess) {
        return SimulationResult(
          compileSuccess:     false,
          simulationSuccess:  false,
          exitCode:           compile.exitCode,
          stdout:             compileStdout,
          stderr:             compileStderr,
        );
      }

      // ── Simulate ─────────────────────────────────────────────────────────────
      final sim = await Process.run(
        vvpPath,
        [simOut],
        workingDirectory: tempDir.path,
      );

      final simSuccess = sim.exitCode == 0;
      final simStdout  = sim.stdout.toString();
      final simStderr  = sim.stderr.toString();

      return SimulationResult(
        compileSuccess:     true,
        simulationSuccess:  simSuccess,
        exitCode:           sim.exitCode,
        // Combine compile and simulation output so the parser sees everything.
        stdout: [compileStdout, simStdout].where((s) => s.isNotEmpty).join('\n'),
        stderr: [compileStderr, simStderr].where((s) => s.isNotEmpty).join('\n'),
      );
    } finally {
      await _cleanup(tempDir);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<Directory> _makeTempDir() async {
    final ts  = DateTime.now().microsecondsSinceEpoch;
    final dir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}chiplens_icarus_$ts',
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
