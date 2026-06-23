// ─── VerificationStrategy ─────────────────────────────────────────────────────

/// The formal verification technique recommended for a planned job.
///
/// Values are engine-independent; translation to SymbiYosys task-mode strings
/// is the responsibility of future backend adapters.
enum VerificationStrategy {
  /// Bounded model checking — explores all paths up to a fixed depth.
  boundedModelChecking,

  /// k-induction — proves invariants hold for all reachable states.
  induction,

  /// Cover check — verifies that a state or sequence is reachable.
  cover,

  /// Let the verification engine choose the best technique automatically.
  automatic,
}

// ─── VerificationPlanItem ─────────────────────────────────────────────────────

/// Represents exactly one planned verification job.
///
/// Immutable: all fields are `final`.  [metadata] is returned as an
/// unmodifiable view so callers cannot mutate it after construction.
///
/// Invariants:
/// - [propertyId] identifies a [FormalProperty] in the source [FormalPropertySet].
/// - [executionOrder] is globally unique within a [VerificationPlan].
/// - [batchId] groups related jobs; all items in the same batch share the same id.
/// - [estimatedCost] is always non-negative.
class VerificationPlanItem {
  /// Identifier of the [FormalProperty] this job will verify.
  final String propertyId;

  /// Zero-based global position of this job within the plan.
  final int executionOrder;

  /// Batch this job belongs to.  Jobs with the same [batchId] may be executed
  /// together by a future parallel executor.
  final int batchId;

  /// Recommended verification technique for this job.
  final VerificationStrategy strategy;

  /// Heuristic estimate of relative execution cost (higher = slower).
  ///
  /// Covers: 1.0 · BMC/auto: 2.0 · Induction: 4.0.
  final double estimatedCost;

  /// Arbitrary key-value annotations for tooling extensions.
  final Map<String, dynamic> metadata;

  VerificationPlanItem({
    required this.propertyId,
    required this.executionOrder,
    required this.batchId,
    required this.strategy,
    required this.estimatedCost,
    Map<String, dynamic>? metadata,
  }) : metadata = Map.unmodifiable(metadata ?? const {});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationPlanItem &&
          propertyId     == other.propertyId &&
          executionOrder == other.executionOrder &&
          batchId        == other.batchId &&
          strategy       == other.strategy &&
          (estimatedCost - other.estimatedCost).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(propertyId, executionOrder, batchId, strategy);

  @override
  String toString() =>
      'VerificationPlanItem($propertyId, order=$executionOrder, '
      'batch=$batchId, strategy=${strategy.name})';
}
