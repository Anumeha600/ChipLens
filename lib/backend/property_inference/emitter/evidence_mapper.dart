// ─── EvidenceMapper ───────────────────────────────────────────────────────────

/// Maps a raw evidence id list to a deduplicated, order-preserving,
/// unmodifiable output list.
///
/// Responsibilities:
/// - Preserve the original ordering of ids.
/// - Remove duplicate ids (first occurrence kept).
/// - Never introduce synthetic evidence ids.
/// - Return an unmodifiable list.
///
/// Does NOT consult the [SemanticEvidenceSet] — this layer operates on ids
/// only and has no dependency on the semantic or ranking layers.
abstract class EvidenceMapper {
  EvidenceMapper._();

  /// Deduplicates [evidenceIds] while preserving insertion order.
  ///
  /// Input: `['e1', 'e2', 'e1', 'e3']`
  /// Output: `['e1', 'e2', 'e3']` (unmodifiable)
  static List<String> map(List<String> evidenceIds) {
    final seen   = <String>{};
    final result = <String>[];
    for (final id in evidenceIds) {
      if (seen.add(id)) result.add(id);
    }
    return List.unmodifiable(result);
  }
}
