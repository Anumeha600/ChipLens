// ─── OrchestratorStage ────────────────────────────────────────────────────────

/// Identifies each discrete stage in the [VerificationOrchestrator] pipeline.
///
/// Stages are ordered from first to last — [initialization] to [completed].
/// The enum declaration order mirrors the execution order; no stage may begin
/// before its predecessor has finished.
///
/// Optional stages ([explainability], [coverageIntelligence], [diagnostics],
/// [repairPlanning]) are skipped when the corresponding
/// [OrchestratorContext] flag is `false`.
///
/// Future extension points:
/// - Add [parallelFormalVerification] for multi-engine execution.
/// - Add [incrementalAnalysis] for cached intermediate results.
enum OrchestratorStage {
  /// Session setup and input validation.
  initialization,

  /// RTL design analysis via Design Intelligence.
  designIntelligence,

  /// Semantic evidence extraction from design knowledge.
  semanticEvidence,

  /// Candidate property synthesis from semantic evidence.
  propertySynthesis,

  /// Property ranking and scoring.
  propertyRanking,

  /// Formal property emission from ranked candidates.
  propertyEmission,

  /// Verification explanation generation (optional).
  explainability,

  /// Verification plan construction.
  verificationPlanning,

  /// Formal verification engine execution.
  formalVerification,

  /// Coverage assessment from formal results (optional).
  coverageIntelligence,

  /// Counterexample trace analysis.
  counterexampleAnalysis,

  /// Diagnostic issue identification across frameworks (optional).
  diagnostics,

  /// Repair step planning from diagnostic report (optional).
  repairPlanning,

  /// Session finalization and result assembly.
  completed,
}
