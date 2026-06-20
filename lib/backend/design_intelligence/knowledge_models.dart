// ─── Knowledge Models ─────────────────────────────────────────────────────────
//
// Immutable semantic facts produced by individual KnowledgeProvider instances.
// These types are engine-agnostic and carry no diagnostic, repair, or UI logic.

// ── ClockInfo ─────────────────────────────────────────────────────────────────

/// Describes a clock signal detected in the RTL.
class ClockInfo {
  /// Signal name as it appears in the RTL source.
  final String name;

  /// True when the name matches a well-known primary clock convention
  /// (e.g. `clk`, `sys_clk`, `pclk`).
  final bool isPrimaryClock;

  /// True when the signal is driven by a posedge trigger but its name does
  /// not match a primary convention — heuristic classification.
  final bool isCandidate;

  /// True when the clock is derived from another clock (e.g. divided or gated).
  /// Reserved for future inference; always `false` in current providers.
  final bool isGenerated;

  const ClockInfo({
    required this.name,
    this.isPrimaryClock = false,
    this.isCandidate    = false,
    this.isGenerated    = false,
  });

  @override
  String toString() =>
      'ClockInfo($name, primary: $isPrimaryClock, candidate: $isCandidate)';
}

// ── ResetInfo ─────────────────────────────────────────────────────────────────

/// Describes a reset signal detected in the RTL.
class ResetInfo {
  final String name;

  /// Asserted inside a posedge-only always block (`if (rst) ...`).
  final bool isSynchronous;

  /// Appears in a multi-edge sensitivity list
  /// (`always @(posedge clk or negedge rst_n)`).
  final bool isAsynchronous;

  /// Asserted when the signal is logic-1.
  final bool isActiveHigh;

  /// Asserted when the signal is logic-0 (typically names ending in `_n`).
  final bool isActiveLow;

  const ResetInfo({
    required this.name,
    this.isSynchronous  = false,
    this.isAsynchronous = false,
    this.isActiveHigh   = false,
    this.isActiveLow    = false,
  });

  @override
  String toString() {
    final polarity = isActiveHigh ? 'active-high' : 'active-low';
    final kind     = isAsynchronous ? 'async' : 'sync';
    return 'ResetInfo($name, $kind, $polarity)';
  }
}

// ── FSMInfo ───────────────────────────────────────────────────────────────────

/// Describes a Finite State Machine detected in the RTL.
class FSMInfo {
  /// Name of the state-holding register (e.g. `state`, `current_state`).
  final String stateRegister;

  /// Number of bits used to encode states (derived from the register width).
  final int encodingWidth;

  /// Names of candidate states — from `localparam`/`parameter` definitions
  /// that feed a case statement, or from pre-computed IR data.
  final List<String> candidateStates;

  /// Encoding style hint: `'localparam'`, `'parameter'`, `'none'`, `'unknown'`.
  final String encodingStyle;

  const FSMInfo({
    required this.stateRegister,
    required this.encodingWidth,
    this.candidateStates = const [],
    this.encodingStyle   = 'unknown',
  });

  @override
  String toString() =>
      'FSMInfo($stateRegister, ${encodingWidth}b, states: ${candidateStates.length})';
}

// ── CounterInfo ───────────────────────────────────────────────────────────────

/// Describes a counter register detected in the RTL.
class CounterInfo {
  final String name;

  /// Declared bit-width (e.g. 8 for `reg [7:0] cnt`).
  final int width;

  /// Signal is used in an increment assignment (`name <= name + ...`).
  final bool isIncrement;

  /// Signal is used in a decrement assignment (`name <= name - ...`).
  final bool isDecrement;

  const CounterInfo({
    required this.name,
    this.width       = 1,
    this.isIncrement = false,
    this.isDecrement = false,
  });

  @override
  String toString() =>
      'CounterInfo($name, ${width}b, incr: $isIncrement, decr: $isDecrement)';
}

// ── RegisterInfo ──────────────────────────────────────────────────────────────

/// Describes a data register or combinational signal detected in the RTL.
class RegisterInfo {
  final String name;

  /// Declared bit-width (1 for single-bit signals).
  final int width;

  /// Driven from a clocked `always @(posedge ...)` block.
  final bool isSequential;

  /// Driven by an `assign` statement or `always @(*)` block.
  final bool isCombinational;

  const RegisterInfo({
    required this.name,
    this.width           = 1,
    this.isSequential    = false,
    this.isCombinational = false,
  });

  @override
  String toString() {
    final kind = isSequential ? 'sequential' : 'combinational';
    return 'RegisterInfo($name, ${width}b, $kind)';
  }
}

// ── PortInfo / ModuleInfo ─────────────────────────────────────────────────────

/// Describes a single port on a module.
class PortInfo {
  final String name;

  /// `'input'`, `'output'`, or `'inout'`.
  final String direction;

  final int width;

  const PortInfo({
    required this.name,
    required this.direction,
    this.width = 1,
  });

  @override
  String toString() => 'PortInfo($direction $name [${width}b])';
}

/// Describes a module detected in the RTL hierarchy.
class ModuleInfo {
  final String name;
  final List<PortInfo> ports;

  /// `parameter` declarations: name → value string.
  final Map<String, String> parameters;

  /// Names of sub-module instances instantiated within this module.
  final List<String> submodules;

  const ModuleInfo({
    required this.name,
    this.ports      = const [],
    this.parameters = const {},
    this.submodules = const [],
  });

  List<PortInfo> get inputs  => ports.where((p) => p.direction == 'input').toList();
  List<PortInfo> get outputs => ports.where((p) => p.direction == 'output').toList();

  @override
  String toString() =>
      'ModuleInfo($name, ports: ${ports.length}, params: ${parameters.length})';
}

// ── HandshakeInfo ─────────────────────────────────────────────────────────────

/// Describes a handshake protocol pair detected in the RTL.
class HandshakeInfo {
  /// Signal names that participate in the protocol.
  final List<String> signals;

  /// Heuristic protocol classification:
  /// `'valid_ready'`, `'req_ack'`, `'start_done'`, or `'unknown'`.
  final String protocolHint;

  const HandshakeInfo({
    required this.signals,
    required this.protocolHint,
  });

  @override
  String toString() => 'HandshakeInfo($protocolHint, signals: $signals)';
}
