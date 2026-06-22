import 'semantic_category.dart';

// ─── SemanticEvidence ─────────────────────────────────────────────────────────

/// Represents one piece of semantic reasoning about an RTL design.
///
/// [SemanticEvidence] is an **immutable value object** — it carries no mutable
/// state and equality is defined by [id].
///
/// Instances are produced only by [SemanticEvidenceExtractor].  They explain
/// *why* a particular design construct exists so that downstream synthesizers
/// can produce well-motivated formal properties.
///
/// [confidence] is a value in `[0.0, 1.0]` where:
/// - `1.0` — structurally certain (primary clock by name convention)
/// - `≥ 0.9` — very likely (multi-edge async reset)
/// - `≥ 0.8` — likely (sequential register from posedge block)
/// - `< 0.8` — heuristic candidate requiring review
class SemanticEvidence {
  /// Unique identifier within a [SemanticEvidenceSet].
  ///
  /// Follows the pattern `{category}.{signal}.{detail}`,
  /// e.g. `clock.clk`, `reset.rst_n`, `fsm.state`.
  final String id;

  /// Design domain this evidence belongs to.
  final SemanticCategory category;

  /// Confidence score in `[0.0, 1.0]`.
  final double confidence;

  /// Human-readable explanation of the observation.
  final String description;

  /// Key of the extractor sub-method that produced this evidence.
  final String sourceProvider;

  /// Extensible key-value payload for downstream consumers.
  ///
  /// Convention: pass `const {}` or a const map literal so the field remains
  /// effectively immutable.  Mutating a non-const map is a caller error.
  final Map<String, dynamic> metadata;

  const SemanticEvidence({
    required this.id,
    required this.category,
    required this.confidence,
    required this.description,
    this.sourceProvider = '',
    this.metadata = const {},
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id':             id,
        'category':       category.name,
        'confidence':     confidence,
        'description':    description,
        'sourceProvider': sourceProvider,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory SemanticEvidence.fromJson(Map<String, dynamic> json) =>
      SemanticEvidence(
        id:             json['id']             as String,
        category:       SemanticCategory.values.byName(json['category'] as String),
        confidence:     (json['confidence']    as num).toDouble(),
        description:    json['description']    as String,
        sourceProvider: (json['sourceProvider'] as String?) ?? '',
        metadata:       (json['metadata']      as Map<String, dynamic>?) ?? const {},
      );

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticEvidence && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SemanticEvidence($id, ${category.name}, confidence: $confidence)';
}
