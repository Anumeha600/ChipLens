// ─── CoverageSummary ──────────────────────────────────────────────────────────

/// Human-readable interpretation of a [CoverageReport].
///
/// Produced by [CoverageIntelligenceEngine] as part of [CoverageAssessment].
/// All fields are derived deterministically from [CoverageReport] data; no
/// user input or AI is involved.
///
/// Invariants:
/// - All fields are non-null, non-empty strings.
/// - [strongestDimension] and [weakestDimension] are one of:
///   `'state'`, `'transition'`, `'branch'`, `'toggle'`, `'condition'`, `'line'`.
class CoverageSummary {
  /// One-sentence description of overall coverage quality.
  final String overview;

  /// The coverage dimension with the highest fraction.
  final String strongestDimension;

  /// The coverage dimension with the lowest fraction.
  final String weakestDimension;

  /// The most critical coverage gap or issue detected.
  final String dominantIssue;

  const CoverageSummary({
    required this.overview,
    required this.strongestDimension,
    required this.weakestDimension,
    required this.dominantIssue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverageSummary &&
          overview            == other.overview            &&
          strongestDimension  == other.strongestDimension  &&
          weakestDimension    == other.weakestDimension    &&
          dominantIssue       == other.dominantIssue;

  @override
  int get hashCode =>
      Object.hash(overview, strongestDimension, weakestDimension, dominantIssue);

  @override
  String toString() =>
      'CoverageSummary(strongest=$strongestDimension, '
      'weakest=$weakestDimension)';
}
