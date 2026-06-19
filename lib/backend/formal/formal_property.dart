import 'formal_property_location.dart';
import 'formal_property_type.dart';

// ─── FormalProperty ───────────────────────────────────────────────────────────

/// Represents a single formal property independently of any verification backend.
///
/// Instances are **immutable**.  Use [copyWith] to produce modified copies —
/// this is the intended path for enabling/disabling a property or attaching
/// metadata after initial construction.
///
/// The [expression] field holds a backend-agnostic logical assertion string
/// (e.g. `"counter <= 255"`).  Translation to SystemVerilog, VHDL, or a `.sby`
/// script is the responsibility of backend-specific emitters introduced in
/// future tasks.
class FormalProperty {
  /// Stable identifier — unique within a [FormalPropertySet].
  final String id;

  /// Short human-readable name, suitable for display in a UI or report.
  final String name;

  /// Optional longer description of what this property checks and why.
  final String description;

  /// Logical role of this property within the verification problem.
  final FormalPropertyType propertyType;

  /// Where in the source this property originates, if known.
  final FormalPropertyLocation? sourceLocation;

  /// Diagnostic severity reported when the property fails.
  ///
  /// Must be one of `'error'`, `'warning'`, or `'info'` — matching the
  /// convention used throughout the diagnostic system.
  final String severity;

  /// When `false` the property is excluded from verification runs and
  /// serialized output retains this state so it survives round-trips.
  final bool enabled;

  /// Backend-agnostic logical expression describing the property.
  ///
  /// Syntax is intentionally unspecified here — backend emitters interpret it.
  final String expression;

  /// Arbitrary key-value pairs for tooling extensions, AI annotations, etc.
  final Map<String, dynamic> metadata;

  const FormalProperty({
    required this.id,
    required this.name,
    this.description   = '',
    required this.propertyType,
    this.sourceLocation,
    this.severity  = 'error',
    this.enabled   = true,
    required this.expression,
    this.metadata  = const {},
  });

  // ── Mutation via copy ─────────────────────────────────────────────────────

  FormalProperty copyWith({
    String? id,
    String? name,
    String? description,
    FormalPropertyType? propertyType,
    FormalPropertyLocation? sourceLocation,
    String? severity,
    bool? enabled,
    String? expression,
    Map<String, dynamic>? metadata,
  }) =>
      FormalProperty(
        id:             id             ?? this.id,
        name:           name           ?? this.name,
        description:    description    ?? this.description,
        propertyType:   propertyType   ?? this.propertyType,
        sourceLocation: sourceLocation ?? this.sourceLocation,
        severity:       severity       ?? this.severity,
        enabled:        enabled        ?? this.enabled,
        expression:     expression     ?? this.expression,
        metadata:       metadata       ?? this.metadata,
      );

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id':           id,
        'name':         name,
        'description':  description,
        'propertyType': propertyType.name,
        'severity':     severity,
        'enabled':      enabled,
        'expression':   expression,
        if (sourceLocation != null) 'sourceLocation': sourceLocation!.toJson(),
        if (metadata.isNotEmpty)    'metadata':       metadata,
      };

  factory FormalProperty.fromJson(Map<String, dynamic> json) => FormalProperty(
        id:           json['id']          as String,
        name:         json['name']        as String,
        description:  (json['description'] as String?) ?? '',
        propertyType: FormalPropertyType.values
            .byName(json['propertyType'] as String),
        severity:     (json['severity']   as String?) ?? 'error',
        enabled:      (json['enabled']    as bool?)   ?? true,
        expression:   json['expression']  as String,
        sourceLocation: json['sourceLocation'] == null
            ? null
            : FormalPropertyLocation.fromJson(
                json['sourceLocation'] as Map<String, dynamic>),
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      );

  @override
  String toString() =>
      'FormalProperty($id, ${propertyType.name}, enabled: $enabled)';
}
