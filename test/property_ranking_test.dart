import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/property_inference/ranking/ranking.dart';
import 'package:chiplens_lite/backend/property_inference/semantic/semantic.dart';
import 'package:chiplens_lite/backend/property_inference/synthesizer/synthesizer.dart';

// ─── Shared fixtures ──────────────────────────────────────────────────────────

SemanticEvidence _fsmEvidence({
  String id = 'fsm.state',
  double confidence = 0.95,
}) =>
    SemanticEvidence(
      id: id,
      category: SemanticCategory.fsm,
      confidence: confidence,
      description: 'FSM state register',
      metadata: const {'stateRegister': 'state', 'stateCount': 3},
    );

SemanticEvidence _resetEvidence({
  String id = 'reset.rst_n',
  double confidence = 0.90,
}) =>
    SemanticEvidence(
      id: id,
      category: SemanticCategory.reset,
      confidence: confidence,
      description: 'Active-low async reset',
      metadata: const {'isActiveLow': true},
    );

SemanticEvidence _counterEvidence({
  String id = 'counter.cnt',
  double confidence = 0.85,
}) =>
    SemanticEvidence(
      id: id,
      category: SemanticCategory.counter,
      confidence: confidence,
      description: '8-bit up counter',
      metadata: const {'name': 'cnt', 'width': 8, 'isIncrement': true},
    );

CandidateProperty _safetyProp({
  String id = 'synth.fsm.state.legal_state',
  List<String> evidenceIds = const ['fsm.state'],
  Map<String, dynamic> metadata = const {'stateCount': 3},
}) =>
    CandidateProperty(
      id: id,
      title: 'Legal state invariant',
      description: 'state must be a legal FSM state.',
      propertyType: CandidatePropertyType.safetyInvariant,
      evidenceIds: evidenceIds,
      rationale: 'FSM must stay in a legal state.',
      metadata: metadata,
    );

CandidateProperty _livenessProp({
  String id = 'synth.reset.rst_n.releases',
  List<String> evidenceIds = const ['reset.rst_n'],
  Map<String, dynamic> metadata = const {},
}) =>
    CandidateProperty(
      id: id,
      title: 'Reset eventually releases',
      description: 'rst_n must eventually deassert.',
      propertyType: CandidatePropertyType.livenessCondition,
      evidenceIds: evidenceIds,
      rationale: 'Reset never releasing leaves design in reset state forever.',
      metadata: metadata,
    );

CandidateProperty _boundednessProp({
  String id = 'synth.counter.cnt.bounds',
  List<String> evidenceIds = const ['counter.cnt'],
  Map<String, dynamic> metadata = const {'width': 8},
}) =>
    CandidateProperty(
      id: id,
      title: 'Counter within bounds',
      description: 'cnt must stay within [0, 255].',
      propertyType: CandidatePropertyType.boundedness,
      evidenceIds: evidenceIds,
      rationale: 'Overflow is either intentional or a bug.',
      metadata: metadata,
    );

CandidateProperty _assumptionProp({
  String id = 'synth.reset.rst_n.polarity',
  List<String> evidenceIds = const ['reset.rst_n'],
}) =>
    CandidateProperty(
      id: id,
      title: 'Reset polarity assumption',
      description: 'rst_n is active-low.',
      propertyType: CandidatePropertyType.assumption,
      evidenceIds: evidenceIds,
      rationale: 'Formal tool must drive reset with correct polarity.',
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // 1. RankingContribution
  // ══════════════════════════════════════════════════════════════════════════
  group('RankingContribution', () {
    test('stores label and value', () {
      const c = RankingContribution(label: 'Evidence confidence', value: 0.38);
      expect(c.label, 'Evidence confidence');
      expect(c.value, 0.38);
    });

    test('equality holds when label and value match', () {
      const a = RankingContribution(label: 'X', value: 0.1);
      const b = RankingContribution(label: 'X', value: 0.1);
      expect(a, b);
    });

    test('inequality when label differs', () {
      const a = RankingContribution(label: 'A', value: 0.1);
      const b = RankingContribution(label: 'B', value: 0.1);
      expect(a, isNot(b));
    });

    test('inequality when value differs', () {
      const a = RankingContribution(label: 'X', value: 0.1);
      const b = RankingContribution(label: 'X', value: 0.2);
      expect(a, isNot(b));
    });

    test('toString includes label and formatted value', () {
      const c = RankingContribution(label: 'Domain bonus', value: 0.1);
      expect(c.toString(), contains('Domain bonus'));
      expect(c.toString(), contains('0.1000'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. RankingScore
  // ══════════════════════════════════════════════════════════════════════════
  group('RankingScore', () {
    test('stores value, contributions, and explanation', () {
      const s = RankingScore(
        value: 0.85,
        contributions: [],
        explanation: 'test',
      );
      expect(s.value, 0.85);
      expect(s.explanation, 'test');
    });

    test('equality by value within epsilon', () {
      const a = RankingScore(value: 0.85, contributions: [], explanation: '');
      const b = RankingScore(value: 0.85, contributions: [], explanation: 'x');
      expect(a, b);
    });

    test('inequality when values differ beyond epsilon', () {
      const a = RankingScore(value: 0.85, contributions: [], explanation: '');
      const b = RankingScore(value: 0.86, contributions: [], explanation: '');
      expect(a, isNot(b));
    });

    test('epsilon tolerance — values within 1e-9 are equal', () {
      const a = RankingScore(value: 0.85,         contributions: [], explanation: '');
      const b = RankingScore(value: 0.850000000001, contributions: [], explanation: '');
      expect(a, b);
    });

    test('toString includes formatted score', () {
      const s = RankingScore(value: 0.9321, contributions: [], explanation: '');
      expect(s.toString(), contains('0.9321'));
    });

    test('contributions list is accessible', () {
      const c = RankingContribution(label: 'Evidence confidence', value: 0.38);
      final s = RankingScore(value: 0.9, contributions: [c], explanation: '');
      expect(s.contributions, hasLength(1));
      expect(s.contributions.first.label, 'Evidence confidence');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. RankingExplanation
  // ══════════════════════════════════════════════════════════════════════════
  group('RankingExplanation', () {
    test('stores score and reasons', () {
      const e = RankingExplanation(score: 0.93, reasons: ['High confidence FSM']);
      expect(e.score, 0.93);
      expect(e.reasons, hasLength(1));
    });

    test('formatted includes score header', () {
      const e = RankingExplanation(score: 0.9300, reasons: ['Reason A']);
      expect(e.formatted, startsWith('Score: 0.9300'));
    });

    test('formatted includes all reasons', () {
      const e = RankingExplanation(
        score: 0.80,
        reasons: ['Reason A', 'Reason B'],
      );
      expect(e.formatted, contains('Reason A'));
      expect(e.formatted, contains('Reason B'));
    });

    test('formatted includes Reasons section header', () {
      const e = RankingExplanation(score: 0.5, reasons: ['X']);
      expect(e.formatted, contains('Reasons:'));
    });

    test('empty reasons list produces valid formatted output', () {
      const e = RankingExplanation(score: 0.5, reasons: []);
      expect(e.formatted, startsWith('Score: 0.5000'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. RankingResult
  // ══════════════════════════════════════════════════════════════════════════
  group('RankingResult', () {
    test('stores all four fields', () {
      final prop = _safetyProp();
      const score = RankingScore(value: 0.82, contributions: [], explanation: '');
      const expl  = RankingExplanation(score: 0.82, reasons: []);
      final result = RankingResult(
        property: prop, score: score, rank: 1, explanation: expl,
      );
      expect(result.property.id, prop.id);
      expect(result.score.value, 0.82);
      expect(result.rank, 1);
    });

    test('rank is the value supplied at construction', () {
      final r = RankingResult(
        property: _safetyProp(),
        score: const RankingScore(value: 0.5, contributions: [], explanation: ''),
        rank: 7,
        explanation: const RankingExplanation(score: 0.5, reasons: []),
      );
      expect(r.rank, 7);
    });

    test('toString includes rank, score, and id', () {
      final r = RankingResult(
        property: _safetyProp(),
        score: const RankingScore(value: 0.82, contributions: [], explanation: ''),
        rank: 1,
        explanation: const RankingExplanation(score: 0.82, reasons: []),
      );
      expect(r.toString(), contains('rank=1'));
      expect(r.toString(), contains('synth.fsm.state.legal_state'));
    });

    test('does not modify the original CandidateProperty', () {
      final prop = _safetyProp();
      final r = RankingResult(
        property: prop,
        score: const RankingScore(value: 0.5, contributions: [], explanation: ''),
        rank: 1,
        explanation: const RankingExplanation(score: 0.5, reasons: []),
      );
      expect(r.property, same(prop));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5. RankingPolicy constants
  // ══════════════════════════════════════════════════════════════════════════
  group('RankingPolicy', () {
    test('five component weights sum to 1.0', () {
      final total = RankingPolicy.weightEvidence +
          RankingPolicy.weightPropertyType +
          RankingPolicy.weightMetadata +
          RankingPolicy.weightEvidenceCount +
          RankingPolicy.weightDomainBonus;
      expect(total, closeTo(1.0, 1e-9));
    });

    test('evidence weight is 0.40', () =>
        expect(RankingPolicy.weightEvidence, 0.40));

    test('property type weight is 0.25', () =>
        expect(RankingPolicy.weightPropertyType, 0.25));

    test('metadata weight is 0.15', () =>
        expect(RankingPolicy.weightMetadata, 0.15));

    test('evidence count saturation is 3', () =>
        expect(RankingPolicy.evidenceCountSaturation, 3));

    test('domainCategoryBonus contains fsm and reset as highest values', () {
      expect(RankingPolicy.domainCategoryBonus['fsm'],   1.0);
      expect(RankingPolicy.domainCategoryBonus['reset'], 1.0);
      expect(RankingPolicy.domainCategoryBonus['custom'], lessThan(1.0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6. EvidenceScore
  // ══════════════════════════════════════════════════════════════════════════
  group('EvidenceScore', () {
    const scorer = EvidenceScore();

    test('empty evidenceIds returns score 0.0', () {
      final r = scorer.compute([], SemanticEvidenceSet());
      expect(r.score, 0.0);
    });

    test('empty evidenceIds explanation mentions no ids', () {
      final r = scorer.compute([], SemanticEvidenceSet());
      expect(r.explanation, isNotEmpty);
    });

    test('unresolved ids return score 0.0', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final r = scorer.compute(['nonexistent.id'], evidence);
      expect(r.score, 0.0);
    });

    test('single resolved evidence returns its confidence', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence(confidence: 0.95)]);
      final r = scorer.compute(['fsm.state'], evidence);
      expect(r.score, closeTo(0.95, 1e-9));
    });

    test('two evidence items return average confidence', () {
      final e1 = _fsmEvidence(id: 'e1', confidence: 0.80);
      final e2 = _resetEvidence(id: 'e2', confidence: 0.60);
      final evidence = SemanticEvidenceSet([e1, e2]);
      final r = scorer.compute(['e1', 'e2'], evidence);
      expect(r.score, closeTo(0.70, 1e-9));
    });

    test('partially resolved ids use only resolved items for average', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence(confidence: 0.80)]);
      final r = scorer.compute(['fsm.state', 'missing.id'], evidence);
      expect(r.score, closeTo(0.80, 1e-9));
    });

    test('high-confidence evidence explanation mentions confidence', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence(confidence: 0.95)]);
      final r = scorer.compute(['fsm.state'], evidence);
      expect(r.explanation, contains('0.95'));
    });

    test('multiple evidence explanation mentions count', () {
      final e1 = _fsmEvidence(id: 'e1', confidence: 0.9);
      final e2 = _resetEvidence(id: 'e2', confidence: 0.8);
      final evidence = SemanticEvidenceSet([e1, e2]);
      final r = scorer.compute(['e1', 'e2'], evidence);
      expect(r.explanation, contains('2'));
    });

    test('score is capped at 1.0', () {
      final e = SemanticEvidence(
        id: 'clk.main',
        category: SemanticCategory.clock,
        confidence: 1.0,
        description: 'Primary clock',
      );
      final evidence = SemanticEvidenceSet([e]);
      final r = scorer.compute(['clk.main'], evidence);
      expect(r.score, closeTo(1.0, 1e-9));
    });

    test('score is non-negative', () {
      final e = SemanticEvidence(
        id: 'reg.x',
        category: SemanticCategory.register,
        confidence: 0.0,
        description: 'Unknown register',
      );
      final evidence = SemanticEvidenceSet([e]);
      final r = scorer.compute(['reg.x'], evidence);
      expect(r.score, greaterThanOrEqualTo(0.0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7. PropertyTypeScore
  // ══════════════════════════════════════════════════════════════════════════
  group('PropertyTypeScore', () {
    const scorer = PropertyTypeScore();

    test('safetyInvariant returns 1.0', () {
      expect(
          scorer.compute(CandidatePropertyType.safetyInvariant).score, 1.0);
    });

    test('livenessCondition returns 0.9', () {
      expect(
          scorer.compute(CandidatePropertyType.livenessCondition).score, 0.9);
    });

    test('boundedness returns 0.8', () {
      expect(scorer.compute(CandidatePropertyType.boundedness).score, 0.8);
    });

    test('reachability returns 0.7', () {
      expect(scorer.compute(CandidatePropertyType.reachability).score, 0.7);
    });

    test('stability returns 0.6', () {
      expect(scorer.compute(CandidatePropertyType.stability).score, 0.6);
    });

    test('assumption returns 0.5', () {
      expect(scorer.compute(CandidatePropertyType.assumption).score, 0.5);
    });

    test('custom returns 0.3', () {
      expect(scorer.compute(CandidatePropertyType.custom).score, 0.3);
    });

    test('safetyInvariant outranks assumption', () {
      final safety     = scorer.compute(CandidatePropertyType.safetyInvariant).score;
      final assumption = scorer.compute(CandidatePropertyType.assumption).score;
      expect(safety, greaterThan(assumption));
    });

    test('explanation contains type name', () {
      final r = scorer.compute(CandidatePropertyType.safetyInvariant);
      expect(r.explanation, contains('safetyInvariant'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 8. MetadataScore
  // ══════════════════════════════════════════════════════════════════════════
  group('MetadataScore', () {
    const scorer = MetadataScore();

    test('empty map returns 0.0', () {
      expect(scorer.compute({}).score, 0.0);
    });

    test('1 key returns 0.4', () {
      expect(scorer.compute({'width': 8}).score, closeTo(0.40, 1e-9));
    });

    test('2 keys returns 0.7', () {
      expect(scorer.compute({'width': 8, 'type': 'counter'}).score,
          closeTo(0.70, 1e-9));
    });

    test('3 keys returns 1.0', () {
      expect(scorer.compute({'a': 1, 'b': 2, 'c': 3}).score,
          closeTo(1.0, 1e-9));
    });

    test('4 keys still returns 1.0 (saturated)', () {
      expect(scorer.compute({'a': 1, 'b': 2, 'c': 3, 'd': 4}).score,
          closeTo(1.0, 1e-9));
    });

    test('empty map explanation mentions no context', () {
      expect(scorer.compute({}).explanation, contains('No metadata'));
    });

    test('1 key explanation uses singular form', () {
      final r = scorer.compute({'k': 1});
      expect(r.explanation, contains('1 metadata field'));
    });

    test('3 keys explanation uses plural form', () {
      final r = scorer.compute({'a': 1, 'b': 2, 'c': 3});
      expect(r.explanation, contains('fields'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 9. RankedCandidatePropertySet
  // ══════════════════════════════════════════════════════════════════════════
  group('RankedCandidatePropertySet', () {
    RankingResult makeResult(String id, double score, {int rank = 1}) {
      final prop = CandidateProperty(
        id: id,
        title: id,
        description: id,
        propertyType: CandidatePropertyType.safetyInvariant,
        rationale: 'Test',
      );
      final s = RankingScore(
        value: score,
        contributions: const [],
        explanation: '',
      );
      return RankingResult(
        property: prop,
        score: s,
        rank: rank,
        explanation: const RankingExplanation(score: 0.5, reasons: []),
      );
    }

    test('empty set has length 0', () {
      expect(RankedCandidatePropertySet().length, 0);
    });

    test('isEmpty is true for empty set', () {
      expect(RankedCandidatePropertySet().isEmpty, isTrue);
    });

    test('isNotEmpty is true for non-empty set', () {
      final s = RankedCandidatePropertySet([makeResult('a', 0.5)]);
      expect(s.isNotEmpty, isTrue);
    });

    test('top(1) returns first result only', () {
      final s = RankedCandidatePropertySet([
        makeResult('a', 0.9, rank: 1),
        makeResult('b', 0.7, rank: 2),
      ]);
      expect(s.top(1).length, 1);
      expect(s.top(1).results.first.property.id, 'a');
    });

    test('top(n) larger than length returns all results', () {
      final s = RankedCandidatePropertySet([makeResult('a', 0.5)]);
      expect(s.top(99).length, 1);
    });

    test('filter keeps matching results', () {
      final s = RankedCandidatePropertySet([
        makeResult('a', 0.9),
        makeResult('b', 0.5),
      ]);
      final filtered = s.filter((r) => r.score.value > 0.7);
      expect(filtered.length, 1);
      expect(filtered.results.first.property.id, 'a');
    });

    test('filter returns empty set when nothing matches', () {
      final s = RankedCandidatePropertySet([makeResult('a', 0.5)]);
      expect(s.filter((r) => r.score.value > 0.9).isEmpty, isTrue);
    });

    test('averageScore returns 0.0 for empty set', () {
      expect(RankedCandidatePropertySet().averageScore(), 0.0);
    });

    test('averageScore is correct for multiple results', () {
      final s = RankedCandidatePropertySet([
        makeResult('a', 0.9),
        makeResult('b', 0.7),
        makeResult('c', 0.5),
      ]);
      expect(s.averageScore(), closeTo(0.7, 1e-9));
    });

    test('highestScore returns null for empty set', () {
      expect(RankedCandidatePropertySet().highestScore(), isNull);
    });

    test('lowestScore returns null for empty set', () {
      expect(RankedCandidatePropertySet().lowestScore(), isNull);
    });

    test('highestScore and lowestScore span the range', () {
      final s = RankedCandidatePropertySet([
        makeResult('a', 0.9),
        makeResult('b', 0.5),
        makeResult('c', 0.3),
      ]);
      expect(s.highestScore()!, closeTo(0.9, 1e-9));
      expect(s.lowestScore()!,  closeTo(0.3, 1e-9));
    });

    test('merge re-ranks combined results descending', () {
      final setA = RankedCandidatePropertySet([makeResult('a', 0.6, rank: 1)]);
      final setB = RankedCandidatePropertySet([makeResult('b', 0.9, rank: 1)]);
      final merged = setA.merge(setB);
      expect(merged.results[0].property.id, 'b');
      expect(merged.results[1].property.id, 'a');
      expect(merged.results[0].rank, 1);
      expect(merged.results[1].rank, 2);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 10. RankingEngine — basic
  // ══════════════════════════════════════════════════════════════════════════
  group('RankingEngine basic', () {
    test('empty CandidatePropertySet returns empty ranked set', () {
      final ranked = RankingEngine.rank(
          CandidatePropertySet(), SemanticEvidenceSet());
      expect(ranked.isEmpty, isTrue);
    });

    test('single property produces single result', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final props    = CandidatePropertySet([_safetyProp()]);
      final ranked   = RankingEngine.rank(props, evidence);
      expect(ranked.length, 1);
    });

    test('single result has rank 1', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final props    = CandidatePropertySet([_safetyProp()]);
      final ranked   = RankingEngine.rank(props, evidence);
      expect(ranked.results.first.rank, 1);
    });

    test('multiple properties produce results in count matching input', () {
      final evidence = SemanticEvidenceSet([
        _fsmEvidence(), _resetEvidence(), _counterEvidence(),
      ]);
      final props = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final ranked = RankingEngine.rank(props, evidence);
      expect(ranked.length, 3);
    });

    test('rank numbers are 1-based and consecutive', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final props = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final ranked = RankingEngine.rank(props, evidence);
      final ranks  = ranked.results.map((r) => r.rank).toList();
      expect(ranks, [1, 2, 3]);
    });

    test('all scores are non-negative', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final props = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final ranked = RankingEngine.rank(props, evidence);
      for (final r in ranked.results) {
        expect(r.score.value, greaterThanOrEqualTo(0.0));
      }
    });

    test('all scores are at most 1.0', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final props = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final ranked = RankingEngine.rank(props, evidence);
      for (final r in ranked.results) {
        expect(r.score.value, lessThanOrEqualTo(1.0));
      }
    });

    test('results are ordered descending by score', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final props = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final ranked = RankingEngine.rank(props, evidence);
      final scores = ranked.results.map((r) => r.score.value).toList();
      for (var i = 0; i < scores.length - 1; i++) {
        expect(scores[i], greaterThanOrEqualTo(scores[i + 1]));
      }
    });

    test('original CandidateProperty is unchanged', () {
      final prop = _safetyProp();
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final ranked = RankingEngine.rank(CandidatePropertySet([prop]), evidence);
      expect(ranked.results.first.property, same(prop));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 11. Score accuracy
  // ══════════════════════════════════════════════════════════════════════════
  group('Score accuracy', () {
    test('safetyInvariant scores higher than assumption with same evidence', () {
      final evidence = SemanticEvidenceSet([_resetEvidence()]);
      final props = CandidatePropertySet([
        _livenessProp(id: 'liveness'),
        _assumptionProp(id: 'assumption'),
      ]);
      final ranked = RankingEngine.rank(props, evidence);
      final livenessScore   = ranked.results.firstWhere((r) => r.property.id == 'liveness').score.value;
      final assumptionScore = ranked.results.firstWhere((r) => r.property.id == 'assumption').score.value;
      expect(livenessScore, greaterThan(assumptionScore));
    });

    test('property with linked evidence scores higher than one with no evidence', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final withEvidence = _safetyProp(id: 'with_evidence',
          evidenceIds: ['fsm.state']);
      final noEvidence = _safetyProp(id: 'no_evidence',
          evidenceIds: []);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([withEvidence, noEvidence]), evidence);
      final scoreWith = ranked.results
          .firstWhere((r) => r.property.id == 'with_evidence').score.value;
      final scoreNo = ranked.results
          .firstWhere((r) => r.property.id == 'no_evidence').score.value;
      expect(scoreWith, greaterThan(scoreNo));
    });

    test('metadata richness contributes positively to score', () {
      final evidence = SemanticEvidenceSet([_resetEvidence()]);
      final richMeta = CandidateProperty(
        id: 'rich',
        title: 'Rich',
        description: 'R',
        propertyType: CandidatePropertyType.assumption,
        evidenceIds: const ['reset.rst_n'],
        rationale: 'R',
        metadata: const {'k1': 1, 'k2': 2, 'k3': 3},
      );
      final emptyMeta = CandidateProperty(
        id: 'empty',
        title: 'Empty',
        description: 'E',
        propertyType: CandidatePropertyType.assumption,
        evidenceIds: const ['reset.rst_n'],
        rationale: 'E',
      );
      final ranked = RankingEngine.rank(
          CandidatePropertySet([richMeta, emptyMeta]), evidence);
      final richScore  = ranked.results.firstWhere((r) => r.property.id == 'rich').score.value;
      final emptyScore = ranked.results.firstWhere((r) => r.property.id == 'empty').score.value;
      expect(richScore, greaterThan(emptyScore));
    });

    test('evidence count of 3 saturates count component', () {
      final e1 = _fsmEvidence(id: 'e1');
      final e2 = _resetEvidence(id: 'e2');
      final e3 = _counterEvidence(id: 'e3');
      final evidence = SemanticEvidenceSet([e1, e2, e3]);
      final threeEvidence = CandidateProperty(
        id: 'three',
        title: 'T',
        description: 'T',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['e1', 'e2', 'e3'],
        rationale: 'T',
      );
      final ranked = RankingEngine.rank(
          CandidatePropertySet([threeEvidence]), evidence);
      // Count contribution should be 1.0 * 0.10 = 0.10 (saturated)
      final countContrib = ranked.results.first.score.contributions
          .firstWhere((c) => c.label == 'Evidence count');
      expect(countContrib.value, closeTo(0.10, 1e-9));
    });

    test('FSM evidence provides maximum domain bonus', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([_safetyProp()]), evidence);
      final domainContrib = ranked.results.first.score.contributions
          .firstWhere((c) => c.label == 'Domain bonus');
      // FSM domain bonus = 1.0 * weightDomainBonus (0.10)
      expect(domainContrib.value, closeTo(0.10, 1e-9));
    });

    test('contributions sum equals reported score', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([_safetyProp()]), evidence);
      final result = ranked.results.first;
      final contribSum = result.score.contributions
          .map((c) => c.value)
          .reduce((a, b) => a + b);
      expect(contribSum, closeTo(result.score.value, 1e-9));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 12. Determinism
  // ══════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    test('same input produces same scores on repeated calls', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final props = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final r1 = RankingEngine.rank(props, evidence);
      final r2 = RankingEngine.rank(props, evidence);
      for (var i = 0; i < r1.results.length; i++) {
        expect(r1.results[i].score.value,
            closeTo(r2.results[i].score.value, 1e-12));
      }
    });

    test('same input produces same ordering on repeated calls', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final props = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final r1 = RankingEngine.rank(props, evidence);
      final r2 = RankingEngine.rank(props, evidence);
      final ids1 = r1.results.map((r) => r.property.id).toList();
      final ids2 = r2.results.map((r) => r.property.id).toList();
      expect(ids1, ids2);
    });

    test('reordering input properties does not change output scores', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final propsABC = CandidatePropertySet(
          [_safetyProp(), _livenessProp(), _boundednessProp()]);
      final propsCBA = CandidatePropertySet(
          [_boundednessProp(), _livenessProp(), _safetyProp()]);
      final r1 = RankingEngine.rank(propsABC, evidence);
      final r2 = RankingEngine.rank(propsCBA, evidence);
      final ids1 = r1.results.map((r) => r.property.id).toSet();
      final ids2 = r2.results.map((r) => r.property.id).toSet();
      expect(ids1, ids2);
    });

    test('no timestamps or random values in score', () {
      // Running at different times should not affect scoring.
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final props    = CandidatePropertySet([_safetyProp()]);
      final score1 = RankingEngine.rank(props, evidence).results.first.score.value;
      final score2 = RankingEngine.rank(props, evidence).results.first.score.value;
      expect(score1, equals(score2));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 13. Tie handling
  // ══════════════════════════════════════════════════════════════════════════
  group('Tie handling', () {
    test('tied scores broken by property id alphabetically ascending', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      // Both properties: same type, same evidenceIds, same metadata → same score.
      final propA = CandidateProperty(
        id: 'synth.a.prop',
        title: 'A', description: 'A',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'k': 1},
      );
      final propB = CandidateProperty(
        id: 'synth.b.prop',
        title: 'B', description: 'B',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'k': 1},
      );
      final ranked = RankingEngine.rank(
          CandidatePropertySet([propB, propA]), evidence);
      expect(ranked.results[0].property.id, 'synth.a.prop');
      expect(ranked.results[1].property.id, 'synth.b.prop');
    });

    test('tie-break is deterministic regardless of insertion order', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final propA = CandidateProperty(
        id: 'alpha.prop', title: 'A', description: 'A',
        propertyType: CandidatePropertyType.stability,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'w': 4},
      );
      final propB = CandidateProperty(
        id: 'beta.prop', title: 'B', description: 'B',
        propertyType: CandidatePropertyType.stability,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'w': 4},
      );
      final r1 = RankingEngine.rank(
          CandidatePropertySet([propA, propB]), evidence);
      final r2 = RankingEngine.rank(
          CandidatePropertySet([propB, propA]), evidence);
      expect(r1.results[0].property.id, r2.results[0].property.id);
      expect(r1.results[1].property.id, r2.results[1].property.id);
    });

    test('tied results both appear in output', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final propA = CandidateProperty(
        id: 'a.tied', title: 'A', description: 'A',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'k': 1},
      );
      final propB = CandidateProperty(
        id: 'b.tied', title: 'B', description: 'B',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'k': 1},
      );
      final ranked = RankingEngine.rank(
          CandidatePropertySet([propA, propB]), evidence);
      expect(ranked.length, 2);
    });

    test('tied results have consecutive rank numbers', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final propA = CandidateProperty(
        id: 'aa.prop', title: 'A', description: 'A',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'k': 1},
      );
      final propB = CandidateProperty(
        id: 'bb.prop', title: 'B', description: 'B',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
        metadata: const {'k': 1},
      );
      final ranked = RankingEngine.rank(
          CandidatePropertySet([propA, propB]), evidence);
      expect(ranked.results[0].rank, 1);
      expect(ranked.results[1].rank, 2);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 14. Edge cases
  // ══════════════════════════════════════════════════════════════════════════
  group('Edge cases', () {
    test('property with no evidenceIds still produces a result', () {
      final prop = CandidateProperty(
        id: 'no.evidence',
        title: 'No evidence',
        description: 'D',
        propertyType: CandidatePropertyType.custom,
        rationale: 'R',
      );
      final ranked = RankingEngine.rank(
          CandidatePropertySet([prop]), SemanticEvidenceSet());
      expect(ranked.length, 1);
      expect(ranked.results.first.score.value, greaterThanOrEqualTo(0.0));
    });

    test('evidence not in set does not crash the engine', () {
      final prop = _safetyProp(evidenceIds: ['nonexistent.id']);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([prop]), SemanticEvidenceSet());
      expect(ranked.length, 1);
    });

    test('property with no metadata still scores correctly', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final prop = CandidateProperty(
        id: 'no.meta',
        title: 'No meta',
        description: 'D',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds: const ['fsm.state'],
        rationale: 'R',
      );
      final ranked = RankingEngine.rank(
          CandidatePropertySet([prop]), evidence);
      expect(ranked.results.first.score.value, greaterThan(0.0));
    });

    test('top(0) returns empty set', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([_safetyProp()]), evidence);
      expect(ranked.top(0).isEmpty, isTrue);
    });

    test('filter with always-false predicate returns empty set', () {
      final evidence = SemanticEvidenceSet(
          [_fsmEvidence(), _resetEvidence(), _counterEvidence()]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet(
              [_safetyProp(), _livenessProp(), _boundednessProp()]),
          evidence);
      expect(ranked.filter((_) => false).isEmpty, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 15. Explanation generation
  // ══════════════════════════════════════════════════════════════════════════
  group('Explanation generation', () {
    test('high-confidence evidence produces a high-confidence reason', () {
      final evidence =
          SemanticEvidenceSet([_fsmEvidence(confidence: 0.95)]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([_safetyProp()]), evidence);
      final reasons = ranked.results.first.explanation.reasons;
      expect(reasons.any((r) => r.toLowerCase().contains('high-confidence')),
          isTrue);
    });

    test('safetyInvariant type produces a high-priority-type reason', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([_safetyProp()]), evidence);
      final reasons = ranked.results.first.explanation.reasons;
      expect(reasons.any((r) => r.toLowerCase().contains('high-priority')),
          isTrue);
    });

    test('explanation.formatted starts with the score', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([_safetyProp()]), evidence);
      final fmt = ranked.results.first.explanation.formatted;
      expect(fmt, startsWith('Score:'));
    });

    test('reasons list is non-empty for a scored property', () {
      final evidence = SemanticEvidenceSet([_fsmEvidence()]);
      final ranked = RankingEngine.rank(
          CandidatePropertySet([_safetyProp()]), evidence);
      expect(ranked.results.first.explanation.reasons, isNotEmpty);
    });
  });
}
