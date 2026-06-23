// ─── CounterexampleStatistics ─────────────────────────────────────────────────

/// Immutable derived statistics from one [CounterexampleReport].
///
/// All values are O(n) projections from [FormalResult] and the generated
/// signal list.  No verification execution occurs here.
///
/// Invariants:
/// - All integer counts are non-negative.
/// - [changedSignalCount] <= [signalCount].
class CounterexampleStatistics {
  /// Number of properties for which a counterexample trace was found.
  final int failedPropertyCount;

  /// Number of properties where the engine could not determine an outcome.
  final int unknownPropertyCount;

  /// Total number of signals in the reconstructed trace.
  final int signalCount;

  /// Number of signals marked as changed at their recorded step.
  final int changedSignalCount;

  /// Heuristic estimate of the counterexample trace depth in time steps.
  final int estimatedDepth;

  const CounterexampleStatistics({
    required this.failedPropertyCount,
    required this.unknownPropertyCount,
    required this.signalCount,
    required this.changedSignalCount,
    required this.estimatedDepth,
  });

  /// Zero-value statistics for a trivially successful or empty result.
  static const CounterexampleStatistics empty = CounterexampleStatistics(
    failedPropertyCount:  0,
    unknownPropertyCount: 0,
    signalCount:          0,
    changedSignalCount:   0,
    estimatedDepth:       0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterexampleStatistics &&
          failedPropertyCount  == other.failedPropertyCount  &&
          unknownPropertyCount == other.unknownPropertyCount &&
          signalCount          == other.signalCount          &&
          changedSignalCount   == other.changedSignalCount   &&
          estimatedDepth       == other.estimatedDepth;

  @override
  int get hashCode => Object.hash(
        failedPropertyCount, unknownPropertyCount,
        signalCount, changedSignalCount, estimatedDepth);

  @override
  String toString() =>
      'CounterexampleStatistics(failed=$failedPropertyCount, '
      'unknown=$unknownPropertyCount, depth=$estimatedDepth)';
}
