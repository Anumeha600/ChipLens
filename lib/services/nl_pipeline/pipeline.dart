// Local NL-to-RTL pipeline — orchestrates all stages.
// Call LocalPipeline.run(description) from a Future/isolate.
//
// The method returns Future<DesignResult> because Verilator lint runs
// asynchronously after RTL generation.  The existing UI call-site:
//   Future.microtask(() => LocalPipeline.run(desc))
// continues to work — Dart's Future.microtask accepts FutureOr<T> and
// automatically flattens an inner Future<T> into the outer one.

import '../../models/design_spec.dart';
import '../../backend/coverage/coverage.dart';
import '../../backend/diagnostics/diagnostics.dart';
import '../../backend/tools/verilator_service.dart';
import '../../backend/tools/yosys_service.dart';
import '../../backend/tools/icarus_service.dart';
import 'intent_extractor.dart';
import 'fsm_builder.dart';
import 'rtl_generator.dart';
import 'testbench_generator.dart';
import 'quality_analyzer.dart';
import 'explanation_engine.dart';

class LocalPipeline {
  static const _verilator = VerilatorService();
  static const _yosys     = YosysService();
  static const _icarus    = IcarusService();

  /// Run all pipeline stages and return a [DesignResult].
  ///
  /// Verilator lint is launched concurrently with [QualityAnalyzer] so the
  /// async overhead does not add to wall-clock time on fast machines.
  ///
  /// If Verilator is unavailable or fails the pipeline still succeeds — the
  /// [QualityReport] will contain only internal diagnostics.
  static Future<DesignResult> run(String description) async {
    // Stage 1 — intent extraction
    final intent = IntentExtractor.extract(description);

    // Stage 2 — FSM / DesignSpecification construction
    final spec = FsmBuilder.build(intent);

    // Stage 3 — RTL generation
    final rtl = RtlGenerator.generate(spec);

    // Stage 4 — testbench generation
    final testbench = TestbenchGenerator.generate(spec);

    // Stage 5a — launch all external tools concurrently while QualityAnalyzer works
    // Icarus needs both RTL and testbench (available since stage 4 completed above).
    final verilatorFuture = _lintWithVerilator(rtl);
    final yosysFuture     = _analyzeWithYosys(rtl);
    final icarusFuture    = _runIcarus(rtl, testbench);

    // Stage 5b — internal quality analysis (synchronous)
    final internalQuality = QualityAnalyzer.analyze(rtl, spec);

    // Stage 5c — await external tools
    final verilatorDiags = await verilatorFuture;
    final yosysDiags     = await yosysFuture;
    final (icarusDiags, simOutput) = await icarusFuture;

    // Stage 5d — coverage analysis (full 6-metric; uses raw sim stdout)
    final coverageReport = CoverageAnalyzer.analyze(
      simulationOutput: simOutput,
      spec:             spec,
      rtlSource:        rtl,
    );

    // Stage 5e — merge external diagnostics + adjust score
    QualityReport quality = internalQuality;
    if (verilatorDiags.isNotEmpty ||
        yosysDiags.isNotEmpty     ||
        icarusDiags.isNotEmpty) {
      final engine = DiagnosticEngine()
        ..addAll(verilatorDiags)
        ..addAll(yosysDiags)
        ..addAll(icarusDiags);
      quality = engine.mergeIntoReport(internalQuality);
    }

    // Stage 5f — append coverage warnings + apply coverage quality penalty
    final coverageWarnings = coverageReport.result.warnings;
    if (coverageWarnings.isNotEmpty) {
      final merged = [...quality.warnings, ...coverageWarnings];
      quality = QualityReport(
        total:           quality.total,
        grade:           quality.grade,
        categories:      quality.categories,
        categoryDetails: quality.categoryDetails,
        warnings:        merged,
        warningCount:    merged.length,
      );
    }

    // Stage 5g — coverage quality adjustment (up to -8 pts for <60% overall)
    final overall = coverageReport.overallCoverage;
    if (overall < 0.60 && simOutput.isNotEmpty) {
      final penalty = ((0.60 - overall) * 20).round().clamp(0, 8);
      if (penalty > 0) {
        quality = QualityReport(
          total:           (quality.total - penalty).clamp(0, 100),
          grade:           quality.grade,
          categories:      quality.categories,
          categoryDetails: quality.categoryDetails,
          warnings:        quality.warnings,
          warningCount:    quality.warningCount,
        );
      }
    }

    // Stage 6 — engineering explanation
    final explanation = ExplanationEngine.explain(spec, quality);

    // Build FSM edge list for the canvas painter
    final fsmEdges = spec.transitions
        .map((t) => <String, dynamic>{
              'from': t.from,
              'to':   t.to,
              'label': t.condition,
            })
        .toList();

    // Identify dead / unreachable states
    final reachable  = _reachableStates(spec);
    final allStates  = spec.states.map((s) => s.name).toList();
    final unreachable = allStates.where((s) => !reachable.contains(s)).toList();

    final hasOutgoing = spec.transitions.map((t) => t.from).toSet();
    final dead = allStates.where((s) => !hasOutgoing.contains(s)).toList();

    return DesignResult(
      spec:                spec,
      rtl:                 rtl,
      testbench:           testbench,
      explanation:         explanation,
      quality:             quality,
      fsmStates:           allStates,
      fsmEdges:            fsmEdges,
      fsmEntryState:       spec.entryState,
      fsmDeadStates:       dead,
      fsmUnreachableStates: unreachable,
      coverageReport:      coverageReport,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Invoke Verilator and parse its output into [Diagnostic] objects.
  /// Returns an empty list if Verilator is unavailable or throws.
  static Future<List<Diagnostic>> _lintWithVerilator(String rtl) async {
    try {
      final result   = await _verilator.lint(rtl);
      final combined = '${result.stderr}\n${result.stdout}'.trim();
      return VerilatorDiagnosticParser.parse(combined);
    } catch (_) {
      return [];
    }
  }

  /// Invoke Yosys and parse its output into [Diagnostic] objects.
  /// Returns an empty list if Yosys is unavailable or throws.
  static Future<List<Diagnostic>> _analyzeWithYosys(String rtl) async {
    try {
      final result   = await _yosys.analyze(rtl);
      final combined = '${result.stderr}\n${result.stdout}'.trim();
      return YosysParser.parse(combined);
    } catch (_) {
      return [];
    }
  }

  /// Compile and simulate with Icarus Verilog.
  /// Returns `(diagnostics, rawOutput)` — raw output is the combined
  /// stdout+stderr string, used by [CoverageEngine] after this call returns.
  /// Returns `([], '')` if Icarus is unavailable or throws.
  static Future<(List<Diagnostic>, String)> _runIcarus(
    String rtl,
    String testbench,
  ) async {
    try {
      final result   = await _icarus.simulate(rtl, testbench);
      final combined = '${result.stderr}\n${result.stdout}'.trim();
      return (IcarusParser.parse(combined), combined);
    } catch (_) {
      return (<Diagnostic>[], '');
    }
  }

  /// BFS from entry state to find all reachable states.
  static Set<String> _reachableStates(DesignSpecification spec) {
    final adj = <String, List<String>>{};
    for (final t in spec.transitions) {
      adj.putIfAbsent(t.from, () => []).add(t.to);
    }
    final visited = <String>{};
    final queue   = [spec.entryState];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (visited.contains(cur)) continue;
      visited.add(cur);
      queue.addAll(adj[cur] ?? []);
    }
    return visited;
  }
}
