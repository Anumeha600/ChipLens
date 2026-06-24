// ─── ReportConfig ─────────────────────────────────────────────────────────────

/// Configuration for [BenchmarkReportGenerator].
///
/// All fields have sensible defaults so callers only need to specify what
/// they want to override.
class ReportConfig {
  /// Path (relative to project root) where the markdown report is written.
  final String outputPath;

  /// When true, includes today's date in the report header.
  final bool includeDate;

  /// When true, includes a notes column in the design table for failed runs.
  final bool includeNotes;

  const ReportConfig({
    this.outputPath  = 'docs/evaluation/benchmark_results.md',
    this.includeDate = true,
    this.includeNotes = false,
  });

  @override
  String toString() => 'ReportConfig(outputPath=$outputPath)';
}
