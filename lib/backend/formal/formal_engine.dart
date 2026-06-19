import 'formal_context.dart';
import 'formal_result.dart';

export 'formal_context.dart';

// ─── FormalEngine ─────────────────────────────────────────────────────────────

/// Common interface for all formal verification backends.
///
/// Implementing [FormalEngine] is the **only** change required to integrate a
/// new formal tool (JasperGold, Tabby CAD, Cadence Conformal, …) into the
/// framework.
///
/// Implementors must:
/// - Contain no tool-agnostic orchestration logic (that belongs in [FormalRunner]).
/// - Populate [FormalResult.provenProperties], [FormalResult.failedProperties],
///   and [FormalResult.unknownProperties] from the tool's raw output.
/// - Never throw on tool unavailability — return [FormalResult.unavailable()]
///   or let [FormalRunner] guard with [isAvailable].
abstract class FormalEngine {
  const FormalEngine();

  /// Human-readable engine identifier, e.g. `'SymbiYosys'`.
  String get engineName;

  /// Returns `true` when the engine binary and all required dependencies are
  /// present on the current system.
  Future<bool> isAvailable();

  /// Run formal verification with [context] and return a [FormalResult].
  ///
  /// The result always contains raw stdout/stderr so that
  /// [FormalDiagnosticParser] can produce [Diagnostic] objects without
  /// re-running the tool.
  Future<FormalResult> verify(FormalContext context);
}
