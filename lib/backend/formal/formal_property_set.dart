import 'formal_property.dart';
import 'formal_property_type.dart';

// ─── FormalPropertySet ────────────────────────────────────────────────────────

/// A mutable, ordered collection of [FormalProperty] objects.
///
/// Contains no backend-specific logic — it is consumed identically by every
/// formal engine and by future automatic property generators.
///
/// IDs must be unique within a set.  [add] throws [ArgumentError] on a
/// duplicate; all other mutation methods are silent no-ops for missing IDs.
class FormalPropertySet {
  final List<FormalProperty> _props;

  FormalPropertySet([List<FormalProperty>? properties])
      : _props = List.of(properties ?? const []);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Unmodifiable ordered view of all properties.
  List<FormalProperty> get properties => List.unmodifiable(_props);

  int get length    => _props.length;
  bool get isEmpty  => _props.isEmpty;
  bool get isNotEmpty => _props.isNotEmpty;

  /// Returns the property with [id], or `null` if none matches.
  FormalProperty? findById(String id) {
    for (final p in _props) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ── Mutation ──────────────────────────────────────────────────────────────

  /// Appends [property] to the set.
  ///
  /// Throws [ArgumentError] when a property with the same [FormalProperty.id]
  /// already exists.
  void add(FormalProperty property) {
    if (_props.any((p) => p.id == property.id)) {
      throw ArgumentError(
          'FormalPropertySet already contains id "${property.id}".');
    }
    _props.add(property);
  }

  /// Removes the property with [id].  Silent no-op when not found.
  void remove(String id) => _props.removeWhere((p) => p.id == id);

  /// Enables the property with [id].  Silent no-op when not found.
  void enable(String id) => _setEnabled(id, value: true);

  /// Disables the property with [id].  Silent no-op when not found.
  void disable(String id) => _setEnabled(id, value: false);

  void _setEnabled(String id, {required bool value}) {
    final idx = _props.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _props[idx] = _props[idx].copyWith(enabled: value);
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  /// Returns a new [FormalPropertySet] containing only properties that satisfy
  /// [predicate].  The original set is not modified.
  FormalPropertySet filter(bool Function(FormalProperty) predicate) =>
      FormalPropertySet(_props.where(predicate).toList());

  /// Convenience: filter by [FormalPropertyType].
  FormalPropertySet byType(FormalPropertyType type) =>
      filter((p) => p.propertyType == type);

  /// Convenience: retain only enabled properties.
  FormalPropertySet enabledOnly() => filter((p) => p.enabled);

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'properties': _props.map((p) => p.toJson()).toList(),
      };

  factory FormalPropertySet.fromJson(Map<String, dynamic> json) {
    final raw = json['properties'] as List<dynamic>? ?? const [];
    return FormalPropertySet(
      raw
          .map((e) => FormalProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() => 'FormalPropertySet(length: $length)';
}
