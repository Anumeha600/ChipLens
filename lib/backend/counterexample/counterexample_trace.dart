import 'counterexample_signal.dart';

// ─── CounterexampleTrace ──────────────────────────────────────────────────────

/// Reconstructed failure trace from [FormalResult].
///
/// Trace reconstruction is pure reasoning from property lists — no waveforms,
/// VCD files, or SymbiYosys output are parsed here.
///
/// Each entry in [signals] corresponds to a property identifier that was
/// classified as failed or unknown.  The ordering matches the order in
/// [FormalResult.failedProperties] followed by [FormalResult.unknownProperties].
///
/// Invariants:
/// - [signals] is unmodifiable.
/// - [failedProperties] is unmodifiable.
/// - [estimatedDepth] is always non-negative; throws [ArgumentError] otherwise.
///
/// Future extension points:
/// - Add [waveformSegments] for VCD-backed trace data.
/// - Add [signalDependencies] for dependency-graph analysis.
class CounterexampleTrace {
  /// Signals participating in the counterexample, in insertion order.
  final List<CounterexampleSignal> signals;

  /// Ordered list of property identifiers for which a counterexample exists.
  final List<String> failedProperties;

  /// Identifier of the first failed property, or an empty string when none.
  final String firstFailure;

  /// Heuristic estimate of trace depth in time steps.
  ///
  /// Computed as [FormalResult.failedProperties.length] — a lower-bound
  /// estimate until waveform data is available.
  final int estimatedDepth;

  CounterexampleTrace({
    required List<CounterexampleSignal> signals,
    required List<String> failedProperties,
    required this.firstFailure,
    required this.estimatedDepth,
  })  : signals          = List.unmodifiable(List.of(signals)),
        failedProperties = List.unmodifiable(List.of(failedProperties)) {
    if (estimatedDepth < 0) {
      throw ArgumentError.value(
        estimatedDepth, 'estimatedDepth', 'Trace depth must be non-negative',
      );
    }
  }

  /// Empty trace for successful verification or disabled trace collection.
  static final CounterexampleTrace empty = CounterexampleTrace(
    signals:          const [],
    failedProperties: const [],
    firstFailure:     '',
    estimatedDepth:   0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterexampleTrace &&
          firstFailure   == other.firstFailure   &&
          estimatedDepth == other.estimatedDepth &&
          _listEq(failedProperties, other.failedProperties) &&
          _sigEq(signals, other.signals);

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sigEq(
    List<CounterexampleSignal> a,
    List<CounterexampleSignal> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(firstFailure, estimatedDepth, signals.length, failedProperties.length);

  @override
  String toString() =>
      'CounterexampleTrace(signals=${signals.length}, '
      'depth=$estimatedDepth, first=$firstFailure)';
}
