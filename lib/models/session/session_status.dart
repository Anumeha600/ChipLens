/// Lifecycle state of a [VerificationSession].
///
/// Sessions advance through this sequence as verification progresses:
///
/// ```
/// created → ready → running → completed
///                          ↘ failed
/// ```
enum SessionStatus {
  /// Session has been created but is not yet configured.
  created,

  /// Session is fully configured and ready to run.
  ready,

  /// Verification tools are actively running.
  running,

  /// Verification completed without tool errors.
  completed,

  /// Verification completed with tool errors or unrecoverable failure.
  failed,
}
