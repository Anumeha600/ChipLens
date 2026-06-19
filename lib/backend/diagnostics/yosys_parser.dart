import 'diagnostic.dart';
import 'diagnostic_source.dart';

/// Parses Yosys stdout/stderr into a list of [Diagnostic] objects.
///
/// Recognised patterns:
/// - `ERROR: <message>`
/// - `Warning: <message>`
/// - `<file>:<line>: ERROR: <message>`
/// - `<file>:<line>: Warning: <message>`
///
/// The rule ID is derived from message keywords; unrecognised messages fall
/// back to `yosys_error` or `yosys_warning`.
class YosysParser {
  // Contextual: file:line: ERROR/Warning: msg
  static final _locatedRe = RegExp(
    r'^(.+?):(\d+):\s*(ERROR|Warning)\s*:\s*(.+)$',
    caseSensitive: true,
  );

  // Plain: ERROR/Warning: msg  (Yosys uses capital-W Warning consistently)
  static final _plainRe = RegExp(
    r'^(ERROR|Warning)\s*:\s*(.+)$',
    caseSensitive: true,
  );

  /// Parse [output] (combined stdout + stderr) into [Diagnostic] objects.
  static List<Diagnostic> parse(String output) {
    final results = <Diagnostic>[];
    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final located = _locatedRe.firstMatch(line);
      if (located != null) {
        final file     = located.group(1)!;
        final lineNum  = int.tryParse(located.group(2)!) ?? 0;
        final level    = located.group(3)!;
        final message  = located.group(4)!.trim();
        results.add(_build(level, message,
            location: SourceLocation(line: lineNum, file: file)));
        continue;
      }

      final plain = _plainRe.firstMatch(line);
      if (plain != null) {
        final level   = plain.group(1)!;
        final message = plain.group(2)!.trim();
        results.add(_build(level, message));
      }
    }
    return results;
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Diagnostic _build(
    String level,
    String message, {
    SourceLocation? location,
  }) {
    final severity = level == 'ERROR' ? 'error' : 'warning';
    final id       = _inferRuleId(message, severity);

    return Diagnostic(
      id:          id,
      severity:    severity,
      title:       _titleFor(id),
      description: message,
      location:    location,
      source:      DiagnosticSource.yosys,
    );
  }

  static String _inferRuleId(String message, String severity) {
    final lower = message.toLowerCase();

    if (lower.contains('latch')) return 'yosys_infer_latch';
    if (lower.contains('multiple driver') || lower.contains('multiple_driver')) {
      return 'yosys_multiple_drivers';
    }
    if (lower.contains('undriven') || lower.contains('not driven')) {
      return 'yosys_undriven';
    }
    if (lower.contains('module not found') ||
        lower.contains("can't resolve") ||
        lower.contains('unknown module')) {
      return 'yosys_missing_module';
    }
    if (lower.contains('combinatorial loop') ||
        lower.contains('loop detected') ||
        lower.contains('combinational loop')) {
      return 'yosys_loop';
    }
    if (lower.contains('syntax error') || lower.contains('parse error')) {
      return 'yosys_syntax_error';
    }

    return severity == 'error' ? 'yosys_error' : 'yosys_warning';
  }

  static String _titleFor(String id) {
    const titles = <String, String>{
      'yosys_infer_latch':      'Latch Inferred',
      'yosys_multiple_drivers': 'Multiple Drivers',
      'yosys_undriven':         'Undriven Signal',
      'yosys_missing_module':   'Missing Module',
      'yosys_loop':             'Combinatorial Loop',
      'yosys_syntax_error':     'Syntax Error',
      'yosys_error':            'Yosys Error',
      'yosys_warning':          'Yosys Warning',
    };
    return titles[id] ?? 'Yosys Diagnostic';
  }
}
