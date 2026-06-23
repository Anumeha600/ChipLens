import 'coverage_confidence.dart';
import 'coverage_recommendation.dart';
import 'coverage_risk.dart';
import 'coverage_statistics.dart';
import 'coverage_summary.dart';

// ─── CoverageAssessment ───────────────────────────────────────────────────────

/// Immutable high-level interpretation of one [CoverageReport].
///
/// Produced by [CoverageIntelligenceEngine.assess].  Contains every derived
/// artifact — summary, risk, confidence, ordered recommendations, and
/// statistics — in a single value object.
///
/// Invariants:
/// - [recommendations] is unmodifiable.
/// - [isHealthy] is `true` when risk is [CoverageRisk.minimal] or
///   [CoverageRisk.low].
/// - All fields are non-null.
///
/// Future extension points:
/// - Add [historicalTrend] for coverage delta reports.
/// - Add [completenessScore] for CI/CD quality gates.
class CoverageAssessment {
  /// Human-readable interpretation of coverage quality.
  final CoverageSummary summary;

  /// Overall verification risk level.
  final CoverageRisk risk;

  /// Confidence in verification completeness.
  final CoverageConfidence confidence;

  /// Ordered list of actionable recommendations (critical first).
  final List<CoverageRecommendation> recommendations;

  /// Derived counts and fractions summarising the assessment.
  final CoverageStatistics statistics;

  CoverageAssessment({
    required this.summary,
    required this.risk,
    required this.confidence,
    required List<CoverageRecommendation> recommendations,
    required this.statistics,
  }) : recommendations = List.unmodifiable(recommendations);

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get hasRecommendations => recommendations.isNotEmpty;

  bool get isHealthy =>
      risk == CoverageRisk.minimal || risk == CoverageRisk.low;

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverageAssessment &&
          summary    == other.summary    &&
          risk       == other.risk       &&
          confidence == other.confidence &&
          statistics == other.statistics &&
          _recsEqual(recommendations, other.recommendations);

  static bool _recsEqual(
    List<CoverageRecommendation> a,
    List<CoverageRecommendation> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(summary, risk, confidence, statistics, recommendations.length);

  @override
  String toString() =>
      'CoverageAssessment(risk=${risk.name}, '
      'confidence=${confidence.name}, recs=${recommendations.length})';
}
