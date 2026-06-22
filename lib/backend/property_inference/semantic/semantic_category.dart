// ─── SemanticCategory ─────────────────────────────────────────────────────────

/// Classifies the design-level domain that a [SemanticEvidence] item belongs to.
///
/// New categories may be added without changing any existing API — consumers
/// that pattern-match should include a default/wildcard arm.
enum SemanticCategory {
  /// Finite state machine — state register and candidate states.
  fsm,

  /// Counter register — increment, decrement, or both.
  counter,

  /// Reset signal — synchronous or asynchronous.
  reset,

  /// Handshake protocol pair — valid/ready, req/ack, etc.
  handshake,

  /// Clock signal — primary or candidate.
  clock,

  /// Declared register with no more specific classification.
  register,

  /// Signal driven entirely by combinational logic (`assign` or `always @(*)`).
  combinational,

  /// Arithmetic operation or result register inferred from naming or assignment.
  arithmetic,

  /// Sequential register driven from a clocked always block.
  sequential,

  /// User-defined or catch-all category for extension.
  custom,
}
