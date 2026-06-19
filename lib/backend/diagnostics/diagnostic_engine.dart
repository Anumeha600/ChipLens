import 'dart:math' as math;

import '../../models/design_spec.dart';
import 'diagnostic.dart';

/// Accumulates [Diagnostic] objects from external tools (Verilator, Yosys, and
/// future passes), deduplicates them against an existing [QualityReport]'s
/// internal findings, applies score penalties for new external findings, and
/// returns a merged [QualityReport].
///
/// **Source priority for deduplication:**
/// internal (highest) > verilator > yosys > icarus (lowest)
///
/// When multiple sources flag the same conceptual issue, the highest-priority
/// diagnostic is kept and lower-priority duplicates are suppressed.
///
/// Usage:
/// ```dart
/// final engine = DiagnosticEngine()
///   ..addAll(VerilatorDiagnosticParser.parse(verilatorOutput))
///   ..addAll(YosysParser.parse(yosysOutput))
///   ..addAll(IcarusParser.parse(icarusOutput));
/// final merged = engine.mergeIntoReport(qualityReport);
/// ```
class DiagnosticEngine {
  final List<Diagnostic> _diagnostics = [];

  // ── Canonical issue-key map ───────────────────────────────────────────────
  //
  // Maps each tool's rule ID to a shared "canonical key" representing the same
  // conceptual issue.  Diagnostics that share a canonical key are considered
  // duplicates; only the one from the highest-priority source is kept.
  //
  // Keys NOT in this map are unique-per-tool and are never suppressed.

  static const _canonical = <String, String>{
    // ── Internal QualityAnalyzer ───────────────────────────────────────────
    'missing_default':    'latch_risk',
    'missing_reset':      'no_reset',
    'no_nonblocking':     'blocking_seq',

    // ── Verilator ─────────────────────────────────────────────────────────
    'verilator_latch':        'latch_risk',
    'verilator_nolatch':      'latch_risk',
    'verilator_resetall':     'no_reset',
    'verilator_blkloopinit':  'blocking_seq',
    'verilator_combdly':      'blocking_seq',
    'verilator_blkandnblk':   'blocking_seq',

    // ── Yosys ─────────────────────────────────────────────────────────────
    'yosys_infer_latch':  'latch_risk',
  };

  // Source priority — lower value = higher priority.
  // Verilator > Yosys > Icarus > Formal for any overlapping canonical keys.
  static const _sourcePriority = <DiagnosticSource, int>{
    DiagnosticSource.internal:  0,
    DiagnosticSource.verilator: 1,
    DiagnosticSource.yosys:     2,
    DiagnosticSource.icarus:    3,
    DiagnosticSource.formal:    4,
  };

  // Penalty applied to the correctness category per unique external finding.
  // Tuple: (penaltyPerOccurrence, capPerRuleId).
  static const _severityPenalty = <String, (int, int)>{
    'error':   (8, 20),
    'warning': (4, 12),
    'info':    (0,  0),
    'hint':    (0,  0),
  };

  // ── Accumulator ────────────────────────────────────────────────────────────

  /// Add [diagnostics] to the internal pool.
  void addAll(List<Diagnostic> diagnostics) {
    _diagnostics.addAll(diagnostics);
  }

  /// Immutable view of all accumulated diagnostics.
  List<Diagnostic> get diagnostics => List.unmodifiable(_diagnostics);

  // ── Core merge logic ───────────────────────────────────────────────────────

  /// Merge all accumulated external diagnostics into [base]:
  ///
  /// 1. **Deduplication** — external diagnostics whose canonical issue key is
  ///    already covered by an internal warning OR by a higher-priority external
  ///    diagnostic are dropped.
  /// 2. **Scoring** — unique external errors/warnings reduce the correctness
  ///    score using [_severityPenalty].
  /// 3. **Warning list** — surviving diagnostics are appended as [QualityWarning]
  ///    objects carrying their original [DiagnosticSource].
  ///
  /// Returns [base] unchanged when there are no accumulated diagnostics.
  QualityReport mergeIntoReport(QualityReport base) {
    if (_diagnostics.isEmpty) return base;

    final unique = _uniqueExternalDiagnostics(base);
    if (unique.isEmpty) return base;

    // ── Score penalty ──────────────────────────────────────────────────────
    final penaltyById = <String, int>{};
    for (final d in unique) {
      final (per, cap) = _severityPenalty[d.severity] ?? (0, 0);
      if (per == 0) continue;
      penaltyById[d.id] = math.min((penaltyById[d.id] ?? 0) + per, cap);
    }
    final totalPenalty = penaltyById.values.fold(0, (a, b) => a + b);

    final newCorrectness =
        math.max(0, (base.categories['correctness'] ?? 0) - totalPenalty);
    final newTotal = math.max(0, base.total - totalPenalty);

    final newCats = Map<String, int>.from(base.categories)
      ..['correctness'] = newCorrectness;

    // ── Convert → QualityWarning (preserving the actual source) ───────────
    final extra = unique
        .map((d) => QualityWarning(
              type:     d.id,
              message:  d.description,
              severity: d.severity == 'error' ? 'critical' : d.severity,
              source:   d.source,
              quickFix: d.quickFix,
            ))
        .toList();

    final merged = [...base.warnings, ...extra];

    return QualityReport(
      total:           newTotal,
      grade:           _grade(newTotal),
      categories:      newCats,
      categoryDetails: base.categoryDetails,
      warnings:        merged,
      warningCount:    merged.length,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Returns external (non-internal) diagnostics after deduplication.
  // Higher-priority sources claim canonical keys first; lower-priority
  // duplicates are discarded.
  List<Diagnostic> _uniqueExternalDiagnostics(QualityReport base) {
    // Canonical keys already covered by internal warnings
    final internalClaimed = base.warnings
        .map((w) => _canonical[w.type])
        .whereType<String>()
        .toSet();

    // Sort by source priority so Verilator diagnostics are evaluated before
    // Yosys ones — Verilator keeps its canonical key, Yosys duplicate is dropped.
    final external = _diagnostics
        .where((d) => d.source != DiagnosticSource.internal)
        .toList()
      ..sort((a, b) =>
          (_sourcePriority[a.source] ?? 99)
              .compareTo(_sourcePriority[b.source] ?? 99));

    final externalClaimed = <String>{};
    final result = <Diagnostic>[];

    for (final d in external) {
      final key = _canonical[d.id];

      // Drop if an internal warning already covers this issue
      if (key != null && internalClaimed.contains(key)) continue;

      // Drop if a higher-priority external diagnostic already claimed this key
      if (key != null && externalClaimed.contains(key)) continue;

      result.add(d);
      if (key != null) externalClaimed.add(key);
    }

    return result;
  }

  static String _grade(int score) {
    if (score >= 94) return 'A+';
    if (score >= 88) return 'A';
    if (score >= 82) return 'A-';
    if (score >= 76) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 64) return 'B-';
    if (score >= 55) return 'C';
    if (score >= 45) return 'D';
    return 'F';
  }
}
