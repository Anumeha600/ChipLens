import 'repair_category.dart';
import 'repair_dependency.dart';
import 'repair_priority.dart';

// ─── RepairStep ───────────────────────────────────────────────────────────────

/// Represents one recommended repair action produced by [RepairPlanner].
///
/// Each [RepairStep] corresponds to one non-informational [DiagnosticIssue].
/// The [id] is stable and unique within a [RepairPlan]; it is used as the
/// reference target in [RepairDependency] records.
///
/// Invariants:
/// - [dependencies] is unmodifiable.
/// - [supportingEvidence] is unmodifiable.
/// - Input list mutations after construction do not affect stored state.
/// - [id] is unique within a [RepairPlan].
///
/// Future extension points:
/// - Add [estimatedHours] for sprint planning integration.
/// - Add [automationAvailable] flag for tool-assisted repair.
/// - Add [relatedStepIds] for loose associations.
class RepairStep {
  /// Stable unique identifier within the enclosing [RepairPlan].
  final String id;

  /// Short human-readable description of the repair action.
  final String title;

  /// Detailed explanation of what needs to be done.
  final String description;

  /// Urgency of this repair relative to the overall verification effort.
  final RepairPriority priority;

  /// Verification sub-system that this repair targets.
  final RepairCategory category;

  /// Estimated implementation effort.
  final RepairComplexity complexity;

  /// Prerequisite repair steps that must complete before this one.
  final List<RepairDependency> dependencies;

  /// Evidence strings from the originating [DiagnosticIssue].
  final List<String> supportingEvidence;

  RepairStep({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.complexity,
    required List<RepairDependency> dependencies,
    required List<String> supportingEvidence,
  })  : dependencies     = List.unmodifiable(List.of(dependencies)),
        supportingEvidence = List.unmodifiable(List.of(supportingEvidence));

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairStep &&
          id          == other.id          &&
          title       == other.title       &&
          description == other.description &&
          priority    == other.priority    &&
          category    == other.category    &&
          complexity  == other.complexity  &&
          _listEq(dependencies, other.dependencies) &&
          _evidenceEq(supportingEvidence, other.supportingEvidence);

  static bool _listEq(List<RepairDependency> a, List<RepairDependency> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _evidenceEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, priority, category, complexity);

  @override
  String toString() =>
      'RepairStep($id, ${priority.name}, ${category.name}, "$title")';
}
