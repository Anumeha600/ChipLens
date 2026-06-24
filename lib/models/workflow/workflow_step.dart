import 'workflow_stage.dart';
import 'workflow_status.dart';

/// Immutable record of a single stage's execution state within a
/// [VerificationWorkflow].
///
/// [startedAt] and [completedAt] are populated by the execution layer once
/// the step begins and ends. They are absent (`null`) until then.
///
/// Example:
/// ```dart
/// final step = WorkflowStep(
///   stage: WorkflowStage.verification,
///   status: WorkflowStatus.pending,
/// );
///
/// // Advance to running:
/// final running = step.copyWith(
///   status: WorkflowStatus.running,
///   startedAt: DateTime.now(),
/// );
/// ```
class WorkflowStep {
  /// The lifecycle stage this step belongs to.
  final WorkflowStage stage;

  /// Current execution status of this step.
  final WorkflowStatus status;

  /// Wall-clock time when execution began; `null` if not yet started.
  final DateTime? startedAt;

  /// Wall-clock time when execution ended; `null` if not yet finished.
  final DateTime? completedAt;

  const WorkflowStep({
    required this.stage,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  /// Returns a copy with selected fields replaced.
  ///
  /// Use [clearStartedAt] or [clearCompletedAt] to explicitly null out the
  /// corresponding timestamp — passing `null` for either is ambiguous
  /// (keep existing vs. clear).
  WorkflowStep copyWith({
    WorkflowStage? stage,
    WorkflowStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
  }) {
    return WorkflowStep(
      stage: stage ?? this.stage,
      status: status ?? this.status,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowStep &&
          stage == other.stage &&
          status == other.status &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(stage, status, startedAt, completedAt);
}
