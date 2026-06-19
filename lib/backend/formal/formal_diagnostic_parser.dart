import '../diagnostics/diagnostic.dart';
import '../diagnostics/diagnostic_source.dart';
import 'formal_result.dart';

// ─── FormalDiagnosticParser ───────────────────────────────────────────────────

/// Converts a [FormalResult] into [Diagnostic] objects that can be fed into
/// [DiagnosticEngine].
///
/// Separation of concerns:
/// - [FormalEngine] implementations capture raw tool output and classify
///   properties as proven / failed / unknown.
/// - [FormalDiagnosticParser] translates that classification into the
///   [Diagnostic] format understood by the rest of the ChipLens pipeline.
///
/// This keeps [DiagnosticEngine] engine-agnostic: it receives [Diagnostic]
/// objects regardless of whether they came from Verilator, Yosys, Icarus, or
/// a formal tool.
abstract class FormalDiagnosticParser {
  FormalDiagnosticParser._();

  // ── Output scanning ────────────────────────────────────────────────────────

  // Engine-level error lines: "ERROR:" prefix or "error:" (not inside filenames)
  static final _engineErrorRe = RegExp(
    r'^(?:ERROR|Error)\s*:\s*(.+)$',
    multiLine: false,
  );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Convert [result] into a list of [Diagnostic] objects.
  ///
  /// - Each entry in [FormalResult.failedProperties] → severity `'error'`.
  /// - Each entry in [FormalResult.unknownProperties] → severity `'warning'`.
  /// - Engine-level errors in raw output (not already in property lists) →
  ///   severity `'error'` with id `'formal_engine_error'`.
  /// - Proven-only results produce no diagnostics (success is silent).
  static List<Diagnostic> parse(FormalResult result) {
    final diags = <Diagnostic>[];

    // ── Failed properties ────────────────────────────────────────────────────
    for (final prop in result.failedProperties) {
      diags.add(Diagnostic(
        id:          'formal_property_failed',
        severity:    'error',
        title:       'Formal assertion failed',
        description: 'Property "$prop" failed — a counterexample trace exists.',
        source:      DiagnosticSource.formal,
        quickFix:    'Inspect the counterexample and correct the RTL or strengthen the assertion.',
      ));
    }

    // ── Unknown / inconclusive properties ────────────────────────────────────
    for (final prop in result.unknownProperties) {
      diags.add(Diagnostic(
        id:          'formal_property_unknown',
        severity:    'warning',
        title:       'Formal property inconclusive',
        description: 'Property "$prop" could not be determined within the '
            'given depth or timeout.',
        source:      DiagnosticSource.formal,
        quickFix:    'Increase the BMC depth or switch to unbounded prove mode.',
      ));
    }

    // ── Engine-level errors not already in property lists ────────────────────
    for (final line in result.combined.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final m = _engineErrorRe.firstMatch(t);
      if (m == null) continue;
      diags.add(Diagnostic(
        id:          'formal_engine_error',
        severity:    'error',
        title:       'Formal engine error',
        description: m.group(1)!.trim(),
        source:      DiagnosticSource.formal,
      ));
    }

    return diags;
  }
}
