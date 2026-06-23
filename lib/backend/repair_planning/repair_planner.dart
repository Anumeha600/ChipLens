import '../diagnostics_intelligence/diagnostics_intelligence.dart'
    show DiagnosticCategory, DiagnosticIssue, DiagnosticReport, DiagnosticSeverity;

import 'repair_category.dart';
import 'repair_context.dart';
import 'repair_dependency.dart';
import 'repair_plan.dart';
import 'repair_priority.dart';
import 'repair_statistics.dart';
import 'repair_step.dart';

// ─── RepairPlanner ────────────────────────────────────────────────────────────

/// Converts a [DiagnosticReport] into an ordered [RepairPlan].
///
/// Inputs:
/// - [DiagnosticReport] — upstream diagnosis with ordered [DiagnosticIssue]s.
///
/// Output:
/// - [RepairPlan] — ordered repair steps with priorities, dependencies, and
///   complexity estimates.
///
/// Responsibilities:
/// - Maps each non-informational [DiagnosticIssue] to a [RepairStep].
/// - Assigns [RepairPriority] from [DiagnosticSeverity].
/// - Assigns [RepairCategory] from [DiagnosticCategory].
/// - Estimates [RepairComplexity] from [RepairCategory].
/// - Generates dependency relationships between steps.
/// - Sorts steps by priority (descending), dependency level (ascending),
///   category, then title.
/// - Computes overall priority and complexity.
///
/// Invariants:
/// - Does NOT modify [DiagnosticReport] or any upstream model.
/// - Does NOT execute formal verification.
/// - Does NOT modify RTL.
/// - Stateless: every call is completely independent.
/// - Output is deterministic for identical [DiagnosticReport] inputs.
class RepairPlanner {
  const RepairPlanner();

  /// Produces a [RepairPlan] from [report] and [context].
  ///
  /// Complexity: O(n log n) dominated by the sort step.
  RepairPlan plan(DiagnosticReport report, RepairContext context) {
    // ── Phase 1: Generate raw steps (one per non-informational issue) ────────
    final rawSteps = <_RawStep>[];
    int idx = 0;
    for (final issue in report.issues) {
      if (issue.severity == DiagnosticSeverity.informational) continue;
      final repairCat = _mapCategory(issue.category);
      rawSteps.add(_RawStep(
        id:        '${repairCat.name}_$idx',
        issue:     issue,
        repairCat: repairCat,
      ));
      idx++;
    }

    // ── Phase 2: Group by category for dependency generation ─────────────────
    final configIds  = <String>[];
    final propertyIds = <String>[];
    for (final r in rawSteps) {
      if (r.repairCat == RepairCategory.configuration) configIds.add(r.id);
      if (r.repairCat == RepairCategory.property)      propertyIds.add(r.id);
    }

    // ── Phase 3: Build RepairStep objects with dependencies ───────────────────
    final steps = rawSteps.map((raw) {
      final deps = <RepairDependency>[];
      if (context.includeDependencies) {
        // Verification depends on all configuration repairs.
        if (raw.repairCat == RepairCategory.verification) {
          for (final cId in configIds) {
            deps.add(RepairDependency(
              repairId:  raw.id,
              dependsOn: cId,
              reason:    'Configuration must be correct before verification can proceed',
            ));
          }
        }
        // Coverage depends on all property repairs.
        if (raw.repairCat == RepairCategory.coverage) {
          for (final pId in propertyIds) {
            deps.add(RepairDependency(
              repairId:  raw.id,
              dependsOn: pId,
              reason:    'Property quality affects coverage outcomes',
            ));
          }
        }
      }

      final complexity = context.includeComplexity
          ? _mapComplexity(raw.repairCat)
          : RepairComplexity.low;

      return RepairStep(
        id:                raw.id,
        title:             'Fix: ${raw.issue.title}',
        description:       raw.issue.description,
        priority:          _mapPriority(raw.issue.severity),
        category:          raw.repairCat,
        complexity:        complexity,
        dependencies:      deps,
        supportingEvidence: List.of(raw.issue.evidence),
      );
    }).toList();

    // ── Phase 4: Sort ─────────────────────────────────────────────────────────
    if (!context.preserveDiagnosticOrdering) {
      // Compute dependency levels for secondary sort key (O(n))
      final levelMap = _computeLevels(steps);
      steps.sort((a, b) {
        // Priority ascending by index (critical=0 is highest priority, comes first)
        final pc = a.priority.index.compareTo(b.priority.index);
        if (pc != 0) return pc;
        // Dependency level ascending (independent first)
        final dc = levelMap[a.id]!.compareTo(levelMap[b.id]!);
        if (dc != 0) return dc;
        // Category name ascending
        final cc = a.category.name.compareTo(b.category.name);
        if (cc != 0) return cc;
        // Title ascending
        return a.title.compareTo(b.title);
      });
    }

    // ── Phase 5: Apply step limit ─────────────────────────────────────────────
    final limited = _applyLimit(steps, context.maximumRepairSteps);

    // ── Phase 6: Statistics ───────────────────────────────────────────────────
    final stats = context.includeStatistics
        ? RepairStatistics.fromSteps(limited)
        : RepairStatistics.empty;

    // ── Phase 7: Overall priority / complexity ────────────────────────────────
    final overallPriority  = _aggregatePriority(limited);
    final overallComplexity = _aggregateComplexity(limited);

    return RepairPlan(
      steps:            limited,
      statistics:       stats,
      overallPriority:  overallPriority,
      overallComplexity: overallComplexity,
    );
  }

  // ── Mapping helpers ───────────────────────────────────────────────────────

  static RepairPriority _mapPriority(DiagnosticSeverity severity) =>
      switch (severity) {
        DiagnosticSeverity.critical     => RepairPriority.critical,
        DiagnosticSeverity.high         => RepairPriority.high,
        DiagnosticSeverity.medium       => RepairPriority.medium,
        DiagnosticSeverity.low          => RepairPriority.low,
        DiagnosticSeverity.informational => RepairPriority.low,
      };

  static RepairCategory _mapCategory(DiagnosticCategory category) =>
      switch (category) {
        DiagnosticCategory.verification  => RepairCategory.verification,
        DiagnosticCategory.coverage      => RepairCategory.coverage,
        DiagnosticCategory.planning      => RepairCategory.planning,
        DiagnosticCategory.property      => RepairCategory.property,
        DiagnosticCategory.counterexample => RepairCategory.verification,
        DiagnosticCategory.configuration => RepairCategory.configuration,
      };

  static RepairComplexity _mapComplexity(RepairCategory category) =>
      switch (category) {
        RepairCategory.configuration => RepairComplexity.low,
        RepairCategory.planning      => RepairComplexity.low,
        RepairCategory.coverage      => RepairComplexity.medium,
        RepairCategory.property      => RepairComplexity.medium,
        RepairCategory.verification  => RepairComplexity.high,
      };

  // ── Dependency level computation (O(n)) ──────────────────────────────────

  static Map<String, int> _computeLevels(List<RepairStep> steps) {
    final depMap = <String, List<String>>{
      for (final s in steps)
        s.id: s.dependencies.map((d) => d.dependsOn).toList(),
    };
    final levels = <String, int>{};

    int level(String id) {
      if (levels.containsKey(id)) return levels[id]!;
      final deps = depMap[id] ?? const [];
      if (deps.isEmpty) {
        levels[id] = 0;
        return 0;
      }
      int maxDep = 0;
      for (final dep in deps) {
        final dl = depMap.containsKey(dep) ? level(dep) : 0;
        if (dl > maxDep) maxDep = dl;
      }
      levels[id] = maxDep + 1;
      return maxDep + 1;
    }

    for (final s in steps) {
      level(s.id);
    }
    return levels;
  }

  // ── Limit and dependency filtering ───────────────────────────────────────

  static List<RepairStep> _applyLimit(List<RepairStep> steps, int max) {
    if (max < 0 || steps.length <= max) return steps;
    final kept = steps.sublist(0, max);
    final keptIds = {for (final s in kept) s.id};
    // Strip dependencies on removed steps to keep the plan valid.
    return kept.map((s) {
      final filteredDeps = s.dependencies
          .where((d) => keptIds.contains(d.dependsOn))
          .toList();
      if (filteredDeps.length == s.dependencies.length) return s;
      return RepairStep(
        id:                 s.id,
        title:              s.title,
        description:        s.description,
        priority:           s.priority,
        category:           s.category,
        complexity:         s.complexity,
        dependencies:       filteredDeps,
        supportingEvidence: List.of(s.supportingEvidence),
      );
    }).toList();
  }

  // ── Aggregation ───────────────────────────────────────────────────────────

  static RepairPriority _aggregatePriority(List<RepairStep> steps) {
    if (steps.isEmpty) return RepairPriority.low;
    // Lower index = higher priority (critical=0, low=3); find the minimum index.
    var result = RepairPriority.low;
    for (final s in steps) {
      if (s.priority.index < result.index) result = s.priority;
    }
    return result;
  }

  static RepairComplexity _aggregateComplexity(List<RepairStep> steps) {
    if (steps.isEmpty) return RepairComplexity.low;
    var max = RepairComplexity.low;
    for (final s in steps) {
      if (s.complexity.index > max.index) max = s.complexity;
    }
    return max;
  }
}

// ── Internal helper ───────────────────────────────────────────────────────────

class _RawStep {
  final String id;
  final DiagnosticIssue issue;
  final RepairCategory repairCat;
  const _RawStep({required this.id, required this.issue, required this.repairCat});
}
