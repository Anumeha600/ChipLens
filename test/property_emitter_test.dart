import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/formal/formal_property_type.dart';
import 'package:chiplens_lite/backend/property_inference/emitter/emitter.dart';
import 'package:chiplens_lite/backend/property_inference/ranking/ranking.dart';
import 'package:chiplens_lite/backend/property_inference/synthesizer/synthesizer.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

RankingResult _makeResult({
  required String id,
  CandidatePropertyType type = CandidatePropertyType.safetyInvariant,
  String? expression,
  List<String> evidenceIds = const [],
  Map<String, dynamic> metadata = const {},
  double score = 0.80,
  int rank = 1,
  List<String> reasons = const [],
}) {
  final prop = CandidateProperty(
    id: id,
    title: '$id title',
    description: '$id description',
    propertyType: type,
    expression: expression,
    evidenceIds: evidenceIds,
    rationale: '$id rationale',
    metadata: metadata,
  );
  final rankingScore = RankingScore(
    value: score,
    contributions: const [],
    explanation: '$id score breakdown',
  );
  final explanation = RankingExplanation(
    score: score,
    reasons: List.unmodifiable(reasons),
  );
  return RankingResult(
    property: prop, score: rankingScore, rank: rank, explanation: explanation,
  );
}

RankedCandidatePropertySet _makeRanked(List<RankingResult> results) =>
    RankedCandidatePropertySet(results);

RankedCandidatePropertySet _generateRanked(int count) {
  final results = List.generate(count, (i) => _makeResult(
    id: 'prop.$i',
    score: 1.0 - (i / (count == 1 ? 1 : count)),
    rank: i + 1,
  ));
  return _makeRanked(results);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // 1. EmitterContext
  // ══════════════════════════════════════════════════════════════════════════
  group('EmitterContext', () {
    test('default construction has sensible defaults', () {
      const ctx = EmitterContext();
      expect(ctx.maximumPropertiesToEmit,   -1);
      expect(ctx.minimumConfidence,          0.0);
      expect(ctx.includeDisabledCandidates,  false);
      expect(ctx.preserveRanking,            true);
    });

    test('custom fields are stored correctly', () {
      const ctx = EmitterContext(
        maximumPropertiesToEmit:   10,
        minimumConfidence:         0.5,
        includeDisabledCandidates: true,
        preserveRanking:           false,
      );
      expect(ctx.maximumPropertiesToEmit,   10);
      expect(ctx.minimumConfidence,          0.5);
      expect(ctx.includeDisabledCandidates,  true);
      expect(ctx.preserveRanking,            false);
    });

    test('equality holds for identical field values', () {
      const a = EmitterContext(maximumPropertiesToEmit: 5, minimumConfidence: 0.3);
      const b = EmitterContext(maximumPropertiesToEmit: 5, minimumConfidence: 0.3);
      expect(a, b);
    });

    test('inequality when any field differs', () {
      const a = EmitterContext(maximumPropertiesToEmit: 5);
      const b = EmitterContext(maximumPropertiesToEmit: 6);
      expect(a, isNot(b));
    });

    test('copyWith overrides only specified fields', () {
      const original = EmitterContext(maximumPropertiesToEmit: 5, minimumConfidence: 0.3);
      final copy = original.copyWith(minimumConfidence: 0.7);
      expect(copy.maximumPropertiesToEmit, 5);
      expect(copy.minimumConfidence,        0.7);
    });

    test('copyWith with no arguments is equal to original', () {
      const ctx = EmitterContext(maximumPropertiesToEmit: 10, minimumConfidence: 0.4);
      expect(ctx.copyWith(), ctx);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. DefaultEmissionPolicy
  // ══════════════════════════════════════════════════════════════════════════
  group('DefaultEmissionPolicy', () {
    const policy = DefaultEmissionPolicy();

    test('accepts enabled candidate', () {
      final r = _makeResult(id: 'a', score: 0.9);
      expect(policy.shouldEmit(r, minimumConfidence: 0.0, includeDisabled: false), isTrue);
    });

    test('rejects candidate with metadata enabled=false when includeDisabled is false', () {
      final r = _makeResult(id: 'b', score: 0.9, metadata: const {'enabled': false});
      expect(policy.shouldEmit(r, minimumConfidence: 0.0, includeDisabled: false), isFalse);
    });

    test('accepts disabled candidate when includeDisabled is true', () {
      final r = _makeResult(id: 'c', score: 0.9, metadata: const {'enabled': false});
      expect(policy.shouldEmit(r, minimumConfidence: 0.0, includeDisabled: true), isTrue);
    });

    test('rejects candidate below minimumConfidence', () {
      final r = _makeResult(id: 'd', score: 0.3);
      expect(policy.shouldEmit(r, minimumConfidence: 0.5, includeDisabled: false), isFalse);
    });

    test('accepts candidate at exactly minimumConfidence', () {
      final r = _makeResult(id: 'e', score: 0.5);
      expect(policy.shouldEmit(r, minimumConfidence: 0.5, includeDisabled: false), isTrue);
    });

    test('disabled check precedes confidence check', () {
      // Disabled AND low confidence — rejected by disabled check first.
      final r = _makeResult(id: 'f', score: 0.0, metadata: const {'enabled': false});
      expect(policy.shouldEmit(r, minimumConfidence: 0.0, includeDisabled: false), isFalse);
    });

    test('candidate without enabled key is treated as enabled', () {
      final r = _makeResult(id: 'g', score: 0.8, metadata: const {});
      expect(policy.shouldEmit(r, minimumConfidence: 0.0, includeDisabled: false), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. PriorityFilter
  // ══════════════════════════════════════════════════════════════════════════
  group('PriorityFilter', () {
    test('empty ranked set returns empty list', () {
      final result = PriorityFilter.filter(
          _makeRanked([]), const EmitterContext());
      expect(result, isEmpty);
    });

    test('single candidate that passes is selected', () {
      final r = _makeResult(id: 'x', score: 0.9);
      final result = PriorityFilter.filter(
          _makeRanked([r]), const EmitterContext());
      expect(result, hasLength(1));
      expect(result.first.property.id, 'x');
    });

    test('multiple candidates all pass with permissive context', () {
      final ranked = _generateRanked(5);
      final result = PriorityFilter.filter(ranked, const EmitterContext());
      expect(result, hasLength(5));
    });

    test('maximum limit stops selection at n', () {
      final ranked = _generateRanked(10);
      final ctx    = const EmitterContext(maximumPropertiesToEmit: 3);
      final result = PriorityFilter.filter(ranked, ctx);
      expect(result, hasLength(3));
    });

    test('confidence threshold excludes low-scoring candidates', () {
      final results = [
        _makeResult(id: 'a', score: 0.9, rank: 1),
        _makeResult(id: 'b', score: 0.4, rank: 2),
        _makeResult(id: 'c', score: 0.8, rank: 3),
      ];
      final ctx = const EmitterContext(minimumConfidence: 0.7);
      final selected = PriorityFilter.filter(_makeRanked(results), ctx);
      expect(selected.map((r) => r.property.id).toList(), ['a', 'c']);
    });

    test('disabled candidates are excluded when includeDisabledCandidates is false', () {
      final results = [
        _makeResult(id: 'a', score: 0.9, rank: 1),
        _makeResult(id: 'b', score: 0.8, rank: 2, metadata: const {'enabled': false}),
        _makeResult(id: 'c', score: 0.7, rank: 3),
      ];
      final ctx = const EmitterContext(includeDisabledCandidates: false);
      final selected = PriorityFilter.filter(_makeRanked(results), ctx);
      expect(selected.map((r) => r.property.id).toList(), ['a', 'c']);
    });

    test('disabled candidates are included when includeDisabledCandidates is true', () {
      final r = _makeResult(id: 'a', metadata: const {'enabled': false});
      final ctx = const EmitterContext(includeDisabledCandidates: true);
      final selected = PriorityFilter.filter(_makeRanked([r]), ctx);
      expect(selected, hasLength(1));
    });

    test('ordering is preserved from the ranked input', () {
      final results = [
        _makeResult(id: 'first',  score: 0.9, rank: 1),
        _makeResult(id: 'second', score: 0.7, rank: 2),
        _makeResult(id: 'third',  score: 0.5, rank: 3),
      ];
      final selected = PriorityFilter.filter(
          _makeRanked(results), const EmitterContext());
      final ids = selected.map((r) => r.property.id).toList();
      expect(ids, ['first', 'second', 'third']);
    });

    test('maximum of 0 returns empty list', () {
      final ranked = _generateRanked(5);
      final result = PriorityFilter.filter(
          ranked, const EmitterContext(maximumPropertiesToEmit: 0));
      expect(result, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. PropertyMapper — type mapping
  // ══════════════════════════════════════════════════════════════════════════
  group('PropertyMapper type mapping', () {
    test('safetyInvariant → safety', () {
      expect(PropertyMapper.mapType(CandidatePropertyType.safetyInvariant),
          FormalPropertyType.safety);
    });

    test('livenessCondition → liveness', () {
      expect(PropertyMapper.mapType(CandidatePropertyType.livenessCondition),
          FormalPropertyType.liveness);
    });

    test('reachability → cover', () {
      expect(PropertyMapper.mapType(CandidatePropertyType.reachability),
          FormalPropertyType.cover);
    });

    test('stability → assertion', () {
      expect(PropertyMapper.mapType(CandidatePropertyType.stability),
          FormalPropertyType.assertion);
    });

    test('boundedness → assertion', () {
      expect(PropertyMapper.mapType(CandidatePropertyType.boundedness),
          FormalPropertyType.assertion);
    });

    test('assumption → assumption', () {
      expect(PropertyMapper.mapType(CandidatePropertyType.assumption),
          FormalPropertyType.assumption);
    });

    test('custom → assertion', () {
      expect(PropertyMapper.mapType(CandidatePropertyType.custom),
          FormalPropertyType.assertion);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5. PropertyMapper — full map
  // ══════════════════════════════════════════════════════════════════════════
  group('PropertyMapper field preservation', () {
    test('id is preserved', () {
      final r = _makeResult(id: 'synth.fsm.state.legal');
      expect(PropertyMapper.map(r).id, 'synth.fsm.state.legal');
    });

    test('name comes from CandidateProperty.title', () {
      final r = _makeResult(id: 'x');
      expect(PropertyMapper.map(r).name, 'x title');
    });

    test('description is preserved', () {
      final r = _makeResult(id: 'x');
      expect(PropertyMapper.map(r).description, 'x description');
    });

    test('non-null expression is preserved', () {
      final r = _makeResult(id: 'x', expression: 'counter <= 255');
      expect(PropertyMapper.map(r).expression, 'counter <= 255');
    });

    test('null expression becomes empty string', () {
      final r = _makeResult(id: 'x', expression: null);
      expect(PropertyMapper.map(r).expression, '');
    });

    test('property type is mapped correctly', () {
      final r = _makeResult(id: 'x', type: CandidatePropertyType.reachability);
      expect(PropertyMapper.map(r).propertyType, FormalPropertyType.cover);
    });

    test('score is in metadata', () {
      final r = _makeResult(id: 'x', score: 0.73);
      expect(PropertyMapper.map(r).metadata['score'], closeTo(0.73, 1e-9));
    });

    test('rank is in metadata', () {
      final r = _makeResult(id: 'x', rank: 4);
      expect(PropertyMapper.map(r).metadata['rank'], 4);
    });

    test('explanation is in metadata', () {
      final r = _makeResult(id: 'x', score: 0.5);
      final meta = PropertyMapper.map(r).metadata;
      expect(meta['explanation'], isNotEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6. MetadataMapper
  // ══════════════════════════════════════════════════════════════════════════
  group('MetadataMapper', () {
    test('contains candidateId', () {
      final r    = _makeResult(id: 'synth.reset.rst');
      final meta = MetadataMapper.build(r, const []);
      expect(meta['candidateId'], 'synth.reset.rst');
    });

    test('contains rank', () {
      final r    = _makeResult(id: 'x', rank: 3);
      final meta = MetadataMapper.build(r, const []);
      expect(meta['rank'], 3);
    });

    test('contains score', () {
      final r    = _makeResult(id: 'x', score: 0.77);
      final meta = MetadataMapper.build(r, const []);
      expect(meta['score'], closeTo(0.77, 1e-9));
    });

    test('contains explanation', () {
      final r    = _makeResult(id: 'x');
      final meta = MetadataMapper.build(r, const []);
      expect(meta.containsKey('explanation'), isTrue);
      expect(meta['explanation'], isNotEmpty);
    });

    test('contains source tag PropertyEmitter', () {
      final r    = _makeResult(id: 'x');
      final meta = MetadataMapper.build(r, const []);
      expect(meta['source'], 'PropertyEmitter');
    });

    test('contains evidenceIds', () {
      final r    = _makeResult(id: 'x');
      final meta = MetadataMapper.build(r, ['e1', 'e2']);
      expect(meta['evidenceIds'], ['e1', 'e2']);
    });

    test('produces exactly 6 keys', () {
      final r    = _makeResult(id: 'x');
      final meta = MetadataMapper.build(r, ['ev.1']);
      expect(meta.length, 6);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7. EvidenceMapper
  // ══════════════════════════════════════════════════════════════════════════
  group('EvidenceMapper', () {
    test('empty list returns empty list', () {
      expect(EvidenceMapper.map([]), isEmpty);
    });

    test('single id is preserved', () {
      expect(EvidenceMapper.map(['e1']), ['e1']);
    });

    test('preserves ordering of distinct ids', () {
      expect(EvidenceMapper.map(['e3', 'e1', 'e2']), ['e3', 'e1', 'e2']);
    });

    test('removes duplicate ids, keeping first occurrence', () {
      expect(EvidenceMapper.map(['e1', 'e2', 'e1', 'e3']), ['e1', 'e2', 'e3']);
    });

    test('all-duplicate list reduces to single entry', () {
      expect(EvidenceMapper.map(['same', 'same', 'same']), ['same']);
    });

    test('returned list is unmodifiable', () {
      final result = EvidenceMapper.map(['e1']);
      expect(() => (result as List).add('e2'), throwsUnsupportedError);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 8. PropertyEmitter — complete pipeline
  // ══════════════════════════════════════════════════════════════════════════
  group('PropertyEmitter pipeline', () {
    test('empty ranked set produces empty FormalPropertySet', () async {
      final result = await PropertyEmitter().emit(
          _makeRanked([]), const EmitterContext());
      expect(result.properties.isEmpty, isTrue);
      expect(result.emittedCount, 0);
    });

    test('emittedCount matches number of emitted properties', () async {
      final result = await PropertyEmitter().emit(
          _generateRanked(3), const EmitterContext());
      expect(result.emittedCount, result.properties.length);
    });

    test('emittedCount + skippedCount equals input size', () async {
      final ranked = _generateRanked(5);
      final ctx    = const EmitterContext(minimumConfidence: 1.5); // none pass
      final result = await PropertyEmitter().emit(ranked, ctx);
      expect(result.emittedCount + result.skippedCount, ranked.length);
    });

    test('property ids are preserved in output', () async {
      final results = [
        _makeResult(id: 'prop.a', rank: 1),
        _makeResult(id: 'prop.b', rank: 2),
      ];
      final result = await PropertyEmitter().emit(
          _makeRanked(results), const EmitterContext());
      final ids = result.properties.properties.map((p) => p.id).toList();
      expect(ids, ['prop.a', 'prop.b']);
    });

    test('output ordering matches ranking order', () async {
      final results = [
        _makeResult(id: 'first',  score: 0.9, rank: 1),
        _makeResult(id: 'second', score: 0.7, rank: 2),
        _makeResult(id: 'third',  score: 0.5, rank: 3),
      ];
      final result = await PropertyEmitter().emit(
          _makeRanked(results), const EmitterContext());
      final ids = result.properties.properties.map((p) => p.id).toList();
      expect(ids, ['first', 'second', 'third']);
    });

    test('maximumPropertiesToEmit limits output', () async {
      final result = await PropertyEmitter().emit(
          _generateRanked(10),
          const EmitterContext(maximumPropertiesToEmit: 4));
      expect(result.emittedCount, 4);
    });

    test('ranking metadata is preserved in FormalProperty', () async {
      final results = [_makeResult(id: 'p', score: 0.82, rank: 1)];
      final result  = await PropertyEmitter().emit(
          _makeRanked(results), const EmitterContext());
      final fp = result.properties.properties.first;
      expect(fp.metadata['rank'],  1);
      expect(fp.metadata['score'], closeTo(0.82, 1e-9));
    });

    test('evidence ids are carried through to metadata', () async {
      final results = [
        _makeResult(id: 'p', evidenceIds: ['ev.fsm', 'ev.reset'], rank: 1),
      ];
      final result = await PropertyEmitter().emit(
          _makeRanked(results), const EmitterContext());
      final evIds = result.properties.properties.first.metadata['evidenceIds']
          as List;
      expect(evIds, containsAll(['ev.fsm', 'ev.reset']));
    });

    test('skippedCount reflects candidates excluded by policy', () async {
      final results = [
        _makeResult(id: 'a', score: 0.9, rank: 1),
        _makeResult(id: 'b', score: 0.2, rank: 2),  // below threshold
      ];
      final ctx    = const EmitterContext(minimumConfidence: 0.5);
      final result = await PropertyEmitter().emit(_makeRanked(results), ctx);
      expect(result.skippedCount, 1);
      expect(result.emittedCount, 1);
    });

    test('executionTime is non-negative', () async {
      final result = await PropertyEmitter().emit(
          _generateRanked(5), const EmitterContext());
      expect(result.executionTime.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('expression preserved when non-null', () async {
      final results = [
        _makeResult(id: 'p', expression: 'state != ILLEGAL', rank: 1),
      ];
      final result = await PropertyEmitter().emit(
          _makeRanked(results), const EmitterContext());
      expect(result.properties.properties.first.expression, 'state != ILLEGAL');
    });

    test('null expression becomes empty string in FormalProperty', () async {
      final results = [_makeResult(id: 'p', expression: null, rank: 1)];
      final result  = await PropertyEmitter().emit(
          _makeRanked(results), const EmitterContext());
      expect(result.properties.properties.first.expression, '');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 9. Determinism
  // ══════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    test('same input produces same output on repeated calls', () async {
      final ranked  = _generateRanked(20);
      final context = const EmitterContext();
      final r1 = await PropertyEmitter().emit(ranked, context);
      final r2 = await PropertyEmitter().emit(ranked, context);
      final ids1 = r1.properties.properties.map((p) => p.id).toList();
      final ids2 = r2.properties.properties.map((p) => p.id).toList();
      expect(ids1, ids2);
    });

    test('metadata scores are identical across runs', () async {
      final ranked  = _generateRanked(5);
      final context = const EmitterContext();
      final r1 = await PropertyEmitter().emit(ranked, context);
      final r2 = await PropertyEmitter().emit(ranked, context);
      for (var i = 0; i < r1.properties.length; i++) {
        expect(r1.properties.properties[i].metadata['score'],
            r2.properties.properties[i].metadata['score']);
      }
    });

    test('emittedCount is identical across runs', () async {
      final ranked  = _generateRanked(8);
      final context = const EmitterContext(minimumConfidence: 0.5);
      final r1 = await PropertyEmitter().emit(ranked, context);
      final r2 = await PropertyEmitter().emit(ranked, context);
      expect(r1.emittedCount, r2.emittedCount);
    });

    test('different PropertyEmitter instances produce equal output', () async {
      final ranked  = _generateRanked(10);
      final context = const EmitterContext();
      final r1 = await const PropertyEmitter().emit(ranked, context);
      final r2 = await const PropertyEmitter().emit(ranked, context);
      final ids1 = r1.properties.properties.map((p) => p.id).toList();
      final ids2 = r2.properties.properties.map((p) => p.id).toList();
      expect(ids1, ids2);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 10. Negative tests
  // ══════════════════════════════════════════════════════════════════════════
  group('Negative tests', () {
    test('duplicate property ids throw ArgumentError', () async {
      final results = [
        _makeResult(id: 'dup', rank: 1),
        _makeResult(id: 'dup', rank: 2),   // same id
      ];
      await expectLater(
        () => PropertyEmitter().emit(_makeRanked(results), const EmitterContext()),
        throwsArgumentError,
      );
    });

    test('all candidates below minimumConfidence produces empty output', () async {
      final ranked = _generateRanked(5);
      final ctx    = const EmitterContext(minimumConfidence: 2.0); // impossible
      final result = await PropertyEmitter().emit(ranked, ctx);
      expect(result.properties.isEmpty, isTrue);
      expect(result.skippedCount, 5);
    });

    test('all candidates disabled and includeDisabled=false → empty output', () async {
      final results = List.generate(3, (i) =>
          _makeResult(id: 'p.$i', rank: i + 1, metadata: const {'enabled': false}));
      final ctx    = const EmitterContext(includeDisabledCandidates: false);
      final result = await PropertyEmitter().emit(_makeRanked(results), ctx);
      expect(result.emittedCount, 0);
    });

    test('EvidenceMapper map with non-list input handles gracefully', () {
      // Empty list is always valid.
      expect(() => EvidenceMapper.map([]), returnsNormally);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 11. EmitterResult convenience getters
  // ══════════════════════════════════════════════════════════════════════════
  group('EmitterResult getters', () {
    test('isEmpty is true when emittedCount is 0', () async {
      final result = await PropertyEmitter().emit(
          _makeRanked([]), const EmitterContext());
      expect(result.isEmpty, isTrue);
      expect(result.isNotEmpty, isFalse);
    });

    test('isNotEmpty is true when at least one property emitted', () async {
      final result = await PropertyEmitter().emit(
          _generateRanked(1), const EmitterContext());
      expect(result.isNotEmpty, isTrue);
    });

    test('hasWarnings is false for normal emission', () async {
      final result = await PropertyEmitter().emit(
          _generateRanked(3), const EmitterContext());
      expect(result.hasWarnings, isFalse);
    });

    test('emissionRate is 1.0 when nothing is skipped', () async {
      final result = await PropertyEmitter().emit(
          _generateRanked(4), const EmitterContext());
      expect(result.emissionRate, closeTo(1.0, 1e-9));
    });

    test('emissionRate is 0.0 when nothing is emitted', () async {
      final result = await PropertyEmitter().emit(
          _makeRanked([]), const EmitterContext());
      expect(result.emissionRate, 0.0);
    });

    test('emissionRate is 0.5 when half are skipped', () async {
      final results = [
        _makeResult(id: 'a', score: 0.9, rank: 1),
        _makeResult(id: 'b', score: 0.1, rank: 2),  // below 0.5
      ];
      final ctx    = const EmitterContext(minimumConfidence: 0.5);
      final result = await PropertyEmitter().emit(_makeRanked(results), ctx);
      expect(result.emissionRate, closeTo(0.5, 1e-9));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 12. Performance tests
  // ══════════════════════════════════════════════════════════════════════════
  group('Performance', () {
    test('100 properties emitted within 200ms', () async {
      final sw     = Stopwatch()..start();
      final result = await PropertyEmitter().emit(
          _generateRanked(100), const EmitterContext());
      sw.stop();
      expect(result.emittedCount, 100);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('500 properties emitted within 500ms', () async {
      final sw     = Stopwatch()..start();
      final result = await PropertyEmitter().emit(
          _generateRanked(500), const EmitterContext());
      sw.stop();
      expect(result.emittedCount, 500);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('1000 properties emitted within 1000ms', () async {
      final sw     = Stopwatch()..start();
      final result = await PropertyEmitter().emit(
          _generateRanked(1000), const EmitterContext());
      sw.stop();
      expect(result.emittedCount, 1000);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('5000 properties emitted within 3000ms', () async {
      final sw     = Stopwatch()..start();
      final result = await PropertyEmitter().emit(
          _generateRanked(5000), const EmitterContext());
      sw.stop();
      expect(result.emittedCount, 5000);
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });
  });
}
