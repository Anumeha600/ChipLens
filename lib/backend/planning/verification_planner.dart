import '../explainability/verification_explanation_set.dart';
import '../formal/formal_property_set.dart';
import 'planning_context.dart';
import 'planning_policy.dart';
import 'planning_result.dart';
import 'planning_statistics.dart';
import 'verification_plan.dart';

// ─── VerificationPlanner ──────────────────────────────────────────────────────

/// High-level orchestrator that converts a [FormalPropertySet] and
/// [VerificationExplanationSet] into a [PlanningResult].
///
/// Responsibilities:
/// - Validates [PlanningContext] before delegating to [PlanningPolicy].
/// - Collects non-fatal warnings (e.g. missing explanations).
/// - Computes [PlanningStatistics] when [PlanningContext.includeStatistics].
/// - Measures wall-clock planning time.
///
/// Invariants:
/// - Does NOT execute verification.
/// - Does NOT modify [FormalProperty], [FormalPropertySet],
///   [VerificationExplanation], or [VerificationExplanationSet].
/// - Stateless: every call is fully independent.
/// - Every [FormalProperty] appears exactly once in the output [VerificationPlan].
class VerificationPlanner {
  /// Creates a [VerificationPlanner].  Stateless — no configuration is stored.
  const VerificationPlanner();

  /// Produces a [PlanningResult] from [properties] and [explanations].
  ///
  /// Throws [ArgumentError] when [PlanningContext.maximumBatchSize] < 1 and
  /// [PlanningContext.batchStrategy] is [BatchStrategy.fixedSize].
  ///
  /// Throws [StateError] when the policy returns a plan whose length does not
  /// match [properties.length] (plan integrity violation).
  PlanningResult plan(
    FormalPropertySet properties,
    VerificationExplanationSet explanations,
    PlanningContext context,
  ) {
    _validateContext(context);

    final stopwatch = Stopwatch()..start();
    final warnings  = <String>[];

    _collectMissingExplanationWarnings(properties, explanations, warnings);

    final plan = context.planningPolicy.createPlan(
      properties,
      explanations,
      maxBatchSize:    context.maximumBatchSize,
      strategy:        context.batchStrategy,
      preserveRanking: context.preserveRanking,
    );

    _validatePlanIntegrity(plan, properties);

    final statistics = context.includeStatistics
        ? PlanningStatistics.fromPlan(plan)
        : PlanningStatistics.empty;

    stopwatch.stop();
    return PlanningResult(
      plan:         plan,
      statistics:   statistics,
      warnings:     warnings,
      planningTime: stopwatch.elapsed,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static void _validateContext(PlanningContext context) {
    if (context.batchStrategy == BatchStrategy.fixedSize &&
        context.maximumBatchSize < 1) {
      throw ArgumentError.value(
        context.maximumBatchSize,
        'context.maximumBatchSize',
        'maximumBatchSize must be >= 1 when using BatchStrategy.fixedSize',
      );
    }
  }

  static void _validatePlanIntegrity(
    VerificationPlan plan,
    FormalPropertySet properties,
  ) {
    if (plan.length != properties.length) {
      throw StateError(
        'PlanningPolicy integrity violation: expected ${properties.length} '
        'plan items but policy produced ${plan.length}.',
      );
    }
  }

  static void _collectMissingExplanationWarnings(
    FormalPropertySet properties,
    VerificationExplanationSet explanations,
    List<String> warnings,
  ) {
    for (final property in properties.properties) {
      if (explanations.findById(property.id) == null) {
        warnings.add(
          'No explanation found for property "${property.id}"; '
          'planning will use defaults.',
        );
      }
    }
  }
}
