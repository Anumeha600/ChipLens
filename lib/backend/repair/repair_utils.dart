// Shared text and regex helpers used across the repair framework.
// No imports from other repair modules — safe to import from any layer.
abstract class RepairUtils {
  RepairUtils._();

  /// Return the leading whitespace of the last non-empty line in [text].
  static String lastLineIndent(String text) {
    final lines = text.split('\n');
    for (final line in lines.reversed) {
      if (line.trim().isNotEmpty) {
        final m = RegExp(r'^([ \t]*)').firstMatch(line);
        return m?.group(1) ?? '      ';
      }
    }
    return '      ';
  }

  /// Return the leading whitespace of the first non-empty line in [body].
  static String detectBodyIndent(String body) {
    for (final line in body.split('\n')) {
      if (line.trim().isNotEmpty) {
        final m = RegExp(r'^([ \t]+)').firstMatch(line);
        return m?.group(1) ?? '  ';
      }
    }
    return '  ';
  }

  /// Return true if [body] contains any blocking assignment (= but not ==, !=, <=, >=).
  static bool hasBlockingAssignment(String body) =>
      RegExp(r'(?<![<>!=])=(?![>=])').hasMatch(body);

  /// Replace blocking assignments (=) with non-blocking (<=) in a clocked
  /// always-block body, skipping Verilog keywords.
  static String replaceBlockingWithNonBlocking(String body) {
    const keywords = {
      'if', 'else', 'for', 'while', 'repeat', 'forever',
      'case', 'casex', 'casez', 'begin', 'end',
    };
    return body.replaceAllMapped(
      RegExp(r'(\b\w+\b)(\s*)(=)(\s*)(?![>=])', multiLine: true),
      (m) {
        final lhs = m.group(1)!;
        if (keywords.contains(lhs)) return m.group(0)!;
        return '$lhs${m.group(2)!}<=${m.group(4)!}';
      },
    );
  }
}
