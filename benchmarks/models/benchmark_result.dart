// ─── BenchmarkResult ──────────────────────────────────────────────────────────

/// Immutable result from running the analysis pipeline against one RTL design.
///
/// Captures elapsed time, output counts, and whether execution succeeded.
///
/// Invariants:
/// - [runtimeMs] is always non-negative.
/// - [diagnosticCount] and [repairCount] are non-negative.
/// - [notes] is null on successful runs and non-null when [success] is false.
class BenchmarkResult {
  /// Name of the RTL design that was benchmarked.
  final String designName;

  /// Wall-clock time in milliseconds for the complete pipeline run.
  final int runtimeMs;

  /// Number of [DiagnosticIssue]s produced by [DiagnosticsEngine].
  final int diagnosticCount;

  /// Number of [RepairStep]s produced by [RepairPlanner].
  final int repairCount;

  /// True when the pipeline completed without throwing an exception.
  final bool success;

  /// Optional human-readable detail — populated on failure with the error.
  final String? notes;

  const BenchmarkResult({
    required this.designName,
    required this.runtimeMs,
    required this.diagnosticCount,
    required this.repairCount,
    required this.success,
    this.notes,
  });

  // ── Copy ──────────────────────────────────────────────────────────────────

  BenchmarkResult copyWith({
    String? designName,
    int? runtimeMs,
    int? diagnosticCount,
    int? repairCount,
    bool? success,
    String? notes,
    bool clearNotes = false,
  }) =>
      BenchmarkResult(
        designName:      designName      ?? this.designName,
        runtimeMs:       runtimeMs       ?? this.runtimeMs,
        diagnosticCount: diagnosticCount ?? this.diagnosticCount,
        repairCount:     repairCount     ?? this.repairCount,
        success:         success         ?? this.success,
        notes:           clearNotes ? null : (notes ?? this.notes),
      );

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BenchmarkResult &&
          designName      == other.designName      &&
          runtimeMs       == other.runtimeMs       &&
          diagnosticCount == other.diagnosticCount &&
          repairCount     == other.repairCount     &&
          success         == other.success         &&
          notes           == other.notes;

  @override
  int get hashCode =>
      Object.hash(designName, runtimeMs, diagnosticCount, repairCount, success, notes);

  @override
  String toString() =>
      'BenchmarkResult(design=$designName, runtime=${runtimeMs}ms, '
      'diagnostics=$diagnosticCount, repairs=$repairCount, success=$success)';
}
