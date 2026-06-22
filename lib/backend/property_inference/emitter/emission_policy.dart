import '../ranking/ranking_result.dart';

// ─── EmissionPolicy ───────────────────────────────────────────────────────────

/// Determines whether a ranked candidate should proceed to emission.
///
/// Implementations are stateless — all configuration is passed explicitly
/// through [shouldEmit], making every emission pass independent.
///
/// [PropertyEmitter] depends only on this abstraction; concrete policies
/// (e.g. [DefaultEmissionPolicy]) are injected via [EmitterContext].
abstract class EmissionPolicy {
  const EmissionPolicy();

  /// Returns `true` when [result] should be emitted.
  ///
  /// Parameters:
  /// - [result]            — the ranked candidate under evaluation.
  /// - [minimumConfidence] — lower bound on [RankingScore.value].
  /// - [includeDisabled]   — when `false`, candidates whose metadata contains
  ///                         `'enabled': false` are excluded.
  bool shouldEmit(
    RankingResult result, {
    required double minimumConfidence,
    required bool includeDisabled,
  });
}

// ─── DefaultEmissionPolicy ────────────────────────────────────────────────────

/// Default emission gate applied by [PropertyEmitter].
///
/// Rules (in evaluation order):
/// 1. Reject candidates flagged as disabled in metadata unless
///    [includeDisabled] is `true`.
/// 2. Reject candidates whose [RankingScore.value] is below
///    [minimumConfidence].
/// 3. Accept everything else.
///
/// Count limits ([EmitterContext.maximumPropertiesToEmit]) are enforced by
/// [PriorityFilter], not here.
class DefaultEmissionPolicy implements EmissionPolicy {
  const DefaultEmissionPolicy();

  @override
  bool shouldEmit(
    RankingResult result, {
    required double minimumConfidence,
    required bool includeDisabled,
  }) {
    final isDisabled = result.property.metadata['enabled'] == false;
    if (isDisabled && !includeDisabled) return false;
    if (result.score.value < minimumConfidence) return false;
    return true;
  }
}
