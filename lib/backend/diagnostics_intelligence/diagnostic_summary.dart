// ─── DiagnosticSummary ────────────────────────────────────────────────────────

/// High-level human-readable description of verification health.
///
/// Produced by [DiagnosticsEngine.analyze] from the full [DiagnosticReport]
/// contents.  All fields are non-null strings.
///
/// Invariants:
/// - All fields are non-null.
/// - [verificationHealth] is one of: 'healthy', 'acceptable', 'reduced',
///   'degraded', 'failing'.
///
/// Future extension points:
/// - Add [healthScore] for numeric dashboard display.
/// - Add [trendDirection] for historical comparison.
class DiagnosticSummary {
  /// One-sentence overview of the verification session outcome.
  final String overview;

  /// Title of the highest-priority [DiagnosticIssue], or 'None'.
  final String primaryIssue;

  /// Name of the [DiagnosticCategory] with the most issues.
  final String dominantCategory;

  /// Short health label: 'healthy', 'acceptable', 'reduced', 'degraded',
  /// or 'failing'.
  final String verificationHealth;

  const DiagnosticSummary({
    required this.overview,
    required this.primaryIssue,
    required this.dominantCategory,
    required this.verificationHealth,
  });

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticSummary &&
          overview            == other.overview            &&
          primaryIssue        == other.primaryIssue        &&
          dominantCategory    == other.dominantCategory    &&
          verificationHealth  == other.verificationHealth;

  @override
  int get hashCode =>
      Object.hash(overview, primaryIssue, dominantCategory, verificationHealth);

  @override
  String toString() =>
      'DiagnosticSummary(health=$verificationHealth, primary="$primaryIssue")';
}
