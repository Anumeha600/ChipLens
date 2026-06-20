import '../design_intelligence/design_knowledge.dart';

// ─── PropertyContext ──────────────────────────────────────────────────────────

/// Immutable input to every [PropertyProvider].
///
/// Carries the semantic view of the design ([knowledge]) plus an open-ended
/// [config] map that providers may consult for tuning without requiring
/// interface changes.
class PropertyContext {
  /// Merged design knowledge produced by the Design Intelligence Framework.
  final DesignKnowledge knowledge;

  /// Provider-specific tuning parameters (e.g. `{'max_counter_width': 32}`).
  final Map<String, dynamic> config;

  const PropertyContext({
    required this.knowledge,
    this.config = const {},
  });
}
