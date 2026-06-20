// ─── Property Inference Models ────────────────────────────────────────────────
//
// Shared constants and types used across every PropertyProvider.
// Contains no design-intelligence logic and no formal-backend logic.

/// Confidence level of an inferred [FormalProperty].
///
/// Stored as `metadata['confidence']` on every emitted property.
/// Consumers can filter or triage by confidence without inspecting expressions.
enum PropertyConfidence {
  /// Structurally guaranteed by DesignKnowledge — almost certainly correct.
  definite,

  /// High-probability heuristic — correct in the common case; validate before shipping.
  likely,

  /// Structural candidate — requires manual review or counterexample confirmation.
  candidate,
}

/// Namespace prefixes for building stable, unique property IDs.
///
/// IDs follow the pattern: `{prefix}.{signal_or_register}.{detail}`
/// e.g. `inferred.reset.rst_n.releases` or `inferred.fsm.state.IDLE.reachable`.
abstract class PropertyIdPrefix {
  PropertyIdPrefix._();

  static const reset     = 'inferred.reset';
  static const fsm       = 'inferred.fsm';
  static const counter   = 'inferred.counter';
  static const handshake = 'inferred.handshake';
  static const safety    = 'inferred.safety';
}
