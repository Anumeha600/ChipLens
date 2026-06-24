import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// ── Fixture helper ─────────────────────────────────────────────────────────────

String _fixture(String name) =>
    File('test/fixtures/rtl/$name').readAsStringSync();

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Counter RTL ──────────────────────────────────────────────────────────────

  group('DesignRunner — counter.v', () {
    late DesignKnowledge knowledge;

    setUpAll(() async {
      knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('counter.v'), topModule: 'counter'),
      );
    });

    test('returns DesignKnowledge', () {
      expect(knowledge, isNotNull);
    });

    test('detects clock signal', () {
      expect(knowledge.hasClock, isTrue);
    });

    test('detects reset signal', () {
      expect(knowledge.hasReset, isTrue);
    });

    test('detects counter pattern', () {
      expect(knowledge.hasCounter, isTrue);
    });

    test('clock list is non-empty', () {
      expect(knowledge.clocks, isNotEmpty);
    });
  });

  // ── FSM RTL ──────────────────────────────────────────────────────────────────

  group('DesignRunner — fsm.v', () {
    late DesignKnowledge knowledge;

    setUpAll(() async {
      knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('fsm.v')),
      );
    });

    test('returns DesignKnowledge', () {
      expect(knowledge, isNotNull);
    });

    test('detects FSM pattern', () {
      expect(knowledge.hasFSM, isTrue);
    });

    test('detects clock', () {
      expect(knowledge.hasClock, isTrue);
    });

    test('FSM list is non-empty', () {
      expect(knowledge.fsms, isNotEmpty);
    });
  });

  // ── UART RTL ─────────────────────────────────────────────────────────────────

  group('DesignRunner — uart.v', () {
    late DesignKnowledge knowledge;

    setUpAll(() async {
      knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('uart.v')),
      );
    });

    test('returns DesignKnowledge', () {
      expect(knowledge, isNotNull);
    });

    test('detects clock in UART', () {
      expect(knowledge.hasClock, isTrue);
    });

    test('detects reset in UART', () {
      expect(knowledge.hasReset, isTrue);
    });
  });

  // ── ALU RTL ──────────────────────────────────────────────────────────────────

  group('DesignRunner — alu.v', () {
    late DesignKnowledge knowledge;

    setUpAll(() async {
      knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('alu.v')),
      );
    });

    test('returns DesignKnowledge', () {
      expect(knowledge, isNotNull);
    });

    test('DesignKnowledge has non-null module list', () {
      expect(knowledge.modules, isNotNull);
    });
  });

  // ── FIFO RTL ─────────────────────────────────────────────────────────────────

  group('DesignRunner — fifo.v', () {
    late DesignKnowledge knowledge;

    setUpAll(() async {
      knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('fifo.v')),
      );
    });

    test('returns DesignKnowledge', () {
      expect(knowledge, isNotNull);
    });

    test('detects clock in FIFO', () {
      expect(knowledge.hasClock, isTrue);
    });

    test('detects reset in FIFO', () {
      expect(knowledge.hasReset, isTrue);
    });
  });

  // ── DesignContext configuration ──────────────────────────────────────────────

  group('DesignRunner — context options', () {
    test('topModule hint is accepted', () async {
      final ctx = DesignContext(
        rtlSource: _fixture('counter.v'),
        topModule: 'counter',
      );
      final knowledge = await DesignRunner.analyze(ctx);
      expect(knowledge, isNotNull);
    });

    test('parsedIr hint is accepted', () async {
      final ctx = DesignContext(
        rtlSource: _fixture('fsm.v'),
        parsedIr: const {'states': 3, 'edges': 4, 'encodingStyle': 'binary'},
      );
      final knowledge = await DesignRunner.analyze(ctx);
      expect(knowledge, isNotNull);
    });

    test('config extension map is accepted', () async {
      final ctx = DesignContext(
        rtlSource: _fixture('counter.v'),
        config: const {'strict': true, 'timeout': 30},
      );
      final knowledge = await DesignRunner.analyze(ctx);
      expect(knowledge, isNotNull);
    });

    test('empty RTL returns valid DesignKnowledge', () async {
      final ctx = DesignContext(rtlSource: '');
      final knowledge = await DesignRunner.analyze(ctx);
      expect(knowledge, isNotNull);
    });

    test('empty RTL → clock list is empty', () async {
      final ctx = DesignContext(rtlSource: '');
      final knowledge = await DesignRunner.analyze(ctx);
      expect(knowledge.clocks, isEmpty);
    });

    test('minimal module header → valid knowledge', () async {
      const minimal = 'module top; endmodule';
      final knowledge =
          await DesignRunner.analyze(DesignContext(rtlSource: minimal));
      expect(knowledge, isNotNull);
    });
  });

  // ── All fixtures ─────────────────────────────────────────────────────────────

  group('DesignRunner — all fixtures analyzable without error', () {
    const fixtures = ['counter.v', 'fsm.v', 'alu.v', 'fifo.v', 'uart.v'];

    for (final fixture in fixtures) {
      test('$fixture completes without exception', () async {
        final ctx = DesignContext(rtlSource: _fixture(fixture));
        final result = await DesignRunner.analyze(ctx);
        expect(result, isNotNull);
      });
    }
  });

  // ── DesignKnowledge structure ─────────────────────────────────────────────────

  group('DesignKnowledge — structure invariants', () {
    test('all list fields are non-null on counter knowledge', () async {
      final knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('counter.v')),
      );
      expect(knowledge.clocks, isNotNull);
      expect(knowledge.resets, isNotNull);
      expect(knowledge.fsms, isNotNull);
      expect(knowledge.counters, isNotNull);
      expect(knowledge.registers, isNotNull);
      expect(knowledge.modules, isNotNull);
      expect(knowledge.handshakes, isNotNull);
    });

    test('primaryClocks is a subset of clocks', () async {
      final knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('counter.v')),
      );
      for (final clock in knowledge.primaryClocks) {
        expect(knowledge.clocks.contains(clock), isTrue);
      }
    });

    test('syncResets and asyncResets are disjoint subsets of resets', () async {
      final knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: _fixture('counter.v')),
      );
      final syncIds = knowledge.syncResets.map((r) => r.name).toSet();
      final asyncIds = knowledge.asyncResets.map((r) => r.name).toSet();
      expect(syncIds.intersection(asyncIds), isEmpty);
    });
  });
}
