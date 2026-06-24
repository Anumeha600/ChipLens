import 'benchmark_result.dart';

// ─── BenchmarkSuiteResult ─────────────────────────────────────────────────────

/// Immutable aggregate of all [BenchmarkResult]s from one benchmark run.
///
/// [totalDesigns], [successfulDesigns], and [failedDesigns] are explicit fields
/// set by the runner — they are not derived from [results] so callers retain
/// full control (e.g. when only a subset of benchmarks is executed).
///
/// Invariants:
/// - [results] is unmodifiable.
/// - All count fields are non-negative.
class BenchmarkSuiteResult {
  /// Ordered results, one per design in the benchmark suite.
  final List<BenchmarkResult> results;

  /// Total number of designs attempted.
  final int totalDesigns;

  /// Number of designs where [BenchmarkResult.success] is true.
  final int successfulDesigns;

  /// Number of designs where [BenchmarkResult.success] is false.
  final int failedDesigns;

  BenchmarkSuiteResult({
    required List<BenchmarkResult> results,
    required this.totalDesigns,
    required this.successfulDesigns,
    required this.failedDesigns,
  }) : results = List.unmodifiable(List.of(results));

  // ── Copy ──────────────────────────────────────────────────────────────────

  BenchmarkSuiteResult copyWith({
    List<BenchmarkResult>? results,
    int? totalDesigns,
    int? successfulDesigns,
    int? failedDesigns,
  }) =>
      BenchmarkSuiteResult(
        results:           results           ?? List.of(this.results),
        totalDesigns:      totalDesigns      ?? this.totalDesigns,
        successfulDesigns: successfulDesigns ?? this.successfulDesigns,
        failedDesigns:     failedDesigns     ?? this.failedDesigns,
      );

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BenchmarkSuiteResult &&
          totalDesigns      == other.totalDesigns      &&
          successfulDesigns == other.successfulDesigns &&
          failedDesigns     == other.failedDesigns     &&
          _listsEqual(results, other.results);

  static bool _listsEqual(List<BenchmarkResult> a, List<BenchmarkResult> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(totalDesigns, successfulDesigns, failedDesigns, results.length);

  @override
  String toString() =>
      'BenchmarkSuiteResult(total=$totalDesigns, success=$successfulDesigns, '
      'failed=$failedDesigns, results=${results.length})';
}
