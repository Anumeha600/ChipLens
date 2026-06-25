import 'dart:io';

import 'package:chiplens_lite/backend/coverage_intelligence/coverage_intelligence.dart';
import 'package:chiplens_lite/backend/counterexample/counterexample.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';
import 'package:chiplens_lite/backend/diagnostics_intelligence/diagnostics_intelligence.dart';
import 'package:chiplens_lite/backend/explainability/explainability.dart';
import 'package:chiplens_lite/backend/planning/planning.dart';
import 'package:chiplens_lite/backend/repair_planning/repair_planning.dart';

import '../models/benchmark_models.dart';
import 'benchmark.dart';

// ─── BenchmarkRunner ─────────────────────────────────────────────────────────

/// Executes the full ChipLens analysis pipeline against one RTL fixture and
/// returns timing and output-count statistics.
///
/// Pipeline:
///   RTL source
///     → [DesignRunner.analyze]      → [DesignKnowledge]
///     → coverage heuristic          → [CoverageAssessment]
///     → [DiagnosticsEngine.analyze] → [DiagnosticReport]
///     → [RepairPlanner.plan]        → [RepairPlan]
///     → [BenchmarkResult]
///
/// The coverage assessment is derived from [DesignKnowledge] using a
/// complexity heuristic so that designs with more detected structures produce
/// measurably different diagnostic and repair counts.
///
/// Invariants:
/// - Never throws. All errors are caught and returned as failed [BenchmarkResult]s.
/// - [BenchmarkResult.runtimeMs] reflects the full pipeline wall-clock time.
class BenchmarkRunner {
  const BenchmarkRunner();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Load the RTL source from [benchmark.fixturePath] and run the pipeline.
  Future<BenchmarkResult> run(Benchmark benchmark) async {
    final String rtlSource;
    try {
      rtlSource = File(benchmark.fixturePath).readAsStringSync();
    } catch (e) {
      return BenchmarkResult(
        designName:      benchmark.designName,
        runtimeMs:       0,
        diagnosticCount: 0,
        repairCount:     0,
        success:         false,
        notes:           'Could not read fixture: $e',
      );
    }
    return runFromSource(benchmark.designName, rtlSource);
  }

  /// Run the full pipeline against [rtlSource] and return a [BenchmarkResult].
  ///
  /// Suitable for tests that provide RTL inline rather than loading from disk.
  Future<BenchmarkResult> runFromSource(
    String designName,
    String rtlSource,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      // ── Step 1: Design Intelligence ─────────────────────────────────────────
      final knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: rtlSource),
      );

      // ── Step 2: Coverage assessment from DesignKnowledge ───────────────────
      final coverage = _buildCoverage(knowledge);

      // ── Step 3: Counterexample report (benchmark mode — no formal run) ──────
      final counterexample = _buildCounterexample();

      // ── Step 4: Diagnostics ─────────────────────────────────────────────────
      final diagReport = const DiagnosticsEngine().analyze(
        coverage,
        counterexample,
        VerificationExplanationSet(),
        VerificationPlan(),
        DiagnosticContext(),
      );

      // ── Step 5: Repair planning ─────────────────────────────────────────────
      final repairPlan = const RepairPlanner().plan(diagReport, RepairContext());

      stopwatch.stop();
      return BenchmarkResult(
        designName:      designName,
        runtimeMs:       stopwatch.elapsedMilliseconds,
        diagnosticCount: diagReport.issues.length,
        repairCount:     repairPlan.steps.length,
        success:         true,
      );
    } catch (e) {
      stopwatch.stop();
      return BenchmarkResult(
        designName:      designName,
        runtimeMs:       stopwatch.elapsedMilliseconds,
        diagnosticCount: 0,
        repairCount:     0,
        success:         false,
        notes:           e.toString(),
      );
    }
  }

  // ── Heuristic inputs ───────────────────────────────────────────────────────

  /// Derive a [CoverageAssessment] from [DesignKnowledge].
  ///
  /// Complexity = FSM count + counter count + register count.
  /// Every unit of complexity reduces estimated coverage by 5 pp (clamped to
  /// [0.55, 0.97]).  The penalty was reduced from 6 pp to 5 pp to avoid
  /// overstating coverage concerns on designs with small register counts: a
  /// design with 3 sequential registers now estimates at 82 % (CoverageRisk.low)
  /// rather than 79 % (CoverageRisk.moderate).
  CoverageAssessment _buildCoverage(DesignKnowledge knowledge) {
    final complexity = knowledge.fsms.length +
        knowledge.counters.length +
        knowledge.registers.length;

    final overallCoverage = complexity == 0
        ? 0.97
        : (0.97 - complexity * 0.05).clamp(0.55, 0.94);

    final CoverageRisk risk;
    final CoverageConfidence confidence;

    if (overallCoverage >= 0.95) {
      risk       = CoverageRisk.minimal;
      confidence = CoverageConfidence.veryHigh;
    } else if (overallCoverage >= 0.80) {
      risk       = CoverageRisk.low;
      confidence = CoverageConfidence.high;
    } else if (overallCoverage >= 0.60) {
      risk       = CoverageRisk.moderate;
      confidence = CoverageConfidence.medium;
    } else {
      risk       = CoverageRisk.high;
      confidence = CoverageConfidence.low;
    }

    final uncoveredStates      = knowledge.fsms.length * 2;
    final uncoveredTransitions = knowledge.fsms.length;
    final uncoveredBranches    = knowledge.counters.length + knowledge.registers.length;
    final untoggledSignals     = knowledge.registers.length;

    return CoverageAssessment(
      summary: CoverageSummary(
        overview:
            'Coverage estimated from design complexity '
            '(${(overallCoverage * 100).toStringAsFixed(0)}%).',
        strongestDimension: 'line',
        weakestDimension:
            knowledge.fsms.isNotEmpty ? 'state' : 'branch',
        dominantIssue: uncoveredStates > 0
            ? '$uncoveredStates estimated uncovered FSM states.'
            : 'None.',
      ),
      risk:            risk,
      confidence:      confidence,
      recommendations: <CoverageRecommendation>[],
      statistics: CoverageStatistics(
        recommendationCount:  0,
        warningCount:         uncoveredStates + uncoveredBranches,
        uncoveredStates:      uncoveredStates,
        uncoveredTransitions: uncoveredTransitions,
        uncoveredBranches:    uncoveredBranches,
        untoggledSignals:     untoggledSignals,
        overallCoverage:      overallCoverage,
      ),
    );
  }

  /// Baseline counterexample report for benchmark mode (no formal tool run).
  CounterexampleReport _buildCounterexample() => CounterexampleReport(
        summary: const CounterexampleSummary(
          overview:        'No formal verification executed in benchmark mode.',
          primaryFailure:  'None',
          earliestFailure: 'None',
          dominantCategory: 'unknown',
        ),
        trace:          CounterexampleTrace.empty,
        classification: CounterexampleClassification.unknown,
        confidence:     CounterexampleConfidence.veryHigh,
        statistics:     CounterexampleStatistics.empty,
      );
}

// ── Suite runner ──────────────────────────────────────────────────────────────

/// Run all [benchmarks] (defaults to [kDefaultBenchmarks]) and return a
/// [BenchmarkSuiteResult].
///
/// Designs are run sequentially so timing measurements are not distorted by
/// concurrent execution.
Future<BenchmarkSuiteResult> runBenchmarkSuite({
  List<Benchmark>? benchmarks,
}) async {
  final suite  = benchmarks ?? kDefaultBenchmarks;
  const runner = BenchmarkRunner();

  final results = <BenchmarkResult>[];
  for (final bench in suite) {
    results.add(await runner.run(bench));
  }

  final successCount = results.where((r) => r.success).length;

  return BenchmarkSuiteResult(
    results:           results,
    totalDesigns:      results.length,
    successfulDesigns: successCount,
    failedDesigns:     results.length - successCount,
  );
}
