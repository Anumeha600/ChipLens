import 'semantic_category.dart';
import 'semantic_evidence.dart';

// ─── SemanticEvidenceSet ──────────────────────────────────────────────────────

/// An immutable, ordered collection of [SemanticEvidence] items.
///
/// All mutation methods ([add], [merge]) return **new** instances — the
/// original set is never modified.  Callers cannot obtain a mutable reference
/// to the backing list.
class SemanticEvidenceSet {
  final List<SemanticEvidence> _items;

  /// Constructs a set from an optional initial list.
  ///
  /// The backing store is made unmodifiable on construction, so changes to
  /// [items] after passing them in have no effect.
  SemanticEvidenceSet([List<SemanticEvidence>? items])
      : _items = List.unmodifiable(List.of(items ?? const []));

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Unmodifiable ordered view of all evidence items.
  List<SemanticEvidence> get items => _items;

  int  get length    => _items.length;
  bool get isEmpty   => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // ── Structural mutation (returns new instances) ───────────────────────────

  /// Returns a new set with [evidence] appended.  The original is unchanged.
  SemanticEvidenceSet add(SemanticEvidence evidence) =>
      SemanticEvidenceSet([..._items, evidence]);

  /// Returns a new set containing all items from this set followed by all
  /// items from [other].  Neither input is modified.
  SemanticEvidenceSet merge(SemanticEvidenceSet other) =>
      SemanticEvidenceSet([..._items, ...other._items]);

  // ── Filtering (returns new instances) ────────────────────────────────────

  /// Returns a new set containing only items that satisfy [predicate].
  SemanticEvidenceSet filter(bool Function(SemanticEvidence) predicate) =>
      SemanticEvidenceSet(_items.where(predicate).toList());

  /// Convenience: retain only items in [category].
  SemanticEvidenceSet byCategory(SemanticCategory category) =>
      filter((e) => e.category == category);

  /// Convenience: retain only items whose [SemanticEvidence.confidence] is
  /// at or above [threshold] (default `0.8`).
  SemanticEvidenceSet highConfidence({double threshold = 0.8}) =>
      filter((e) => e.confidence >= threshold);

  @override
  String toString() => 'SemanticEvidenceSet(length: $length)';
}
