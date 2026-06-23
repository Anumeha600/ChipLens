// ─── CounterexampleSummary ────────────────────────────────────────────────────

/// Human-readable summary of the counterexample analysis.
///
/// All fields are derived deterministically from [FormalResult] data and the
/// computed [CounterexampleClassification].  No AI or randomness is involved.
///
/// Invariants:
/// - All fields are non-null strings.
/// - [dominantCategory] is the [CounterexampleClassification.name] of the
///   computed classification.
class CounterexampleSummary {
  /// One-sentence description of the overall verification outcome.
  final String overview;

  /// Identifier of the first failed property, or `'None'` when there are none.
  final String primaryFailure;

  /// Identifier of the first property to fail, or `'None'` when there are none.
  ///
  /// Equivalent to [primaryFailure] unless failure ordering is refined in a
  /// future waveform-aware implementation.
  final String earliestFailure;

  /// The [CounterexampleClassification.name] string of the dominant category.
  final String dominantCategory;

  const CounterexampleSummary({
    required this.overview,
    required this.primaryFailure,
    required this.earliestFailure,
    required this.dominantCategory,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterexampleSummary &&
          overview         == other.overview         &&
          primaryFailure   == other.primaryFailure   &&
          earliestFailure  == other.earliestFailure  &&
          dominantCategory == other.dominantCategory;

  @override
  int get hashCode =>
      Object.hash(overview, primaryFailure, earliestFailure, dominantCategory);

  @override
  String toString() =>
      'CounterexampleSummary(primary=$primaryFailure, '
      'category=$dominantCategory)';
}
