// ─── FormalPropertyLocation ───────────────────────────────────────────────────

/// Source location of a [FormalProperty] within the RTL design.
///
/// All fields except [file] are optional — a property derived from static
/// analysis may only have a file path, while one extracted from a parsed source
/// token can carry full line/column information.
class FormalPropertyLocation {
  /// Source file path (relative or absolute).
  final String file;

  /// 1-based line number, or `null` when unavailable.
  final int? line;

  /// 1-based column number, or `null` when unavailable.
  final int? column;

  /// Verilog/VHDL module name that contains the property, or `null`.
  final String? module;

  const FormalPropertyLocation({
    required this.file,
    this.line,
    this.column,
    this.module,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'file': file,
        if (line != null) 'line': line,
        if (column != null) 'column': column,
        if (module != null) 'module': module,
      };

  factory FormalPropertyLocation.fromJson(Map<String, dynamic> json) =>
      FormalPropertyLocation(
        file:   json['file']   as String,
        line:   json['line']   as int?,
        column: json['column'] as int?,
        module: json['module'] as String?,
      );

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      other is FormalPropertyLocation &&
      other.file   == file   &&
      other.line   == line   &&
      other.column == column &&
      other.module == module;

  @override
  int get hashCode => Object.hash(file, line, column, module);

  @override
  String toString() {
    final buf = StringBuffer(file);
    if (line   != null) buf.write(':$line');
    if (column != null) buf.write(':$column');
    return buf.toString();
  }
}
