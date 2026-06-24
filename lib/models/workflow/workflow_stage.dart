/// Major lifecycle stage in a ChipLens verification workflow.
///
/// Stages are ordered by their typical execution sequence:
/// design intelligence → property synthesis → property ranking →
/// property emission → verification → coverage → diagnostics → repair.
enum WorkflowStage {
  /// Extract RTL structure and module hierarchy.
  designIntelligence,

  /// Synthesise formal properties from the design model.
  propertySynthesis,

  /// Rank properties by risk and coverage impact.
  propertyRanking,

  /// Emit synthesised properties to the tool input format.
  propertyEmission,

  /// Run formal/simulation verification tools.
  verification,

  /// Collect and aggregate coverage data.
  coverage,

  /// Analyse and classify tool-emitted diagnostics.
  diagnostics,

  /// Generate and score repair candidates.
  repair,
}
