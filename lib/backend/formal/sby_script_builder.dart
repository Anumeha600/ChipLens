import 'formal_context.dart';

// ─── SbyScriptBuilder ─────────────────────────────────────────────────────────

/// Generates a SymbiYosys `.sby` configuration script from a [FormalContext].
///
/// All string generation is centralised here so that [SymbiYosysEngine] stays
/// free of script-formatting logic and [SbyScriptBuilder] can be tested in
/// isolation as a pure function.
///
/// The generated script assumes the RTL file has been written as `design.v`
/// in the engine's working directory; the `[files]` section references that
/// name so SymbiYosys copies it into its own task directory.
abstract class SbyScriptBuilder {
  SbyScriptBuilder._();

  /// Basename of the RTL file written to the working directory.
  static const rtlFileName = 'design.v';

  /// Build a complete `.sby` script string from [context].
  ///
  /// [FormalMode.bmc] adds a `depth` line; [FormalMode.prove] and
  /// [FormalMode.cover] omit it (SymbiYosys manages depth internally for those
  /// strategies).
  static String build(FormalContext context) {
    final buf = StringBuffer();

    // ── [options] ──────────────────────────────────────────────────────────
    buf.writeln('[options]');
    buf.writeln('mode ${context.mode.name}');
    if (context.mode == FormalMode.bmc) {
      buf.writeln('depth ${context.depth}');
    }
    buf.writeln();

    // ── [engines] ─────────────────────────────────────────────────────────
    buf.writeln('[engines]');
    buf.writeln('smtbmc');
    buf.writeln();

    // ── [script] ──────────────────────────────────────────────────────────
    buf.writeln('[script]');
    buf.writeln('read -formal $rtlFileName');
    if (context.topModule != null) {
      buf.writeln('prep -top ${context.topModule}');
    } else {
      buf.writeln('prep');
    }
    buf.writeln();

    // ── [files] ───────────────────────────────────────────────────────────
    buf.writeln('[files]');
    buf.writeln(rtlFileName);

    return buf.toString();
  }
}
