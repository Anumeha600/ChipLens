import '../formal/formal_property_set.dart';
import 'property_context.dart';
import 'property_provider.dart';
import 'property_result.dart';
import 'providers/counter_property_provider.dart';
import 'providers/fsm_property_provider.dart';
import 'providers/handshake_property_provider.dart';
import 'providers/reset_property_provider.dart';
import 'providers/safety_property_provider.dart';

// ─── PropertyRunner ───────────────────────────────────────────────────────────

/// Coordinates execution of all [PropertyProvider] plugins.
///
/// - Runs every provider concurrently via [Future.wait].
/// - Wraps each call in [_safeInfer] so a failing provider cannot abort others.
/// - Merges all [PropertyResult] objects into one [FormalPropertySet].
/// - Contains zero provider-specific logic.
abstract class PropertyRunner {
  PropertyRunner._();

  static const List<PropertyProvider> _defaultProviders = [
    ResetPropertyProvider(),
    FSMPropertyProvider(),
    CounterPropertyProvider(),
    HandshakePropertyProvider(),
    SafetyPropertyProvider(),
  ];

  /// Infer formal properties from [context].
  ///
  /// Pass a custom [providers] list to run a subset or inject test doubles.
  static Future<FormalPropertySet> infer(
    PropertyContext context, {
    List<PropertyProvider>? providers,
  }) async {
    final ps      = providers ?? _defaultProviders;
    final futures = ps.map((p) => _safeInfer(p, context));
    final results = await Future.wait(futures);
    return _merge(results);
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static Future<PropertyResult> _safeInfer(
    PropertyProvider provider,
    PropertyContext context,
  ) async {
    try {
      return await provider.infer(context);
    } catch (_) {
      return PropertyResult.empty(provider.providerKey);
    }
  }

  static FormalPropertySet _merge(List<PropertyResult> results) {
    final set = FormalPropertySet();
    for (final result in results) {
      for (final property in result.properties) {
        try {
          set.add(property);
        } on ArgumentError {
          // Duplicate id — providers are independent and should not collide;
          // guard absorbs the rare edge case without propagating.
        }
      }
    }
    return set;
  }
}
