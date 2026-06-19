import 'diagnostic_source.dart';

/// File / line / column location inside a Verilog source file.
class SourceLocation {
  final int line;
  final int? column;
  final String? file;

  const SourceLocation({required this.line, this.column, this.file});

  @override
  String toString() {
    final col  = column != null ? ':$column' : '';
    final name = file   != null ? '$file:'   : '';
    return '$name$line$col';
  }
}

/// A single diagnostic from any analysis pass (internal rule engine or
/// external tool such as Verilator).
///
/// Diagnostics are converted to [QualityWarning] objects before they enter
/// the [QualityReport], keeping the UI free from source-awareness.
class Diagnostic {
  /// Rule identifier — e.g. `'missing_reset'`, `'verilator_unused'`.
  final String id;

  /// Severity level: `'error'`, `'warning'`, `'info'`, or `'hint'`.
  final String severity;

  /// Short human-readable label.
  final String title;

  /// Full diagnostic explanation.
  final String description;

  /// Source location if available (typically only for Verilator diagnostics).
  final SourceLocation? location;

  /// Optional remediation hint.
  final String? quickFix;

  /// Which subsystem produced this diagnostic.
  final DiagnosticSource source;

  const Diagnostic({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    this.location,
    this.quickFix,
    this.source = DiagnosticSource.internal,
  });
}
