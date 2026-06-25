// ─── RtlPreprocessor ──────────────────────────────────────────────────────────

/// Static utilities for pre-processing RTL source text before structural
/// analysis.
///
/// Assumptions:
/// - Input is synthesizable Verilog or SystemVerilog source.
/// - String literals are not expected in synthesizable RTL; no special
///   handling is provided for quoted strings.
/// - The character-level lexer correctly handles `//` inside `/* */` (the
///   block comment takes precedence) and `/*` inside `//` (the line comment
///   takes precedence).
class RtlPreprocessor {
  RtlPreprocessor._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Return a copy of [rtl] with all Verilog/SystemVerilog comments removed.
  ///
  /// Single-line comments (`// …`) are deleted from the `//` delimiter to the
  /// end of the line.  The terminating newline is preserved so that line
  /// numbers remain stable for diagnostic messages.
  ///
  /// Block comments (`/* … */`) are replaced character-for-character with
  /// spaces, with the exception that embedded newlines are preserved.  This
  /// keeps token column positions accurate.
  ///
  /// The original [rtl] string is never modified.
  static String stripComments(String rtl) {
    final buf = StringBuffer();
    final len = rtl.length;
    int i = 0;

    while (i < len) {
      final ch = rtl[i];

      // ── Block comment ──────────────────────────────────────────────────────
      if (ch == '/' && i + 1 < len && rtl[i + 1] == '*') {
        i += 2; // consume /*
        while (i < len) {
          if (rtl[i] == '*' && i + 1 < len && rtl[i + 1] == '/') {
            i += 2; // consume */
            break;
          }
          // Preserve newlines; replace everything else with a space so that
          // column positions of subsequent tokens remain unchanged.
          buf.write(rtl[i] == '\n' ? '\n' : ' ');
          i++;
        }
        continue;
      }

      // ── Line comment ───────────────────────────────────────────────────────
      if (ch == '/' && i + 1 < len && rtl[i + 1] == '/') {
        i += 2; // consume //
        while (i < len && rtl[i] != '\n') {
          i++; // skip comment body (newline written on next outer iteration)
        }
        continue;
      }

      // ── Normal character ───────────────────────────────────────────────────
      buf.write(ch);
      i++;
    }

    return buf.toString();
  }
}
