import '../../models/design_spec.dart';
import '../../backend/coverage/coverage_report.dart';

/// All data required during a repair pass.
///
/// Designed as an immutable value object so it can be safely passed across
/// the pipeline stages without risk of mutation.
///
/// ## Extension points
///
/// Future analysis passes extend the context by adding new optional fields
/// and constructor parameters rather than subclassing:
///
/// - **Formal Verification**: add `formalResult: FormalVerificationResult?`
///   so [RepairPipeline] can incorporate formal counterexamples as additional
///   diagnostics.
///
/// - **Timing Analysis**: add `timingReport: TimingReport?` so the repair
///   catalog can weight timing-critical paths differently.
///
/// - **Incremental repair**: add `previousResult: RepairResult?` to allow
///   the pipeline to skip already-fixed issues.
///
/// The [config] map provides an escape hatch for arbitrary key-value data
/// without breaking binary compatibility between releases.
class RepairContext {
  /// The RTL Verilog source to be analysed or repaired.
  final String rtlSource;

  /// Diagnostic warnings driving the repair pass.
  final List<QualityWarning> diagnostics;

  /// Optional coverage report; used to generate coverage-gap suggestions.
  final CoverageReport? coverageReport;

  /// Design specification; used to generate testbenches during re-analysis.
  final DesignSpecification? spec;

  /// Arbitrary key-value configuration for future pipeline extensions.
  final Map<String, dynamic> config;

  const RepairContext({
    required this.rtlSource,
    this.diagnostics  = const [],
    this.coverageReport,
    this.spec,
    this.config       = const {},
  });
}
