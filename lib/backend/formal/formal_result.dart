// ─── FormalResult ─────────────────────────────────────────────────────────────

/// Standard result returned by every [FormalEngine] implementation.
///
/// Raw output ([stdout], [stderr]) is always captured so that
/// [FormalDiagnosticParser] can convert it to [Diagnostic] objects without
/// re-running the tool.
///
/// Property lists ([provenProperties], [failedProperties], [unknownProperties])
/// are populated by the engine from its raw output.  Future formal engines
/// must populate the same fields so that callers are engine-agnostic.
class FormalResult {
  /// Whether the overall verification run succeeded (exit code 0 + no failures).
  final bool success;

  /// Raw process exit code.
  final int exitCode;

  /// Captured stdout from the verification engine.
  final String stdout;

  /// Captured stderr from the verification engine.
  final String stderr;

  /// Wall-clock time spent running the engine.
  final Duration executionTime;

  // ── Property classification ────────────────────────────────────────────────

  /// Properties that were formally proven to hold for all reachable states
  /// (within the chosen depth for BMC, or unconditionally for prove mode).
  final List<String> provenProperties;

  /// Properties for which the engine found a counterexample trace.
  final List<String> failedProperties;

  /// Properties where the engine could not determine a result — e.g. timeout,
  /// depth insufficient, or SMT solver resource limit.
  final List<String> unknownProperties;

  const FormalResult({
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.executionTime      = Duration.zero,
    this.provenProperties   = const [],
    this.failedProperties   = const [],
    this.unknownProperties  = const [],
  });

  /// Stderr + stdout concatenated and trimmed — the format all parsers expect.
  String get combined => '$stderr\n$stdout'.trim();

  /// True when at least one property failed.
  bool get hasFailures => failedProperties.isNotEmpty;

  /// True when every checked property is in [provenProperties] and none failed
  /// or are unknown.
  bool get allProven =>
      failedProperties.isEmpty &&
      unknownProperties.isEmpty &&
      provenProperties.isNotEmpty;

  /// Sentinel result emitted when the engine binary is not installed.
  factory FormalResult.unavailable() => const FormalResult(
        success:  false,
        exitCode: -1,
        stdout:   '',
        stderr:   'Formal verification engine not available on this system.',
      );

  @override
  String toString() =>
      'FormalResult(success: $success, exitCode: $exitCode, '
      'proven: ${provenProperties.length}, '
      'failed: ${failedProperties.length}, '
      'unknown: ${unknownProperties.length}, '
      'time: ${executionTime.inMilliseconds}ms)';
}
