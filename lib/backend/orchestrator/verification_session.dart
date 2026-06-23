// ─── VerificationSession ──────────────────────────────────────────────────────

/// Immutable input to [VerificationOrchestrator.run].
///
/// Carries the RTL source and session metadata needed to coordinate the full
/// verification pipeline.  The session owns no reasoning logic and does not
/// reference any framework outputs.
///
/// Invariants:
/// - [sessionId] uniquely identifies the session within a run.
/// - [rtlSource] is the raw Verilog / SystemVerilog text to verify.
/// - [metadata] is carried through unchanged and appears in
///   [VerificationSessionResult] for traceability.
///
/// Thread safety: immutable — safe to share across async boundaries.
///
/// Future extension points:
/// - Add [workingDirectory] for multi-file designs.
/// - Add [designSpecification] for simulation-based coverage.
/// - Add [previousResult] for incremental re-verification.
class VerificationSession {
  /// Unique identifier for this verification session.
  ///
  /// Used to correlate [VerificationSessionResult] with its input and for
  /// tracing in logs or CI pipelines.
  final String sessionId;

  /// Raw Verilog / SystemVerilog RTL source text to analyse and verify.
  final String rtlSource;

  /// Optional hint for the top-level module name.
  ///
  /// When `null`, Design Intelligence and the formal engine each attempt to
  /// infer the top module from the source text.
  final String? topModule;

  /// Wall-clock timestamp recorded when this session object was created.
  ///
  /// Preserved unchanged in [VerificationSessionResult] for audit trails.
  final DateTime startTime;

  /// Arbitrary key-value metadata attached to this session.
  ///
  /// Propagated verbatim to [VerificationSessionResult.metadata].
  /// The orchestrator never reads or interprets these values.
  final Map<String, dynamic> metadata;

  const VerificationSession({
    required this.sessionId,
    required this.rtlSource,
    this.topModule,
    required this.startTime,
    this.metadata = const {},
  });

  // ── Identity — keyed on sessionId ─────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationSession && sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;

  @override
  String toString() =>
      'VerificationSession(id=$sessionId, '
      'topModule=$topModule, '
      'rtlLength=${rtlSource.length})';
}
