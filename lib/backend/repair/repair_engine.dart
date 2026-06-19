import '../../models/design_spec.dart';
import '../../backend/coverage/coverage_report.dart';
import 'repair_context.dart';
import 'repair_executor.dart';
import 'repair_pipeline.dart';
import 'repair_suggestion.dart';

// ─── RepairEngine ─────────────────────────────────────────────────────────────

/// Public API for the repair framework.
///
/// All methods delegate immediately to the appropriate internal module:
/// - [RepairPipeline] for orchestration
/// - [RepairExecutor] for patch application
///
/// No business logic lives here.  Adding a new repair type requires changes
/// only to [RepairMatcher] (detection) and [RepairCatalog] (strategy).
class RepairEngine {
  /// Analyse [rtlSource] against [warnings] and return repair suggestions.
  ///
  /// Results are ordered by descending confidence and deduplicated by
  /// [RepairSuggestion.originalCode] so that two warnings that target the
  /// same code fragment produce only one suggestion.
  static List<RepairSuggestion> suggest({
    required String rtlSource,
    required List<QualityWarning> warnings,
    CoverageReport? coverageReport,
  }) =>
      RepairPipeline.suggest(RepairContext(
        rtlSource:       rtlSource,
        diagnostics:     warnings,
        coverageReport:  coverageReport,
      ));

  /// Apply [suggestions] sequentially to [rtlSource] and return the result.
  ///
  /// Non-auto-fixable suggestions (empty [RepairSuggestion.originalCode]) are
  /// skipped.  If a later suggestion's [originalCode] was already replaced by
  /// an earlier one, the replacement is skipped gracefully.
  static String applyAll(
    String rtlSource,
    List<RepairSuggestion> suggestions,
  ) =>
      RepairExecutor.applyAll(rtlSource, suggestions);

  /// Apply [suggestions] to [originalRtl], then re-run the full analysis
  /// pipeline (internal quality + Verilator + Yosys + Icarus) and return a
  /// [RepairResult] comparing before/after metrics.
  static Future<RepairResult> repair({
    required String originalRtl,
    required List<RepairSuggestion> suggestions,
    required DesignSpecification spec,
    required QualityReport qualityBefore,
  }) =>
      RepairPipeline.repair(
        ctx:           RepairContext(rtlSource: originalRtl, spec: spec),
        suggestions:   suggestions,
        qualityBefore: qualityBefore,
      );
}
