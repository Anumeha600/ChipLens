import '../../models/design_spec.dart';

// ─── RepairSuggestion ─────────────────────────────────────────────────────────

/// A single, actionable fix for one diagnostic finding.
class RepairSuggestion {
  /// Which diagnostic rule triggered this suggestion.
  final String ruleId;

  /// Short human-readable title of the fix.
  final String title;

  /// Explanation of why the issue exists and what this fix does.
  final String explanation;

  /// The exact source fragment to be replaced.
  /// Empty string means no automatic code replacement is possible.
  final String originalCode;

  /// The replacement source fragment.
  /// Empty string when [originalCode] is empty.
  final String replacementCode;

  /// Estimated probability that this repair is correct (0.0 – 1.0).
  final double confidence;

  const RepairSuggestion({
    required this.ruleId,
    required this.title,
    required this.explanation,
    required this.originalCode,
    required this.replacementCode,
    required this.confidence,
  }) : assert(confidence >= 0.0 && confidence <= 1.0);

  /// Whether this suggestion can be applied automatically.
  bool get isAutoFixable => originalCode.isNotEmpty;

  String get confidenceLabel {
    if (confidence >= 0.85) return 'High';
    if (confidence >= 0.60) return 'Medium';
    return 'Low';
  }
}

// ─── RepairResult ─────────────────────────────────────────────────────────────

/// The outcome of applying one or more [RepairSuggestion]s and re-analysing.
class RepairResult {
  /// The RTL source after all selected suggestions were applied.
  final String repairedRTL;

  /// Number of diagnostic issues that disappeared after the repair.
  final int issuesFixed;

  /// Number of diagnostic issues remaining after the repair.
  final int remainingIssues;

  /// Quality score (0–100) before the repair.
  final double qualityBefore;

  /// Quality score (0–100) after re-analysis of the repaired RTL.
  final double qualityAfter;

  /// The suggestions that were actually applied.
  final List<RepairSuggestion> appliedSuggestions;

  /// Full quality report after repair (for detailed display).
  final QualityReport newQualityReport;

  const RepairResult({
    required this.repairedRTL,
    required this.issuesFixed,
    required this.remainingIssues,
    required this.qualityBefore,
    required this.qualityAfter,
    required this.appliedSuggestions,
    required this.newQualityReport,
  });

  double get qualityDelta => qualityAfter - qualityBefore;
}
