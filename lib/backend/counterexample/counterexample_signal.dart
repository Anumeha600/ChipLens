// ─── CounterexampleSignal ─────────────────────────────────────────────────────

/// Represents one signal participating in a counterexample trace.
///
/// Signals are reconstructed from [FormalResult] property lists — not from
/// waveform or VCD files.  Each signal corresponds to a formal property
/// identifier that was classified as failed or unknown.
///
/// Invariants:
/// - [step] is always non-negative.
/// - [name] is non-empty and corresponds to a property identifier.
///
/// Future extension points:
/// - Add [bitWidth] and [numericValue] when VCD integration arrives.
/// - Add [sourceLine] for RTL traceability.
class CounterexampleSignal {
  /// Property identifier used as the signal name.
  final String name;

  /// Observed value at [step] (e.g. `'FAIL'`, `'UNKNOWN'`, `'1'`, `'0'`).
  final String value;

  /// Zero-based time step at which this signal was observed.
  final int step;

  /// Whether this signal changed state at [step].
  final bool changed;

  CounterexampleSignal({
    required this.name,
    required this.value,
    required this.step,
    required this.changed,
  }) {
    if (step < 0) {
      throw ArgumentError.value(step, 'step', 'Signal step must be non-negative');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterexampleSignal &&
          name    == other.name  &&
          value   == other.value &&
          step    == other.step  &&
          changed == other.changed;

  @override
  int get hashCode => Object.hash(name, value, step, changed);

  @override
  String toString() =>
      'CounterexampleSignal($name=$value @ step $step, changed=$changed)';
}
