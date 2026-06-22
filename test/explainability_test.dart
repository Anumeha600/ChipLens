import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/explainability/explainability.dart';
import 'package:chiplens_lite/backend/formal/formal_property.dart';
import 'package:chiplens_lite/backend/formal/formal_property_set.dart';
import 'package:chiplens_lite/backend/formal/formal_property_type.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

/// Creates a [FormalProperty] with the metadata keys written by PropertyEmitter.
FormalProperty _makeProp({
  String id          = 'test.prop',
  String name        = 'Test Property',
  String description = 'A test property',
  FormalPropertyType type = FormalPropertyType.assertion,
  String expression  = '',
  double score       = 0.80,
  int rank           = 1,
  List<String> evidenceIds = const [],
  String rankingText = 'Score: 0.8000\nReasons:\n  - High-confidence evidence',
}) =>
    FormalProperty(
      id:           id,
      name:         name,
      description:  description,
      propertyType: type,
      expression:   expression,
      metadata:     {
        'candidateId': id,
        'rank':        rank,
        'score':       score,
        'explanation': rankingText,
        'source':      'PropertyEmitter',
        'evidenceIds': List<String>.unmodifiable(evidenceIds),
      },
    );

FormalPropertySet _makeSet(List<FormalProperty> props) {
  final set = FormalPropertySet();
  for (final p in props) { set.add(p); }
  return set;
}

FormalPropertySet _generateSet(int count) {
  final set = FormalPropertySet();
  for (var i = 0; i < count; i++) {
    set.add(_makeProp(
      id:    'prop.$i',
      name:  'Prop $i',
      score: 1.0 - (i / (count == 1 ? 1 : count)),
      rank:  i + 1,
    ));
  }
  return set;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // 1. ExplanationFormat enum
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationFormat', () {
    test('has exactly four values', () {
      expect(ExplanationFormat.values, hasLength(4));
    });

    test('contains structured, markdown, plainText, json', () {
      expect(ExplanationFormat.values, containsAll([
        ExplanationFormat.structured,
        ExplanationFormat.markdown,
        ExplanationFormat.plainText,
        ExplanationFormat.json,
      ]));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. ExplanationContext
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationContext', () {
    test('default construction has sensible defaults', () {
      const ctx = ExplanationContext();
      expect(ctx.includeEvidence,   isTrue);
      expect(ctx.includeRanking,    isTrue);
      expect(ctx.includeConfidence, isTrue);
      expect(ctx.includeMetadata,   isTrue);
      expect(ctx.format,            ExplanationFormat.structured);
      expect(ctx.maximumEvidence,   -1);
    });

    test('custom fields are stored correctly', () {
      const ctx = ExplanationContext(
        includeEvidence:   false,
        maximumEvidence:   3,
        format:            ExplanationFormat.markdown,
      );
      expect(ctx.includeEvidence, isFalse);
      expect(ctx.maximumEvidence, 3);
      expect(ctx.format,          ExplanationFormat.markdown);
    });

    test('equality holds for identical field values', () {
      const a = ExplanationContext(maximumEvidence: 5, format: ExplanationFormat.json);
      const b = ExplanationContext(maximumEvidence: 5, format: ExplanationFormat.json);
      expect(a, b);
    });

    test('inequality when any field differs', () {
      const a = ExplanationContext(maximumEvidence: 5);
      const b = ExplanationContext(maximumEvidence: 6);
      expect(a, isNot(b));
    });

    test('copyWith overrides only specified fields', () {
      const ctx  = ExplanationContext(maximumEvidence: 5, format: ExplanationFormat.json);
      final copy = ctx.copyWith(format: ExplanationFormat.markdown);
      expect(copy.maximumEvidence, 5);
      expect(copy.format,          ExplanationFormat.markdown);
    });

    test('copyWith with no args equals original', () {
      const ctx = ExplanationContext(maximumEvidence: 3);
      expect(ctx.copyWith(), ctx);
    });

    test('includeEvidence=false is preserved through copyWith', () {
      const ctx  = ExplanationContext(includeEvidence: false);
      final copy = ctx.copyWith(maximumEvidence: 2);
      expect(copy.includeEvidence, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. ExplanationTrace
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationTrace', () {
    test('stores all required fields', () {
      final t = ExplanationTrace(
        semanticEvidenceIds: ['e1', 'e2'],
        rankingExplanation:  'Good evidence',
        confidence:          0.85,
        emissionReason:      'Emitted at rank 1',
        propertyType:        'safety',
      );
      expect(t.semanticEvidenceIds, ['e1', 'e2']);
      expect(t.rankingExplanation,  'Good evidence');
      expect(t.confidence,          0.85);
      expect(t.emissionReason,      'Emitted at rank 1');
      expect(t.propertyType,        'safety');
    });

    test('verificationEngine defaults to empty string', () {
      final t = ExplanationTrace(
        semanticEvidenceIds: const [],
        rankingExplanation:  '',
        confidence:          0.5,
        emissionReason:      '',
        propertyType:        'assertion',
      );
      expect(t.verificationEngine, '');
    });

    test('futureMetadata defaults to empty map', () {
      final t = ExplanationTrace(
        semanticEvidenceIds: const [],
        rankingExplanation:  '',
        confidence:          0.5,
        emissionReason:      '',
        propertyType:        '',
      );
      expect(t.futureMetadata, isEmpty);
    });

    test('semanticEvidenceIds is unmodifiable', () {
      final t = ExplanationTrace(
        semanticEvidenceIds: ['e1'],
        rankingExplanation:  '',
        confidence:          0.5,
        emissionReason:      '',
        propertyType:        '',
      );
      expect(() => (t.semanticEvidenceIds as List).add('e2'),
          throwsUnsupportedError);
    });

    test('empty evidence ids are preserved', () {
      final t = ExplanationTrace(
        semanticEvidenceIds: const [],
        rankingExplanation:  '',
        confidence:          0.0,
        emissionReason:      '',
        propertyType:        '',
      );
      expect(t.semanticEvidenceIds, isEmpty);
    });

    test('confidence of 0.0 is valid', () {
      final t = ExplanationTrace(
        semanticEvidenceIds: const [],
        rankingExplanation:  '',
        confidence:          0.0,
        emissionReason:      '',
        propertyType:        '',
      );
      expect(t.confidence, 0.0);
    });

    test('confidence of 1.0 is valid', () {
      final t = ExplanationTrace(
        semanticEvidenceIds: const [],
        rankingExplanation:  '',
        confidence:          1.0,
        emissionReason:      '',
        propertyType:        '',
      );
      expect(t.confidence, 1.0);
    });

    test('input list mutation does not affect stored ids', () {
      final ids = ['e1', 'e2'];
      final t   = ExplanationTrace(
        semanticEvidenceIds: ids,
        rankingExplanation:  '',
        confidence:          0.5,
        emissionReason:      '',
        propertyType:        '',
      );
      ids.add('e3');
      expect(t.semanticEvidenceIds, hasLength(2));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. VerificationExplanation
  // ══════════════════════════════════════════════════════════════════════════
  group('VerificationExplanation', () {
    ExplanationTrace makeTrace() => ExplanationTrace(
          semanticEvidenceIds: const ['e1'],
          rankingExplanation:  'Good ranking',
          confidence:          0.9,
          emissionReason:      'Emitted at rank 1',
          propertyType:        'safety',
        );

    test('stores propertyId, title, description, trace', () {
      final exp = VerificationExplanation(
        propertyId:  'prop.x',
        title:       'X title',
        description: 'X description',
        trace:       makeTrace(),
      );
      expect(exp.propertyId,  'prop.x');
      expect(exp.title,       'X title');
      expect(exp.description, 'X description');
    });

    test('equality is by propertyId', () {
      final a = VerificationExplanation(propertyId: 'x', title: 'A', trace: makeTrace());
      final b = VerificationExplanation(propertyId: 'x', title: 'B', trace: makeTrace());
      expect(a, b);
    });

    test('inequality when propertyIds differ', () {
      final a = VerificationExplanation(propertyId: 'a', title: 'T', trace: makeTrace());
      final b = VerificationExplanation(propertyId: 'b', title: 'T', trace: makeTrace());
      expect(a, isNot(b));
    });

    test('metadata is unmodifiable', () {
      final exp = VerificationExplanation(
        propertyId: 'x', title: 'T', trace: makeTrace(),
        metadata:   {'k': 1},
      );
      expect(() => exp.metadata['new'] = 2, throwsUnsupportedError);
    });

    test('description defaults to empty string', () {
      final exp = VerificationExplanation(
        propertyId: 'x', title: 'T', trace: makeTrace(),
      );
      expect(exp.description, '');
    });

    test('toString includes propertyId', () {
      final exp = VerificationExplanation(
        propertyId: 'fsm.state.legal', title: 'T', trace: makeTrace(),
      );
      expect(exp.toString(), contains('fsm.state.legal'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5. VerificationExplanationSet
  // ══════════════════════════════════════════════════════════════════════════
  group('VerificationExplanationSet', () {
    ExplanationTrace makeTrace() => ExplanationTrace(
          semanticEvidenceIds: const [],
          rankingExplanation:  '',
          confidence:          0.5,
          emissionReason:      '',
          propertyType:        'assertion',
        );

    VerificationExplanation makeExp(String id) =>
        VerificationExplanation(propertyId: id, title: id, trace: makeTrace());

    test('empty set has length 0', () {
      expect(VerificationExplanationSet().length, 0);
    });

    test('isEmpty is true for empty set', () {
      expect(VerificationExplanationSet().isEmpty, isTrue);
    });

    test('isNotEmpty is true for non-empty set', () {
      final s = VerificationExplanationSet([makeExp('x')]);
      expect(s.isNotEmpty, isTrue);
    });

    test('operator[] returns correct element', () {
      final a = makeExp('a');
      final b = makeExp('b');
      final s = VerificationExplanationSet([a, b]);
      expect(s[0].propertyId, 'a');
      expect(s[1].propertyId, 'b');
    });

    test('operator[] throws RangeError out of bounds', () {
      final s = VerificationExplanationSet([makeExp('x')]);
      expect(() => s[5], throwsRangeError);
    });

    test('explanations list is unmodifiable', () {
      final s = VerificationExplanationSet([makeExp('x')]);
      expect(() => (s.explanations as List).add(makeExp('y')),
          throwsUnsupportedError);
    });

    test('findById returns matching explanation', () {
      final s = VerificationExplanationSet([makeExp('a'), makeExp('b')]);
      expect(s.findById('b')!.propertyId, 'b');
    });

    test('findById returns null for missing id', () {
      final s = VerificationExplanationSet([makeExp('a')]);
      expect(s.findById('nonexistent'), isNull);
    });

    test('filter returns matching subset', () {
      final s = VerificationExplanationSet(
          [makeExp('fsm.prop'), makeExp('reset.prop'), makeExp('counter.prop')]);
      final filtered = s.filter((e) => e.propertyId.startsWith('fsm'));
      expect(filtered.length, 1);
      expect(filtered[0].propertyId, 'fsm.prop');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6. ExplanationBuilder
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationBuilder', () {
    const ctx = ExplanationContext();

    test('propertyId is preserved', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'synth.fsm.state.legal'), ctx);
      expect(exp.propertyId, 'synth.fsm.state.legal');
    });

    test('title comes from FormalProperty.name', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', name: 'Legal State'), ctx);
      expect(exp.title, 'Legal State');
    });

    test('description is preserved', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', description: 'FSM must stay legal'), ctx);
      expect(exp.description, 'FSM must stay legal');
    });

    test('property type is preserved in trace', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', type: FormalPropertyType.cover), ctx);
      expect(exp.trace.propertyType, 'cover');
    });

    test('confidence is extracted from metadata score', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', score: 0.73), ctx);
      expect(exp.trace.confidence, closeTo(0.73, 1e-9));
    });

    test('evidence ids are populated in trace', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', evidenceIds: ['fsm.state', 'reset.rst_n']), ctx);
      expect(exp.trace.semanticEvidenceIds, ['fsm.state', 'reset.rst_n']);
    });

    test('ranking explanation is extracted from metadata', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', rankingText: 'Custom ranking text'), ctx);
      expect(exp.trace.rankingExplanation, contains('Custom ranking text'));
    });

    test('emission reason mentions rank', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', rank: 3), ctx);
      expect(exp.trace.emissionReason, contains('3'));
    });

    test('metadata is included when includeMetadata is true', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x'), const ExplanationContext(includeMetadata: true));
      expect(exp.metadata, isNotEmpty);
    });

    test('metadata is excluded when includeMetadata is false', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x'), const ExplanationContext(includeMetadata: false));
      expect(exp.metadata, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7. ExplanationBuilder — evidence limits and fallbacks
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationBuilder evidence handling', () {
    test('maximumEvidence limits the ids in trace', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', evidenceIds: ['e1', 'e2', 'e3', 'e4']),
          const ExplanationContext(maximumEvidence: 2));
      expect(exp.trace.semanticEvidenceIds, hasLength(2));
    });

    test('includeEvidence=false produces empty evidence list', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', evidenceIds: ['e1', 'e2']),
          const ExplanationContext(includeEvidence: false));
      expect(exp.trace.semanticEvidenceIds, isEmpty);
    });

    test('FormalProperty with empty metadata produces default trace', () {
      final prop = FormalProperty(
        id: 'bare.prop', name: 'Bare', propertyType: FormalPropertyType.assertion,
        expression: '',
      );
      final exp = ExplanationBuilder.build(prop, const ExplanationContext());
      expect(exp.trace.confidence, 0.0);
      expect(exp.trace.semanticEvidenceIds, isEmpty);
      expect(exp.trace.emissionReason, isNotEmpty);
    });

    test('includeRanking=false produces empty ranking text', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x'),
          const ExplanationContext(includeRanking: false));
      expect(exp.trace.rankingExplanation, '');
    });

    test('includeConfidence=false produces zero confidence', () {
      final exp = ExplanationBuilder.build(
          _makeProp(id: 'x', score: 0.95),
          const ExplanationContext(includeConfidence: false));
      expect(exp.trace.confidence, 0.0);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 8. ExplanationFormatter — plain text
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationFormatter — plainText', () {
    late VerificationExplanation exp;
    setUp(() {
      exp = ExplanationBuilder.build(
          _makeProp(id: 'p', name: 'My Property',
              evidenceIds: ['fsm.state']),
          const ExplanationContext());
    });

    test('output contains property id', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.plainText);
      expect(out, contains('p'));
    });

    test('output contains type label', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.plainText);
      expect(out, contains('assertion'));
    });

    test('output contains confidence value', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.plainText);
      expect(out, contains('0.8000'));
    });

    test('output contains evidence id', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.plainText);
      expect(out, contains('fsm.state'));
    });

    test('does not modify the original explanation', () {
      final before = exp.propertyId;
      ExplanationFormatter.format(exp, ExplanationFormat.plainText);
      expect(exp.propertyId, before);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 9. ExplanationFormatter — markdown
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationFormatter — markdown', () {
    late VerificationExplanation exp;
    setUp(() {
      exp = ExplanationBuilder.build(
          _makeProp(id: 'fsm.state.legal', name: 'Legal State'),
          const ExplanationContext());
    });

    test('output starts with markdown heading', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.markdown);
      expect(out, startsWith('## Legal State'));
    });

    test('output contains bold property id label', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.markdown);
      expect(out, contains('**Property ID:**'));
    });

    test('output contains markdown table header', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.markdown);
      expect(out, contains('| Field | Value |'));
    });

    test('output contains type in table', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.markdown);
      expect(out, contains('assertion'));
    });

    test('does not modify the original explanation', () {
      final title = exp.title;
      ExplanationFormatter.format(exp, ExplanationFormat.markdown);
      expect(exp.title, title);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 10. ExplanationFormatter — structured
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationFormatter — structured', () {
    late VerificationExplanation exp;
    setUp(() {
      exp = ExplanationBuilder.build(
          _makeProp(id: 'x', name: 'X'), const ExplanationContext());
    });

    test('output contains propertyId key', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.structured);
      expect(out, contains('propertyId: x'));
    });

    test('output contains title key', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.structured);
      expect(out, contains('title: X'));
    });

    test('output contains confidence key', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.structured);
      expect(out, contains('confidence:'));
    });

    test('output is multi-line', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.structured);
      expect(out.contains('\n'), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 11. ExplanationFormatter — JSON
  // ══════════════════════════════════════════════════════════════════════════
  group('ExplanationFormatter — json', () {
    late VerificationExplanation exp;
    setUp(() {
      exp = ExplanationBuilder.build(
          _makeProp(id: 'json.prop', name: 'JSON Test',
              evidenceIds: ['e1']),
          const ExplanationContext());
    });

    test('output starts with opening brace', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.json);
      expect(out.trimLeft(), startsWith('{'));
    });

    test('output ends with closing brace', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.json);
      expect(out.trimRight(), endsWith('}'));
    });

    test('output contains propertyId field', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.json);
      expect(out, contains('"propertyId"'));
    });

    test('output contains evidenceIds array', () {
      final out = ExplanationFormatter.format(exp, ExplanationFormat.json);
      expect(out, contains('"evidenceIds"'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 12. VerificationExplainer
  // ══════════════════════════════════════════════════════════════════════════
  group('VerificationExplainer', () {
    const explainer = VerificationExplainer();
    const ctx       = ExplanationContext();

    test('empty FormalPropertySet produces empty set', () {
      final result = explainer.explain(FormalPropertySet(), ctx);
      expect(result.isEmpty, isTrue);
    });

    test('single property produces single explanation', () {
      final result = explainer.explain(
          _makeSet([_makeProp(id: 'a')]), ctx);
      expect(result.length, 1);
    });

    test('multiple properties produce matching count', () {
      final result = explainer.explain(_generateSet(5), ctx);
      expect(result.length, 5);
    });

    test('output ordering matches input ordering', () {
      final set = _makeSet([
        _makeProp(id: 'first',  rank: 1),
        _makeProp(id: 'second', rank: 2),
        _makeProp(id: 'third',  rank: 3),
      ]);
      final result = explainer.explain(set, ctx);
      expect(result[0].propertyId, 'first');
      expect(result[1].propertyId, 'second');
      expect(result[2].propertyId, 'third');
    });

    test('explanation count exactly matches property count', () {
      for (final n in [0, 1, 5, 10]) {
        expect(explainer.explain(_generateSet(n), ctx).length, n);
      }
    });

    test('each explanation has the correct propertyId', () {
      final props = [
        _makeProp(id: 'p1'), _makeProp(id: 'p2'), _makeProp(id: 'p3'),
      ];
      final result = explainer.explain(_makeSet(props), ctx);
      final ids    = result.explanations.map((e) => e.propertyId).toList();
      expect(ids, ['p1', 'p2', 'p3']);
    });

    test('does not modify the input FormalPropertySet', () {
      final set    = _makeSet([_makeProp(id: 'a')]);
      final before = set.length;
      explainer.explain(set, ctx);
      expect(set.length, before);
    });

    test('result is immutable — explanations list cannot be modified', () {
      final result = explainer.explain(_generateSet(3), ctx);
      expect(
        () => (result.explanations as List)
            .add(result.explanations.first),
        throwsUnsupportedError,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 13. Determinism
  // ══════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    const explainer = VerificationExplainer();
    const ctx       = ExplanationContext();

    test('same input produces identical property ids', () {
      final set = _generateSet(20);
      final r1  = explainer.explain(set, ctx);
      final r2  = explainer.explain(set, ctx);
      expect(
        r1.explanations.map((e) => e.propertyId).toList(),
        r2.explanations.map((e) => e.propertyId).toList(),
      );
    });

    test('same input produces identical confidence values', () {
      final set = _generateSet(10);
      final r1  = explainer.explain(set, ctx);
      final r2  = explainer.explain(set, ctx);
      for (var i = 0; i < r1.length; i++) {
        expect(r1[i].trace.confidence, r2[i].trace.confidence);
      }
    });

    test('different explainer instances produce equal output', () {
      final set = _generateSet(5);
      final r1  = const VerificationExplainer().explain(set, ctx);
      final r2  = const VerificationExplainer().explain(set, ctx);
      expect(
        r1.explanations.map((e) => e.propertyId).toList(),
        r2.explanations.map((e) => e.propertyId).toList(),
      );
    });

    test('formatted output is identical across runs', () {
      final prop = _makeProp(id: 'x', evidenceIds: ['e1']);
      final exp  = ExplanationBuilder.build(prop, ctx);
      final fmt1 = ExplanationFormatter.format(exp, ExplanationFormat.json);
      final fmt2 = ExplanationFormatter.format(exp, ExplanationFormat.json);
      expect(fmt1, fmt2);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 14. Negative tests
  // ══════════════════════════════════════════════════════════════════════════
  group('Negative tests', () {
    test('ExplanationBuilder throws ArgumentError for empty property id', () {
      final prop = FormalProperty(
        id: '', name: 'No Id',
        propertyType: FormalPropertyType.assertion,
        expression: '',
      );
      expect(
        () => ExplanationBuilder.build(prop, const ExplanationContext()),
        throwsArgumentError,
      );
    });

    test('VerificationExplanationSet operator[] throws RangeError out of bounds', () {
      final s = VerificationExplanationSet();
      expect(() => s[0], throwsRangeError);
    });

    test('FormalProperty with no metadata produces graceful fallback (no throw)', () {
      final prop = FormalProperty(
        id: 'bare', name: 'Bare',
        propertyType: FormalPropertyType.cover,
        expression: '',
      );
      expect(
        () => ExplanationBuilder.build(prop, const ExplanationContext()),
        returnsNormally,
      );
    });

    test('all explanation fields accessible even with missing metadata', () {
      final prop = FormalProperty(
        id: 'minimal', name: 'Minimal',
        propertyType: FormalPropertyType.safety,
        expression: '',
      );
      final exp = ExplanationBuilder.build(prop, const ExplanationContext());
      expect(exp.propertyId,              'minimal');
      expect(exp.trace.confidence,         0.0);
      expect(exp.trace.semanticEvidenceIds, isEmpty);
      expect(exp.trace.emissionReason,     isNotEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 15. Performance
  // ══════════════════════════════════════════════════════════════════════════
  group('Performance', () {
    const explainer = VerificationExplainer();
    const ctx       = ExplanationContext();

    test('100 properties explained within 200ms', () {
      final sw     = Stopwatch()..start();
      final result = explainer.explain(_generateSet(100), ctx);
      sw.stop();
      expect(result.length, 100);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('500 properties explained within 500ms', () {
      final sw     = Stopwatch()..start();
      final result = explainer.explain(_generateSet(500), ctx);
      sw.stop();
      expect(result.length, 500);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('1000 properties explained within 1000ms', () {
      final sw     = Stopwatch()..start();
      final result = explainer.explain(_generateSet(1000), ctx);
      sw.stop();
      expect(result.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('5000 properties explained within 3000ms', () {
      final sw     = Stopwatch()..start();
      final result = explainer.explain(_generateSet(5000), ctx);
      sw.stop();
      expect(result.length, 5000);
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });
  });
}
