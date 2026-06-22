import '../../formal/formal_property_set.dart';

// ─── EmitterResult ────────────────────────────────────────────────────────────

/// Immutable result of one [PropertyEmitter] emission pass.
///
/// [properties]    — the emitted [FormalPropertySet] in ranking order.
/// [emittedCount]  — number of candidates successfully translated.
/// [skippedCount]  — number of candidates excluded by policy.
/// [warnings]      — non-fatal diagnostic messages produced during emission.
/// [executionTime] — wall-clock duration of the emission pass.
///
/// Invariants:
/// - [emittedCount] == [properties.length].
/// - [emittedCount] + [skippedCount] equals the size of the ranked input.
/// - No setters; no mutable fields.
class EmitterResult {
  final FormalPropertySet properties;
  final int emittedCount;
  final int skippedCount;
  final List<String> warnings;
  final Duration executionTime;

  EmitterResult({
    required this.properties,
    required this.emittedCount,
    required this.skippedCount,
    required List<String> warnings,
    required this.executionTime,
  }) : warnings = List.unmodifiable(warnings);

  // ── Convenience getters ───────────────────────────────────────────────────

  /// `true` when no properties were emitted.
  bool get isEmpty => emittedCount == 0;

  /// `true` when at least one property was emitted.
  bool get isNotEmpty => emittedCount > 0;

  /// `true` when the emission produced at least one warning.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Fraction of input candidates that were emitted (0.0 when input is empty).
  double get emissionRate {
    final total = emittedCount + skippedCount;
    return total == 0 ? 0.0 : emittedCount / total;
  }

  @override
  String toString() =>
      'EmitterResult(emitted=$emittedCount, skipped=$skippedCount, '
      '${executionTime.inMicroseconds}µs)';
}
