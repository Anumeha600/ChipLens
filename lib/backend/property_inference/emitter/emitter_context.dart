import 'emission_policy.dart';

// ─── EmitterContext ───────────────────────────────────────────────────────────

/// Immutable configuration object consumed by [PropertyEmitter].
///
/// All fields have sensible defaults so a bare `EmitterContext()` produces a
/// permissive, ordering-preserving emission pass.
///
/// Invariants:
/// - [maximumPropertiesToEmit] = -1 means no limit.
/// - [minimumConfidence] must be in [0.0, 1.0].
/// - Changing a field always creates a new instance via [copyWith].
class EmitterContext {
  /// Maximum number of properties that may be emitted.
  ///
  /// A value of `-1` (default) means no limit.
  final int maximumPropertiesToEmit;

  /// Minimum composite ranking score required to emit a candidate.
  ///
  /// Candidates whose [RankingScore.value] is strictly below this threshold
  /// are skipped and counted in [EmitterResult.skippedCount].
  final double minimumConfidence;

  /// When `false` (default), candidates with `metadata['enabled'] == false`
  /// are excluded.  When `true`, they proceed to emission regardless.
  final bool includeDisabledCandidates;

  /// When `true` (default), emitted properties preserve the original ranking
  /// order.  Setting this to `false` signals that downstream code may reorder
  /// — [PropertyEmitter] itself does not reorder in either case.
  final bool preserveRanking;

  /// Policy that decides whether each candidate should be emitted.
  ///
  /// Defaults to [DefaultEmissionPolicy].
  final EmissionPolicy emissionPolicy;

  const EmitterContext({
    this.maximumPropertiesToEmit   = -1,
    this.minimumConfidence         = 0.0,
    this.includeDisabledCandidates = false,
    this.preserveRanking           = true,
    this.emissionPolicy            = const DefaultEmissionPolicy(),
  });

  // ── Immutable copy ────────────────────────────────────────────────────────

  EmitterContext copyWith({
    int?            maximumPropertiesToEmit,
    double?         minimumConfidence,
    bool?           includeDisabledCandidates,
    bool?           preserveRanking,
    EmissionPolicy? emissionPolicy,
  }) =>
      EmitterContext(
        maximumPropertiesToEmit:   maximumPropertiesToEmit   ?? this.maximumPropertiesToEmit,
        minimumConfidence:         minimumConfidence         ?? this.minimumConfidence,
        includeDisabledCandidates: includeDisabledCandidates ?? this.includeDisabledCandidates,
        preserveRanking:           preserveRanking           ?? this.preserveRanking,
        emissionPolicy:            emissionPolicy            ?? this.emissionPolicy,
      );

  // ── Equality ─────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmitterContext &&
          maximumPropertiesToEmit   == other.maximumPropertiesToEmit &&
          minimumConfidence         == other.minimumConfidence &&
          includeDisabledCandidates == other.includeDisabledCandidates &&
          preserveRanking           == other.preserveRanking;

  @override
  int get hashCode => Object.hash(
      maximumPropertiesToEmit,
      minimumConfidence,
      includeDisabledCandidates,
      preserveRanking);

  @override
  String toString() =>
      'EmitterContext(max=$maximumPropertiesToEmit, '
      'minConf=$minimumConfidence, '
      'inclDisabled=$includeDisabledCandidates)';
}
