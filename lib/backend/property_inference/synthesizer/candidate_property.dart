import 'candidate_property_type.dart';

// ─── CandidateProperty ────────────────────────────────────────────────────────

/// An immutable value object representing a property candidate before it
/// is translated into a backend-specific [FormalProperty].
///
/// At this stage:
/// - [expression] is `null` — the synthesizer reasons over semantic concepts,
///   not Verilog syntax.  The emitter layer (Task 1C) fills it in.
/// - [evidenceIds] links back to the [SemanticEvidence] items that justified
///   this candidate, enabling downstream explanation and ranking.
/// - [rationale] provides a human-readable justification for why this property
///   should exist.
///
/// Equality is defined by [id].
class CandidateProperty {
  /// Stable identifier — unique within a [CandidatePropertySet].
  ///
  /// Pattern: `synth.{category}.{signal}.{aspect}`,
  /// e.g. `synth.fsm.state.legal_state`.
  final String id;

  /// Short label suitable for display in a report or UI.
  final String title;

  /// Longer explanation of what the property checks.
  final String description;

  /// Semantic classification of this candidate.
  final CandidatePropertyType propertyType;

  /// Optional formal expression.
  ///
  /// `null` at synthesis time.  Filled in by the emitter layer.
  final String? expression;

  /// IDs of the [SemanticEvidence] items that motivated this candidate.
  final List<String> evidenceIds;

  /// Human-readable justification for why this property should be verified.
  final String rationale;

  /// Extensible payload for downstream consumers (ranking, AI annotation, etc.).
  final Map<String, dynamic> metadata;

  const CandidateProperty({
    required this.id,
    required this.title,
    required this.description,
    required this.propertyType,
    this.expression,
    this.evidenceIds  = const [],
    required this.rationale,
    this.metadata     = const {},
  });

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidateProperty && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CandidateProperty($id, ${propertyType.name})';
}
