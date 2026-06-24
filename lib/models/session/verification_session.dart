import 'session_metadata.dart';
import 'session_status.dart';
import 'session_summary.dart';
import '../workflow/verification_workflow.dart';

/// Primary model representing a single ChipLens verification workflow.
///
/// [VerificationSession] is the canonical integration boundary between
/// the RTL, Verification, Coverage, Diagnostics, and Repair subsystems.
/// Future controllers and UI components will read and derive new sessions
/// from this immutable object.
///
/// Sessions are immutable value objects. Workflow progression is expressed by
/// creating new instances via [copyWith]:
///
/// ```dart
/// // Advance from created → ready
/// final ready = session.copyWith(status: SessionStatus.ready);
///
/// // Attach results after completion
/// final done = ready.copyWith(
///   status: SessionStatus.completed,
///   summary: SessionSummary(
///     rtlModules: 3,
///     diagnosticCount: 0,
///     repairCount: 0,
///     coveragePercent: 97.4,
///   ),
/// );
/// ```
///
/// Future extension points (not yet implemented):
/// - formal verification results
/// - coverage report reference
/// - diagnostics report reference
/// - repair plan reference
class VerificationSession {
  /// Identity and timestamp metadata for this session.
  final SessionMetadata metadata;

  /// Current lifecycle state.
  final SessionStatus status;

  /// Raw RTL source code submitted for verification.
  final String rtlSource;

  /// Quantitative results populated after [SessionStatus.completed].
  ///
  /// `null` when the session has not yet finished (or if it [SessionStatus.failed]).
  final SessionSummary? summary;

  /// Workflow lifecycle model attached to this session.
  ///
  /// `null` until a workflow is constructed and linked to the session.
  final VerificationWorkflow? workflow;

  const VerificationSession({
    required this.metadata,
    required this.status,
    required this.rtlSource,
    this.summary,
    this.workflow,
  });

  /// Returns a copy with selected fields replaced.
  ///
  /// Set [clearSummary] to `true` to explicitly null out [summary].
  /// Set [clearWorkflow] to `true` to explicitly null out [workflow].
  /// (Passing `null` for either optional field is ambiguous — it would mean
  /// "keep the existing value", not "clear it".)
  VerificationSession copyWith({
    SessionMetadata? metadata,
    SessionStatus? status,
    String? rtlSource,
    SessionSummary? summary,
    VerificationWorkflow? workflow,
    bool clearSummary = false,
    bool clearWorkflow = false,
  }) {
    return VerificationSession(
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      rtlSource: rtlSource ?? this.rtlSource,
      summary: clearSummary ? null : (summary ?? this.summary),
      workflow: clearWorkflow ? null : (workflow ?? this.workflow),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationSession &&
          metadata == other.metadata &&
          status == other.status &&
          rtlSource == other.rtlSource &&
          summary == other.summary &&
          workflow == other.workflow;

  @override
  int get hashCode =>
      Object.hash(metadata, status, rtlSource, summary, workflow);
}
