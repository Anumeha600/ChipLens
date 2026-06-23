import '../counterexample/counterexample.dart'
    show CounterexampleReport, CounterexampleClassification;
import '../coverage_intelligence/coverage_intelligence.dart'
    show CoverageAssessment, CoverageRisk;
import '../explainability/verification_explanation_set.dart';
import '../planning/planning.dart'
    show VerificationPlan, VerificationStrategy;

import 'diagnostic_category.dart';
import 'diagnostic_context.dart';
import 'diagnostic_issue.dart';
import 'diagnostic_report.dart';
import 'diagnostic_severity.dart';
import 'diagnostic_statistics.dart';
import 'diagnostic_summary.dart';

// ─── DiagnosticsEngine ────────────────────────────────────────────────────────

/// Combines upstream framework outputs into a unified [DiagnosticReport].
///
/// Inputs:
/// - [CoverageAssessment]       — coverage risk, recommendations, statistics.
/// - [CounterexampleReport]     — classification, trace, confidence.
/// - [VerificationExplanationSet] — property explanations and provenance.
/// - [VerificationPlan]         — scheduled verification jobs.
///
/// Output:
/// - [DiagnosticReport] — unified diagnosis with ordered [DiagnosticIssue]s.
///
/// Responsibilities:
/// - Identifies issues from each framework independently.
/// - Fuses evidence from multiple frameworks into single issues when relevant.
/// - Sorts issues by severity (highest first), then category, then title.
/// - Computes overall severity and confidence deterministically.
/// - Generates human-readable summary.
///
/// Invariants:
/// - Does NOT execute formal verification.
/// - Does NOT modify any upstream model.
/// - Does NOT parse RTL, waveforms, or VCD files.
/// - Stateless: every call is completely independent.
/// - Output is deterministic for identical inputs.
class DiagnosticsEngine {
  const DiagnosticsEngine();

  /// Produces a [DiagnosticReport] from the four upstream framework outputs.
  ///
  /// The analysis is O(n log n) where n is the total number of issues
  /// generated (dominated by the sort step).
  DiagnosticReport analyze(
    CoverageAssessment coverage,
    CounterexampleReport counterexample,
    VerificationExplanationSet explanations,
    VerificationPlan plan,
    DiagnosticContext context,
  ) {
    final issues = <DiagnosticIssue>[];

    _addCounterexampleIssue(issues, counterexample, coverage, context);
    _addCoverageIssue(issues, coverage, counterexample, plan, context);
    _addPlanningIssue(issues, plan, explanations, coverage, context);
    _addPropertyQualityIssue(issues, explanations, coverage, context);

    // Sort: highest severity first; ties → category name A-Z → title A-Z.
    issues.sort((a, b) {
      final sc = b.severity.index.compareTo(a.severity.index);
      if (sc != 0) return sc;
      final cc = a.category.name.compareTo(b.category.name);
      if (cc != 0) return cc;
      return a.title.compareTo(b.title);
    });

    // Apply issue limit.
    final limited = (context.maximumIssues >= 0 && issues.length > context.maximumIssues)
        ? issues.sublist(0, context.maximumIssues)
        : issues;

    final overallSeverity = _aggregateSeverity(limited);

    final overallConfidence = context.includeConfidence
        ? _computeConfidence(coverage, counterexample, overallSeverity)
        : DiagnosticConfidence.veryHigh;

    final statistics = context.includeStatistics
        ? DiagnosticStatistics.fromIssues(limited)
        : DiagnosticStatistics.empty;

    final summary = _buildSummary(limited, overallSeverity);

    return DiagnosticReport(
      summary:           summary,
      issues:            limited,
      statistics:        statistics,
      overallSeverity:   overallSeverity,
      overallConfidence: overallConfidence,
    );
  }

  // ── Issue generators ──────────────────────────────────────────────────────

  static void _addCounterexampleIssue(
    List<DiagnosticIssue> issues,
    CounterexampleReport counterexample,
    CoverageAssessment coverage,
    DiagnosticContext context,
  ) {
    final cls   = counterexample.classification;
    final stats = counterexample.statistics;

    switch (cls) {
      case CounterexampleClassification.engineFailure:
        final evidence = <String>[
          'Formal verification engine failure (classification: ${cls.name})',
          'All verification results are unreliable',
        ];
        if (!coverage.isHealthy && context.includeEvidence) {
          evidence.add('Coverage risk also elevated: ${coverage.risk.name}');
        }
        issues.add(DiagnosticIssue(
          title:       'Formal verification engine failure',
          description: 'The verification engine failed to complete. '
              'No reliable verification results are available.',
          category: DiagnosticCategory.verification,
          severity: DiagnosticSeverity.critical,
          evidence: context.includeEvidence ? evidence : const [],
        ));

      case CounterexampleClassification.timeout:
        final evidence = <String>[
          'Verification timed out',
          '${stats.unknownPropertyCount} properties have unknown status',
        ];
        if (!coverage.isHealthy && context.includeEvidence) {
          evidence.add('Coverage risk: ${coverage.risk.name}');
        }
        issues.add(DiagnosticIssue(
          title:       'Verification timeout',
          description: 'Formal verification exceeded the time limit. '
              '${stats.unknownPropertyCount} properties remain unverified.',
          category: DiagnosticCategory.verification,
          severity: DiagnosticSeverity.high,
          evidence: context.includeEvidence ? evidence : const [],
        ));

      case CounterexampleClassification.assertionFailure:
        final evidence = <String>[
          '${stats.failedPropertyCount} properties failed with counterexample trace',
          'Counterexample trace depth: ${counterexample.trace.estimatedDepth}',
        ];
        if (!coverage.isHealthy && context.includeEvidence) {
          evidence.add(
            'Coverage risk: ${coverage.risk.name} — '
            'gaps may correlate with property failures',
          );
        }
        issues.add(DiagnosticIssue(
          title:       'Property assertion failure',
          description: '${stats.failedPropertyCount} '
              '${stats.failedPropertyCount == 1 ? "property" : "properties"} '
              'failed. Counterexample traces are available for analysis.',
          category: DiagnosticCategory.counterexample,
          severity: DiagnosticSeverity.high,
          evidence: context.includeEvidence ? evidence : const [],
        ));

      case CounterexampleClassification.assumptionViolation:
        issues.add(DiagnosticIssue(
          title:       'Assumption violation',
          description: 'The verification run was terminated by an assumption '
              'violation. Review input constraints.',
          category: DiagnosticCategory.verification,
          severity: DiagnosticSeverity.medium,
          evidence: context.includeEvidence
              ? [
                  'Assumption violation terminated the verification run',
                  'Classification: ${cls.name}',
                ]
              : const [],
        ));

      case CounterexampleClassification.unknown:
        if (stats.unknownPropertyCount > 0) {
          issues.add(DiagnosticIssue(
            title:       'Inconclusive verification results',
            description: '${stats.unknownPropertyCount} properties have unknown '
                'verification status.',
            category: DiagnosticCategory.counterexample,
            severity: DiagnosticSeverity.low,
            evidence: context.includeEvidence
                ? [
                    '${stats.unknownPropertyCount} properties inconclusive',
                    'Classification: unknown',
                  ]
                : const [],
          ));
        }
    }
  }

  static void _addCoverageIssue(
    List<DiagnosticIssue> issues,
    CoverageAssessment coverage,
    CounterexampleReport counterexample,
    VerificationPlan plan,
    DiagnosticContext context,
  ) {
    final risk = coverage.risk;
    if (risk == CoverageRisk.minimal) return;

    final pct = '${(coverage.statistics.overallCoverage * 100).toStringAsFixed(1)}%';

    final evidence = <String>[
      'Coverage risk: ${risk.name}',
      'Overall coverage: $pct',
    ];
    if (context.includeEvidence) {
      if (counterexample.hasFailures) {
        evidence.add(
          '${counterexample.statistics.failedPropertyCount} verification '
          'failures coincide with coverage gaps',
        );
      }
      if (plan.isNotEmpty) {
        evidence.add('${plan.length} properties in verification plan');
      }
    } else {
      evidence.clear();
    }

    final severity = switch (risk) {
      CoverageRisk.critical => DiagnosticSeverity.critical,
      CoverageRisk.high     => DiagnosticSeverity.high,
      CoverageRisk.moderate => DiagnosticSeverity.medium,
      CoverageRisk.low      => DiagnosticSeverity.low,
      CoverageRisk.minimal  => DiagnosticSeverity.informational,
    };

    final description = switch (risk) {
      CoverageRisk.critical =>
          'Coverage is critically insufficient at $pct. '
          'Verification results cannot be trusted.',
      CoverageRisk.high =>
          'Coverage is insufficient at $pct. '
          'Significant verification gaps exist.',
      CoverageRisk.moderate =>
          'Coverage is below acceptable levels at $pct. '
          'Some state space is unexplored.',
      CoverageRisk.low =>
          'Coverage is slightly below target at $pct.',
      CoverageRisk.minimal => '',
    };

    issues.add(DiagnosticIssue(
      title:       'Coverage ${risk.name}',
      description: description,
      category:    DiagnosticCategory.coverage,
      severity:    severity,
      evidence:    evidence,
    ));
  }

  static void _addPlanningIssue(
    List<DiagnosticIssue> issues,
    VerificationPlan plan,
    VerificationExplanationSet explanations,
    CoverageAssessment coverage,
    DiagnosticContext context,
  ) {
    if (plan.isEmpty && explanations.isNotEmpty) {
      final evidence = <String>[
        'Verification plan is empty',
        '${explanations.length} property explanations available but not scheduled',
      ];
      if (context.includeEvidence && !coverage.isHealthy) {
        evidence.add(
          'Coverage risk is ${coverage.risk.name} — '
          'planning would help improve coverage',
        );
      }
      issues.add(DiagnosticIssue(
        title:       'Empty verification plan',
        description: 'No verification jobs are planned despite '
            '${explanations.length} available properties.',
        category: DiagnosticCategory.planning,
        severity: DiagnosticSeverity.medium,
        evidence: context.includeEvidence ? evidence : const [],
      ));
    } else if (plan.isNotEmpty &&
        plan.jobs.every((j) => j.strategy == VerificationStrategy.induction)) {
      issues.add(DiagnosticIssue(
        title:       'All properties use induction strategy',
        description: 'All ${plan.length} jobs use induction. '
            'Consider mixing strategies for efficiency.',
        category: DiagnosticCategory.planning,
        severity: DiagnosticSeverity.low,
        evidence: context.includeEvidence
            ? [
                'All ${plan.length} jobs use induction strategy',
                'Induction has 4× the cost of cover verification',
              ]
            : const [],
      ));
    }
  }

  static void _addPropertyQualityIssue(
    List<DiagnosticIssue> issues,
    VerificationExplanationSet explanations,
    CoverageAssessment coverage,
    DiagnosticContext context,
  ) {
    // Empty explanations are a valid healthy state — no plan, no properties.
    if (explanations.isEmpty) return;

    double total = 0;
    for (final e in explanations.explanations) {
      total += e.trace.confidence;
    }
    final avg = total / explanations.length;

    if (avg < 0.3) {
      final evidence = <String>[
        'Average property confidence: ${avg.toStringAsFixed(2)}',
        '${explanations.length} properties with critically low confidence',
      ];
      if (context.includeEvidence && !coverage.isHealthy) {
        evidence.add(
          'Coverage risk ${coverage.risk.name} indicates weak verification setup',
        );
      }
      issues.add(DiagnosticIssue(
        title:       'Low property confidence',
        description: 'Average property confidence is critically low '
            '(${avg.toStringAsFixed(2)}). Property specifications may be too weak.',
        category: DiagnosticCategory.property,
        severity: DiagnosticSeverity.medium,
        evidence: context.includeEvidence ? evidence : const [],
      ));
    } else if (avg < 0.5) {
      issues.add(DiagnosticIssue(
        title:       'Borderline property confidence',
        description: 'Average property confidence is below threshold '
            '(${avg.toStringAsFixed(2)}).',
        category: DiagnosticCategory.property,
        severity: DiagnosticSeverity.low,
        evidence: context.includeEvidence
            ? ['Average confidence: ${avg.toStringAsFixed(2)}']
            : const [],
      ));
    }
  }

  // ── Severity aggregation ──────────────────────────────────────────────────

  static DiagnosticSeverity _aggregateSeverity(List<DiagnosticIssue> issues) {
    if (issues.isEmpty) return DiagnosticSeverity.informational;
    var max = DiagnosticSeverity.informational;
    for (final issue in issues) {
      if (issue.severity.index > max.index) max = issue.severity;
    }
    return max;
  }

  // ── Confidence ────────────────────────────────────────────────────────────

  static DiagnosticConfidence _computeConfidence(
    CoverageAssessment coverage,
    CounterexampleReport counterexample,
    DiagnosticSeverity overallSeverity,
  ) {
    // Engine failure → veryLow: cannot trust any result.
    if (counterexample.classification == CounterexampleClassification.engineFailure) {
      return DiagnosticConfidence.veryLow;
    }

    // High coverage + no failures + no significant issues → veryHigh.
    if (coverage.isHealthy &&
        !counterexample.hasFailures &&
        overallSeverity.index <= DiagnosticSeverity.low.index) {
      return DiagnosticConfidence.veryHigh;
    }

    // Coverage issues only (no counterexample failures) → high.
    if (!counterexample.hasFailures && !coverage.isHealthy) {
      return DiagnosticConfidence.high;
    }

    // Counterexample failures + coverage issues → low (worst combination).
    if (counterexample.hasFailures && !coverage.isHealthy) {
      return DiagnosticConfidence.low;
    }

    // Counterexample failures with healthy coverage → medium.
    return DiagnosticConfidence.medium;
  }

  // ── Summary ───────────────────────────────────────────────────────────────

  static DiagnosticSummary _buildSummary(
    List<DiagnosticIssue> issues,
    DiagnosticSeverity overallSeverity,
  ) {
    final overview = switch (overallSeverity) {
      DiagnosticSeverity.critical      => 'Critical verification failures detected.',
      DiagnosticSeverity.high          => 'Significant verification issues require attention.',
      DiagnosticSeverity.medium        => 'Verification has quality issues.',
      DiagnosticSeverity.low           => 'Minor verification concerns detected.',
      DiagnosticSeverity.informational => 'Verification health is good.',
    };

    final primaryIssue = issues.isEmpty ? 'None' : issues.first.title;

    // Dominant category: most frequent; alphabetical tie-break by category name.
    String dominantCategory = 'none';
    if (issues.isNotEmpty) {
      final counts = <DiagnosticCategory, int>{};
      for (final i in issues) {
        counts[i.category] = (counts[i.category] ?? 0) + 1;
      }
      final sorted = counts.entries.toList()
        ..sort((a, b) {
          final cmp = b.value.compareTo(a.value);
          return cmp != 0 ? cmp : a.key.name.compareTo(b.key.name);
        });
      dominantCategory = sorted.first.key.name;
    }

    final verificationHealth = switch (overallSeverity) {
      DiagnosticSeverity.critical      => 'failing',
      DiagnosticSeverity.high          => 'degraded',
      DiagnosticSeverity.medium        => 'reduced',
      DiagnosticSeverity.low           => 'acceptable',
      DiagnosticSeverity.informational => 'healthy',
    };

    return DiagnosticSummary(
      overview:           overview,
      primaryIssue:       primaryIssue,
      dominantCategory:   dominantCategory,
      verificationHealth: verificationHealth,
    );
  }
}
