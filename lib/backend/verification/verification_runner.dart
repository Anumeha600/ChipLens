import 'dart:io';

import '../diagnostics/diagnostics.dart';
import '../tools/verilator_service.dart';
import '../tools/yosys_service.dart';
import '../tools/icarus_service.dart';
import 'process_utilities.dart';
import 'verification_result.dart';
import 'verification_tool.dart';

/// Orchestrates [VerificationTool] execution and exposes shared OS utilities.
///
/// Convenience methods ([runVerilator], [runYosys], [runIcarus]) each run the
/// appropriate tool and immediately parse the output into [Diagnostic] objects,
/// removing the duplicate helpers that previously existed in both the pipeline
/// and the repair engine.
///
/// To integrate a new tool, implement [VerificationTool] and call [execute].
/// No changes to this class or any other class are required.
class VerificationRunner {
  VerificationRunner._();

  static const _verilator = VerilatorService();
  static const _yosys     = YosysService();
  static const _icarus    = IcarusService();

  // ── Core entry point ────────────────────────────────────────────────────────

  /// Run [tool] with [context] and return the raw [VerificationResult].
  static Future<VerificationResult> execute(
    VerificationTool tool,
    VerificationContext context,
  ) =>
      tool.run(context);

  // ── Convenience: run + parse in one call ─────────────────────────────────

  /// Lint [rtlSource] with Verilator and return parsed [Diagnostic]s.
  /// Returns an empty list when the tool is unavailable or throws.
  static Future<List<Diagnostic>> runVerilator(String rtlSource) async {
    try {
      final r = await _verilator.run(VerificationContext(rtlSource: rtlSource));
      return VerilatorDiagnosticParser.parse(r.combined);
    } catch (_) {
      return [];
    }
  }

  /// Analyze [rtlSource] with Yosys and return parsed [Diagnostic]s.
  /// Returns an empty list when the tool is unavailable or throws.
  static Future<List<Diagnostic>> runYosys(String rtlSource) async {
    try {
      final r = await _yosys.run(VerificationContext(rtlSource: rtlSource));
      return YosysParser.parse(r.combined);
    } catch (_) {
      return [];
    }
  }

  /// Compile and simulate [rtlSource] with Icarus Verilog.
  ///
  /// Returns `(diagnostics, rawOutput)` — the raw combined stdout+stderr is
  /// forwarded to [CoverageAnalyzer] by the pipeline after this call returns.
  /// Returns `([], '')` when the tool is unavailable or throws.
  static Future<(List<Diagnostic>, String)> runIcarus(
    String rtlSource,
    String testbenchSource,
  ) async {
    try {
      final r = await _icarus.run(VerificationContext(
        rtlSource:       rtlSource,
        testbenchSource: testbenchSource,
      ));
      return (IcarusParser.parse(r.combined), r.combined);
    } catch (_) {
      return (<Diagnostic>[], '');
    }
  }

  // ── Shared OS utilities (delegate to ProcessUtilities) ───────────────────

  static Future<ProcessResult> runProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) =>
      ProcessUtilities.runProcess(executable, arguments,
          workingDirectory: workingDirectory);

  static Future<Directory> makeTempDir(String prefix) =>
      ProcessUtilities.makeTempDir(prefix);

  static Future<void> cleanupDir(Directory dir) =>
      ProcessUtilities.cleanupDir(dir);

  static Future<File> writeTempFile(
    String source, {
    required String prefix,
    required String extension,
  }) =>
      ProcessUtilities.writeTempFile(source,
          prefix: prefix, extension: extension);

  static Future<void> deleteFile(File file) =>
      ProcessUtilities.deleteFile(file);
}
