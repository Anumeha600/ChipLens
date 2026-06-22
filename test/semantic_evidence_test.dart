import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';
import 'package:chiplens_lite/backend/property_inference/semantic/semantic.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _ePrimary = SemanticEvidence(
  id:         'clock.clk',
  category:   SemanticCategory.clock,
  confidence: 1.0,
  description: 'clk is a primary clock signal.',
);

const _eCandidate = SemanticEvidence(
  id:         'clock.gclk',
  category:   SemanticCategory.clock,
  confidence: 0.7,
  description: 'gclk is a candidate clock signal.',
);

const _eFsm = SemanticEvidence(
  id:         'fsm.state',
  category:   SemanticCategory.fsm,
  confidence: 0.95,
  description: 'State machine detected.',
  sourceProvider: 'fsm_extractor',
);

const _eCounter = SemanticEvidence(
  id:         'counter.cnt',
  category:   SemanticCategory.counter,
  confidence: 0.9,
  description: 'Counter detected.',
);

const _eReset = SemanticEvidence(
  id:         'reset.rst_n',
  category:   SemanticCategory.reset,
  confidence: 0.95,
  description: 'rst_n is an async active-low reset.',
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── SemanticCategory ──────────────────────────────────────────────────────

  group('SemanticCategory', () {
    test('all required categories exist', () {
      const expected = {
        SemanticCategory.fsm,
        SemanticCategory.counter,
        SemanticCategory.reset,
        SemanticCategory.handshake,
        SemanticCategory.clock,
        SemanticCategory.register,
        SemanticCategory.combinational,
        SemanticCategory.arithmetic,
        SemanticCategory.sequential,
        SemanticCategory.custom,
      };
      for (final cat in expected) {
        expect(SemanticCategory.values, contains(cat));
      }
    });

    test('has exactly 10 values', () {
      expect(SemanticCategory.values.length, 10);
    });

    test('each category has a unique name', () {
      final names = SemanticCategory.values.map((c) => c.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  // ── SemanticEvidence construction ─────────────────────────────────────────

  group('SemanticEvidence construction', () {
    test('required fields are stored correctly', () {
      expect(_ePrimary.id,          'clock.clk');
      expect(_ePrimary.category,    SemanticCategory.clock);
      expect(_ePrimary.confidence,  1.0);
      expect(_ePrimary.description, 'clk is a primary clock signal.');
    });

    test('sourceProvider defaults to empty string', () {
      expect(_ePrimary.sourceProvider, '');
    });

    test('metadata defaults to empty map', () {
      expect(_ePrimary.metadata, isEmpty);
    });

    test('metadata provided at construction is stored', () {
      const e = SemanticEvidence(
        id:          'fsm.state',
        category:    SemanticCategory.fsm,
        confidence:  0.9,
        description: 'test',
        metadata:    {'stateCount': 3},
      );
      expect(e.metadata['stateCount'], 3);
    });

    test('default const metadata is unmodifiable', () {
      expect(() => _ePrimary.metadata['key'] = 'v', throwsUnsupportedError);
    });

    test('toString contains id and category and confidence', () {
      final s = _ePrimary.toString();
      expect(s, contains('clock.clk'));
      expect(s, contains('clock'));
      expect(s, contains('1.0'));
    });
  });

  // ── SemanticEvidence equality ─────────────────────────────────────────────

  group('SemanticEvidence equality', () {
    test('two instances with same id are equal', () {
      const a = SemanticEvidence(
        id: 'clock.clk', category: SemanticCategory.clock,
        confidence: 1.0, description: 'primary',
      );
      const b = SemanticEvidence(
        id: 'clock.clk', category: SemanticCategory.clock,
        confidence: 1.0, description: 'primary',
      );
      expect(a, equals(b));
    });

    test('two instances with different ids are not equal', () {
      expect(_ePrimary, isNot(equals(_eCandidate)));
    });

    test('hashCode is consistent with equality', () {
      const a = SemanticEvidence(
        id: 'fsm.state', category: SemanticCategory.fsm,
        confidence: 0.9, description: 'test',
      );
      const b = SemanticEvidence(
        id: 'fsm.state', category: SemanticCategory.fsm,
        confidence: 0.9, description: 'test',
      );
      expect(a.hashCode, b.hashCode);
    });
  });

  // ── SemanticEvidence serialization ────────────────────────────────────────

  group('SemanticEvidence serialization', () {
    test('toJson includes all required fields', () {
      final j = _eFsm.toJson();
      expect(j['id'],             'fsm.state');
      expect(j['category'],       'fsm');
      expect(j['confidence'],     0.95);
      expect(j['description'],    'State machine detected.');
      expect(j['sourceProvider'], 'fsm_extractor');
    });

    test('fromJson round-trips id, category, confidence, description', () {
      final j  = _eFsm.toJson();
      final e2 = SemanticEvidence.fromJson(j);
      expect(e2.id,           _eFsm.id);
      expect(e2.category,     _eFsm.category);
      expect(e2.confidence,   _eFsm.confidence);
      expect(e2.description,  _eFsm.description);
    });

    test('metadata omitted from JSON when empty', () {
      final j = _ePrimary.toJson();
      expect(j.containsKey('metadata'), isFalse);
    });

    test('metadata included in JSON when non-empty', () {
      const e = SemanticEvidence(
        id: 't', category: SemanticCategory.counter,
        confidence: 0.9, description: 'd', metadata: {'k': 1},
      );
      expect(e.toJson()['metadata'], {'k': 1});
    });
  });

  // ── SemanticEvidenceSet construction ──────────────────────────────────────

  group('SemanticEvidenceSet construction', () {
    test('default constructor produces empty set', () {
      expect(SemanticEvidenceSet().isEmpty, isTrue);
    });

    test('constructor from list stores all items', () {
      final s = SemanticEvidenceSet([_ePrimary, _eFsm]);
      expect(s.length, 2);
    });

    test('isEmpty and isNotEmpty are consistent', () {
      final empty    = SemanticEvidenceSet();
      final nonEmpty = SemanticEvidenceSet([_ePrimary]);
      expect(empty.isEmpty,       isTrue);
      expect(empty.isNotEmpty,    isFalse);
      expect(nonEmpty.isEmpty,    isFalse);
      expect(nonEmpty.isNotEmpty, isTrue);
    });

    test('items list is unmodifiable', () {
      final s = SemanticEvidenceSet([_ePrimary]);
      expect(() => (s.items as dynamic).add(_eFsm), throwsUnsupportedError);
    });
  });

  // ── SemanticEvidenceSet add / merge ───────────────────────────────────────

  group('SemanticEvidenceSet add / merge', () {
    test('add() returns new set with item appended', () {
      final original = SemanticEvidenceSet([_ePrimary]);
      final result   = original.add(_eFsm);
      expect(result.length, 2);
      expect(result.items, contains(_ePrimary));
      expect(result.items, contains(_eFsm));
    });

    test('add() does not mutate the original set', () {
      final original = SemanticEvidenceSet([_ePrimary]);
      original.add(_eFsm);
      expect(original.length, 1);
    });

    test('merge() combines both sets', () {
      final a      = SemanticEvidenceSet([_ePrimary]);
      final b      = SemanticEvidenceSet([_eFsm, _eCounter]);
      final merged = a.merge(b);
      expect(merged.length, 3);
    });

    test('merge() does not mutate either input set', () {
      final a = SemanticEvidenceSet([_ePrimary]);
      final b = SemanticEvidenceSet([_eFsm]);
      a.merge(b);
      expect(a.length, 1);
      expect(b.length, 1);
    });

    test('merging with empty set yields a copy of the original', () {
      final a      = SemanticEvidenceSet([_ePrimary, _eFsm]);
      final merged = a.merge(SemanticEvidenceSet());
      expect(merged.length, 2);
    });

    test('merging two empty sets yields an empty set', () {
      final merged = SemanticEvidenceSet().merge(SemanticEvidenceSet());
      expect(merged.isEmpty, isTrue);
    });
  });

  // ── SemanticEvidenceSet filter / byCategory / highConfidence ──────────────

  group('SemanticEvidenceSet filter / byCategory / highConfidence', () {
    final mixed = SemanticEvidenceSet([
      _ePrimary,    // clock, 1.0
      _eCandidate,  // clock, 0.7
      _eFsm,        // fsm, 0.95
      _eCounter,    // counter, 0.9
      _eReset,      // reset, 0.95
    ]);

    test('filter() returns matching items only', () {
      final result = mixed.filter((e) => e.confidence == 1.0);
      expect(result.length, 1);
      expect(result.items.first.id, 'clock.clk');
    });

    test('filter() returning no match yields empty set', () {
      final result = mixed.filter((e) => e.category == SemanticCategory.handshake);
      expect(result.isEmpty, isTrue);
    });

    test('byCategory() returns only items of that category', () {
      final clocks = mixed.byCategory(SemanticCategory.clock);
      expect(clocks.length, 2);
      expect(clocks.items.every((e) => e.category == SemanticCategory.clock), isTrue);
    });

    test('highConfidence() with default threshold 0.8 excludes candidates', () {
      final high = mixed.highConfidence();
      expect(high.items.any((e) => e.id == 'clock.gclk'), isFalse);
      expect(high.length, 4);
    });

    test('highConfidence() with custom threshold works', () {
      final veryHigh = mixed.highConfidence(threshold: 0.96);
      expect(veryHigh.length, 1);
      expect(veryHigh.items.first.confidence, 1.0);
    });

    test('filter() does not mutate the original set', () {
      mixed.filter((e) => false);
      expect(mixed.length, 5);
    });
  });

  // ── SemanticEvidenceExtractor — empty knowledge ───────────────────────────

  group('SemanticEvidenceExtractor — empty DesignKnowledge', () {
    test('empty DesignKnowledge yields empty SemanticEvidenceSet', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge());
      expect(result.isEmpty, isTrue);
    });

    test('extract() returns a SemanticEvidenceSet', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge());
      expect(result, isA<SemanticEvidenceSet>());
    });
  });

  // ── SemanticEvidenceExtractor — clocks ────────────────────────────────────

  group('SemanticEvidenceExtractor — clocks', () {
    test('primary clock produces clock evidence with confidence 1.0', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        clocks: [ClockInfo(name: 'clk', isPrimaryClock: true)],
      ));
      final e = result.byCategory(SemanticCategory.clock).items.single;
      expect(e.confidence, 1.0);
      expect(e.id,         'clock.clk');
    });

    test('candidate clock produces clock evidence with confidence 0.7', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        clocks: [ClockInfo(name: 'gclk', isCandidate: true)],
      ));
      final e = result.byCategory(SemanticCategory.clock).items.single;
      expect(e.confidence, 0.7);
    });

    test('multiple clocks produce one evidence item each', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        clocks: [
          ClockInfo(name: 'clk', isPrimaryClock: true),
          ClockInfo(name: 'gclk', isCandidate: true),
        ],
      ));
      expect(result.byCategory(SemanticCategory.clock).length, 2);
    });

    test('clock metadata contains isPrimary and isCandidate flags', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        clocks: [ClockInfo(name: 'clk', isPrimaryClock: true)],
      ));
      final meta = result.items.first.metadata;
      expect(meta['isPrimary'],   true);
      expect(meta['isCandidate'], false);
    });
  });

  // ── SemanticEvidenceExtractor — resets ────────────────────────────────────

  group('SemanticEvidenceExtractor — resets', () {
    test('async active-low reset produces reset evidence with confidence 0.95',
        () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        resets: [ResetInfo(name: 'rst_n', isAsynchronous: true, isActiveLow: true)],
      ));
      final e = result.byCategory(SemanticCategory.reset).items.single;
      expect(e.confidence, 0.95);
      expect(e.id,         'reset.rst_n');
    });

    test('sync active-high reset produces reset evidence with confidence 0.85',
        () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        resets: [ResetInfo(name: 'rst', isSynchronous: true, isActiveHigh: true)],
      ));
      final e = result.byCategory(SemanticCategory.reset).items.single;
      expect(e.confidence, 0.85);
    });

    test('reset metadata contains polarity flags', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        resets: [ResetInfo(name: 'rst_n', isActiveLow: true)],
      ));
      final meta = result.byCategory(SemanticCategory.reset).items.first.metadata;
      expect(meta['isActiveLow'],  true);
      expect(meta['isActiveHigh'], false);
    });

    test('multiple resets produce one evidence item each', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        resets: [
          ResetInfo(name: 'rst_n', isAsynchronous: true, isActiveLow: true),
          ResetInfo(name: 'srst',  isSynchronous: true, isActiveHigh: true),
        ],
      ));
      expect(result.byCategory(SemanticCategory.reset).length, 2);
    });
  });

  // ── SemanticEvidenceExtractor — FSMs ──────────────────────────────────────

  group('SemanticEvidenceExtractor — FSMs', () {
    test('FSM with localparam encoding produces confidence 0.95', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        fsms: [FSMInfo(
          stateRegister: 'state', encodingWidth: 2,
          candidateStates: ['IDLE', 'RUN', 'DONE'], encodingStyle: 'localparam',
        )],
      ));
      final e = result.byCategory(SemanticCategory.fsm).items.single;
      expect(e.confidence, 0.95);
    });

    test('FSM with unknown encoding produces confidence 0.75', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        fsms: [FSMInfo(
          stateRegister: 'state', encodingWidth: 2,
          candidateStates: ['S0', 'S1'],
        )],
      ));
      final e = result.byCategory(SemanticCategory.fsm).items.single;
      expect(e.confidence, 0.75);
    });

    test('FSM with no candidate states produces confidence 0.5', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        fsms: [FSMInfo(stateRegister: 'unk', encodingWidth: 2)],
      ));
      final e = result.byCategory(SemanticCategory.fsm).items.single;
      expect(e.confidence, 0.5);
    });

    test('FSM metadata contains stateRegister, stateCount, encodingStyle', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        fsms: [FSMInfo(
          stateRegister: 'state', encodingWidth: 2,
          candidateStates: ['IDLE', 'RUN'], encodingStyle: 'localparam',
        )],
      ));
      final meta = result.byCategory(SemanticCategory.fsm).items.first.metadata;
      expect(meta['stateRegister'], 'state');
      expect(meta['stateCount'],    2);
      expect(meta['encodingStyle'], 'localparam');
    });
  });

  // ── SemanticEvidenceExtractor — counters ──────────────────────────────────

  group('SemanticEvidenceExtractor — counters', () {
    test('increment-only counter produces confidence 0.95', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        counters: [CounterInfo(name: 'cnt', width: 8, isIncrement: true)],
      ));
      final e = result.byCategory(SemanticCategory.counter).items.single;
      expect(e.confidence, 0.95);
    });

    test('bidirectional counter produces confidence 0.95', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        counters: [CounterInfo(name: 'bidir', width: 8, isIncrement: true, isDecrement: true)],
      ));
      final e = result.byCategory(SemanticCategory.counter).items.single;
      expect(e.confidence, 0.95);
    });

    test('decrement-only counter produces confidence 0.85', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        counters: [CounterInfo(name: 'dcnt', width: 4, isDecrement: true)],
      ));
      final e = result.byCategory(SemanticCategory.counter).items.single;
      expect(e.confidence, 0.85);
    });

    test('counter metadata contains width, isIncrement, isDecrement', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        counters: [CounterInfo(name: 'cnt', width: 8, isIncrement: true)],
      ));
      final meta = result.byCategory(SemanticCategory.counter).items.first.metadata;
      expect(meta['width'],       8);
      expect(meta['isIncrement'], true);
      expect(meta['isDecrement'], false);
    });
  });

  // ── SemanticEvidenceExtractor — registers ─────────────────────────────────

  group('SemanticEvidenceExtractor — registers', () {
    test('sequential register maps to SemanticCategory.sequential', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        registers: [RegisterInfo(name: 'data_reg', width: 8, isSequential: true)],
      ));
      expect(result.byCategory(SemanticCategory.sequential).length, 1);
    });

    test('sequential register produces confidence 0.85', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        registers: [RegisterInfo(name: 'data_reg', width: 8, isSequential: true)],
      ));
      expect(result.byCategory(SemanticCategory.sequential).items.first.confidence, 0.85);
    });

    test('combinational register maps to SemanticCategory.combinational', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        registers: [RegisterInfo(name: 'sum', width: 8, isCombinational: true)],
      ));
      expect(result.byCategory(SemanticCategory.combinational).length, 1);
    });

    test('unclassified register maps to SemanticCategory.register with confidence 0.5', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        registers: [RegisterInfo(name: 'misc', width: 1)],
      ));
      final e = result.byCategory(SemanticCategory.register).items.single;
      expect(e.confidence, 0.5);
    });
  });

  // ── SemanticEvidenceExtractor — handshakes ────────────────────────────────

  group('SemanticEvidenceExtractor — handshakes', () {
    test('valid/ready handshake produces confidence 0.95', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        handshakes: [HandshakeInfo(signals: ['valid', 'ready'], protocolHint: 'valid_ready')],
      ));
      final e = result.byCategory(SemanticCategory.handshake).items.single;
      expect(e.confidence, 0.95);
    });

    test('start/done handshake produces confidence 0.85', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        handshakes: [HandshakeInfo(signals: ['start', 'done'], protocolHint: 'start_done')],
      ));
      final e = result.byCategory(SemanticCategory.handshake).items.single;
      expect(e.confidence, 0.85);
    });

    test('unknown protocol hint produces confidence 0.5', () {
      final result = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        handshakes: [HandshakeInfo(signals: ['a', 'b'], protocolHint: 'unknown')],
      ));
      final e = result.byCategory(SemanticCategory.handshake).items.single;
      expect(e.confidence, 0.5);
    });
  });

  // ── SemanticEvidenceExtractor — confidence preservation ───────────────────

  group('confidence preservation', () {
    test('primary clock confidence 1.0 survives into SemanticEvidenceSet', () {
      final set = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        clocks: [ClockInfo(name: 'clk', isPrimaryClock: true)],
      ));
      expect(set.items.first.confidence, 1.0);
    });

    test('highConfidence() correctly excludes candidate clock (0.7)', () {
      final set = SemanticEvidenceExtractor.extract(const DesignKnowledge(
        clocks: [
          ClockInfo(name: 'clk',  isPrimaryClock: true),
          ClockInfo(name: 'gclk', isCandidate:    true),
        ],
      ));
      final high = set.highConfidence();
      expect(high.items.any((e) => e.id == 'clock.gclk'), isFalse);
      expect(high.items.any((e) => e.id == 'clock.clk'),  isTrue);
    });
  });

  // ── SemanticEvidenceExtractor — multi-domain ──────────────────────────────

  group('SemanticEvidenceExtractor — multi-domain extraction', () {
    final fullKnowledge = DesignKnowledge(
      clocks:     const [ClockInfo(name: 'clk', isPrimaryClock: true)],
      resets:     const [ResetInfo(name: 'rst_n', isAsynchronous: true, isActiveLow: true)],
      fsms:       const [FSMInfo(stateRegister: 'state', encodingWidth: 2, candidateStates: ['IDLE', 'RUN'])],
      counters:   const [CounterInfo(name: 'cnt', width: 8, isIncrement: true)],
      registers:  const [RegisterInfo(name: 'data_reg', width: 8, isSequential: true)],
      handshakes: const [HandshakeInfo(signals: ['valid', 'ready'], protocolHint: 'valid_ready')],
    );

    test('all six domains produce evidence items', () {
      final result = SemanticEvidenceExtractor.extract(fullKnowledge);
      final cats = result.items.map((e) => e.category).toSet();
      expect(cats, containsAll([
        SemanticCategory.clock,
        SemanticCategory.reset,
        SemanticCategory.fsm,
        SemanticCategory.counter,
        SemanticCategory.sequential,
        SemanticCategory.handshake,
      ]));
    });

    test('all evidence IDs are unique within the set', () {
      final result = SemanticEvidenceExtractor.extract(fullKnowledge);
      final ids = result.items.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('result can be filtered by category after full extraction', () {
      final result = SemanticEvidenceExtractor.extract(fullKnowledge);
      final fsms = result.byCategory(SemanticCategory.fsm);
      expect(fsms.length, 1);
      expect(fsms.items.first.id, 'fsm.state');
    });
  });
}
