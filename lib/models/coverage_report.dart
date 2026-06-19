import 'dart:convert';

import 'coverage_result.dart';
import 'coverage_model.dart';

// ─── CoverageReport ───────────────────────────────────────────────────────────

/// Complete coverage output from one analysis run.
///
/// Contains the full [CoverageResult] (all metric fractions + detail lists),
/// raw [CoverageMetrics] counts, typed [coverageWarnings], and a
/// [CoverageHeatMapData] ready to drive a heatmap widget.
///
/// Export helpers ([toJson], [toCsv], [toMarkdown]) produce strings suitable
/// for file download, clipboard copy, or sharing.
class CoverageReport {
  final CoverageResult result;
  final CoverageMetrics metrics;
  final List<CoverageWarning> coverageWarnings;
  final CoverageHeatMapData heatMap;

  const CoverageReport({
    required this.result,
    required this.metrics,
    required this.coverageWarnings,
    required this.heatMap,
  });

  static CoverageReport empty() => CoverageReport(
        result:           CoverageResult.empty(),
        metrics:          CoverageMetrics.empty,
        coverageWarnings: const [],
        heatMap:          CoverageHeatMapData.empty,
      );

  // ── Convenience passthroughs ───────────────────────────────────────────────

  double get overallCoverage     => result.overallCoverage;
  double get stateCoverage       => result.stateCoverage;
  double get transitionCoverage  => result.transitionCoverage;
  double get branchCoverage      => result.branchCoverage;
  double get toggleCoverage      => result.toggleCoverage;
  double get conditionCoverage   => result.conditionCoverage;
  double get lineCoverage        => result.lineCoverage;
  String get grade               => result.grade;
  int    get totalGaps           => result.totalGaps;

  // ── Export — JSON ──────────────────────────────────────────────────────────

  String toJson({bool pretty = true}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(_toMap());
  }

  Map<String, dynamic> _toMap() => {
    'coverage': {
      'overall':    _pct(result.overallCoverage),
      'state':      _pct(result.stateCoverage),
      'transition': _pct(result.transitionCoverage),
      'branch':     _pct(result.branchCoverage),
      'toggle':     _pct(result.toggleCoverage),
      'condition':  _pct(result.conditionCoverage),
      'line':       _pct(result.lineCoverage),
      'grade':      result.grade,
    },
    'metrics': metrics.toMap(),
    'details': {
      'visitedStates':       result.visitedStates,
      'unvisitedStates':     result.unvisitedStates,
      'takenTransitions':    result.takenTransitions,
      'untakenTransitions':  result.untakenTransitions,
      'coveredBranches':     result.coveredBranches,
      'uncoveredBranches':   result.uncoveredBranches,
      'toggledSignals':      result.toggledSignals,
      'untoggledSignals':    result.untoggledSignals,
      'coveredConditions':   result.coveredConditions,
      'uncoveredConditions': result.uncoveredConditions,
    },
    'warnings': coverageWarnings.map((w) => {
      'category':   w.category.name,
      'target':     w.target,
      'message':    w.message,
      'severity':   w.severity,
      'suggestion': w.suggestion,
    }).toList(),
    'heatMap': heatMap.toMap(),
  };

  // ── Export — CSV ───────────────────────────────────────────────────────────

  String toCsv() {
    final buf = StringBuffer();

    buf.writeln('## Coverage Summary');
    buf.writeln('Metric,Covered,Total,Percentage');
    buf.writeln('State,${metrics.visitedStateCount},${metrics.totalStates},${_pctStr(result.stateCoverage)}');
    buf.writeln('Transition,${metrics.executedTransitionCount},${metrics.totalTransitions},${_pctStr(result.transitionCoverage)}');
    buf.writeln('Branch,${metrics.coveredBranchCount},${metrics.totalBranches},${_pctStr(result.branchCoverage)}');
    buf.writeln('Toggle,${metrics.toggledSignalCount},${metrics.totalSignals},${_pctStr(result.toggleCoverage)}');
    buf.writeln('Condition,${metrics.evaluatedConditionCount},${metrics.totalConditions},${_pctStr(result.conditionCoverage)}');
    buf.writeln('Line,${metrics.executedLineCount},${metrics.totalLines},${_pctStr(result.lineCoverage)}');
    buf.writeln('Overall,,,${_pctStr(result.overallCoverage)}');
    buf.writeln();

    buf.writeln('## Unvisited States');
    buf.writeln('State');
    for (final s in result.unvisitedStates) {
      buf.writeln(s);
    }
    buf.writeln();

    buf.writeln('## Untaken Transitions');
    buf.writeln('From,To');
    for (final t in result.untakenTransitions) {
      final parts = t.split(' → ');
      buf.writeln('${parts[0]},${parts.length > 1 ? parts[1] : ''}');
    }
    buf.writeln();

    buf.writeln('## Uncovered Branches');
    buf.writeln('Branch');
    for (final b in result.uncoveredBranches) {
      buf.writeln('"$b"');
    }
    buf.writeln();

    buf.writeln('## Untoggled Signals');
    buf.writeln('Signal');
    for (final s in result.untoggledSignals) {
      buf.writeln(s);
    }

    return buf.toString();
  }

  // ── Export — Markdown ──────────────────────────────────────────────────────

  String toMarkdown() {
    final buf = StringBuffer();

    buf.writeln('# RTL Coverage Report');
    buf.writeln();
    buf.writeln('**Overall Coverage:** ${_pctStr(result.overallCoverage)}  '
        '**Grade:** ${result.grade}  '
        '**Gaps:** ${result.totalGaps}');
    buf.writeln();

    buf.writeln('## Coverage Summary');
    buf.writeln();
    buf.writeln('| Metric | Covered | Total | % |');
    buf.writeln('|--------|---------|-------|---|');
    buf.writeln('| State | ${metrics.visitedStateCount} | ${metrics.totalStates} | ${_pctStr(result.stateCoverage)} |');
    buf.writeln('| Transition | ${metrics.executedTransitionCount} | ${metrics.totalTransitions} | ${_pctStr(result.transitionCoverage)} |');
    buf.writeln('| Branch | ${metrics.coveredBranchCount} | ${metrics.totalBranches} | ${_pctStr(result.branchCoverage)} |');
    buf.writeln('| Toggle | ${metrics.toggledSignalCount} | ${metrics.totalSignals} | ${_pctStr(result.toggleCoverage)} |');
    buf.writeln('| Condition | ${metrics.evaluatedConditionCount} | ${metrics.totalConditions} | ${_pctStr(result.conditionCoverage)} |');
    buf.writeln('| Line | ${metrics.executedLineCount} | ${metrics.totalLines} | ${_pctStr(result.lineCoverage)} |');
    buf.writeln();

    if (result.unvisitedStates.isNotEmpty) {
      buf.writeln('## Unvisited States');
      buf.writeln();
      for (final s in result.unvisitedStates) {
        buf.writeln('- `$s`');
      }
      buf.writeln();
    }

    if (result.untakenTransitions.isNotEmpty) {
      buf.writeln('## Missing Transitions');
      buf.writeln();
      for (final t in result.untakenTransitions) {
        buf.writeln('- $t');
      }
      buf.writeln();
    }

    if (result.uncoveredBranches.isNotEmpty) {
      buf.writeln('## Uncovered Branches');
      buf.writeln();
      for (final b in result.uncoveredBranches) {
        buf.writeln('- `$b`');
      }
      buf.writeln();
    }

    if (result.untoggledSignals.isNotEmpty) {
      buf.writeln('## Untoggled Signals');
      buf.writeln();
      for (final s in result.untoggledSignals) {
        buf.writeln('- `$s`');
      }
      buf.writeln();
    }

    if (coverageWarnings.isNotEmpty) {
      buf.writeln('## Coverage Warnings');
      buf.writeln();
      for (final w in coverageWarnings) {
        final icon = w.severity == 'critical'
            ? '🔴' : w.severity == 'warning' ? '🟡' : 'ℹ️';
        buf.writeln('$icon **[${w.category.name}]** ${w.message}');
        if (w.suggestion != null) {
          buf.writeln('  > _Suggestion: ${w.suggestion}_');
        }
      }
    }

    return buf.toString();
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static double _pct(double v) =>
      double.parse((v * 100).toStringAsFixed(1));

  static String _pctStr(double v) =>
      '${(v * 100).toStringAsFixed(1)}%';
}
