import 'diagnostic_source.dart';

export 'diagnostic_source.dart';

class QualityWarning {
  final String type;
  final String message;
  final String severity; // 'critical' | 'warning' | 'info'

  // Extended fields — optional and backward-compatible.
  // The UI does not need to read these; they exist for test assertions,
  // analytics, and future display features.
  final DiagnosticSource source;
  final String? quickFix;

  const QualityWarning({
    required this.type,
    required this.message,
    required this.severity,
    this.source   = DiagnosticSource.internal,
    this.quickFix,
  });
}

class QualityCategory {
  final String name;
  final int score;
  final int maxScore;
  final String explanation;
  final List<String> issues;
  final List<String> recommendations;

  const QualityCategory({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.explanation,
    this.issues = const [],
    this.recommendations = const [],
  });

  double get fraction => maxScore > 0 ? score / maxScore : 0.0;
}

class QualityReport {
  final int total;
  final String grade;
  final Map<String, int> categories;
  final List<QualityCategory> categoryDetails;
  final List<QualityWarning> warnings;
  final int warningCount;

  const QualityReport({
    required this.total,
    required this.grade,
    required this.categories,
    this.categoryDetails = const [],
    this.warnings = const [],
    this.warningCount = 0,
  });
}
