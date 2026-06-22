import 'explanation_trace.dart';

// ─── VerificationExplanation ──────────────────────────────────────────────────

/// Immutable explanation for one [FormalProperty].
///
/// Carries the property's identity and human-readable fields alongside an
/// [ExplanationTrace] that records the full provenance from semantic evidence
/// through synthesis, ranking, and emission.
///
/// Equality is defined by [propertyId] — two explanations for the same
/// property are considered the same regardless of how their traces differ.
///
/// Invariants:
/// - [metadata] is unmodifiable.
/// - [trace] is never null.
/// - [propertyId] uniquely identifies the source [FormalProperty].
class VerificationExplanation {
  /// Identifier copied from [FormalProperty.id].
  final String propertyId;

  /// Short label copied from [FormalProperty.name].
  final String title;

  /// Longer description copied from [FormalProperty.description].
  final String description;

  /// Provenance trace linking this explanation to upstream pipeline data.
  final ExplanationTrace trace;

  /// Arbitrary metadata carried from [FormalProperty.metadata] when
  /// [ExplanationContext.includeMetadata] is `true`.
  final Map<String, dynamic> metadata;

  VerificationExplanation({
    required this.propertyId,
    required this.title,
    this.description = '',
    required this.trace,
    Map<String, dynamic>? metadata,
  }) : metadata = Map.unmodifiable(metadata ?? const {});

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationExplanation && propertyId == other.propertyId;

  @override
  int get hashCode => propertyId.hashCode;

  @override
  String toString() =>
      'VerificationExplanation($propertyId, conf=${trace.confidence.toStringAsFixed(4)})';
}
