import 'diagnostic_category.dart';
import 'diagnostic_severity.dart';

// ─── DiagnosticIssue ──────────────────────────────────────────────────────────

/// Represents one diagnosed problem identified by [DiagnosticsEngine].
///
/// Each issue carries a [title], [description], [category], [severity], and a
/// list of [evidence] strings drawn from one or more upstream frameworks.
///
/// Evidence strings are deterministically ordered and deduplicated within each
/// issue.  The same evidence string is never repeated inside one issue.
///
/// Invariants:
/// - [evidence] is unmodifiable.
/// - Input list mutation after construction does not affect the stored evidence.
/// - Equality is defined by all five fields.
///
/// Future extension points:
/// - Add [suggestedFix] for repair-planning integration.
/// - Add [relatedIssueIds] for cross-issue dependency tracking.
class DiagnosticIssue {
  /// Short human-readable identifier for the issue.
  final String title;

  /// Detailed explanation of the problem.
  final String description;

  /// Verification sub-system this issue originates from.
  final DiagnosticCategory category;

  /// Impact level on verification quality.
  final DiagnosticSeverity severity;

  /// Supporting evidence strings drawn from upstream framework outputs.
  ///
  /// Each entry is a human-readable summary of one data point.
  /// The list is unmodifiable.
  final List<String> evidence;

  DiagnosticIssue({
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required List<String> evidence,
  }) : evidence = List.unmodifiable(List.of(evidence));

  // ── Identity ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticIssue &&
          title       == other.title       &&
          description == other.description &&
          category    == other.category    &&
          severity    == other.severity    &&
          _evidenceEqual(evidence, other.evidence);

  static bool _evidenceEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(title, category, severity);

  @override
  String toString() =>
      'DiagnosticIssue(${category.name}, ${severity.name}, "$title")';
}
