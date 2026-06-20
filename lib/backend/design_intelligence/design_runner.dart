import 'design_context.dart';
import 'design_knowledge.dart';
import 'knowledge_provider.dart';
import 'knowledge_result.dart';
import 'providers/clock_provider.dart';
import 'providers/counter_provider.dart';
import 'providers/fsm_provider.dart';
import 'providers/handshake_provider.dart';
import 'providers/module_provider.dart';
import 'providers/register_provider.dart';
import 'providers/reset_provider.dart';

// ─── DesignRunner ─────────────────────────────────────────────────────────────

/// Orchestrates all [KnowledgeProvider] plugins and merges their output into
/// a single [DesignKnowledge].
///
/// **No provider-specific logic lives here.**  The runner only:
/// 1. Discovers which providers to run (defaults or caller-supplied list).
/// 2. Executes every provider concurrently via [Future.wait].
/// 3. Merges all [KnowledgeResult] objects into [DesignKnowledge].
///
/// Adding a new provider requires only inserting it into [_defaultProviders]
/// and extending [KnowledgeResult] / [DesignKnowledge] with the new type.
abstract class DesignRunner {
  DesignRunner._();

  /// Default provider suite, covering all seven detection domains.
  static const List<KnowledgeProvider> _defaultProviders = [
    ClockProvider(),
    ResetProvider(),
    FSMProvider(),
    CounterProvider(),
    RegisterProvider(),
    ModuleProvider(),
    HandshakeProvider(),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Run every provider in [providers] (or the built-in defaults) concurrently
  /// against [context] and return the merged [DesignKnowledge].
  ///
  /// Individual provider failures are silenced — a failing provider contributes
  /// an empty result rather than propagating an exception.
  static Future<DesignKnowledge> analyze(
    DesignContext context, {
    List<KnowledgeProvider>? providers,
  }) async {
    final ps      = providers ?? _defaultProviders;
    final futures = ps.map((p) => _safeAnalyze(p, context));
    final results = await Future.wait(futures);
    return _merge(results);
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  static Future<KnowledgeResult> _safeAnalyze(
    KnowledgeProvider provider,
    DesignContext context,
  ) async {
    try {
      return await provider.analyze(context);
    } catch (_) {
      return KnowledgeResult.empty(provider.providerKey);
    }
  }

  static DesignKnowledge _merge(List<KnowledgeResult> results) =>
      DesignKnowledge(
        clocks:     results.expand((r) => r.clocks).toList(),
        resets:     results.expand((r) => r.resets).toList(),
        fsms:       results.expand((r) => r.fsms).toList(),
        counters:   results.expand((r) => r.counters).toList(),
        registers:  results.expand((r) => r.registers).toList(),
        modules:    results.expand((r) => r.modules).toList(),
        handshakes: results.expand((r) => r.handshakes).toList(),
      );
}
