// ─── RecommendationPriority ───────────────────────────────────────────────────

/// Priority of a [CoverageRecommendation].
///
/// Values are ordered lowest to highest so that integer index arithmetic
/// can be used to sort recommendations (descending = critical first).
enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

// ─── RecommendationCategory ───────────────────────────────────────────────────

/// Coverage dimension that a [CoverageRecommendation] targets.
enum RecommendationCategory {
  stateCoverage,
  transitionCoverage,
  branchCoverage,
  toggleCoverage,
  conditionCoverage,
  lineCoverage,
  verificationPlanning,
  testbench,
}

// ─── CoverageRecommendation ───────────────────────────────────────────────────

/// One actionable recommendation for improving verification coverage.
///
/// Generated deterministically from [CoverageReport] data; never from AI or
/// randomness.  Ordered by [RecommendationPriority] (critical first) inside
/// [CoverageAssessment.recommendations].
///
/// Invariants:
/// - [metadata] is unmodifiable.
/// - All fields are non-null.
class CoverageRecommendation {
  /// Short label shown in summary views.
  final String title;

  /// Full explanation of the issue and what to do about it.
  final String description;

  /// How urgently this recommendation should be addressed.
  final RecommendationPriority priority;

  /// Which coverage dimension this recommendation targets.
  final RecommendationCategory category;

  /// Arbitrary annotations for tooling extensions.
  final Map<String, dynamic> metadata;

  CoverageRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    Map<String, dynamic>? metadata,
  }) : metadata = Map.unmodifiable(metadata ?? const {});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverageRecommendation &&
          title    == other.title    &&
          priority == other.priority &&
          category == other.category;

  @override
  int get hashCode => Object.hash(title, priority, category);

  @override
  String toString() =>
      'CoverageRecommendation(${priority.name}: $title)';
}
