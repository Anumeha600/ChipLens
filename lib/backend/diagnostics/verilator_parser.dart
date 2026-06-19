import 'diagnostic.dart';
import 'diagnostic_source.dart';

/// Parses Verilator lint output (stdout + stderr) into [Diagnostic] objects.
///
/// Verilator writes one diagnostic per line in these formats:
/// ```
/// %Error: file.v:10:5: Unknown module name: 'foo'
/// %Warning-UNUSED: file.v:5:3: Signal 'x' is not used
/// %Warning-WIDTH: file.v:12: Operator '+' width mismatch
/// %Error: Exiting due to 1 error(s)          ← summary line, ignored
/// ```
class VerilatorDiagnosticParser {
  static final _diagRe = RegExp(
    r'^%(Error|Warning)(?:-(\w+))?\s*:\s*(.+?):(\d+)(?::(\d+))?\s*:\s*(.+)$',
  );
  static final _summaryRe = RegExp(r'^%(Error|Warning)\s*:\s*Exiting');

  /// Parse [output] (combined stdout + stderr) into a list of [Diagnostic]s.
  static List<Diagnostic> parse(String output) {
    final diags = <Diagnostic>[];

    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (_summaryRe.hasMatch(line)) continue;

      final m = _diagRe.firstMatch(line);
      if (m == null) continue;

      final level    = m.group(1)!;            // 'Error' | 'Warning'
      final code     = m.group(2);             // 'UNUSED', 'WIDTH', null
      final filePath = m.group(3)!;
      final lineNum  = int.parse(m.group(4)!);
      final colNum   = m.group(5) != null ? int.parse(m.group(5)!) : null;
      final text     = m.group(6)!.trim();

      final severity = level == 'Error' ? 'error' : 'warning';

      // Derive a stable rule id: 'verilator_unused', 'verilator_width', …
      final id = code != null
          ? 'verilator_${code.toLowerCase()}'
          : (level == 'Error' ? 'verilator_error' : 'verilator_warning');

      final title = code != null ? 'Verilator: $code' : 'Verilator $level';

      // Trim the temp-file path to just the basename so the UI shows a
      // readable name rather than an opaque temp-dir path.
      final filename = filePath
          .split('/')
          .last
          .split(r'\')
          .last;

      diags.add(Diagnostic(
        id:          id,
        severity:    severity,
        title:       title,
        description: text,
        location:    SourceLocation(line: lineNum, column: colNum, file: filename),
        source:      DiagnosticSource.verilator,
      ));
    }

    return diags;
  }
}
