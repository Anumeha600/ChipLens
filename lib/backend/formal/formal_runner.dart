import '../diagnostics/diagnostic.dart';
import 'formal_diagnostic_parser.dart';
import 'formal_engine.dart';
import 'formal_result.dart';
import 'symbiyosys_engine.dart';

// ─── FormalRunner ─────────────────────────────────────────────────────────────

/// Coordinates [FormalEngine] execution and exposes convenience helpers.
///
/// Mirrors the role of [VerificationRunner] in the simulation framework:
/// it contains **no tool-specific logic** — every concrete detail lives inside
/// the [FormalEngine] implementation.
///
/// To integrate a new formal tool, implement [FormalEngine] and call [run].
/// No changes to [FormalRunner] or any other class are required.
abstract class FormalRunner {
  FormalRunner._();

  static const _defaultEngine = SymbiYosysEngine();

  // ── Core entry point ──────────────────────────────────────────────────────

  /// Run formal verification with [context] using [engine].
  ///
  /// [engine] defaults to [SymbiYosysEngine].  Pass any [FormalEngine]
  /// implementation to switch backends without touching any other code.
  static Future<FormalResult> run(
    FormalContext context, {
    FormalEngine? engine,
  }) =>
      (engine ?? _defaultEngine).verify(context);

  // ── Convenience: run + parse in one call ──────────────────────────────────

  /// Run SymbiYosys on [rtlSource] and return parsed [Diagnostic]s.
  ///
  /// Returns an empty list when SymbiYosys is unavailable or the subprocess
  /// throws.
  static Future<List<Diagnostic>> runSymbiYosys(
    String rtlSource, {
    FormalMode mode  = FormalMode.bmc,
    int depth        = 20,
    String? topModule,
  }) async {
    try {
      final result = await run(FormalContext(
        rtlSource: rtlSource,
        mode:      mode,
        depth:     depth,
        topModule: topModule,
      ));
      return FormalDiagnosticParser.parse(result);
    } catch (_) {
      return [];
    }
  }
}
