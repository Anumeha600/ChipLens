import '../semantic/semantic_evidence_set.dart';
import '../synthesizer/candidate_property.dart';
import '../synthesizer/candidate_property_set.dart';
import 'ranked_candidate_property_set.dart';
import 'ranking_explanation.dart';
import 'ranking_policy.dart';
import 'ranking_result.dart';
import 'ranking_score.dart';
import 'scoring/evidence_score.dart';
import 'scoring/metadata_score.dart';
import 'scoring/property_type_score.dart';

// ─── RankingEngine ────────────────────────────────────────────────────────────

/// Deterministic ranking engine for [CandidatePropertySet].
///
/// Uses [RankingPolicy] weights and three scoring strategies to produce a
/// [RankedCandidatePropertySet] sorted descending by score.
///
/// Invariants:
/// - No random numbers, timestamps, hash ordering, or AI.
/// - No external services or I/O.
/// - No Flutter / UI imports.
/// - Tie-breaking is alphabetical by [CandidateProperty.id] (ascending).
/// - [CandidateProperty] objects are never modified.
abstract class RankingEngine {
  RankingEngine._();

  static const _evidenceScorer = EvidenceScore();
  static const _typeScorer     = PropertyTypeScore();
  static const _metadataScorer = MetadataScore();

  /// Ranks all properties in [properties] using [evidence] to resolve
  /// [CandidateProperty.evidenceIds].
  ///
  /// Returns a [RankedCandidatePropertySet] sorted descending by score.
  /// Rank 1 is the highest-priority property.
  static RankedCandidatePropertySet rank(
    CandidatePropertySet properties,
    SemanticEvidenceSet evidence,
  ) {
    final scored =
        <(CandidateProperty, RankingScore, RankingExplanation)>[];

    for (final prop in properties.items) {
      final evResult     = _evidenceScorer.compute(prop.evidenceIds, evidence);
      final typeResult   = _typeScorer.compute(prop.propertyType);
      final metaResult   = _metadataScorer.compute(prop.metadata);
      final countResult  = _evidenceCountScore(prop.evidenceIds.length);
      final domainResult = _domainBonusScore(prop.evidenceIds, evidence);

      final wEvidence = evResult.score     * RankingPolicy.weightEvidence;
      final wType     = typeResult.score   * RankingPolicy.weightPropertyType;
      final wMeta     = metaResult.score   * RankingPolicy.weightMetadata;
      final wCount    = countResult.score  * RankingPolicy.weightEvidenceCount;
      final wDomain   = domainResult.score * RankingPolicy.weightDomainBonus;

      final total =
          (wEvidence + wType + wMeta + wCount + wDomain).clamp(0.0, 1.0);

      final contributions = List<RankingContribution>.unmodifiable([
        RankingContribution(label: 'Evidence confidence', value: wEvidence),
        RankingContribution(label: 'Property type',       value: wType),
        RankingContribution(label: 'Metadata richness',   value: wMeta),
        RankingContribution(label: 'Evidence count',      value: wCount),
        RankingContribution(label: 'Domain bonus',        value: wDomain),
      ]);

      final explanationText = contributions
          .map((c) => '${c.label}: +${c.value.toStringAsFixed(4)}')
          .join('; ');

      final reasons = <String>[];
      if (evResult.score     >= 0.85) {
        reasons.add('High-confidence evidence: ${evResult.explanation}');
      }
      if (typeResult.score   >= 0.80) {
        reasons.add('High-priority type: ${typeResult.explanation}');
      }
      if (metaResult.score   >= 0.70) {
        reasons.add('Rich metadata: ${metaResult.explanation}');
      }
      if (domainResult.score >= 0.80) {
        reasons.add('Domain bonus: ${domainResult.explanation}');
      }
      if (reasons.isEmpty) reasons.add(evResult.explanation);

      final rankingScore = RankingScore(
        value:         total,
        contributions: contributions,
        explanation:   explanationText,
      );
      final rankingExplanation = RankingExplanation(
        score:   total,
        reasons: List.unmodifiable(reasons),
      );

      scored.add((prop, rankingScore, rankingExplanation));
    }

    // Stable descending sort; tie-break alphabetically by id (deterministic).
    scored.sort((a, b) {
      final cmp = b.$2.value.compareTo(a.$2.value);
      return cmp != 0 ? cmp : a.$1.id.compareTo(b.$1.id);
    });

    final results = [
      for (var i = 0; i < scored.length; i++)
        RankingResult(
          property:    scored[i].$1,
          score:       scored[i].$2,
          rank:        i + 1,
          explanation: scored[i].$3,
        ),
    ];

    return RankedCandidatePropertySet(results);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static ({double score, String explanation}) _evidenceCountScore(int count) {
    if (count == 0) {
      return (score: 0.0, explanation: 'No supporting evidence');
    }
    final score =
        (count / RankingPolicy.evidenceCountSaturation).clamp(0.0, 1.0);
    final itemWord = count == 1 ? 'item' : 'items';
    return (
      score: score,
      explanation: '$count supporting evidence $itemWord',
    );
  }

  static ({double score, String explanation}) _domainBonusScore(
    List<String> evidenceIds,
    SemanticEvidenceSet evidence,
  ) {
    if (evidenceIds.isEmpty) {
      return (score: 0.0, explanation: 'No evidence ids for domain bonus');
    }

    double maxBonus     = 0.0;
    String bestCategory = '';

    for (final id in evidenceIds) {
      for (final e in evidence.items) {
        if (e.id == id) {
          final bonus =
              RankingPolicy.domainCategoryBonus[e.category.name] ?? 0.0;
          if (bonus > maxBonus) {
            maxBonus     = bonus;
            bestCategory = e.category.name;
          }
          break;
        }
      }
    }

    if (bestCategory.isEmpty) {
      return (
        score: 0.0,
        explanation: 'No matching evidence found for domain bonus',
      );
    }
    return (
      score: maxBonus,
      explanation:
          'Domain: $bestCategory (bonus: ${maxBonus.toStringAsFixed(2)})',
    );
  }
}
