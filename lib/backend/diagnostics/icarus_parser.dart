import 'diagnostic.dart';
import 'diagnostic_source.dart';

/// Parses Icarus Verilog (iverilog compile + vvp simulation) output into
/// [Diagnostic] objects.
///
/// Recognised patterns:
///
/// Compile-time (iverilog):
/// - `<file>:<line>: error: <message>`
/// - `<file>:<line>: warning: <message>`
/// - `error: <message>`          (no file/line context)
/// - `warning: <message>`
///
/// Runtime (vvp):
/// - `<file>:<line>: $stop called at <n>`
///
/// Summary lines such as `N error(s) during elaboration.` are ignored.
class IcarusParser {
  // file:line: error/warning: msg
  static final _locatedRe = RegExp(
    r'^(.+?):(\d+):\s*(error|warning)\s*:\s*(.+)$',
    caseSensitive: false,
  );

  // plain error/warning: msg (no file/line)
  static final _plainRe = RegExp(
    r'^(error|warning)\s*:\s*(.+)$',
    caseSensitive: false,
  );

  // vvp runtime $stop — file:line: $stop called at N
  static final _stopRe = RegExp(
    r'^(.+?):(\d+):\s*\$stop\s+called',
    caseSensitive: false,
  );

  // Summary line — "N error(s) during elaboration." — skip it
  static final _summaryRe = RegExp(
    r'^\d+\s+error\(s\)',
    caseSensitive: false,
  );

  /// Parse [output] (combined iverilog + vvp stdout/stderr) into [Diagnostic]
  /// objects tagged with [DiagnosticSource.icarus].
  static List<Diagnostic> parse(String output) {
    final results = <Diagnostic>[];
    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (_summaryRe.hasMatch(line)) continue;

      final stop = _stopRe.firstMatch(line);
      if (stop != null) {
        results.add(_build(
          'error',
          '\$stop called during simulation',
          location: SourceLocation(
            line: int.tryParse(stop.group(2)!) ?? 0,
            file: stop.group(1),
          ),
          ruleId: 'icarus_simulation_stop',
        ));
        continue;
      }

      final located = _locatedRe.firstMatch(line);
      if (located != null) {
        final file    = located.group(1)!;
        final lineNum = int.tryParse(located.group(2)!) ?? 0;
        final level   = located.group(3)!.toLowerCase();
        final message = located.group(4)!.trim();
        results.add(_build(level, message,
            location: SourceLocation(line: lineNum, file: file)));
        continue;
      }

      final plain = _plainRe.firstMatch(line);
      if (plain != null) {
        final level   = plain.group(1)!.toLowerCase();
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
    String? ruleId,
  }) {
    final severity = level == 'error' ? 'error' : 'warning';
    final id       = ruleId ?? _inferRuleId(message, severity);
    return Diagnostic(
      id:          id,
      severity:    severity,
      title:       _titleFor(id),
      description: message,
      location:    location,
      source:      DiagnosticSource.icarus,
    );
  }

  static String _inferRuleId(String message, String severity) {
    final lower = message.toLowerCase();

    if (lower.contains('syntax error'))                              return 'icarus_syntax_error';
    if (lower.contains('implicit declaration'))                      return 'icarus_implicit_wire';
    if (lower.contains('unknown module') ||
        lower.contains('no module named') ||
        lower.contains('module type'))                               return 'icarus_undefined_module';
    if (lower.contains('port') && lower.contains('connect'))        return 'icarus_port_mismatch';
    if (lower.contains('type mismatch') ||
        lower.contains('width mismatch'))                           return 'icarus_type_error';
    if (lower.contains('not defined') ||
        lower.contains('undefined'))                                return 'icarus_undefined';
    if (lower.contains('\$stop') || lower.contains('simulation'))   return 'icarus_simulation_stop';

    return severity == 'error' ? 'icarus_error' : 'icarus_warning';
  }

  static String _titleFor(String id) {
    const titles = <String, String>{
      'icarus_syntax_error':      'Syntax Error',
      'icarus_implicit_wire':     'Implicit Wire Declaration',
      'icarus_undefined_module':  'Undefined Module',
      'icarus_port_mismatch':     'Port Connection Mismatch',
      'icarus_type_error':        'Type/Width Mismatch',
      'icarus_undefined':         'Undefined Reference',
      'icarus_simulation_stop':   'Simulation Stop',
      'icarus_error':             'Icarus Error',
      'icarus_warning':           'Icarus Warning',
    };
    return titles[id] ?? 'Icarus Diagnostic';
  }
}
