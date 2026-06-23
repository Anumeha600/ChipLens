// ─── DiagnosticContext ────────────────────────────────────────────────────────

/// Immutable configuration that drives [DiagnosticsEngine].
///
/// All fields have sensible defaults so callers only override what they need.
///
/// Invariants:
/// - [maximumIssues] must be >= -1 (-1 means no limit).
///
/// Future extension points:
/// - Add [minimumSeverity] to suppress low-severity issues.
/// - Add [categoryFilter] to restrict which [DiagnosticCategory] values appear.
class DiagnosticContext {
  /// When `true`, [DiagnosticReport.statistics] is populated.
  final bool includeStatistics;

  /// When `true`, each [DiagnosticIssue.evidence] list is populated with
  /// supporting data from upstream framework outputs.
  final bool includeEvidence;

  /// When `true`, issues that carry actionable recommendations are included.
  final bool includeRecommendations;

  /// When `true`, [DiagnosticReport.overallConfidence] is computed.
  final bool includeConfidence;

  /// Maximum number of issues to include in [DiagnosticReport.issues].
  /// -1 means no limit.
  final int maximumIssues;

  DiagnosticContext({
    this.includeStatistics      = true,
    this.includeEvidence        = true,
    this.includeRecommendations = true,
    this.includeConfidence      = true,
    this.maximumIssues          = -1,
  }) {
    if (maximumIssues < -1) {
      throw ArgumentError.value(
        maximumIssues,
        'maximumIssues',
        'maximumIssues must be >= -1 (-1 means no limit)',
      );
    }
  }

  /// Returns a copy with only the specified fields overridden.
  DiagnosticContext copyWith({
    bool? includeStatistics,
    bool? includeEvidence,
    bool? includeRecommendations,
    bool? includeConfidence,
    int?  maximumIssues,
  }) =>
      DiagnosticContext(
        includeStatistics:      includeStatistics      ?? this.includeStatistics,
        includeEvidence:        includeEvidence        ?? this.includeEvidence,
        includeRecommendations: includeRecommendations ?? this.includeRecommendations,
        includeConfidence:      includeConfidence      ?? this.includeConfidence,
        maximumIssues:          maximumIssues          ?? this.maximumIssues,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticContext &&
          includeStatistics      == other.includeStatistics      &&
          includeEvidence        == other.includeEvidence        &&
          includeRecommendations == other.includeRecommendations &&
          includeConfidence      == other.includeConfidence      &&
          maximumIssues          == other.maximumIssues;

  @override
  int get hashCode => Object.hash(
        includeStatistics, includeEvidence, includeRecommendations,
        includeConfidence, maximumIssues);

  @override
  String toString() =>
      'DiagnosticContext(maxIssues=$maximumIssues)';
}
