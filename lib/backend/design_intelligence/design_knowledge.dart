import 'knowledge_models.dart';

// ─── DesignKnowledge ──────────────────────────────────────────────────────────

/// The merged semantic view of an RTL design, produced by [DesignRunner].
///
/// Each section is the union of every [KnowledgeProvider]'s contribution for
/// that domain.  The object is **immutable** — consumers can safely hold a
/// reference across async boundaries.
///
/// Consumers (Formal Verification, Repair, Coverage Advisor, AI, …) read only
/// the sections they care about and are unaffected when new sections are added.
class DesignKnowledge {
  final List<ClockInfo>     clocks;
  final List<ResetInfo>     resets;
  final List<FSMInfo>       fsms;
  final List<CounterInfo>   counters;
  final List<RegisterInfo>  registers;
  final List<ModuleInfo>    modules;
  final List<HandshakeInfo> handshakes;

  const DesignKnowledge({
    this.clocks     = const [],
    this.resets     = const [],
    this.fsms       = const [],
    this.counters   = const [],
    this.registers  = const [],
    this.modules    = const [],
    this.handshakes = const [],
  });

  // ── Convenience accessors ──────────────────────────────────────────────────

  bool get hasClock     => clocks.isNotEmpty;
  bool get hasReset     => resets.isNotEmpty;
  bool get hasFSM       => fsms.isNotEmpty;
  bool get hasCounter   => counters.isNotEmpty;
  bool get hasHandshake => handshakes.isNotEmpty;

  /// Primary clocks (those matching well-known clock naming conventions).
  List<ClockInfo> get primaryClocks =>
      clocks.where((c) => c.isPrimaryClock).toList();

  /// Asynchronous resets detected in the design.
  List<ResetInfo> get asyncResets =>
      resets.where((r) => r.isAsynchronous).toList();

  /// Synchronous resets detected in the design.
  List<ResetInfo> get syncResets =>
      resets.where((r) => r.isSynchronous).toList();

  @override
  String toString() =>
      'DesignKnowledge('
      'clocks: ${clocks.length}, '
      'resets: ${resets.length}, '
      'fsms: ${fsms.length}, '
      'counters: ${counters.length}, '
      'registers: ${registers.length}, '
      'modules: ${modules.length}, '
      'handshakes: ${handshakes.length})';
}
