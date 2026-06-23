import '../explainability/verification_explanation_set.dart';
import '../formal/formal_property.dart';
import '../formal/formal_property_set.dart';
import '../formal/formal_property_type.dart';
import 'verification_plan.dart';
import 'verification_plan_item.dart';

// ─── BatchStrategy ────────────────────────────────────────────────────────────

/// Controls how [VerificationPlanItem]s are grouped into batches.
enum BatchStrategy {
  /// All properties in a single batch, ordered by input position.
  sequential,

  /// Groups of at most [PlanningContext.maximumBatchSize] properties.
  ///
  /// Requires [PlanningContext.maximumBatchSize] >= 1.
  fixedSize,

  /// One batch per [FormalPropertyType]; properties of the same type are
  /// grouped together.
  propertyType,

  /// Properties sorted by confidence (descending) before batching.
  ///
  /// Confidence is read from [FormalProperty.metadata] key `'score'`.
  /// Uses [PlanningContext.maximumBatchSize] for further grouping when > 0.
  confidence,
}

// ─── PlanningPolicy ───────────────────────────────────────────────────────────

/// Abstract planning policy.
///
/// Implementations decide how a [FormalPropertySet] becomes a [VerificationPlan].
///
/// Invariants:
/// - Must NOT execute verification.
/// - Must NOT modify [FormalProperty] or [VerificationExplanationSet].
/// - The returned [VerificationPlan] must contain exactly one item per property.
/// - Output must be deterministic for identical inputs.
abstract class PlanningPolicy {
  const PlanningPolicy();

  /// Converts [properties] into a [VerificationPlan].
  ///
  /// Parameters extracted from [PlanningContext] are passed individually to
  /// avoid a circular import between [PlanningPolicy] and [PlanningContext].
  VerificationPlan createPlan(
    FormalPropertySet properties,
    VerificationExplanationSet explanations, {
    required int maxBatchSize,
    required BatchStrategy strategy,
    required bool preserveRanking,
  });
}

// ─── DefaultPlanningPolicy ────────────────────────────────────────────────────

/// Default [PlanningPolicy] implementation.
///
/// Supports all four [BatchStrategy] values.  Delegates to private helpers so
/// each strategy is independently testable.
///
/// Invariants:
/// - Stateless: all behaviour is driven by parameters.
/// - Confidence ordering reads only from [FormalProperty.metadata] `'score'`.
/// - Tie-breaking within confidence sort is alphabetical by property id.
class DefaultPlanningPolicy implements PlanningPolicy {
  const DefaultPlanningPolicy();

  @override
  VerificationPlan createPlan(
    FormalPropertySet properties,
    VerificationExplanationSet explanations, {
    required int maxBatchSize,
    required BatchStrategy strategy,
    required bool preserveRanking,
  }) {
    final props = properties.properties;
    if (props.isEmpty) return VerificationPlan(const []);

    final items = switch (strategy) {
      BatchStrategy.sequential   => _sequential(props),
      BatchStrategy.fixedSize    => _fixedSize(props, maxBatchSize),
      BatchStrategy.propertyType => _byPropertyType(props),
      BatchStrategy.confidence   => _byConfidence(props, maxBatchSize),
    };

    return VerificationPlan(items);
  }

  // ── Sequential ────────────────────────────────────────────────────────────

  List<VerificationPlanItem> _sequential(List<FormalProperty> props) => [
        for (int i = 0; i < props.length; i++)
          _makeItem(props[i], executionOrder: i, batchId: 0),
      ];

  // ── Fixed-size ────────────────────────────────────────────────────────────

  List<VerificationPlanItem> _fixedSize(
    List<FormalProperty> props,
    int batchSize,
  ) =>
      [
        for (int i = 0; i < props.length; i++)
          _makeItem(props[i], executionOrder: i, batchId: i ~/ batchSize),
      ];

  // ── Property-type ─────────────────────────────────────────────────────────

  List<VerificationPlanItem> _byPropertyType(List<FormalProperty> props) {
    final typeIds = <FormalPropertyType, int>{};
    int nextId = 0;
    return [
      for (int i = 0; i < props.length; i++)
        _makeItem(
          props[i],
          executionOrder: i,
          batchId: typeIds.putIfAbsent(props[i].propertyType, () => nextId++),
        ),
    ];
  }

  // ── Confidence ────────────────────────────────────────────────────────────

  List<VerificationPlanItem> _byConfidence(
    List<FormalProperty> props,
    int maxBatchSize,
  ) {
    final sorted = [...props]..sort((a, b) {
        final ca = (a.metadata['score'] as num?)?.toDouble() ?? 0.0;
        final cb = (b.metadata['score'] as num?)?.toDouble() ?? 0.0;
        final cmp = cb.compareTo(ca);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

    final effectiveBatch = maxBatchSize > 0 ? maxBatchSize : sorted.length;
    return [
      for (int i = 0; i < sorted.length; i++)
        _makeItem(sorted[i], executionOrder: i, batchId: i ~/ effectiveBatch),
    ];
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  VerificationPlanItem _makeItem(
    FormalProperty property, {
    required int executionOrder,
    required int batchId,
  }) {
    final strategy = _strategyFor(property);
    return VerificationPlanItem(
      propertyId:     property.id,
      executionOrder: executionOrder,
      batchId:        batchId,
      strategy:       strategy,
      estimatedCost:  _costFor(strategy),
    );
  }

  static VerificationStrategy _strategyFor(FormalProperty p) =>
      switch (p.propertyType) {
        FormalPropertyType.cover    => VerificationStrategy.cover,
        FormalPropertyType.liveness => VerificationStrategy.induction,
        _                           => VerificationStrategy.boundedModelChecking,
      };

  static double _costFor(VerificationStrategy s) => switch (s) {
        VerificationStrategy.cover                => 1.0,
        VerificationStrategy.boundedModelChecking  => 2.0,
        VerificationStrategy.automatic             => 2.0,
        VerificationStrategy.induction             => 4.0,
      };
}
