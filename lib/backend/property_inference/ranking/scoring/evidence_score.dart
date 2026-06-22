import '../../semantic/semantic_evidence.dart';
import '../../semantic/semantic_evidence_set.dart';

// ─── EvidenceScore ────────────────────────────────────────────────────────────

/// Computes a score in [0.0, 1.0] from the average [SemanticEvidence.confidence]
/// of the items referenced by a [CandidateProperty.evidenceIds] list.
///
/// Stateless and const-constructible — safe to share as a singleton.
class EvidenceScore {
  const EvidenceScore();

  ({double score, String explanation}) compute(
    List<String> evidenceIds,
    SemanticEvidenceSet evidence,
  ) {
    if (evidenceIds.isEmpty) {
      return (score: 0.0, explanation: 'No supporting evidence ids');
    }

    final supporting = <SemanticEvidence>[];
    for (final id in evidenceIds) {
      for (final e in evidence.items) {
        if (e.id == id) {
          supporting.add(e);
          break;
        }
      }
    }

    if (supporting.isEmpty) {
      return (score: 0.0, explanation: 'Evidence ids not resolved in set');
    }

    final avg = supporting.map((e) => e.confidence).reduce((a, b) => a + b) /
        supporting.length;

    final label = supporting.length == 1
        ? '1 evidence item (confidence ${avg.toStringAsFixed(2)})'
        : '${supporting.length} evidence items, avg confidence '
            '${avg.toStringAsFixed(2)}';

    return (score: avg, explanation: label);
  }
}
