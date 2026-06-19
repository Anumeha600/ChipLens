import 'dart:io';

import '../verification/process_utilities.dart';
import 'formal_engine.dart';
import 'formal_result.dart';
import 'sby_output_parser.dart';
import 'sby_script_builder.dart';

// ─── SymbiYosysEngine ─────────────────────────────────────────────────────────

/// [FormalEngine] implementation backed by SymbiYosys (`sby`).
///
/// Responsibilities:
/// 1. Write the RTL source to a temporary working directory as `design.v`.
/// 2. Generate a `.sby` script via [SbyScriptBuilder].
/// 3. Invoke `sby` through an MSYS2 bash shell (same pattern used by
///    [VerilatorService] and [IcarusService] to satisfy MSYS2 DLL resolution).
/// 4. Delegate stdout/stderr interpretation to [SbyOutputParser].
///
/// Parsing raw output into [Diagnostic] objects is the responsibility of
/// [FormalDiagnosticParser].
class SymbiYosysEngine implements FormalEngine {
  /// Absolute path to the `sby` executable.
  final String sbyPath;

  /// Absolute path to the MSYS2 bash shell.
  final String bashPath;

  const SymbiYosysEngine({
    this.sbyPath  = r'E:\msys64\ucrt64\bin\sby',
    this.bashPath = r'E:\msys64\usr\bin\bash.exe',
  });

  static const _pathPrefix = '/ucrt64/bin:/usr/bin';

  @override
  String get engineName => 'SymbiYosys';

  @override
  Future<bool> isAvailable() async =>
      File(bashPath).existsSync() && File(sbyPath).existsSync();

  @override
  Future<FormalResult> verify(FormalContext context) async {
    final sw      = Stopwatch()..start();
    final workDir = await ProcessUtilities.makeTempDir('chiplens_formal');

    try {
      // 1 — Write RTL source
      await File('${workDir.path}/${SbyScriptBuilder.rtlFileName}')
          .writeAsString(context.rtlSource);

      // 2 — Write .sby script (relative file references; sby runs in workDir)
      await File('${workDir.path}/design.sby')
          .writeAsString(SbyScriptBuilder.build(context));

      // 3 — Invoke sby through bash with MSYS2 PATH prefix
      final cmd  = "PATH='$_pathPrefix:\$PATH' '${_posix(sbyPath)}' design.sby";
      final proc = await ProcessUtilities.runProcess(
        bashPath, ['-c', cmd],
        workingDirectory: workDir.path,
      );
      sw.stop();

      // 4 — Interpret output
      return SbyOutputParser.interpret(proc, sw.elapsed);
    } finally {
      await ProcessUtilities.cleanupDir(workDir);
    }
  }

  static String _posix(String path) => path.replaceAll(r'\', '/');
}
