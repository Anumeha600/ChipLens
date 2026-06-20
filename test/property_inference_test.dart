import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';
import 'package:chiplens_lite/backend/property_inference/property_inference.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _asyncLowReset = ResetInfo(
  name: 'rst_n',
  isAsynchronous: true,
  isActiveLow: true,
);

const _syncHighReset = ResetInfo(
  name: 'rst',
  isSynchronous: true,
  isActiveHigh: true,
);

const _seqReg = RegisterInfo(name: 'data_reg', width: 8, isSequential: true);
const _combReg = RegisterInfo(name: 'sum', width: 8, isCombinational: true);

const _fsmWith3States = FSMInfo(
  stateRegister: 'state',
  encodingWidth: 2,
  candidateStates: ['IDLE', 'ACTIVE', 'DONE'],
);

const _fsmOneHotCandidate = FSMInfo(
  stateRegister: 'fsm_state',
  encodingWidth: 3,
  candidateStates: ['S0', 'S1', 'S2'],
);

const _fsmNoStates = FSMInfo(
  stateRegister: 'unk_state',
  encodingWidth: 2,
);

const _incrCounter = CounterInfo(name: 'cnt', width: 8, isIncrement: true);
const _decrCounter = CounterInfo(name: 'dcnt', width: 4, isDecrement: true);
const _bidir = CounterInfo(name: 'bidcnt', width: 8, isIncrement: true, isDecrement: true);

const _validReadyHs = HandshakeInfo(
  signals: ['data_valid', 'data_ready'],
  protocolHint: 'valid_ready',
);

const _reqAckHs = HandshakeInfo(
  signals: ['bus_req', 'bus_ack'],
  protocolHint: 'req_ack',
);

const _startDoneHs = HandshakeInfo(
  signals: ['op_start', 'op_done'],
  protocolHint: 'start_done',
);

const _enableDoneHs = HandshakeInfo(
  signals: ['dma_en', 'dma_done'],
  protocolHint: 'enable_done',
);

const _primaryClk = ClockInfo(name: 'clk', isPrimaryClock: true);

final _modWithSeqOutput = ModuleInfo(
  name: 'adder',
  ports: [
    const PortInfo(name: 'a', direction: 'input', width: 8),
    const PortInfo(name: 'data_reg', direction: 'output', width: 8),
  ],
);

final _modWithCombOutput = ModuleInfo(
  name: 'comb_unit',
  ports: [
    const PortInfo(name: 'sum', direction: 'output', width: 8),
  ],
);

final _modWithUnknownOutput = ModuleInfo(
  name: 'misc',
  ports: [
    const PortInfo(name: 'out_x', direction: 'output', width: 1),
  ],
);

PropertyContext _ctx(DesignKnowledge dk) => PropertyContext(knowledge: dk);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── ResetPropertyProvider ─────────────────────────────────────────────────

  group('ResetPropertyProvider', () {
    const provider = ResetPropertyProvider();

    test('empty resets yields empty result', () async {
      final r = await provider.infer(_ctx(const DesignKnowledge()));
      expect(r.isEmpty, isTrue);
    });

    test('active-low async reset emits liveness property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(resets: [_asyncLowReset])),
      );
      final liveness = r.properties
          .where((p) => p.propertyType == FormalPropertyType.liveness)
          .toList();
      expect(liveness, hasLength(1));
      expect(liveness.first.id, contains('rst_n'));
      expect(liveness.first.expression, contains('!rst_n'));
    });

    test('active-high sync reset uses non-negated expression', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(resets: [_syncHighReset])),
      );
      final liveness = r.properties
          .where((p) => p.propertyType == FormalPropertyType.liveness)
          .toList();
      expect(liveness.first.expression, contains('rst'));
      expect(liveness.first.expression, isNot(contains('!rst')));
    });

    test('reset + sequential register emits initialise property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          registers: [_seqReg],
        )),
      );
      final init = r.properties
          .where((p) => p.id.contains('initializes'))
          .toList();
      expect(init, hasLength(1));
      expect(init.first.expression, contains('data_reg == 0'));
      expect(init.first.propertyType, FormalPropertyType.safety);
    });

    test('reset + FSM emits FSM initial-state property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          fsms: [_fsmWith3States],
        )),
      );
      final fsmProps = r.properties
          .where((p) => p.id.contains('fsm'))
          .toList();
      expect(fsmProps, hasLength(1));
      expect(fsmProps.first.expression, contains('state == IDLE'));
    });

    test('FSM with no candidate states emits no FSM property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          fsms: [_fsmNoStates],
        )),
      );
      expect(r.properties.where((p) => p.id.contains('fsm')), isEmpty);
    });

    test('reset + registers + FSM emits all three property categories', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          registers: [_seqReg],
          fsms: [_fsmWith3States],
        )),
      );
      final types = r.properties.map((p) => p.propertyType).toSet();
      expect(types, containsAll([FormalPropertyType.liveness, FormalPropertyType.safety]));
      expect(r.properties.length, greaterThanOrEqualTo(3));
    });

    test('confidence stored in metadata', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(resets: [_asyncLowReset])),
      );
      expect(r.properties.first.metadata['confidence'], isNotNull);
    });
  });

  // ── FSMPropertyProvider ───────────────────────────────────────────────────

  group('FSMPropertyProvider', () {
    const provider = FSMPropertyProvider();

    test('empty FSMs yields empty result', () async {
      final r = await provider.infer(_ctx(const DesignKnowledge()));
      expect(r.isEmpty, isTrue);
    });

    test('FSM with no candidate states emits no properties', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(fsms: [_fsmNoStates])),
      );
      expect(r.isEmpty, isTrue);
    });

    test('FSM with states emits legal-state invariant', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(fsms: [_fsmWith3States])),
      );
      final legal = r.properties
          .where((p) => p.id.contains('legal_state'))
          .toList();
      expect(legal, hasLength(1));
      expect(legal.first.propertyType, FormalPropertyType.safety);
      expect(legal.first.expression, contains('IDLE'));
      expect(legal.first.expression, contains('ACTIVE'));
      expect(legal.first.expression, contains('DONE'));
    });

    test('FSM emits cover property per candidate state', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(fsms: [_fsmWith3States])),
      );
      final covers = r.properties
          .where((p) => p.propertyType == FormalPropertyType.cover)
          .toList();
      expect(covers, hasLength(3));
      final covered = covers.map((p) => p.metadata['state'] as String).toSet();
      expect(covered, containsAll(['IDLE', 'ACTIVE', 'DONE']));
    });

    test('one-hot candidate emitted when encodingWidth == state count', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(fsms: [_fsmOneHotCandidate])),
      );
      final oneHot = r.properties
          .where((p) => p.id.contains('one_hot_candidate'))
          .toList();
      expect(oneHot, hasLength(1));
      expect(oneHot.first.propertyType, FormalPropertyType.invariant);
    });

    test('no one-hot candidate when encodingWidth != state count', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(fsms: [_fsmWith3States])),
      );
      expect(
        r.properties.where((p) => p.id.contains('one_hot_candidate')),
        isEmpty,
      );
    });

    test('multiple FSMs produce independent property sets', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(
          fsms: [_fsmWith3States, _fsmOneHotCandidate],
        )),
      );
      final legalProps = r.properties
          .where((p) => p.id.contains('legal_state'))
          .toList();
      expect(legalProps, hasLength(2));
    });
  });

  // ── CounterPropertyProvider ───────────────────────────────────────────────

  group('CounterPropertyProvider', () {
    const provider = CounterPropertyProvider();

    test('empty counters yields empty result', () async {
      final r = await provider.infer(_ctx(const DesignKnowledge()));
      expect(r.isEmpty, isTrue);
    });

    test('increment-only counter emits bounds + monotonic, no wraparound', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(counters: [_incrCounter])),
      );
      expect(r.properties.any((p) => p.id.contains('bounds')), isTrue);
      expect(r.properties.any((p) => p.id.contains('monotonic')), isTrue);
      expect(r.properties.any((p) => p.id.contains('wraparound')), isFalse);
    });

    test('decrement-only counter emits bounds only', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(counters: [_decrCounter])),
      );
      expect(r.properties.length, 1);
      expect(r.properties.first.id, contains('bounds'));
    });

    test('bidirectional counter emits bounds + wraparound, no monotonic', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(counters: [_bidir])),
      );
      expect(r.properties.any((p) => p.id.contains('bounds')), isTrue);
      expect(r.properties.any((p) => p.id.contains('wraparound')), isTrue);
      expect(r.properties.any((p) => p.id.contains('monotonic')), isFalse);
    });

    test('8-bit counter bounds expression uses maxVal 255', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(counters: [_incrCounter])),
      );
      final bounds = r.properties.firstWhere((p) => p.id.contains('bounds'));
      expect(bounds.metadata['maxVal'], 255);
    });

    test('multiple counters produce independent bound properties', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(counters: [_incrCounter, _decrCounter])),
      );
      final bounds = r.properties.where((p) => p.id.contains('bounds')).toList();
      expect(bounds, hasLength(2));
    });
  });

  // ── HandshakePropertyProvider ─────────────────────────────────────────────

  group('HandshakePropertyProvider', () {
    const provider = HandshakePropertyProvider();

    test('empty handshakes yields empty result', () async {
      final r = await provider.infer(_ctx(const DesignKnowledge()));
      expect(r.isEmpty, isTrue);
    });

    test('valid/ready emits assertion stability property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(handshakes: [_validReadyHs])),
      );
      expect(r.properties, hasLength(1));
      expect(r.properties.first.propertyType, FormalPropertyType.assertion);
      expect(r.properties.first.expression, contains('data_valid'));
      expect(r.properties.first.expression, contains('data_ready'));
    });

    test('req/ack emits assertion stability property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(handshakes: [_reqAckHs])),
      );
      expect(r.properties, hasLength(1));
      expect(r.properties.first.propertyType, FormalPropertyType.assertion);
      expect(r.properties.first.expression, contains('bus_req'));
    });

    test('start/done emits liveness completion property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(handshakes: [_startDoneHs])),
      );
      expect(r.properties, hasLength(1));
      expect(r.properties.first.propertyType, FormalPropertyType.liveness);
      expect(r.properties.first.expression, contains('eventually'));
    });

    test('enable/done emits assertion stability property', () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(handshakes: [_enableDoneHs])),
      );
      expect(r.properties, hasLength(1));
      expect(r.properties.first.propertyType, FormalPropertyType.assertion);
    });

    test('unknown protocol hint produces no property', () async {
      const unknown = HandshakeInfo(signals: ['a', 'b'], protocolHint: 'unknown');
      final r = await provider.infer(
        _ctx(const DesignKnowledge(handshakes: [unknown])),
      );
      expect(r.isEmpty, isTrue);
    });
  });

  // ── SafetyPropertyProvider ────────────────────────────────────────────────

  group('SafetyPropertyProvider', () {
    const provider = SafetyPropertyProvider();

    test('empty knowledge yields empty result', () async {
      final r = await provider.infer(_ctx(const DesignKnowledge()));
      expect(r.isEmpty, isTrue);
    });

    test('module with sequential output emits stable property', () async {
      final r = await provider.infer(
        _ctx(DesignKnowledge(
          modules: [_modWithSeqOutput],
          registers: [_seqReg],
        )),
      );
      expect(r.properties, hasLength(1));
      final p = r.properties.first;
      expect(p.id, contains('stable'));
      expect(p.propertyType, FormalPropertyType.safety);
      expect(p.metadata['type'], 'registered');
    });

    test('module with combinational output emits defined property', () async {
      final r = await provider.infer(
        _ctx(DesignKnowledge(
          modules: [_modWithCombOutput],
          registers: [_combReg],
        )),
      );
      expect(r.properties, hasLength(1));
      expect(r.properties.first.metadata['type'], 'combinational');
    });

    test('module output not in registers emits generic defined property', () async {
      final r = await provider.infer(
        _ctx(DesignKnowledge(modules: [_modWithUnknownOutput])),
      );
      expect(r.properties, hasLength(1));
      expect(r.properties.first.expression, contains('isunknown'));
    });

    test('no modules with sequential registers emits fallback stable properties',
        () async {
      final r = await provider.infer(
        _ctx(const DesignKnowledge(registers: [_seqReg])),
      );
      expect(r.properties, hasLength(1));
      expect(r.properties.first.id, contains('data_reg'));
    });

    test('primary clock name used in stable expression when available', () async {
      final r = await provider.infer(
        _ctx(DesignKnowledge(
          clocks: [_primaryClk],
          modules: [_modWithSeqOutput],
          registers: [_seqReg],
        )),
      );
      expect(r.properties.first.expression, contains('clk'));
    });
  });

  // ── PropertyRunner orchestration ──────────────────────────────────────────

  group('PropertyRunner orchestration', () {
    test('returns FormalPropertySet', () async {
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          counters: [_incrCounter],
        )),
      );
      expect(set, isA<FormalPropertySet>());
    });

    test('all default providers run — properties from multiple domains merged',
        () async {
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          fsms: [_fsmWith3States],
          counters: [_incrCounter],
          handshakes: [_validReadyHs],
        )),
      );
      expect(set.isNotEmpty, isTrue);
      final types = set.properties.map((p) => p.propertyType).toSet();
      expect(
        types,
        containsAll([
          FormalPropertyType.liveness,
          FormalPropertyType.safety,
          FormalPropertyType.cover,
          FormalPropertyType.assertion,
        ]),
      );
    });

    test('failing provider is swallowed — others still contribute', () async {
      final failing = _FailingProvider();
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge(counters: [_incrCounter])),
        providers: [const CounterPropertyProvider(), failing],
      );
      expect(set.isNotEmpty, isTrue);
    });

    test('empty provider list returns empty FormalPropertySet', () async {
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge(resets: [_asyncLowReset])),
        providers: [],
      );
      expect(set.isEmpty, isTrue);
    });

    test('merged set has all unique IDs', () async {
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          fsms: [_fsmWith3States],
          counters: [_incrCounter],
          handshakes: [_validReadyHs],
        )),
      );
      final ids = set.properties.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  // ── Provider independence ─────────────────────────────────────────────────

  group('Provider independence', () {
    test('all providers have unique providerKey', () {
      final providers = <PropertyProvider>[
        const ResetPropertyProvider(),
        const FSMPropertyProvider(),
        const CounterPropertyProvider(),
        const HandshakePropertyProvider(),
        const SafetyPropertyProvider(),
      ];
      final keys = providers.map((p) => p.providerKey).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('ResetPropertyProvider result contains no FSM-keyed IDs', () async {
      final r = await const ResetPropertyProvider().infer(
        _ctx(const DesignKnowledge(resets: [_asyncLowReset])),
      );
      expect(r.properties.every((p) => !p.id.startsWith(PropertyIdPrefix.fsm)),
          isTrue);
    });

    test('FSMPropertyProvider result contains no counter-keyed IDs', () async {
      final r = await const FSMPropertyProvider().infer(
        _ctx(const DesignKnowledge(fsms: [_fsmWith3States])),
      );
      expect(
        r.properties.every((p) => !p.id.startsWith(PropertyIdPrefix.counter)),
        isTrue,
      );
    });

    test('CounterPropertyProvider result contains no handshake-keyed IDs', () async {
      final r = await const CounterPropertyProvider().infer(
        _ctx(const DesignKnowledge(counters: [_incrCounter])),
      );
      expect(
        r.properties.every((p) => !p.id.startsWith(PropertyIdPrefix.handshake)),
        isTrue,
      );
    });
  });

  // ── Property merging ──────────────────────────────────────────────────────

  group('Property merging', () {
    test('FormalPropertySet can be filtered by type after merge', () async {
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          fsms: [_fsmWith3States],
        )),
      );
      final safetySet = set.byType(FormalPropertyType.safety);
      expect(safetySet.properties.every(
        (p) => p.propertyType == FormalPropertyType.safety,
      ), isTrue);
    });

    test('reset + counter merge yields properties from both providers', () async {
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge(
          resets: [_asyncLowReset],
          counters: [_incrCounter],
        )),
        providers: [
          const ResetPropertyProvider(),
          const CounterPropertyProvider(),
        ],
      );
      expect(set.properties.any((p) => p.id.startsWith(PropertyIdPrefix.reset)),
          isTrue);
      expect(set.properties.any((p) => p.id.startsWith(PropertyIdPrefix.counter)),
          isTrue);
    });

    test('PropertyResult.empty contributes nothing to merged set', () async {
      final set = await PropertyRunner.infer(
        _ctx(const DesignKnowledge()),
        providers: [const ResetPropertyProvider()],
      );
      expect(set.isEmpty, isTrue);
    });
  });
}

// ─── Test doubles ─────────────────────────────────────────────────────────────

class _FailingProvider implements PropertyProvider {
  @override
  String get providerKey => 'failing';

  @override
  Future<PropertyResult> infer(PropertyContext context) =>
      throw Exception('deliberate failure for test');
}
