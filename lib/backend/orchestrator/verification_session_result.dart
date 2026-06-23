import '../counterexample/counterexample.dart' show CounterexampleReport;
import '../coverage_intelligence/coverage_intelligence.dart'
    show CoverageAssessment;
import '../design_intelligence/design_intelligence.dart' show DesignKnowledge;
import '../diagnostics_intelligence/diagnostics_intelligence.dart'
    show DiagnosticReport;
import '../explainability/explainability.dart' show VerificationExplanationSet;
import '../formal/formal.dart' show FormalPropertySet, FormalResult;
import '../planning/planning.dart' show VerificationPlan;
import '../property_inference/ranking/ranking.dart'
    show RankedCandidatePropertySet;
import '../property_inference/semantic/semantic.dart' show SemanticEvidenceSet;
import '../property_inference/synthesizer/synthesizer.dart'
    show CandidatePropertySet;
import '../repair_planning/repair_planning.dart' show RepairPlan;
import 'orchestrator_statistics.dart';
import 'orchestrator_status.dart';

// ─── VerificationSessionResult ────────────────────────────────────────────────

/// Immutable aggregate result of one complete [VerificationSession].
///
/// Contains every reasoning artifact produced by the enabled pipeline stages.
/// Disabled stages contribute their documented default values — never `null`.
///
/// Ownership:
/// - [VerificationOrchestrator] is the sole producer.
/// - No framework may modify any field after the result is assembled.
///
/// Invariants:
/// - All fields are non-null.
/// - [sessionId] matches the originating [VerificationSession.sessionId].
/// - [status] is [VerificationStatus.success] only when
///   [formalResult.success] is `true` and [counterexampleReport.isSuccessful].
///
/// Thread safety: immutable (all field types are themselves immutable or
/// effectively immutable) — safe to share across async boundaries.
///
/// Future extension points:
/// - Add [stageTimings] for per-stage profiling.
/// - Add [sessionMetadata] mirror for traceability.
/// - Add [verificationVersion] for schema evolution.
class VerificationSessionResult {
  /// Session ID of the originating [VerificationSession].
  final String sessionId;

  // ── Stage results — in pipeline order ────────────────────────────────────

  /// Design knowledge produced by the Design Intelligence stage.
  final DesignKnowledge designKnowledge;

  /// Semantic evidence extracted from [designKnowledge].
  final SemanticEvidenceSet semanticEvidence;

  /// Candidate properties synthesised from [semanticEvidence].
  final CandidatePropertySet candidateProperties;

  /// Candidate properties ranked by scoring engine.
  final RankedCandidatePropertySet rankedProperties;

  /// Formal properties emitted from [rankedProperties].
  final FormalPropertySet emittedProperties;

  /// Explanations generated for [emittedProperties] (empty when explainability
  /// is disabled via [OrchestratorContext.enableExplainability]).
  final VerificationExplanationSet explanations;

  /// Verification plan derived from [emittedProperties] and [explanations].
  final VerificationPlan verificationPlan;

  /// Raw formal verification result from the formal engine.
  final FormalResult formalResult;

  /// Coverage assessment (default healthy assessment when coverage is disabled
  /// via [OrchestratorContext.enableCoverage]).
  final CoverageAssessment coverageAssessment;

  /// Counterexample trace analysis of [formalResult].
  final CounterexampleReport counterexampleReport;

  /// Diagnostic report across all frameworks (empty when diagnostics is
  /// disabled via [OrchestratorContext.enableDiagnostics]).
  final DiagnosticReport diagnosticReport;

  /// Repair plan derived from [diagnosticReport] (empty when repair planning
  /// is disabled via [OrchestratorContext.enableRepairPlanning]).
  final RepairPlan repairPlan;

  // ── Orchestration metadata ────────────────────────────────────────────────

  /// Stage execution statistics ([OrchestratorStatistics.empty] when
  /// [OrchestratorContext.collectStatistics] is `false`).
  final OrchestratorStatistics statistics;

  /// Overall session outcome.
  final VerificationStatus status;

  const VerificationSessionResult({
    required this.sessionId,
    required this.designKnowledge,
    required this.semanticEvidence,
    required this.candidateProperties,
    required this.rankedProperties,
    required this.emittedProperties,
    required this.explanations,
    required this.verificationPlan,
    required this.formalResult,
    required this.coverageAssessment,
    required this.counterexampleReport,
    required this.diagnosticReport,
    required this.repairPlan,
    required this.statistics,
    required this.status,
  });

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// `true` when the session completed with [VerificationStatus.success].
  bool get isSuccessful => status == VerificationStatus.success;

  /// `true` when any diagnostic issues were found.
  bool get hasIssues => diagnosticReport.hasIssues;

  /// `true` when at least one repair step was planned.
  bool get hasRepairs => repairPlan.hasRepairs;

  /// `true` when the counterexample analysis found failures or coverage was not
  /// healthy — indicating the result requires engineer attention.
  bool get requiresAttention =>
      counterexampleReport.hasFailures || !coverageAssessment.isHealthy;

  // ── Identity ──────────────────────────────────────────────────────────────
  //
  // Equality compares only the final-stage output fields whose types implement
  // structural ==.  Intermediate pipeline artifacts (DesignKnowledge,
  // SemanticEvidenceSet, CandidatePropertySet, RankedCandidatePropertySet,
  // FormalPropertySet, VerificationExplanationSet, FormalResult) use object
  // identity internally and cannot be compared across independent runs.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerificationSessionResult &&
        sessionId            == other.sessionId            &&
        status               == other.status               &&
        verificationPlan     == other.verificationPlan     &&
        coverageAssessment   == other.coverageAssessment   &&
        counterexampleReport == other.counterexampleReport &&
        diagnosticReport     == other.diagnosticReport     &&
        repairPlan           == other.repairPlan           &&
        statistics           == other.statistics;
  }

  @override
  int get hashCode => Object.hash(
        sessionId, status, statistics,
        counterexampleReport, diagnosticReport, repairPlan);

  @override
  String toString() =>
      'VerificationSessionResult('
      'session=$sessionId, '
      'status=${status.name}, '
      'issues=${diagnosticReport.issues.length}, '
      'repairs=${repairPlan.steps.length})';
}
