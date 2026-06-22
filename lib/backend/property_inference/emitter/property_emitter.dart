import '../../formal/formal_property_set.dart';
import '../ranking/ranked_candidate_property_set.dart';
import 'emitter_context.dart';
import 'emitter_result.dart';
import 'priority_filter.dart';
import 'property_mapper.dart';

// ─── PropertyEmitter ─────────────────────────────────────────────────────────

/// Orchestrates translation of a [RankedCandidatePropertySet] into a
/// [FormalPropertySet].
///
/// Execution flow:
/// 1. [PriorityFilter] selects candidates that pass the emission gate.
/// 2. [PropertyMapper] converts each selected [RankingResult] into a
///    [FormalProperty], invoking [MetadataMapper] and [EvidenceMapper]
///    internally.
/// 3. Properties are added to a [FormalPropertySet] in ranking order.
/// 4. An [EmitterResult] is returned with counts and timing.
///
/// Invariants:
/// - Does NOT modify inputs.
/// - Does NOT reorder candidates.
/// - Does NOT generate formal expressions (that is the engine-specific layer).
/// - Does NOT perform ranking, scoring, or inference.
/// - Output is deterministic for identical input.
/// - Every emission pass is stateless and independent.
class PropertyEmitter {
  /// Creates a [PropertyEmitter].
  ///
  /// Stateless: no configuration is stored on the instance.  All behaviour
  /// is driven by the [EmitterContext] passed to [emit].
  const PropertyEmitter();

  /// Translates [ranked] into a [FormalPropertySet] according to [context].
  ///
  /// Returns an [EmitterResult] containing the emitted properties, counts,
  /// warnings, and wall-clock execution time.
  ///
  /// Throws [ArgumentError] when two candidates share the same id (malformed
  /// input — [FormalPropertySet.add] enforces unique ids).
  Future<EmitterResult> emit(
    RankedCandidatePropertySet ranked,
    EmitterContext context,
  ) async {
    final stopwatch = Stopwatch()..start();

    // 1. Select.
    final selected = PriorityFilter.filter(ranked, context);
    final skipped  = ranked.length - selected.length;

    // 2. Map & assemble.
    final properties = FormalPropertySet();
    for (final result in selected) {
      properties.add(PropertyMapper.map(result));
    }

    stopwatch.stop();

    return EmitterResult(
      properties:    properties,
      emittedCount:  selected.length,
      skippedCount:  skipped,
      warnings:      const [],
      executionTime: stopwatch.elapsed,
    );
  }
}
