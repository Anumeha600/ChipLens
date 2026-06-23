// ─── CounterexampleContext ────────────────────────────────────────────────────

/// Immutable configuration that drives [CounterexampleAnalyzer].
///
/// All fields have sensible defaults so callers only override what they need.
///
/// Future extension points:
/// - [minimumFailureDepth] for ignoring shallow counterexamples.
/// - [signalFilter] predicate for custom signal selection.
class CounterexampleContext {
  /// When `true`, [CounterexampleReport.trace] is reconstructed from
  /// [FormalResult] property lists.
  final bool includeTrace;

  /// When `true`, [CounterexampleTrace.signals] is populated.
  final bool includeSignals;

  /// When `true`, [CounterexampleReport.statistics] is populated.
  final bool includeStatistics;

  /// When `true`, [CounterexampleReport.confidence] is computed.
  final bool includeConfidence;

  /// Maximum number of signals to include in [CounterexampleTrace.signals].
  /// -1 means no limit.
  final int maximumSignals;

  const CounterexampleContext({
    this.includeTrace      = true,
    this.includeSignals    = true,
    this.includeStatistics = true,
    this.includeConfidence = true,
    this.maximumSignals    = -1,
  });

  /// Returns a copy with only the specified fields overridden.
  CounterexampleContext copyWith({
    bool? includeTrace,
    bool? includeSignals,
    bool? includeStatistics,
    bool? includeConfidence,
    int?  maximumSignals,
  }) =>
      CounterexampleContext(
        includeTrace:      includeTrace      ?? this.includeTrace,
        includeSignals:    includeSignals    ?? this.includeSignals,
        includeStatistics: includeStatistics ?? this.includeStatistics,
        includeConfidence: includeConfidence ?? this.includeConfidence,
        maximumSignals:    maximumSignals    ?? this.maximumSignals,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterexampleContext &&
          includeTrace      == other.includeTrace      &&
          includeSignals    == other.includeSignals    &&
          includeStatistics == other.includeStatistics &&
          includeConfidence == other.includeConfidence &&
          maximumSignals    == other.maximumSignals;

  @override
  int get hashCode => Object.hash(
        includeTrace, includeSignals, includeStatistics,
        includeConfidence, maximumSignals);

  @override
  String toString() =>
      'CounterexampleContext(maxSignals=$maximumSignals)';
}
