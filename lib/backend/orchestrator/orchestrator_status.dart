// ─── VerificationStatus ───────────────────────────────────────────────────────

/// Overall outcome of one [VerificationSession] as determined by
/// [VerificationOrchestrator].
///
/// The status reflects the aggregate result of all enabled pipeline stages:
/// - [success]        — every stage completed and all properties were proven.
/// - [partialSuccess] — all stages completed, but issues were detected (e.g.
///   failing properties, coverage gaps, or diagnostic warnings).
/// - [failed]         — the orchestration could not complete due to an
///   unrecoverable error (exception from a mandatory stage).
/// - [cancelled]      — the session was interrupted before all stages could
///   complete (e.g. [OrchestratorContext.timeout] elapsed).
///
/// Future extension points:
/// - Add [timedOut] to distinguish from caller-initiated cancellation.
/// - Add [degraded] for partially-proven results with known incompleteness.
enum VerificationStatus {
  /// All enabled stages completed and every formal property was proven.
  success,

  /// All enabled stages completed, but one or more issues were detected
  /// (failing properties, coverage gaps, diagnostic warnings, etc.).
  partialSuccess,

  /// The orchestration could not complete due to an unrecoverable error.
  failed,

  /// The session was interrupted before all stages could complete.
  cancelled,
}
