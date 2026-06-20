import 'design_context.dart';
import 'knowledge_result.dart';

// ─── KnowledgeProvider ────────────────────────────────────────────────────────

/// Abstract interface for a single-responsibility semantic analysis unit.
///
/// Each concrete provider owns exactly one extraction domain (clocks, resets,
/// FSMs, …) and is:
/// - **Independent**: providers must not import or call one another.
/// - **Testable in isolation**: [analyze] is a pure async function of [context].
/// - **Immutable in output**: the returned [KnowledgeResult] is const-safe.
///
/// To add a new knowledge domain, implement [KnowledgeProvider], add an entry
/// to `DesignRunner._defaultProviders`, and extend [KnowledgeResult] /
/// [DesignKnowledge] with the new type list.  No existing providers change.
abstract class KnowledgeProvider {
  const KnowledgeProvider();

  /// Short identifier used for logging and [KnowledgeResult.providerKey].
  String get providerKey;

  /// Analyse [context] and return all semantic facts within this provider's
  /// responsibility.
  ///
  /// Must not throw — return [KnowledgeResult.empty] on error.
  Future<KnowledgeResult> analyze(DesignContext context);
}
