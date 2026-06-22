import '../ranking/ranked_candidate_property_set.dart';
import '../ranking/ranking_result.dart';
import 'emitter_context.dart';

// ─── PriorityFilter ───────────────────────────────────────────────────────────

/// Selects which ranked candidates proceed to the mapping stage.
///
/// Responsibilities:
/// - Iterate exactly once through the input set.
/// - Apply [EmitterContext.emissionPolicy] to each candidate.
/// - Preserve the original ranking order among selected candidates.
/// - Stop once [EmitterContext.maximumPropertiesToEmit] is reached.
///
/// Does NOT:
/// - Construct [FormalProperty] objects.
/// - Modify scores, explanations, or metadata.
/// - Reorder candidates.
abstract class PriorityFilter {
  PriorityFilter._();

  /// Returns the subset of [ranked] that passes the emission gate.
  ///
  /// Order is preserved from [RankedCandidatePropertySet.results].
  /// The returned list is unmodifiable.
  static List<RankingResult> filter(
    RankedCandidatePropertySet ranked,
    EmitterContext context,
  ) {
    final policy   = context.emissionPolicy;
    final maxCount = context.maximumPropertiesToEmit;
    final selected = <RankingResult>[];

    for (final result in ranked.results) {
      if (maxCount >= 0 && selected.length >= maxCount) break;

      if (policy.shouldEmit(
        result,
        minimumConfidence: context.minimumConfidence,
        includeDisabled:   context.includeDisabledCandidates,
      )) {
        selected.add(result);
      }
    }

    return List.unmodifiable(selected);
  }
}
