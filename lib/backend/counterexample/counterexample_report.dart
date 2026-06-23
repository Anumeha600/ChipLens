import 'counterexample_classification.dart';
import 'counterexample_statistics.dart';
import 'counterexample_summary.dart';
import 'counterexample_trace.dart';

// ─── CounterexampleReport ─────────────────────────────────────────────────────

/// Immutable reasoning result produced by [CounterexampleAnalyzer.analyze].
///
/// Bundles every derived artifact — summary, trace, classification, confidence,
/// and statistics — into a single self-contained value object.
///
/// Invariants:
/// - All fields are non-null.
/// - [isSuccessful] is `true` only when no properties failed or were unknown
///   and the classification is not a failure mode.
///
/// Future extension points:
/// - Add [repairSuggestions] when Repair Planning is integrated.
/// - Add [historicalComparison] for regression tracking.
class CounterexampleReport {
  /// High-level human-readable description of the verification outcome.
  final CounterexampleSummary summary;

  /// Reconstructed failure trace from property outcome lists.
  final CounterexampleTrace trace;

  /// Category of failure determined from [FormalResult].
  final CounterexampleClassification classification;

  /// Confidence in the completeness of the analysis.
  final CounterexampleConfidence confidence;

  /// Derived counts summarising the analysis.
  final CounterexampleStatistics statistics;

  const CounterexampleReport({
    required this.summary,
    required this.trace,
    required this.classification,
    required this.confidence,
    required this.statistics,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// `true` when at least one property has a counterexample.
  bool get hasFailures => statistics.failedPropertyCount > 0;

  /// `true` when no properties failed or were unknown and the engine did not
  /// error out.
  bool get isSuccessful =>
      statistics.failedPropertyCount  == 0 &&
      statistics.unknownPropertyCount == 0 &&
      classification != CounterexampleClassification.engineFailure &&
      classification != CounterexampleClassification.timeout       &&
      classification != CounterexampleClassification.assumptionViolation;

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterexampleReport &&
          summary        == other.summary        &&
          trace          == other.trace          &&
          classification == other.classification &&
          confidence     == other.confidence     &&
          statistics     == other.statistics;

  @override
  int get hashCode =>
      Object.hash(summary, trace, classification, confidence, statistics);

  @override
  String toString() =>
      'CounterexampleReport(${classification.name}, '
      'conf=${confidence.name}, failures=${statistics.failedPropertyCount})';
}
