import 'diagnostic_issue.dart';
import 'diagnostic_severity.dart';

// ─── DiagnosticStatistics ─────────────────────────────────────────────────────

/// Derived metrics summarising a [DiagnosticReport].
///
/// All fields are non-negative integer counts computed from the [DiagnosticIssue]
/// list.  The component severity counts must always sum to [issueCount]; the
/// constructor enforces this invariant at construction time.
///
/// Invariants:
/// - All fields are non-negative.
/// - [criticalIssues] + [highIssues] + [mediumIssues] + [lowIssues] +
///   [informationalIssues] == [issueCount].
///
/// Future extension points:
/// - Add [issuesByCategory] map for category breakdown.
/// - Add [averageSeverityScore] for trend analysis.
class DiagnosticStatistics {
  /// Total number of issues in the [DiagnosticReport].
  final int issueCount;

  /// Number of [DiagnosticSeverity.critical] issues.
  final int criticalIssues;

  /// Number of [DiagnosticSeverity.high] issues.
  final int highIssues;

  /// Number of [DiagnosticSeverity.medium] issues.
  final int mediumIssues;

  /// Number of [DiagnosticSeverity.low] issues.
  final int lowIssues;

  /// Number of [DiagnosticSeverity.informational] issues.
  final int informationalIssues;

  DiagnosticStatistics({
    required this.issueCount,
    required this.criticalIssues,
    required this.highIssues,
    required this.mediumIssues,
    required this.lowIssues,
    required this.informationalIssues,
  }) {
    final sum =
        criticalIssues + highIssues + mediumIssues + lowIssues + informationalIssues;
    if (sum != issueCount) {
      throw StateError(
        'DiagnosticStatistics: severity counts ($sum) do not sum to '
        'issueCount ($issueCount).',
      );
    }
  }

  /// Zero-value statistics for an empty or disabled assessment.
  static final DiagnosticStatistics empty = DiagnosticStatistics(
    issueCount:          0,
    criticalIssues:      0,
    highIssues:          0,
    mediumIssues:        0,
    lowIssues:           0,
    informationalIssues: 0,
  );

  /// Builds statistics from an issue list in O(n).
  factory DiagnosticStatistics.fromIssues(List<DiagnosticIssue> issues) {
    int critical = 0, high = 0, medium = 0, low = 0, informational = 0;
    for (final issue in issues) {
      switch (issue.severity) {
        case DiagnosticSeverity.critical:      critical++;      break;
        case DiagnosticSeverity.high:          high++;          break;
        case DiagnosticSeverity.medium:        medium++;        break;
        case DiagnosticSeverity.low:           low++;           break;
        case DiagnosticSeverity.informational: informational++; break;
      }
    }
    return DiagnosticStatistics(
      issueCount:          issues.length,
      criticalIssues:      critical,
      highIssues:          high,
      mediumIssues:        medium,
      lowIssues:           low,
      informationalIssues: informational,
    );
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticStatistics &&
          issueCount          == other.issueCount          &&
          criticalIssues      == other.criticalIssues      &&
          highIssues          == other.highIssues          &&
          mediumIssues        == other.mediumIssues        &&
          lowIssues           == other.lowIssues           &&
          informationalIssues == other.informationalIssues;

  @override
  int get hashCode =>
      Object.hash(issueCount, criticalIssues, highIssues, mediumIssues,
          lowIssues, informationalIssues);

  @override
  String toString() =>
      'DiagnosticStatistics(total=$issueCount, '
      'critical=$criticalIssues, high=$highIssues, medium=$mediumIssues, '
      'low=$lowIssues, info=$informationalIssues)';
}
