import 'workflow_step.dart';
import 'workflow_summary.dart';

/// Primary model representing the lifecycle of a ChipLens verification project.
///
/// [VerificationWorkflow] describes *what needs to happen and what has happened*
/// in a session, without encoding *how* it happens. Future execution engines
/// and progress reporters will consume this model without needing to know
/// about the underlying tools.
///
/// The workflow is linked to a [VerificationSession] via [sessionId].
///
/// Example:
/// ```dart
/// final workflow = VerificationWorkflow(
///   sessionId: 'session_001',
///   steps: [
///     WorkflowStep(
///       stage: WorkflowStage.verification,
///       status: WorkflowStatus.pending,
///     ),
///   ],
///   summary: WorkflowSummary(
///     totalSteps: 1,
///     completedSteps: 0,
///     failedSteps: 0,
///     skippedSteps: 0,
///   ),
/// );
/// ```
///
/// Future extension points (not yet implemented):
/// - execution engine attachment
/// - progress stream
/// - orchestration policy
/// - benchmark tracking
/// - report generation
class VerificationWorkflow {
  /// ID of the [VerificationSession] this workflow belongs to.
  final String sessionId;

  /// Ordered list of workflow steps.
  final List<WorkflowStep> steps;

  /// Aggregate counts across all steps.
  final WorkflowSummary summary;

  const VerificationWorkflow({
    required this.sessionId,
    required this.steps,
    required this.summary,
  });

  /// Returns a copy with selected fields replaced.
  VerificationWorkflow copyWith({
    String? sessionId,
    List<WorkflowStep>? steps,
    WorkflowSummary? summary,
  }) {
    return VerificationWorkflow(
      sessionId: sessionId ?? this.sessionId,
      steps: steps ?? this.steps,
      summary: summary ?? this.summary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VerificationWorkflow) return false;
    if (sessionId != other.sessionId) return false;
    if (summary != other.summary) return false;
    if (steps.length != other.steps.length) return false;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i] != other.steps[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(sessionId, Object.hashAll(steps), summary);
}
