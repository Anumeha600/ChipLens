import 'knowledge_models.dart';

// ─── KnowledgeResult ──────────────────────────────────────────────────────────

/// The semantic facts contributed by a single [KnowledgeProvider] invocation.
///
/// Each provider populates only the list(s) relevant to its responsibility
/// and leaves all other lists empty.  [DesignRunner] merges every provider's
/// result into a single [DesignKnowledge].
///
/// **No diagnostics.  No repairs.  No warnings.  Semantic facts only.**
///
/// Adding a new knowledge dimension requires:
/// 1. A new `List<FooInfo>` field here.
/// 2. A matching field in [DesignKnowledge].
/// 3. One more `expand` line in `DesignRunner._merge`.
/// No existing providers need modification.
class KnowledgeResult {
  /// Identifies the provider that produced this result (for debugging/tracing).
  final String providerKey;

  final List<ClockInfo>     clocks;
  final List<ResetInfo>     resets;
  final List<FSMInfo>       fsms;
  final List<CounterInfo>   counters;
  final List<RegisterInfo>  registers;
  final List<ModuleInfo>    modules;
  final List<HandshakeInfo> handshakes;

  const KnowledgeResult({
    required this.providerKey,
    this.clocks     = const [],
    this.resets     = const [],
    this.fsms       = const [],
    this.counters   = const [],
    this.registers  = const [],
    this.modules    = const [],
    this.handshakes = const [],
  });

  /// Convenience: an empty result (provider found nothing noteworthy).
  factory KnowledgeResult.empty(String providerKey) =>
      KnowledgeResult(providerKey: providerKey);

  bool get isEmpty =>
      clocks.isEmpty &&
      resets.isEmpty &&
      fsms.isEmpty &&
      counters.isEmpty &&
      registers.isEmpty &&
      modules.isEmpty &&
      handshakes.isEmpty;
}
