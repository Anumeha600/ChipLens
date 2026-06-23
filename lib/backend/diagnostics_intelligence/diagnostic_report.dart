import 'diagnostic_issue.dart';
import 'diagnostic_severity.dart';
import 'diagnostic_statistics.dart';
import 'diagnostic_summary.dart';

export 'diagnostic_severity.dart' show DiagnosticConfidence;

// ─── DiagnosticReport ─────────────────────────────────────────────────────────

/// Immutable reasoning result produced by [DiagnosticsEngine.analyze].
///
/// Bundles every derived artifact — summary, issue list, statistics, overall
/// severity, and overall confidence — into a single self-contained value.
///
/// Invariants:
/// - [issues] is unmodifiable.
/// - All fields are non-null.
/// - [isHealthy] is `true` only when [overallSeverity] is
///   [DiagnosticSeverity.informational].
///
/// Future extension points:
/// - Add [historicalComparison] for regression tracking.
/// - Add [repairSuggestions] when Repair Planning is integrated.
/// - Add [verificationHealthScore] (0–100) for CI/CD gates.
class DiagnosticReport {
  /// High-level human-readable description of the overall verification health.
  final DiagnosticSummary summary;

  /// Ordered list of diagnosed issues, highest severity first.
  final List<DiagnosticIssue> issues;

  /// Derived counts summarising severity distribution.
  final DiagnosticStatistics statistics;

  /// Highest severity level among all issues, or
  /// [DiagnosticSeverity.informational] when there are no issues.
  final DiagnosticSeverity overallSeverity;

  /// Confidence in the completeness of the diagnosis.
  final DiagnosticConfidence overallConfidence;

  DiagnosticReport({
    required this.summary,
    required List<DiagnosticIssue> issues,
    required this.statistics,
    required this.overallSeverity,
    required this.overallConfidence,
  }) : issues = List.unmodifiable(List.of(issues));

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// `true` when at least one issue was diagnosed.
  bool get hasIssues => issues.isNotEmpty;

  /// `true` when no significant issues were found (severity is informational).
  bool get isHealthy => overallSeverity == DiagnosticSeverity.informational;

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticReport &&
          summary          == other.summary          &&
          overallSeverity  == other.overallSeverity  &&
          overallConfidence == other.overallConfidence &&
          statistics       == other.statistics       &&
          _issuesEqual(issues, other.issues);

  static bool _issuesEqual(
    List<DiagnosticIssue> a,
    List<DiagnosticIssue> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        summary, overallSeverity, overallConfidence, statistics, issues.length);

  @override
  String toString() =>
      'DiagnosticReport(severity=${overallSeverity.name}, '
      'confidence=${overallConfidence.name}, issues=${issues.length})';
}
