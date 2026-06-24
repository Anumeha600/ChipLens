/// Execution status of a single [WorkflowStep].
enum WorkflowStatus {
  /// Not yet started; waiting for its prerequisites.
  pending,

  /// Prerequisites met; the step is ready to execute.
  ready,

  /// The step is actively executing.
  running,

  /// The step finished without errors.
  completed,

  /// The step finished with one or more tool errors.
  failed,

  /// The step was intentionally bypassed.
  skipped,
}
