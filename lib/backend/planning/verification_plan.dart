import 'verification_plan_item.dart';

// ─── VerificationPlan ─────────────────────────────────────────────────────────

/// Immutable ordered execution plan produced by [PlanningPolicy.createPlan].
///
/// Contains one [VerificationPlanItem] per [FormalProperty] from the input
/// [FormalPropertySet].  The plan does NOT execute verification; it describes
/// what should be verified and in what order.
///
/// Invariants:
/// - [jobs] is unmodifiable.
/// - Each [FormalProperty] appears exactly once.
/// - [operator[]] throws [RangeError] for out-of-bounds access.
class VerificationPlan {
  final List<VerificationPlanItem> _jobs;

  VerificationPlan([List<VerificationPlanItem>? jobs])
      : _jobs = List.unmodifiable(List.of(jobs ?? const []));

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Unmodifiable ordered list of all planned jobs.
  List<VerificationPlanItem> get jobs => _jobs;

  int  get length    => _jobs.length;
  bool get isEmpty   => _jobs.isEmpty;
  bool get isNotEmpty => _jobs.isNotEmpty;

  /// Returns the item at [index].
  ///
  /// Throws [RangeError] when [index] is out of bounds.
  VerificationPlanItem operator [](int index) => _jobs[index];

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationPlan &&
          _jobs.length == other._jobs.length &&
          _listsEqual(_jobs, other._jobs);

  static bool _listsEqual(
    List<VerificationPlanItem> a,
    List<VerificationPlanItem> b,
  ) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_jobs);

  @override
  String toString() => 'VerificationPlan(length: $length)';
}
