import 'candidate_property.dart';
import 'candidate_property_type.dart';

// ─── CandidatePropertySet ─────────────────────────────────────────────────────

/// An immutable, ordered collection of [CandidateProperty] objects.
///
/// All structural methods ([add], [merge], [filter], [byType], [sort],
/// [deduplicate]) return **new** instances — the original is never modified.
/// Callers cannot obtain a mutable reference to the backing list.
class CandidatePropertySet {
  final List<CandidateProperty> _items;

  /// Constructs a set from an optional initial list.
  ///
  /// The backing store is made unmodifiable on construction.
  CandidatePropertySet([List<CandidateProperty>? items])
      : _items = List.unmodifiable(List.of(items ?? const []));

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Unmodifiable ordered view of all candidate properties.
  List<CandidateProperty> get items => _items;

  int  get length    => _items.length;
  bool get isEmpty   => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // ── Structural mutation (new instances) ───────────────────────────────────

  /// Returns a new set with [property] appended.
  CandidatePropertySet add(CandidateProperty property) =>
      CandidatePropertySet([..._items, property]);

  /// Returns a new set containing all items from this set followed by [other].
  CandidatePropertySet merge(CandidatePropertySet other) =>
      CandidatePropertySet([..._items, ...other._items]);

  /// Returns a new set containing only items that satisfy [predicate].
  CandidatePropertySet filter(bool Function(CandidateProperty) predicate) =>
      CandidatePropertySet(_items.where(predicate).toList());

  /// Convenience: retain only items of [type].
  CandidatePropertySet byType(CandidatePropertyType type) =>
      filter((p) => p.propertyType == type);

  /// Returns a new set ordered by [comparator].  Stable sort.
  CandidatePropertySet sort(Comparator<CandidateProperty> comparator) {
    final copy = List.of(_items)..sort(comparator);
    return CandidatePropertySet(copy);
  }

  /// Returns a new set with duplicate [CandidateProperty.id]s removed.
  ///
  /// First occurrence of each id is retained; subsequent duplicates are
  /// discarded.  Order is otherwise preserved.
  CandidatePropertySet deduplicate() {
    final seen = <String>{};
    return CandidatePropertySet(
      _items.where((p) => seen.add(p.id)).toList(),
    );
  }

  @override
  String toString() => 'CandidatePropertySet(length: $length)';
}
