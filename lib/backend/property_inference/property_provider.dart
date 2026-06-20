import 'property_context.dart';
import 'property_result.dart';

// ─── PropertyProvider ─────────────────────────────────────────────────────────

/// Abstract interface for a single-responsibility property inference unit.
///
/// Rules:
/// - Each provider owns exactly one inference domain.
/// - Providers must not import or depend on one another.
/// - Providers must not contain UI, parser, repair, or formal-execution logic.
/// - All returned [FormalProperty] instances must be immutable.
abstract class PropertyProvider {
  const PropertyProvider();

  /// Unique key identifying this provider.  Used for diagnostics and merging.
  String get providerKey;

  /// Infer formal properties from the given [context].
  ///
  /// Must never throw — error handling is the caller's responsibility via
  /// [PropertyRunner._safeInfer].
  Future<PropertyResult> infer(PropertyContext context);
}
