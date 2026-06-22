import 'package:chiplens_lite/backend/property_inference/semantic/semantic.dart';
import 'package:chiplens_lite/backend/property_inference/synthesizer/synthesizer.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

// FSM evidence — 3 states, localparam encoded
final _fsmEvidence = SemanticEvidence(
  id:             'fsm.state',
  category:       SemanticCategory.fsm,
  confidence:     0.95,
  description:    'State machine detected.',
  sourceProvider: 'fsm_extractor',
  metadata: {
    'stateRegister':  'state',
    'encodingWidth':  2,
    'stateCount':     3,
    'encodingStyle':  'localparam',
    'candidateStates': ['IDLE', 'ACTIVE', 'DONE'],
  },
);

// FSM evidence — one-hot candidate (encodingWidth == stateCount)
final _fsmOneHot = SemanticEvidence(
  id:             'fsm.ctrl',
  category:       SemanticCategory.fsm,
  confidence:     0.9,
  description:    'One-hot FSM.',
  sourceProvider: 'fsm_extractor',
  metadata: {
    'stateRegister':  'ctrl',
    'encodingWidth':  3,
    'stateCount':     3,
    'encodingStyle':  'localparam',
    'candidateStates': ['S0', 'S1', 'S2'],
  },
);

// FSM evidence — no candidate states
final _fsmEmpty = SemanticEvidence(
  id:             'fsm.unk',
  category:       SemanticCategory.fsm,
  confidence:     0.5,
  description:    'FSM with no states.',
  sourceProvider: 'fsm_extractor',
  metadata: {
    'stateRegister':  'unk',
    'encodingWidth':  2,
    'stateCount':     0,
    'candidateStates': <String>[],
  },
);

// Counter evidence — increment only
final _counterIncr = SemanticEvidence(
  id:             'counter.cnt',
  category:       SemanticCategory.counter,
  confidence:     0.95,
  description:    'Increment counter.',
  sourceProvider: 'counter_extractor',
  metadata: {
    'counter':     'cnt',
    'width':       8,
    'isIncrement': true,
    'isDecrement': false,
  },
);

// Counter evidence — bidirectional
final _counterBidir = SemanticEvidence(
  id:             'counter.bidir',
  category:       SemanticCategory.counter,
  confidence:     0.9,
  description:    'Bidirectional counter.',
  sourceProvider: 'counter_extractor',
  metadata: {
    'counter':     'bidir',
    'width':       8,
    'isIncrement': true,
    'isDecrement': true,
  },
);

// Counter evidence — decrement only
final _counterDecr = SemanticEvidence(
  id:             'counter.dcnt',
  category:       SemanticCategory.counter,
  confidence:     0.85,
  description:    'Decrement counter.',
  sourceProvider: 'counter_extractor',
  metadata: {
    'counter':     'dcnt',
    'width':       4,
    'isIncrement': false,
    'isDecrement': true,
  },
);

// Reset evidence — async active-low
final _resetAsync = SemanticEvidence(
  id:             'reset.rst_n',
  category:       SemanticCategory.reset,
  confidence:     0.95,
  description:    'Async reset.',
  sourceProvider: 'reset_extractor',
  metadata: {
    'signal':        'rst_n',
    'isAsynchronous': true,
    'isSynchronous':  false,
    'isActiveLow':    true,
    'isActiveHigh':   false,
  },
);

// Reset evidence — sync active-high
final _resetSync = SemanticEvidence(
  id:             'reset.rst',
  category:       SemanticCategory.reset,
  confidence:     0.85,
  description:    'Sync reset.',
  sourceProvider: 'reset_extractor',
  metadata: {
    'signal':        'rst',
    'isAsynchronous': false,
    'isSynchronous':  true,
    'isActiveLow':    false,
    'isActiveHigh':   true,
  },
);

// Handshake evidence — valid/ready
final _handshakeVR = SemanticEvidence(
  id:             'handshake.valid_ready.valid_ready',
  category:       SemanticCategory.handshake,
  confidence:     0.95,
  description:    'Valid/ready pair.',
  sourceProvider: 'handshake_extractor',
  metadata: {
    'protocolHint': 'valid_ready',
    'signals':      ['valid', 'ready'],
  },
);

// Handshake evidence — req/ack
final _handshakeRA = SemanticEvidence(
  id:             'handshake.req_ack.req_ack',
  category:       SemanticCategory.handshake,
  confidence:     0.95,
  description:    'Req/ack pair.',
  sourceProvider: 'handshake_extractor',
  metadata: {
    'protocolHint': 'req_ack',
    'signals':      ['req', 'ack'],
  },
);

// Register evidence — sequential
final _seqReg = SemanticEvidence(
  id:             'register.data_reg',
  category:       SemanticCategory.sequential,
  confidence:     0.85,
  description:    'Sequential register.',
  sourceProvider: 'register_extractor',
  metadata: {
    'register':        'data_reg',
    'width':           8,
    'isSequential':    true,
    'isCombinational': false,
  },
);

// Register evidence — combinational
final _combReg = SemanticEvidence(
  id:             'register.sum',
  category:       SemanticCategory.combinational,
  confidence:     0.8,
  description:    'Combinational signal.',
  sourceProvider: 'register_extractor',
  metadata: {
    'register':        'sum',
    'width':           8,
    'isSequential':    false,
    'isCombinational': true,
  },
);

// Clock evidence — not handled by any current rule
const _clockEvidence = SemanticEvidence(
  id:          'clock.clk',
  category:    SemanticCategory.clock,
  confidence:  1.0,
  description: 'Primary clock.',
);

SemanticEvidenceSet _set(List<SemanticEvidence> items) =>
    SemanticEvidenceSet(items);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── CandidatePropertyType ─────────────────────────────────────────────────

  group('CandidatePropertyType', () {
    test('all required values exist', () {
      const expected = {
        CandidatePropertyType.safetyInvariant,
        CandidatePropertyType.livenessCondition,
        CandidatePropertyType.reachability,
        CandidatePropertyType.stability,
        CandidatePropertyType.boundedness,
        CandidatePropertyType.assumption,
        CandidatePropertyType.custom,
      };
      for (final t in expected) {
        expect(CandidatePropertyType.values, contains(t));
      }
    });

    test('all names are unique', () {
      final names = CandidatePropertyType.values.map((t) => t.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  // ── CandidateProperty ─────────────────────────────────────────────────────

  group('CandidateProperty', () {
    const p = CandidateProperty(
      id:           'test.prop',
      title:        'Test property',
      description:  'A test.',
      propertyType: CandidatePropertyType.safetyInvariant,
      rationale:    'Because tests.',
    );

    test('required fields stored correctly', () {
      expect(p.id,           'test.prop');
      expect(p.title,        'Test property');
      expect(p.propertyType, CandidatePropertyType.safetyInvariant);
      expect(p.rationale,    'Because tests.');
    });

    test('expression is null by default', () {
      expect(p.expression, isNull);
    });

    test('evidenceIds defaults to empty list', () {
      expect(p.evidenceIds, isEmpty);
    });

    test('metadata defaults to empty map', () {
      expect(p.metadata, isEmpty);
    });

    test('equality is based on id', () {
      const a = CandidateProperty(
        id: 'x', title: 'A', description: '', propertyType: CandidatePropertyType.custom, rationale: 'r',
      );
      const b = CandidateProperty(
        id: 'x', title: 'B', description: '', propertyType: CandidatePropertyType.custom, rationale: 's',
      );
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      const a = CandidateProperty(id: 'a', title: '', description: '', propertyType: CandidatePropertyType.custom, rationale: '');
      const b = CandidateProperty(id: 'b', title: '', description: '', propertyType: CandidatePropertyType.custom, rationale: '');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = CandidateProperty(id: 'z', title: '', description: '', propertyType: CandidatePropertyType.custom, rationale: '');
      const b = CandidateProperty(id: 'z', title: '', description: '', propertyType: CandidatePropertyType.custom, rationale: '');
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains id and propertyType', () {
      expect(p.toString(), contains('test.prop'));
      expect(p.toString(), contains('safetyInvariant'));
    });
  });

  // ── CandidatePropertySet ──────────────────────────────────────────────────

  group('CandidatePropertySet', () {
    const pA = CandidateProperty(id: 'a', title: '', description: '', propertyType: CandidatePropertyType.safetyInvariant, rationale: '');
    const pB = CandidateProperty(id: 'b', title: '', description: '', propertyType: CandidatePropertyType.livenessCondition, rationale: '');
    const pC = CandidateProperty(id: 'c', title: '', description: '', propertyType: CandidatePropertyType.reachability, rationale: '');

    test('default constructor produces empty set', () {
      expect(CandidatePropertySet().isEmpty, isTrue);
    });

    test('items list is unmodifiable', () {
      final s = CandidatePropertySet([pA]);
      expect(() => (s.items as dynamic).add(pB), throwsUnsupportedError);
    });

    test('add() returns new set without mutating original', () {
      final original = CandidatePropertySet([pA]);
      final result   = original.add(pB);
      expect(original.length, 1);
      expect(result.length,   2);
    });

    test('merge() combines both sets without mutating either', () {
      final s1 = CandidatePropertySet([pA]);
      final s2 = CandidatePropertySet([pB, pC]);
      final merged = s1.merge(s2);
      expect(s1.length,     1);
      expect(s2.length,     2);
      expect(merged.length, 3);
    });

    test('filter() returns only matching items', () {
      final s = CandidatePropertySet([pA, pB, pC]);
      final result = s.filter((p) => p.propertyType == CandidatePropertyType.safetyInvariant);
      expect(result.length, 1);
      expect(result.items.first.id, 'a');
    });

    test('byType() filters by CandidatePropertyType', () {
      final s = CandidatePropertySet([pA, pB, pC]);
      expect(s.byType(CandidatePropertyType.reachability).length, 1);
    });

    test('sort() returns new set ordered by comparator', () {
      final s      = CandidatePropertySet([pC, pA, pB]);
      final sorted = s.sort((x, y) => x.id.compareTo(y.id));
      expect(sorted.items.map((p) => p.id).toList(), ['a', 'b', 'c']);
    });

    test('sort() does not mutate original', () {
      final s = CandidatePropertySet([pC, pA, pB]);
      s.sort((x, y) => x.id.compareTo(y.id));
      expect(s.items.first.id, 'c');
    });

    test('deduplicate() keeps first occurrence of each id', () {
      const dup = CandidateProperty(id: 'a', title: 'dup', description: '', propertyType: CandidatePropertyType.custom, rationale: '');
      final s   = CandidatePropertySet([pA, pB, dup]);
      final d   = s.deduplicate();
      expect(d.length, 2);
      expect(d.items.first.title, '');  // original pA, not dup
    });

    test('deduplicate() on set with no duplicates returns equivalent set', () {
      final s = CandidatePropertySet([pA, pB, pC]);
      expect(s.deduplicate().length, 3);
    });
  });

  // ── FSMRule ───────────────────────────────────────────────────────────────

  group('FSMRule', () {
    const rule = FSMRule();

    test('appliesTo returns true for fsm category', () {
      expect(rule.appliesTo(_fsmEvidence), isTrue);
    });

    test('appliesTo returns false for counter category', () {
      expect(rule.appliesTo(_counterIncr), isFalse);
    });

    test('FSM with no candidate states produces no properties', () {
      expect(rule.synthesize(_fsmEmpty), isEmpty);
    });

    test('synthesizes legal-state invariant', () {
      final props = rule.synthesize(_fsmEvidence);
      final legal = props.where((p) => p.id.contains('legal_state')).toList();
      expect(legal, hasLength(1));
      expect(legal.first.propertyType, CandidatePropertyType.safetyInvariant);
      expect(legal.first.rationale, contains('IDLE'));
      expect(legal.first.rationale, contains('ACTIVE'));
      expect(legal.first.rationale, contains('DONE'));
    });

    test('synthesizes one reachability property per candidate state', () {
      final props    = rule.synthesize(_fsmEvidence);
      final reach    = props.where((p) => p.propertyType == CandidatePropertyType.reachability).toList();
      final covered  = reach.map((p) => p.metadata['state'] as String).toSet();
      expect(reach,   hasLength(3));
      expect(covered, containsAll(['IDLE', 'ACTIVE', 'DONE']));
    });

    test('no one-hot property when encodingWidth != stateCount', () {
      final props = rule.synthesize(_fsmEvidence); // 2-bit encoding, 3 states
      expect(props.any((p) => p.id.contains('one_hot')), isFalse);
    });

    test('one-hot property emitted when encodingWidth == stateCount', () {
      final props = rule.synthesize(_fsmOneHot); // 3-bit encoding, 3 states
      expect(props.any((p) => p.id.contains('one_hot')), isTrue);
    });

    test('all emitted property evidenceIds reference the input evidence id', () {
      final props = rule.synthesize(_fsmEvidence);
      expect(props.every((p) => p.evidenceIds.contains('fsm.state')), isTrue);
    });
  });

  // ── CounterRule ───────────────────────────────────────────────────────────

  group('CounterRule', () {
    const rule = CounterRule();

    test('appliesTo returns true for counter category', () {
      expect(rule.appliesTo(_counterIncr), isTrue);
    });

    test('appliesTo returns false for reset category', () {
      expect(rule.appliesTo(_resetAsync), isFalse);
    });

    test('increment-only counter: bounds + monotonic, no wraparound', () {
      final props = rule.synthesize(_counterIncr);
      expect(props.any((p) => p.id.contains('bounds')),     isTrue);
      expect(props.any((p) => p.id.contains('monotonic')),  isTrue);
      expect(props.any((p) => p.id.contains('wraparound')), isFalse);
    });

    test('decrement-only counter: bounds only', () {
      final props = rule.synthesize(_counterDecr);
      expect(props.length,                                  1);
      expect(props.first.id,                                contains('bounds'));
    });

    test('bidirectional counter: bounds + wraparound, no monotonic', () {
      final props = rule.synthesize(_counterBidir);
      expect(props.any((p) => p.id.contains('bounds')),     isTrue);
      expect(props.any((p) => p.id.contains('wraparound')), isTrue);
      expect(props.any((p) => p.id.contains('monotonic')),  isFalse);
    });

    test('bounds rationale mentions maxVal (255 for 8-bit)', () {
      final props  = rule.synthesize(_counterIncr);
      final bounds = props.firstWhere((p) => p.id.contains('bounds'));
      expect(bounds.rationale, contains('255'));
      expect(bounds.metadata['maxVal'], 255);
    });
  });

  // ── ResetRule ─────────────────────────────────────────────────────────────

  group('ResetRule', () {
    const rule = ResetRule();

    test('appliesTo returns true for reset category', () {
      expect(rule.appliesTo(_resetAsync), isTrue);
    });

    test('appliesTo returns false for handshake category', () {
      expect(rule.appliesTo(_handshakeVR), isFalse);
    });

    test('synthesizes liveness property', () {
      final props    = rule.synthesize(_resetAsync);
      final liveness = props.where((p) => p.propertyType == CandidatePropertyType.livenessCondition).toList();
      expect(liveness, hasLength(1));
      expect(liveness.first.id, contains('releases'));
    });

    test('synthesizes polarity assumption', () {
      final props     = rule.synthesize(_resetAsync);
      final assumption = props.where((p) => p.propertyType == CandidatePropertyType.assumption).toList();
      expect(assumption, hasLength(1));
      expect(assumption.first.id, contains('polarity'));
    });

    test('rationale of async active-low reset mentions kind and polarity', () {
      final props = rule.synthesize(_resetAsync);
      expect(props.every((p) =>
          p.rationale.contains('asynchronous') || p.rationale.contains('active-low')),
        isTrue,
      );
    });

    test('sync reset rationale differs from async', () {
      final asyncProps = rule.synthesize(_resetAsync);
      final syncProps  = rule.synthesize(_resetSync);
      expect(
        asyncProps.first.rationale,
        isNot(equals(syncProps.first.rationale)),
      );
    });
  });

  // ── HandshakeRule ─────────────────────────────────────────────────────────

  group('HandshakeRule', () {
    const rule = HandshakeRule();

    test('appliesTo returns true for handshake category', () {
      expect(rule.appliesTo(_handshakeVR), isTrue);
    });

    test('appliesTo returns false for sequential category', () {
      expect(rule.appliesTo(_seqReg), isFalse);
    });

    test('synthesizes stability property for valid/ready', () {
      final props   = rule.synthesize(_handshakeVR);
      final stability = props.where((p) => p.propertyType == CandidatePropertyType.stability).toList();
      expect(stability, hasLength(1));
      expect(stability.first.id, contains('stability'));
    });

    test('synthesizes liveness completion property', () {
      final props    = rule.synthesize(_handshakeVR);
      final liveness = props.where((p) => p.propertyType == CandidatePropertyType.livenessCondition).toList();
      expect(liveness, hasLength(1));
      expect(liveness.first.id, contains('completion'));
    });

    test('req/ack generates equivalent structure to valid/ready', () {
      final vr   = rule.synthesize(_handshakeVR);
      final ra   = rule.synthesize(_handshakeRA);
      final vrTypes = vr.map((p) => p.propertyType).toSet();
      final raTypes = ra.map((p) => p.propertyType).toSet();
      expect(vrTypes, equals(raTypes));
    });

    test('rationale includes signal names', () {
      final props = rule.synthesize(_handshakeVR);
      expect(props.any((p) => p.rationale.contains('valid')), isTrue);
    });
  });

  // ── RegisterRule ──────────────────────────────────────────────────────────

  group('RegisterRule', () {
    const rule = RegisterRule();

    test('appliesTo returns true for sequential category', () {
      expect(rule.appliesTo(_seqReg), isTrue);
    });

    test('appliesTo returns true for combinational category', () {
      expect(rule.appliesTo(_combReg), isTrue);
    });

    test('appliesTo returns false for fsm category', () {
      expect(rule.appliesTo(_fsmEvidence), isFalse);
    });

    test('sequential register produces stability property', () {
      final props = rule.synthesize(_seqReg);
      expect(props, hasLength(1));
      expect(props.first.propertyType, CandidatePropertyType.stability);
    });

    test('combinational register produces safetyInvariant property', () {
      final props = rule.synthesize(_combReg);
      expect(props, hasLength(1));
      expect(props.first.propertyType, CandidatePropertyType.safetyInvariant);
    });
  });

  // ── PropertySynthesizer ───────────────────────────────────────────────────

  group('PropertySynthesizer', () {
    test('empty evidence produces empty CandidatePropertySet', () {
      final result = PropertySynthesizer.synthesize(SemanticEvidenceSet());
      expect(result.isEmpty, isTrue);
    });

    test('returns CandidatePropertySet', () {
      final result = PropertySynthesizer.synthesize(SemanticEvidenceSet());
      expect(result, isA<CandidatePropertySet>());
    });

    test('single FSM evidence produces FSM properties', () {
      final result = PropertySynthesizer.synthesize(_set([_fsmEvidence]));
      expect(result.isNotEmpty, isTrue);
      expect(result.items.any((p) => p.id.contains('legal_state')), isTrue);
    });

    test('single counter evidence produces counter properties', () {
      final result = PropertySynthesizer.synthesize(_set([_counterIncr]));
      expect(result.items.any((p) => p.id.contains('bounds')), isTrue);
    });

    test('multiple evidence items produce properties from all applicable rules', () {
      final result = PropertySynthesizer.synthesize(_set([
        _fsmEvidence,
        _counterIncr,
        _resetAsync,
        _handshakeVR,
        _seqReg,
      ]));
      final types = result.items.map((p) => p.propertyType).toSet();
      expect(types, containsAll([
        CandidatePropertyType.safetyInvariant,
        CandidatePropertyType.livenessCondition,
        CandidatePropertyType.reachability,
        CandidatePropertyType.boundedness,
        CandidatePropertyType.stability,
        CandidatePropertyType.assumption,
      ]));
    });

    test('evidence with no applicable rule produces no properties', () {
      final result = PropertySynthesizer.synthesize(_set([_clockEvidence]));
      expect(result.isEmpty, isTrue);
    });

    test('output is deterministic — same input produces same result twice', () {
      final evidence = _set([_fsmEvidence, _counterIncr]);
      final r1 = PropertySynthesizer.synthesize(evidence);
      final r2 = PropertySynthesizer.synthesize(evidence);
      expect(
        r1.items.map((p) => p.id).toList(),
        r2.items.map((p) => p.id).toList(),
      );
    });

    test('deduplicate applied — no duplicate IDs in output', () {
      final result = PropertySynthesizer.synthesize(_set([
        _fsmEvidence, _counterIncr, _resetAsync, _handshakeVR, _seqReg,
      ]));
      final ids = result.items.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('custom rule list restricts synthesis to those rules', () {
      final result = PropertySynthesizer.synthesize(
        _set([_fsmEvidence, _counterIncr]),
        rules: [const CounterRule()],
      );
      expect(result.items.any((p) => p.id.startsWith('synth.fsm')),     isFalse);
      expect(result.items.any((p) => p.id.startsWith('synth.counter')), isTrue);
    });

    test('empty rule list produces empty set regardless of evidence', () {
      final result = PropertySynthesizer.synthesize(
        _set([_fsmEvidence, _counterIncr, _resetAsync]),
        rules: [],
      );
      expect(result.isEmpty, isTrue);
    });
  });

  // ── Rule isolation ────────────────────────────────────────────────────────

  group('Rule isolation', () {
    test('FSMRule does not fire on counter evidence', () {
      expect(const FSMRule().appliesTo(_counterIncr), isFalse);
    });

    test('CounterRule does not fire on reset evidence', () {
      expect(const CounterRule().appliesTo(_resetAsync), isFalse);
    });

    test('ResetRule does not fire on handshake evidence', () {
      expect(const ResetRule().appliesTo(_handshakeVR), isFalse);
    });

    test('HandshakeRule does not fire on register evidence', () {
      expect(const HandshakeRule().appliesTo(_seqReg), isFalse);
    });

    test('RegisterRule does not fire on FSM evidence', () {
      expect(const RegisterRule().appliesTo(_fsmEvidence), isFalse);
    });
  });

  // ── Rationale generation ──────────────────────────────────────────────────

  group('Rationale generation', () {
    test('FSM legal-state rationale names all candidate states', () {
      final props = const FSMRule().synthesize(_fsmEvidence);
      final legal = props.firstWhere((p) => p.id.contains('legal_state'));
      expect(legal.rationale, contains('IDLE'));
      expect(legal.rationale, contains('ACTIVE'));
      expect(legal.rationale, contains('DONE'));
    });

    test('counter bounds rationale names the maxVal', () {
      final props  = const CounterRule().synthesize(_counterIncr);
      final bounds = props.firstWhere((p) => p.id.contains('bounds'));
      expect(bounds.rationale, contains('255'));
    });

    test('reset rationale distinguishes async from sync', () {
      final async = const ResetRule().synthesize(_resetAsync);
      final sync  = const ResetRule().synthesize(_resetSync);
      expect(async.first.rationale, contains('asynchronous'));
      expect(sync.first.rationale,  contains('synchronous'));
    });

    test('handshake completion rationale names the protocol hint', () {
      final props      = const HandshakeRule().synthesize(_handshakeVR);
      final completion = props.firstWhere((p) => p.id.contains('completion'));
      expect(completion.rationale, contains('valid_ready'));
    });

    test('all synthesized properties have non-empty rationale', () {
      final result = PropertySynthesizer.synthesize(_set([
        _fsmEvidence, _counterIncr, _resetAsync, _handshakeVR, _seqReg,
      ]));
      expect(
        result.items.every((p) => p.rationale.isNotEmpty),
        isTrue,
      );
    });
  });

  // ── Extensibility ─────────────────────────────────────────────────────────

  group('Extensibility', () {
    test('custom SynthesisRule can be injected into PropertySynthesizer', () {
      final result = PropertySynthesizer.synthesize(
        _set([_clockEvidence]),
        rules: [_ClockTestRule()],
      );
      expect(result.items, hasLength(1));
      expect(result.items.first.id, 'synth.clock.clk.test');
    });

    test('custom rule does not affect output when its evidence category is absent', () {
      final result = PropertySynthesizer.synthesize(
        _set([_fsmEvidence]),
        rules: [_ClockTestRule()],
      );
      expect(result.isEmpty, isTrue);
    });
  });
}

// ─── Test doubles ─────────────────────────────────────────────────────────────

class _ClockTestRule implements SynthesisRule {
  @override
  bool appliesTo(SemanticEvidence evidence) =>
      evidence.category == SemanticCategory.clock;

  @override
  List<CandidateProperty> synthesize(SemanticEvidence evidence) => [
        CandidateProperty(
          id:           'synth.clock.${evidence.metadata['signal'] ?? evidence.id.split('.').last}.test',
          title:        'Clock test property',
          description:  'Test property from custom rule.',
          propertyType: CandidatePropertyType.custom,
          evidenceIds:  [evidence.id],
          rationale:    'Generated by test rule.',
        ),
      ];
}
