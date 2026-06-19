/// Origin of a [Diagnostic] — which subsystem emitted it.
///
/// The UI must not branch on this value for display purposes; diagnostics are
/// styled by severity, not by origin.  The field exists so test code,
/// analytics, and the deduplication pass can distinguish sources without
/// parsing the [Diagnostic.id] string.
enum DiagnosticSource {
  /// Emitted by the built-in ChipLens [QualityAnalyzer] rule set.
  internal,

  /// Emitted by the external Verilator linter.
  verilator,

  /// Emitted by the Yosys open-source synthesis suite.
  yosys,

  /// Emitted by the Icarus Verilog compiler/simulator (iverilog + vvp).
  icarus,

  /// Emitted by the RTL Coverage Analysis engine.
  coverage,

  /// Emitted by a formal verification engine (SymbiYosys, JasperGold, …).
  formal,
}
