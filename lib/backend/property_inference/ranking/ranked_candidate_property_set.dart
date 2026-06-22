import 'ranking_result.dart';

// ─── RankedCandidatePropertySet ───────────────────────────────────────────────

/// Immutable ordered collection of [RankingResult] objects.
///
/// Results are stored in the order supplied at construction.  [RankingEngine]
/// always supplies them sorted descending by score.
///
/// All structural methods return **new** instances — the original is never
/// modified.  Callers cannot obtain a mutable reference to the backing list.
class RankedCandidatePropertySet {
  final List<RankingResult> _results;

  RankedCandidatePropertySet([List<RankingResult>? results])
      : _results = List.unmodifiable(List.of(results ?? const []));

  // ── Read ──────────────────────────────────────────────────────────────────

  List<RankingResult> get results => _results;
  int  get length    => _results.length;
  bool get isEmpty   => _results.isEmpty;
  bool get isNotEmpty => _results.isNotEmpty;

  // ── Slicing / filtering ───────────────────────────────────────────────────

  /// Returns the first [n] results in their current order.
  RankedCandidatePropertySet top(int n) =>
      RankedCandidatePropertySet(_results.take(n).toList());

  /// Returns only results that satisfy [predicate].
  RankedCandidatePropertySet filter(bool Function(RankingResult) predicate) =>
      RankedCandidatePropertySet(_results.where(predicate).toList());

  /// Returns results sorted by [comparator].
  RankedCandidatePropertySet sort(Comparator<RankingResult> comparator) {
    final copy = List.of(_results)..sort(comparator);
    return RankedCandidatePropertySet(copy);
  }

  // ── Merge ─────────────────────────────────────────────────────────────────

  /// Combines this set with [other] and re-ranks the merged list.
  ///
  /// Sorted descending by score; ties broken alphabetically by property id.
  /// Rank numbers are reassigned from 1.
  RankedCandidatePropertySet merge(RankedCandidatePropertySet other) {
    final combined = [..._results, ...other._results];
    combined.sort((a, b) {
      final cmp = b.score.value.compareTo(a.score.value);
      return cmp != 0 ? cmp : a.property.id.compareTo(b.property.id);
    });
    final reranked = [
      for (var i = 0; i < combined.length; i++)
        RankingResult(
          property:    combined[i].property,
          score:       combined[i].score,
          rank:        i + 1,
          explanation: combined[i].explanation,
        ),
    ];
    return RankedCandidatePropertySet(reranked);
  }

  // ── Aggregates ────────────────────────────────────────────────────────────

  /// Average score across all results.  Returns 0.0 for an empty set.
  double averageScore() {
    if (_results.isEmpty) return 0.0;
    return _results.map((r) => r.score.value).reduce((a, b) => a + b) /
        _results.length;
  }

  /// Maximum score in the set, or `null` if empty.
  double? highestScore() =>
      _results.isEmpty
          ? null
          : _results
              .map((r) => r.score.value)
              .reduce((a, b) => a > b ? a : b);

  /// Minimum score in the set, or `null` if empty.
  double? lowestScore() =>
      _results.isEmpty
          ? null
          : _results
              .map((r) => r.score.value)
              .reduce((a, b) => a < b ? a : b);

  @override
  String toString() => 'RankedCandidatePropertySet(length: $length)';
}
