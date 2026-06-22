import '../formal/formal_property.dart';
import 'explanation_context.dart';
import 'explanation_trace.dart';
import 'verification_explanation.dart';

// ─── ExplanationBuilder ───────────────────────────────────────────────────────

/// Constructs [VerificationExplanation] objects from [FormalProperty] instances.
///
/// Reads provenance data from [FormalProperty.metadata] — the keys written
/// there by the Property Emitter layer:
/// - `candidateId` — original candidate identifier
/// - `rank`        — ranking position
/// - `score`       — composite confidence score
/// - `explanation` — formatted ranking explanation text
/// - `source`      — emitter tag (e.g. `'PropertyEmitter'`)
/// - `evidenceIds` — list of supporting semantic evidence ids
///
/// When any of these keys are missing, [ExplanationBuilder] falls back
/// to sensible defaults rather than throwing.
///
/// Invariants:
/// - Does NOT format output (that is [ExplanationFormatter]'s responsibility).
/// - Does NOT modify [FormalProperty].
/// - Every output [VerificationExplanation] has a non-null [ExplanationTrace].
abstract class ExplanationBuilder {
  ExplanationBuilder._();

  /// Builds one [VerificationExplanation] from [property] and [context].
  ///
  /// Throws [ArgumentError] when [property.id] is empty (malformed property).
  static VerificationExplanation build(
    FormalProperty property,
    ExplanationContext context,
  ) {
    if (property.id.isEmpty) {
      throw ArgumentError.value(
          property.id, 'property.id', 'Property id must not be empty');
    }

    final meta = property.metadata;

    final evidenceIds = context.includeEvidence
        ? _extractEvidenceIds(meta, context.maximumEvidence)
        : const <String>[];

    final rankingText = context.includeRanking
        ? (meta['explanation'] as String?) ??
            'No ranking explanation available'
        : '';

    final confidence = context.includeConfidence
        ? (meta['score'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    final emissionReason = _buildEmissionReason(meta);

    final trace = ExplanationTrace(
      semanticEvidenceIds: evidenceIds,
      rankingExplanation:  rankingText,
      confidence:          confidence,
      emissionReason:      emissionReason,
      propertyType:        property.propertyType.name,
      verificationEngine:  '',
    );

    final explanationMeta = context.includeMetadata
        ? Map<String, dynamic>.of(meta)
        : const <String, dynamic>{};

    return VerificationExplanation(
      propertyId:  property.id,
      title:       property.name,
      description: property.description,
      trace:       trace,
      metadata:    explanationMeta,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static List<String> _extractEvidenceIds(
    Map<String, dynamic> metadata,
    int maxEvidence,
  ) {
    final raw = metadata['evidenceIds'];
    final List<String> ids =
        raw is List ? List<String>.from(raw.cast<String>()) : const [];

    if (maxEvidence < 0 || ids.length <= maxEvidence) {
      return ids;
    }
    return ids.take(maxEvidence).toList();
  }

  static String _buildEmissionReason(Map<String, dynamic> metadata) {
    final rank   = metadata['rank'];
    final source = (metadata['source'] as String?) ?? 'unknown';
    if (rank != null) return 'Emitted at rank $rank by $source';
    return 'Emitted by $source';
  }
}
