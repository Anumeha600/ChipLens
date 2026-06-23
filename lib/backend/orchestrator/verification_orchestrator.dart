import '../counterexample/counterexample.dart'
    show
        CounterexampleAnalyzer,
        CounterexampleContext,
        CounterexampleReport;
import '../coverage_intelligence/coverage_intelligence.dart'
    show
        CoverageAssessment,
        CoverageConfidence,
        CoverageIntelligenceContext,
        CoverageIntelligenceEngine,
        CoverageRisk,
        CoverageStatistics,
        CoverageSummary;
import '../design_intelligence/design_intelligence.dart'
    show DesignContext, DesignKnowledge, DesignRunner;
import '../diagnostics_intelligence/diagnostics_intelligence.dart'
    show
        DiagnosticConfidence,
        DiagnosticContext,
        DiagnosticReport,
        DiagnosticSeverity,
        DiagnosticStatistics,
        DiagnosticSummary,
        DiagnosticsEngine;
import '../explainability/explainability.dart'
    show
        ExplanationContext,
        VerificationExplainer,
        VerificationExplanationSet;
import '../formal/formal.dart'
    show
        FormalContext,
        FormalEngine,
        FormalPropertySet,
        FormalResult,
        FormalRunner;
import '../planning/planning.dart'
    show PlanningContext, VerificationPlan, VerificationPlanner;
import '../property_inference/emitter/emitter.dart'
    show EmitterContext, PropertyEmitter;
import '../property_inference/ranking/ranking.dart'
    show RankedCandidatePropertySet, RankingEngine;
import '../property_inference/semantic/semantic.dart'
    show SemanticEvidenceExtractor, SemanticEvidenceSet;
import '../property_inference/synthesizer/synthesizer.dart'
    show CandidatePropertySet, PropertySynthesizer;
import '../repair_planning/repair_planning.dart'
    show
        RepairComplexity,
        RepairContext,
        RepairPlan,
        RepairPlanner,
        RepairPriority,
        RepairStatistics;
import '../../models/coverage_report.dart' show CoverageReport;
import 'orchestrator_context.dart';
import 'orchestrator_statistics.dart';
import 'orchestrator_status.dart';
import 'verification_session.dart';
import 'verification_session_result.dart';

// ─── VerificationOrchestrator ─────────────────────────────────────────────────

/// Top-level coordinator for the ChipLens verification pipeline.
///
/// Executes every enabled reasoning framework in a fixed, deterministic order
/// and assembles the results into a single [VerificationSessionResult].
///
/// Inputs:
/// - [VerificationSession] — RTL source and session metadata.
/// - [OrchestratorContext] — flags controlling which optional stages run.
///
/// Output:
/// - [VerificationSessionResult] — all framework results plus statistics.
///
/// Pipeline order (see [OrchestratorStage]):
/// 1. Initialization
/// 2. Design Intelligence
/// 3. Semantic Evidence
/// 4. Property Synthesis
/// 5. Property Ranking
/// 6. Property Emission
/// 7. Explainability (optional)
/// 8. Verification Planning
/// 9. Formal Verification
/// 10. Coverage Intelligence (optional)
/// 11. Counterexample Analysis
/// 12. Diagnostics (optional)
/// 13. Repair Planning (optional)
/// 14. Completed
///
/// Invariants:
/// - Does NOT implement any reasoning algorithm.
/// - Does NOT parse RTL.
/// - Does NOT modify any framework output.
/// - Stateless: every [run] call is fully independent.
/// - Output is deterministic for identical inputs.
/// - No mutable static fields, no singleton state, no caches.
///
/// Error policy:
/// - [FormalRunner.run] failures fall back to [FormalResult.unavailable];
///   all other stage exceptions propagate as [VerificationStatus.failed].
/// - [OrchestratorContext.timeout] fires as [VerificationStatus.cancelled].
///
/// Thread safety: stateless — multiple concurrent [run] calls are safe.
///
/// Future extension points:
/// - Inject custom [FormalEngine] via the optional [formalEngine] parameter.
/// - Add [progressCallback] for real-time stage notifications.
/// - Add [checkpointDir] for resume-from-checkpoint support.
class VerificationOrchestrator {
  /// Creates a [VerificationOrchestrator].  Stateless — no configuration stored.
  const VerificationOrchestrator();

  // ── Static defaults for disabled / cancelled stages ───────────────────────

  static final SemanticEvidenceSet _emptySemanticEvidence =
      SemanticEvidenceSet();

  static final CandidatePropertySet _emptyCandidateProperties =
      CandidatePropertySet();

  static final RankedCandidatePropertySet _emptyRankedProperties =
      RankedCandidatePropertySet();

  static final VerificationExplanationSet _emptyExplanations =
      VerificationExplanationSet();

  static final CoverageAssessment _defaultCoverageAssessment = CoverageAssessment(
    summary: const CoverageSummary(
      overview:           'Coverage intelligence is disabled for this session.',
      strongestDimension: 'state',
      weakestDimension:   'state',
      dominantIssue:      'None',
    ),
    risk:            CoverageRisk.minimal,
    confidence:      CoverageConfidence.veryHigh,
    recommendations: const [],
    statistics:      CoverageStatistics.empty,
  );

  static final CounterexampleReport _defaultCounterexampleReport =
      const CounterexampleAnalyzer().analyze(
        FormalResult.unavailable(),
        const CounterexampleContext(),
      );

  static final DiagnosticReport _defaultDiagnosticReport = DiagnosticReport(
    summary: const DiagnosticSummary(
      overview:           'Diagnostics intelligence is disabled for this session.',
      primaryIssue:       'None',
      dominantCategory:   'none',
      verificationHealth: 'healthy',
    ),
    issues:           const [],
    statistics:       DiagnosticStatistics.empty,
    overallSeverity:  DiagnosticSeverity.informational,
    overallConfidence: DiagnosticConfidence.veryHigh,
  );

  static final RepairPlan _defaultRepairPlan = RepairPlan(
    steps:            const [],
    statistics:       RepairStatistics.empty,
    overallPriority:  RepairPriority.low,
    overallComplexity: RepairComplexity.low,
  );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Runs the complete verification pipeline for [session] under [context].
  ///
  /// Optional [formalEngine] allows injection of a custom [FormalEngine]
  /// implementation (primarily for unit testing without SymbiYosys).
  ///
  /// Returns a [VerificationSessionResult] regardless of outcome.  Check
  /// [VerificationSessionResult.status] to determine the overall result.
  ///
  /// Complexity: O(s) for stage dispatch; O(n log n) dominated by property
  /// synthesis and ranking where n = evidence items.
  Future<VerificationSessionResult> run(
    VerificationSession session,
    OrchestratorContext context, {
    FormalEngine? formalEngine,
  }) async {
    final stopwatch = Stopwatch()..start();
    var completed = 0, skipped = 0, failed = 0;

    Future<VerificationSessionResult> pipeline() async {
      // ── 1. Initialization ───────────────────────────────────────────────
      completed++;

      // ── 2. Design Intelligence ──────────────────────────────────────────
      final designKnowledge = await DesignRunner.analyze(
        DesignContext(
          rtlSource:  session.rtlSource,
          topModule:  session.topModule,
        ),
      );
      completed++;

      // ── 3. Semantic Evidence ────────────────────────────────────────────
      final semanticEvidence =
          SemanticEvidenceExtractor.extract(designKnowledge);
      completed++;

      // ── 4. Property Synthesis ───────────────────────────────────────────
      final candidateProperties =
          PropertySynthesizer.synthesize(semanticEvidence);
      completed++;

      // ── 5. Property Ranking ─────────────────────────────────────────────
      final rankedProperties =
          RankingEngine.rank(candidateProperties, semanticEvidence);
      completed++;

      // ── 6. Property Emission ────────────────────────────────────────────
      final emitterResult = await const PropertyEmitter().emit(
        rankedProperties,
        const EmitterContext(),
      );
      completed++;

      // ── 7. Explainability (optional) ────────────────────────────────────
      final VerificationExplanationSet explanations;
      if (context.enableExplainability) {
        explanations = const VerificationExplainer().explain(
          emitterResult.properties,
          const ExplanationContext(),
        );
        completed++;
      } else {
        explanations = _emptyExplanations;
        skipped++;
      }

      // ── 8. Verification Planning ────────────────────────────────────────
      final planningResult = const VerificationPlanner().plan(
        emitterResult.properties,
        explanations,
        const PlanningContext(),
      );
      completed++;

      // ── 9. Formal Verification ──────────────────────────────────────────
      FormalResult formalResult;
      try {
        formalResult = await FormalRunner.run(
          FormalContext(
            rtlSource:  session.rtlSource,
            topModule:  session.topModule,
          ),
          engine: formalEngine,
        );
      } catch (_) {
        // Engine unavailable or environment error — use sentinel so downstream
        // stages (CounterexampleAnalyzer, DiagnosticsEngine) can still run.
        formalResult = FormalResult.unavailable();
      }
      completed++;

      // ── 10. Coverage Intelligence (optional) ────────────────────────────
      final CoverageAssessment coverageAssessment;
      if (context.enableCoverage) {
        coverageAssessment = const CoverageIntelligenceEngine().assess(
          CoverageReport.empty(),
          const CoverageIntelligenceContext(),
        );
        completed++;
      } else {
        coverageAssessment = _defaultCoverageAssessment;
        skipped++;
      }

      // ── 11. Counterexample Analysis ─────────────────────────────────────
      final counterexampleReport = const CounterexampleAnalyzer().analyze(
        formalResult,
        const CounterexampleContext(),
      );
      completed++;

      // ── 12. Diagnostics (optional) ──────────────────────────────────────
      final DiagnosticReport diagnosticReport;
      if (context.enableDiagnostics) {
        diagnosticReport = const DiagnosticsEngine().analyze(
          coverageAssessment,
          counterexampleReport,
          explanations,
          planningResult.plan,
          DiagnosticContext(),
        );
        completed++;
      } else {
        diagnosticReport = _defaultDiagnosticReport;
        skipped++;
      }

      // ── 13. Repair Planning (optional) ──────────────────────────────────
      final RepairPlan repairPlan;
      if (context.enableRepairPlanning) {
        repairPlan = const RepairPlanner().plan(
          diagnosticReport,
          RepairContext(),
        );
        completed++;
      } else {
        repairPlan = _defaultRepairPlan;
        skipped++;
      }

      // ── 14. Completed ────────────────────────────────────────────────────
      completed++;

      stopwatch.stop();

      final stats = context.collectStatistics
          ? OrchestratorStatistics(
              totalExecutionTime: stopwatch.elapsed,
              completedStages:    completed,
              skippedStages:      skipped,
              failedStages:       failed,
            )
          : OrchestratorStatistics.empty;

      final status = _computeStatus(formalResult, counterexampleReport);

      return VerificationSessionResult(
        sessionId:            session.sessionId,
        designKnowledge:      designKnowledge,
        semanticEvidence:     semanticEvidence,
        candidateProperties:  candidateProperties,
        rankedProperties:     rankedProperties,
        emittedProperties:    emitterResult.properties,
        explanations:         explanations,
        verificationPlan:     planningResult.plan,
        formalResult:         formalResult,
        coverageAssessment:   coverageAssessment,
        counterexampleReport: counterexampleReport,
        diagnosticReport:     diagnosticReport,
        repairPlan:           repairPlan,
        statistics:           stats,
        status:               status,
      );
    }

    try {
      if (context.timeout > Duration.zero) {
        return await pipeline().timeout(
          context.timeout,
          onTimeout: () {
            stopwatch.stop();
            return _buildCancelledResult(
              session, context, stopwatch.elapsed,
              completed, skipped, failed,
            );
          },
        );
      }
      return await pipeline();
    } catch (e) {
      stopwatch.stop();
      return _buildFailedResult(
        session, context, stopwatch.elapsed,
        completed, skipped, failed,
      );
    }
  }

  // ── Status computation ────────────────────────────────────────────────────

  static VerificationStatus _computeStatus(
    FormalResult formalResult,
    CounterexampleReport counterexampleReport,
  ) {
    if (formalResult.success && counterexampleReport.isSuccessful) {
      return VerificationStatus.success;
    }
    return VerificationStatus.partialSuccess;
  }

  // ── Cancelled result (timeout) ────────────────────────────────────────────

  static VerificationSessionResult _buildCancelledResult(
    VerificationSession session,
    OrchestratorContext context,
    Duration elapsed,
    int completed,
    int skipped,
    int failed,
  ) {
    final stats = context.collectStatistics
        ? OrchestratorStatistics(
            totalExecutionTime: elapsed,
            completedStages:    completed,
            skippedStages:      skipped,
            failedStages:       failed,
          )
        : OrchestratorStatistics.empty;

    return VerificationSessionResult(
      sessionId:            session.sessionId,
      designKnowledge:      const DesignKnowledge(),
      semanticEvidence:     _emptySemanticEvidence,
      candidateProperties:  _emptyCandidateProperties,
      rankedProperties:     _emptyRankedProperties,
      emittedProperties:    FormalPropertySet(),
      explanations:         _emptyExplanations,
      verificationPlan:     VerificationPlan(),
      formalResult:         FormalResult.unavailable(),
      coverageAssessment:   _defaultCoverageAssessment,
      counterexampleReport: _defaultCounterexampleReport,
      diagnosticReport:     _defaultDiagnosticReport,
      repairPlan:           _defaultRepairPlan,
      statistics:           stats,
      status:               VerificationStatus.cancelled,
    );
  }

  // ── Failed result (unrecoverable exception) ───────────────────────────────

  static VerificationSessionResult _buildFailedResult(
    VerificationSession session,
    OrchestratorContext context,
    Duration elapsed,
    int completed,
    int skipped,
    int failed,
  ) {
    final stats = context.collectStatistics
        ? OrchestratorStatistics(
            totalExecutionTime: elapsed,
            completedStages:    completed,
            skippedStages:      skipped,
            failedStages:       failed + 1,
          )
        : OrchestratorStatistics.empty;

    return VerificationSessionResult(
      sessionId:            session.sessionId,
      designKnowledge:      const DesignKnowledge(),
      semanticEvidence:     _emptySemanticEvidence,
      candidateProperties:  _emptyCandidateProperties,
      rankedProperties:     _emptyRankedProperties,
      emittedProperties:    FormalPropertySet(),
      explanations:         _emptyExplanations,
      verificationPlan:     VerificationPlan(),
      formalResult:         FormalResult.unavailable(),
      coverageAssessment:   _defaultCoverageAssessment,
      counterexampleReport: _defaultCounterexampleReport,
      diagnosticReport:     _defaultDiagnosticReport,
      repairPlan:           _defaultRepairPlan,
      statistics:           stats,
      status:               VerificationStatus.failed,
    );
  }
}
