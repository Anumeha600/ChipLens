import '../formal/formal_result.dart';
import 'counterexample_classification.dart';
import 'counterexample_context.dart';
import 'counterexample_report.dart';
import 'counterexample_signal.dart';
import 'counterexample_statistics.dart';
import 'counterexample_summary.dart';
import 'counterexample_trace.dart';

// ─── CounterexampleAnalyzer ───────────────────────────────────────────────────

/// Interprets a [FormalResult] and produces a [CounterexampleReport].
///
/// Responsibilities:
/// - Validates [FormalResult] integrity before any reasoning.
/// - Classifies the result into [CounterexampleClassification].
/// - Computes [CounterexampleConfidence] from property outcomes.
/// - Reconstructs a [CounterexampleTrace] from property identifier lists
///   (no waveform or VCD parsing).
/// - Generates [CounterexampleStatistics].
/// - Assembles [CounterexampleSummary].
///
/// Invariants:
/// - Does NOT invoke SymbiYosys or any verification engine.
/// - Does NOT parse stdout or stderr text.
/// - Does NOT modify [FormalResult].
/// - Stateless: every call is completely independent.
/// - Output is deterministic for identical [FormalResult] inputs.
class CounterexampleAnalyzer {
  /// Creates a [CounterexampleAnalyzer].  Stateless — no configuration stored.
  const CounterexampleAnalyzer();

  // ── Exit-code sentinel used by [FormalResult.unavailable] ─────────────────
  static const int _engineUnavailableExitCode = -1;

  // ── Timeout exit code (POSIX standard: 124) ────────────────────────────────
  static const int _timeoutExitCode = 124;

  /// Produces a [CounterexampleReport] from [result] and [context].
  ///
  /// Throws [ArgumentError] when [FormalResult.exitCode] < -1 (clearly
  /// malformed; -1 is the engine-unavailable sentinel).
  ///
  /// Throws [StateError] when [FormalResult.success] is `true` but
  /// [FormalResult.failedProperties] is non-empty (contradictory state).
  CounterexampleReport analyze(
    FormalResult result,
    CounterexampleContext context,
  ) {
    _validateResult(result);

    final classification = _classify(result);

    final confidence = context.includeConfidence
        ? _computeConfidence(result, classification)
        : CounterexampleConfidence.veryHigh;

    final signals = context.includeSignals
        ? _buildSignals(result, context)
        : const <CounterexampleSignal>[];

    final trace = context.includeTrace
        ? _buildTrace(result, signals)
        : CounterexampleTrace.empty;

    final summary = _buildSummary(result, classification);

    final statistics = context.includeStatistics
        ? CounterexampleStatistics(
            failedPropertyCount:  result.failedProperties.length,
            unknownPropertyCount: result.unknownProperties.length,
            signalCount:          signals.length,
            changedSignalCount:   signals.where((s) => s.changed).length,
            estimatedDepth:       result.failedProperties.length,
          )
        : CounterexampleStatistics.empty;

    return CounterexampleReport(
      summary:        summary,
      trace:          trace,
      classification: classification,
      confidence:     confidence,
      statistics:     statistics,
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  static void _validateResult(FormalResult result) {
    if (result.exitCode < _engineUnavailableExitCode) {
      throw ArgumentError.value(
        result.exitCode,
        'result.exitCode',
        'Exit code must be >= -1 (the engine-unavailable sentinel value)',
      );
    }
    if (result.success && result.failedProperties.isNotEmpty) {
      throw StateError(
        'CounterexampleAnalyzer: FormalResult is internally inconsistent — '
        'success is true but ${result.failedProperties.length} '
        'property(ies) are in failedProperties.',
      );
    }
  }

  // ── Classification ────────────────────────────────────────────────────────

  static CounterexampleClassification _classify(FormalResult result) {
    // Priority: engineFailure > timeout > assertionFailure > assumptionViolation > unknown
    if (result.exitCode < 0) {
      return CounterexampleClassification.engineFailure;
    }
    if (result.exitCode == _timeoutExitCode) {
      return CounterexampleClassification.timeout;
    }
    if (result.failedProperties.isNotEmpty) {
      return CounterexampleClassification.assertionFailure;
    }
    // Assumption violation: engine ran (exitCode == 0) but reported not-success
    // with no classified properties at all — assumption check terminated early.
    if (!result.success &&
        result.failedProperties.isEmpty &&
        result.unknownProperties.isEmpty &&
        result.provenProperties.isEmpty) {
      return CounterexampleClassification.assumptionViolation;
    }
    // Everything else: unknown (covers all-proven and inconclusive)
    return CounterexampleClassification.unknown;
  }

  // ── Confidence ────────────────────────────────────────────────────────────

  static CounterexampleConfidence _computeConfidence(
    FormalResult result,
    CounterexampleClassification classification,
  ) {
    if (classification == CounterexampleClassification.engineFailure) {
      return CounterexampleConfidence.veryLow;
    }

    final proven   = result.provenProperties.length;
    final failed   = result.failedProperties.length;
    final unknown  = result.unknownProperties.length;
    final total    = proven + failed + unknown;

    if (total == 0) return CounterexampleConfidence.veryLow;

    // All properties proven — very high confidence
    if (failed == 0 && unknown == 0 && proven > 0) {
      return CounterexampleConfidence.veryHigh;
    }

    // Single failure with all others proven — high confidence
    if (failed == 1 && unknown == 0) {
      return CounterexampleConfidence.high;
    }

    // Mostly unknown (unknowns outnumber both failures and proven)
    if (unknown > failed && unknown > proven) {
      return CounterexampleConfidence.low;
    }

    // Problem rate determines medium vs. veryLow
    final problemRate = (failed + unknown) / total;
    return problemRate <= 0.5
        ? CounterexampleConfidence.medium
        : CounterexampleConfidence.veryLow;
  }

  // ── Signal reconstruction ─────────────────────────────────────────────────

  static List<CounterexampleSignal> _buildSignals(
    FormalResult result,
    CounterexampleContext context,
  ) {
    final seen    = <String>{};
    final signals = <CounterexampleSignal>[];

    // Failed properties → changed signals at step 0
    for (final prop in result.failedProperties) {
      if (seen.add(prop)) {
        signals.add(CounterexampleSignal(
          name:    prop,
          value:   'FAIL',
          step:    0,
          changed: true,
        ));
      }
    }

    // Unknown properties → unchanged signals at step 0
    for (final prop in result.unknownProperties) {
      if (seen.add(prop)) {
        signals.add(CounterexampleSignal(
          name:    prop,
          value:   'UNKNOWN',
          step:    0,
          changed: false,
        ));
      }
    }

    final max = context.maximumSignals;
    if (max >= 0 && signals.length > max) {
      return List.unmodifiable(signals.take(max).toList());
    }
    return List.unmodifiable(signals);
  }

  // ── Trace reconstruction ──────────────────────────────────────────────────

  static CounterexampleTrace _buildTrace(
    FormalResult result,
    List<CounterexampleSignal> signals,
  ) =>
      CounterexampleTrace(
        signals:          signals,
        failedProperties: result.failedProperties,
        firstFailure:
            result.failedProperties.isEmpty ? '' : result.failedProperties.first,
        estimatedDepth:   result.failedProperties.length,
      );

  // ── Summary ───────────────────────────────────────────────────────────────

  static CounterexampleSummary _buildSummary(
    FormalResult result,
    CounterexampleClassification cls,
  ) {
    final failedCount  = result.failedProperties.length;
    final unknownCount = result.unknownProperties.length;
    final provenCount  = result.provenProperties.length;

    final overview = switch (cls) {
      CounterexampleClassification.engineFailure =>
          'Verification engine failure (exit code ${result.exitCode}).',
      CounterexampleClassification.timeout =>
          'Verification timed out. $unknownCount property(ies) inconclusive.',
      CounterexampleClassification.assertionFailure =>
          '$failedCount property(ies) failed with counterexample trace(s).',
      CounterexampleClassification.assumptionViolation =>
          'Assumption violation terminated the verification run.',
      CounterexampleClassification.unknown =>
          provenCount > 0
              ? 'All $provenCount property(ies) verified successfully.'
              : '$unknownCount property(ies) with unknown outcome.',
    };

    final primaryFailure = result.failedProperties.isEmpty
        ? (result.unknownProperties.isEmpty ? 'None' : result.unknownProperties.first)
        : result.failedProperties.first;

    final earliestFailure = result.failedProperties.isEmpty
        ? 'None'
        : result.failedProperties.first;

    return CounterexampleSummary(
      overview:          overview,
      primaryFailure:    primaryFailure,
      earliestFailure:   earliestFailure,
      dominantCategory:  cls.name,
    );
  }
}
