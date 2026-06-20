import '../formal/formal_property.dart';

// ─── PropertyResult ───────────────────────────────────────────────────────────

/// The output of a single [PropertyProvider.infer] call.
///
/// Contains only inferred [FormalProperty] objects — no diagnostics, no repairs,
/// no formal execution results.  [PropertyRunner] collects all results and
/// merges them into a single [FormalPropertySet].
class PropertyResult {
  /// Key of the provider that produced this result.
  final String providerKey;

  /// Properties inferred by this provider.
  final List<FormalProperty> properties;

  const PropertyResult({
    required this.providerKey,
    this.properties = const [],
  });

  factory PropertyResult.empty(String providerKey) =>
      PropertyResult(providerKey: providerKey);

  bool get isEmpty  => properties.isEmpty;
  int  get length   => properties.length;
}
