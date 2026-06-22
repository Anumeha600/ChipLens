// ─── ExplanationFormat ────────────────────────────────────────────────────────

/// Output format produced by [ExplanationFormatter].
///
/// New values may be added without modifying [ExplanationFormatter]'s
/// existing branches — just extend the switch.
enum ExplanationFormat {
  /// Key-value pairs, one per line — machine-readable and human-readable.
  structured,

  /// GitHub-flavoured Markdown with headings and a summary table.
  markdown,

  /// Prose-style output with no markup — suitable for terminal display.
  plainText,

  /// Minimal JSON object — suitable for logging or API transport.
  json,
}

// ─── ExplanationContext ───────────────────────────────────────────────────────

/// Immutable configuration object for one [VerificationExplainer] pass.
///
/// Controls which fields are included in the generated explanations and
/// what output format [ExplanationFormatter] should produce.
///
/// Invariants:
/// - All fields are `final` — use [copyWith] to derive variants.
/// - [maximumEvidence] = -1 means include all evidence ids.
class ExplanationContext {
  /// When `true`, semantic evidence ids are included in each trace.
  final bool includeEvidence;

  /// When `true`, the ranking explanation string is included.
  final bool includeRanking;

  /// When `true`, the confidence score is included.
  final bool includeConfidence;

  /// When `true`, [FormalProperty.metadata] is carried into
  /// [VerificationExplanation.metadata].
  final bool includeMetadata;

  /// Format [ExplanationFormatter] will use when [format] is called.
  final ExplanationFormat format;

  /// Maximum number of evidence ids to include per explanation.
  ///
  /// `-1` (default) means no limit.
  final int maximumEvidence;

  const ExplanationContext({
    this.includeEvidence   = true,
    this.includeRanking    = true,
    this.includeConfidence = true,
    this.includeMetadata   = true,
    this.format            = ExplanationFormat.structured,
    this.maximumEvidence   = -1,
  });

  // ── Immutable copy ────────────────────────────────────────────────────────

  ExplanationContext copyWith({
    bool?             includeEvidence,
    bool?             includeRanking,
    bool?             includeConfidence,
    bool?             includeMetadata,
    ExplanationFormat? format,
    int?              maximumEvidence,
  }) =>
      ExplanationContext(
        includeEvidence:   includeEvidence   ?? this.includeEvidence,
        includeRanking:    includeRanking    ?? this.includeRanking,
        includeConfidence: includeConfidence ?? this.includeConfidence,
        includeMetadata:   includeMetadata   ?? this.includeMetadata,
        format:            format            ?? this.format,
        maximumEvidence:   maximumEvidence   ?? this.maximumEvidence,
      );

  // ── Equality ─────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExplanationContext &&
          includeEvidence   == other.includeEvidence &&
          includeRanking    == other.includeRanking &&
          includeConfidence == other.includeConfidence &&
          includeMetadata   == other.includeMetadata &&
          format            == other.format &&
          maximumEvidence   == other.maximumEvidence;

  @override
  int get hashCode => Object.hash(
      includeEvidence, includeRanking, includeConfidence,
      includeMetadata, format, maximumEvidence);

  @override
  String toString() =>
      'ExplanationContext(format=$format, maxEvidence=$maximumEvidence)';
}
