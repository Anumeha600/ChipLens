// ─── DesignContext ────────────────────────────────────────────────────────────

/// Immutable input snapshot passed to every [KnowledgeProvider].
///
/// Providers read [rtlSource] directly (regex / lexer heuristics) and may
/// consult [parsedIr] when pre-computed structured data is available.
///
/// No mutable state — providers may run concurrently without coordination.
class DesignContext {
  /// Raw Verilog / SystemVerilog source text to analyse.
  final String rtlSource;

  /// Optional structured IR produced by an upstream parser
  /// (e.g. the result of `LocalFsmExtractor.extract()`).
  ///
  /// Providers check for well-known keys (`'states'`, `'edges'`,
  /// `'encodingStyle'`, …) but must fall back to heuristic analysis
  /// on [rtlSource] when this is `null` or missing a key.
  final Map<String, dynamic>? parsedIr;

  /// Optional hint about which module is the analysis root.
  final String? topModule;

  /// Extension configuration for future provider features.
  ///
  /// Providers may read named keys here without any global schema — callers
  /// add keys and the providers they enable consume them.
  final Map<String, dynamic> config;

  const DesignContext({
    required this.rtlSource,
    this.parsedIr,
    this.topModule,
    this.config = const {},
  });
}
