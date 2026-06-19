import '../../backend/coverage/coverage_model.dart';
import '../../backend/diagnostics/diagnostics.dart';
import '../../backend/verification/verification_runner.dart';
import '../../backend/tools/rtl_testbench_generator.dart';
import '../../models/design_spec.dart';
import '../../services/nl_pipeline/quality_analyzer.dart';
import '../../services/nl_pipeline/testbench_generator.dart';
import 'repair_catalog.dart';
import 'repair_context.dart';
import 'repair_executor.dart';
import 'repair_matcher.dart';
import 'repair_suggestion.dart';

/// Orchestrates the full repair flow.
///
/// ```
/// RepairContext
///   → RepairMatcher (detect fix group per warning)
///   → RepairCatalog (build suggestion from RTL + fix group)
///   → deduplication + coverage suggestions + sort
///   → List<RepairSuggestion>
///
/// List<RepairSuggestion>
///   → RepairExecutor (apply patches)
///   → VerificationRunner (re-analyse repaired RTL)
///   → RepairResult
/// ```
///
/// Future pipeline extensions (formal verification, timing analysis) add
/// new stages here without touching [RepairEngine], [RepairMatcher], or
/// [RepairCatalog].
abstract class RepairPipeline {
  RepairPipeline._();

  /// Run the suggest pass over [ctx] and return deduplicated, sorted
  /// [RepairSuggestion]s.
  static List<RepairSuggestion> suggest(RepairContext ctx) {
    final seen        = <String>{};
    final suggestions = <RepairSuggestion>[];

    for (final w in ctx.diagnostics) {
      final fixGroup = RepairMatcher.detect(w.type);
      if (fixGroup == null) continue;

      final s = RepairCatalog.build(fixGroup, ctx.rtlSource, w);
      if (s == null) continue;

      final key = s.isAutoFixable ? s.originalCode : '${s.ruleId}:info';
      if (seen.add(key)) suggestions.add(s);
    }

    // Coverage-gap informational suggestions
    if (ctx.coverageReport != null) {
      for (final w in ctx.coverageReport!.coverageWarnings) {
        final key = 'coverage:${w.category.name}:${w.target}';
        if (!seen.add(key)) continue;
        suggestions.add(RepairSuggestion(
          ruleId:          w.toQualityWarning().type,
          title:           _coverageTitle(w),
          explanation:     '${w.message}'
              '${w.suggestion != null ? " ${w.suggestion}" : ""}',
          originalCode:    '',
          replacementCode: '',
          confidence:      _coverageConfidence(w),
        ));
      }
    }

    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions;
  }

  /// Apply [suggestions] to the RTL in [ctx], re-run the full analysis
  /// pipeline, and return a [RepairResult] comparing before/after metrics.
  static Future<RepairResult> repair({
    required RepairContext ctx,
    required List<RepairSuggestion> suggestions,
    required QualityReport qualityBefore,
  }) async {
    // 1 — apply patches
    final repairedRtl = RepairExecutor.applyAll(ctx.rtlSource, suggestions);

    // 2 — generate testbench (prefer RTL-inferred, fall back to spec template)
    final tbResult  = RtlTestbenchGenerator.generate(repairedRtl);
    final testbench = tbResult.success
        ? tbResult.source
        : ctx.spec != null
            ? TestbenchGenerator.generate(ctx.spec!)
            : '';

    // 3 — launch all external tools concurrently while the sync analyser runs
    final verilatorFuture = VerificationRunner.runVerilator(repairedRtl);
    final yosysFuture     = VerificationRunner.runYosys(repairedRtl);
    final icarusFuture    = VerificationRunner.runIcarus(repairedRtl, testbench)
        .then((r) => r.$1);

    // 4 — internal quality re-analysis (synchronous)
    final newInternal = ctx.spec != null
        ? QualityAnalyzer.analyze(repairedRtl, ctx.spec!)
        : qualityBefore;

    // 5 — collect external results
    final verilatorDiags = await verilatorFuture;
    final yosysDiags     = await yosysFuture;
    final icarusDiags    = await icarusFuture;

    // 6 — merge external diagnostics
    QualityReport newQuality = newInternal;
    if (verilatorDiags.isNotEmpty ||
        yosysDiags.isNotEmpty     ||
        icarusDiags.isNotEmpty) {
      final engine = DiagnosticEngine()
        ..addAll(verilatorDiags)
        ..addAll(yosysDiags)
        ..addAll(icarusDiags);
      newQuality = engine.mergeIntoReport(newInternal);
    }

    // 7 — compute delta metrics
    final before = qualityBefore.warnings.length;
    final after  = newQuality.warnings.length;

    return RepairResult(
      repairedRTL:        repairedRtl,
      issuesFixed:        (before - after).clamp(0, before),
      remainingIssues:    after,
      qualityBefore:      qualityBefore.total.toDouble(),
      qualityAfter:       newQuality.total.toDouble(),
      appliedSuggestions: suggestions,
      newQualityReport:   newQuality,
    );
  }

  // ── Coverage helpers ───────────────────────────────────────────────────────

  static String _coverageTitle(CoverageWarning w) {
    switch (w.category) {
      case CoverageWarningCategory.state:      return 'Unvisited state: ${w.target}';
      case CoverageWarningCategory.transition: return 'Missing transition: ${w.target}';
      case CoverageWarningCategory.branch:     return 'Uncovered branch';
      case CoverageWarningCategory.toggle:     return 'Untoggled signal: ${w.target}';
      case CoverageWarningCategory.condition:  return 'Partial condition coverage';
      case CoverageWarningCategory.deadLogic:  return 'Potential dead logic detected';
    }
  }

  static double _coverageConfidence(CoverageWarning w) {
    switch (w.severity) {
      case 'critical': return 0.80;
      case 'warning':  return 0.65;
      default:         return 0.45;
    }
  }
}
