import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// ── Canned RTL fixtures ───────────────────────────────────────────────────────

// Counter: async active-low reset, primary clock, 8-bit increment counter.
const _counterRtl = '''
module counter(
  input  clk,
  input  rst_n,
  input  en,
  output reg [7:0] cnt
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) cnt <= 8'h00;
    else if (en) cnt <= cnt + 1;
  end
endmodule
''';

// FSM: synchronous active-high reset, 3 localparams, 2-bit state register.
const _fsmRtl = '''
module traffic(input clk, input rst, output reg [1:0] light);
  localparam RED   = 2'b00;
  localparam GREEN = 2'b01;
  localparam AMBER = 2'b10;
  reg [1:0] state;
  always @(posedge clk) begin
    if (rst) state <= RED;
    else case (state)
      RED:   state <= GREEN;
      GREEN: state <= AMBER;
      AMBER: state <= RED;
    endcase
  end
  always @(*) light = state;
endmodule
''';

// Async active-high reset.
const _asyncHighRtl = '''
module top(input clk, input arst, output reg q);
  always @(posedge clk or posedge arst) begin
    if (arst) q <= 0;
    else      q <= ~q;
  end
endmodule
''';

// Handshake: valid/ready protocol.
const _handshakeRtl = '''
module arbiter(
  input  clk, input rst_n,
  input  valid_in,  output ready_out,
  output valid_out, input  ready_in
);
endmodule
''';

// Handshake: req/ack protocol.
const _reqAckRtl = '''
module bus(
  input clk, input rst_n,
  input  req, output ack
);
endmodule
''';

// Handshake: start/done protocol.
const _startDoneRtl = '''
module compute(
  input clk, input rst_n,
  input  start, output reg done
);
endmodule
''';

// Module with ports and parameters.
const _moduleRtl = '''
module adder #(parameter WIDTH = 8) (
  input  [WIDTH-1:0] a,
  input  [WIDTH-1:0] b,
  output [WIDTH-1:0] sum
);
  assign sum = a + b;
endmodule
''';

// Register: sequential register + combinational assign target.
const _registerRtl = '''
module reg_test(input clk, input [7:0] d, output reg [7:0] q, output [7:0] c);
  always @(posedge clk) q <= d;
  assign c = d + 1;
endmodule
''';

// Candidate (non-primary) clock.
const _candidateClkRtl = '''
module gen(input gated_clk);
  always @(posedge gated_clk) begin end
endmodule
''';

// Sync active-low reset (no async sensitivity).
const _syncLowRtl = '''
module sync_rst(input clk, input rst_n, output reg q);
  always @(posedge clk) begin
    if (!rst_n) q <= 0;
    else        q <= ~q;
  end
endmodule
''';

// Decrement counter.
const _decrRtl = '''
module downcnt(input clk, input rst, output reg [3:0] cnt);
  always @(posedge clk) begin
    if (rst) cnt <= 4'hF;
    else     cnt <= cnt - 1;
  end
endmodule
''';

// ── Helper ────────────────────────────────────────────────────────────────────

DesignContext _ctx(String rtl, {Map<String, dynamic>? ir}) =>
    DesignContext(rtlSource: rtl, parsedIr: ir);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {

  // ── ClockProvider ──────────────────────────────────────────────────────────

  group('ClockProvider', () {
    const provider = ClockProvider();

    test('detects primary clock named clk', () async {
      final r = await provider.analyze(_ctx(_counterRtl));
      final clocks = r.clocks;
      expect(clocks, isNotEmpty);
      final clk = clocks.firstWhere((c) => c.name == 'clk');
      expect(clk.isPrimaryClock, isTrue);
      expect(clk.isCandidate,    isFalse);
    });

    test('does not include negedge reset as a clock', () async {
      final r = await provider.analyze(_ctx(_counterRtl));
      expect(r.clocks.any((c) => c.name == 'rst_n'), isFalse);
    });

    test('candidate clock: non-standard name', () async {
      final r = await provider.analyze(_ctx(_candidateClkRtl));
      final clocks = r.clocks;
      expect(clocks, isNotEmpty);
      final gc = clocks.first;
      expect(gc.name,         'gated_clk');
      expect(gc.isPrimaryClock, isFalse);
      expect(gc.isCandidate,    isTrue);
    });

    test('FSM RTL: detects clk as primary', () async {
      final r = await provider.analyze(_ctx(_fsmRtl));
      expect(r.clocks.any((c) => c.name == 'clk' && c.isPrimaryClock), isTrue);
    });

    test('no clocks in empty RTL', () async {
      final r = await provider.analyze(_ctx('module m; endmodule'));
      expect(r.clocks, isEmpty);
    });

    test('providerKey is clock', () {
      expect(provider.providerKey, 'clock');
    });
  });

  // ── ResetProvider ──────────────────────────────────────────────────────────

  group('ResetProvider', () {
    const provider = ResetProvider();

    test('async active-low reset: always @(posedge clk or negedge rst_n)', () async {
      final r = await provider.analyze(_ctx(_counterRtl));
      final rst = r.resets.firstWhere((r) => r.name == 'rst_n');
      expect(rst.isAsynchronous, isTrue);
      expect(rst.isSynchronous,  isFalse);
      expect(rst.isActiveLow,    isTrue);
      expect(rst.isActiveHigh,   isFalse);
    });

    test('async active-high reset: always @(posedge clk or posedge arst)', () async {
      final r = await provider.analyze(_ctx(_asyncHighRtl));
      final rst = r.resets.firstWhere((r) => r.name == 'arst');
      expect(rst.isAsynchronous, isTrue);
      expect(rst.isActiveHigh,   isTrue);
      expect(rst.isActiveLow,    isFalse);
    });

    test('sync active-high reset: if (rst) inside posedge-only block', () async {
      final r = await provider.analyze(_ctx(_fsmRtl));
      final rst = r.resets.firstWhere((r) => r.name == 'rst');
      expect(rst.isSynchronous,  isTrue);
      expect(rst.isAsynchronous, isFalse);
      expect(rst.isActiveHigh,   isTrue);
    });

    test('sync active-low reset: if (!rst_n) inside posedge-only block', () async {
      final r = await provider.analyze(_ctx(_syncLowRtl));
      final rst = r.resets.firstWhere((r) => r.name == 'rst_n');
      expect(rst.isSynchronous,  isTrue);
      expect(rst.isAsynchronous, isFalse);
      expect(rst.isActiveLow,    isTrue);
    });

    test('async reset not double-counted as sync', () async {
      // _counterRtl has rst_n in both sensitivity list AND if(!rst_n)
      final r    = await provider.analyze(_ctx(_counterRtl));
      final rsts = r.resets.where((r) => r.name == 'rst_n').toList();
      expect(rsts.length, 1);
      expect(rsts.first.isAsynchronous, isTrue);
    });

    test('no resets in clock-only RTL', () async {
      final r = await provider.analyze(_ctx(_candidateClkRtl));
      expect(r.resets, isEmpty);
    });

    test('providerKey is reset', () {
      expect(provider.providerKey, 'reset');
    });
  });

  // ── FSMProvider ────────────────────────────────────────────────────────────

  group('FSMProvider', () {
    const provider = FSMProvider();

    test('detects state register from reg [1:0] state', () async {
      final r = await provider.analyze(_ctx(_fsmRtl));
      expect(r.fsms, isNotEmpty);
      final fsm = r.fsms.first;
      expect(fsm.stateRegister, 'state');
      expect(fsm.encodingWidth, 2);
    });

    test('candidate states from localparam definitions', () async {
      final r = await provider.analyze(_ctx(_fsmRtl));
      final fsm = r.fsms.first;
      expect(fsm.candidateStates, containsAll(['RED', 'GREEN', 'AMBER']));
      expect(fsm.encodingStyle,   'localparam');
    });

    test('uses parsedIr fast path when states key present', () async {
      final ir = {
        'states': ['IDLE', 'RUN', 'DONE'],
        'stateRegister': 'cur_state',
        'encodingWidth': 2,
        'encodingStyle': 'localparam',
      };
      final r   = await provider.analyze(_ctx('module m; endmodule', ir: ir));
      final fsm = r.fsms.first;
      expect(fsm.stateRegister,   'cur_state');
      expect(fsm.candidateStates, ['IDLE', 'RUN', 'DONE']);
    });

    test('falls back to RTL heuristics when parsedIr has no states', () async {
      final r = await provider.analyze(_ctx(_fsmRtl, ir: {'other': 'data'}));
      expect(r.fsms, isNotEmpty);
    });

    test('no FSMs in combinational-only RTL', () async {
      final r = await provider.analyze(_ctx(_moduleRtl));
      expect(r.fsms, isEmpty);
    });

    test('providerKey is fsm', () {
      expect(provider.providerKey, 'fsm');
    });
  });

  // ── CounterProvider ────────────────────────────────────────────────────────

  group('CounterProvider', () {
    const provider = CounterProvider();

    test('detects 8-bit increment counter named cnt', () async {
      final r   = await provider.analyze(_ctx(_counterRtl));
      final cnt = r.counters.firstWhere((c) => c.name == 'cnt');
      expect(cnt.width,       8);
      expect(cnt.isIncrement, isTrue);
      expect(cnt.isDecrement, isFalse);
    });

    test('detects 4-bit decrement counter', () async {
      final r   = await provider.analyze(_ctx(_decrRtl));
      final cnt = r.counters.firstWhere((c) => c.name == 'cnt');
      expect(cnt.width,       4);
      expect(cnt.isDecrement, isTrue);
      expect(cnt.isIncrement, isFalse);
    });

    test('no counters in FSM RTL', () async {
      final r = await provider.analyze(_ctx(_fsmRtl));
      expect(r.counters, isEmpty);
    });

    test('providerKey is counter', () {
      expect(provider.providerKey, 'counter');
    });
  });

  // ── RegisterProvider ───────────────────────────────────────────────────────

  group('RegisterProvider', () {
    const provider = RegisterProvider();

    test('detects sequential register q (8-bit)', () async {
      final r   = await provider.analyze(_ctx(_registerRtl));
      final reg = r.registers.firstWhere((r) => r.name == 'q');
      expect(reg.width,        8);
      expect(reg.isSequential, isTrue);
    });

    test('detects combinational signal from assign', () async {
      final r    = await provider.analyze(_ctx(_registerRtl));
      final comb = r.registers.firstWhere((r) => r.name == 'c');
      expect(comb.isCombinational, isTrue);
      expect(comb.isSequential,    isFalse);
    });

    test('no sequential registers in combinational-only RTL', () async {
      const rtl = 'module m(input a, output b); assign b = ~a; endmodule';
      final r   = await provider.analyze(_ctx(rtl));
      expect(r.registers.any((r) => r.isSequential), isFalse);
    });

    test('providerKey is register', () {
      expect(provider.providerKey, 'register');
    });
  });

  // ── ModuleProvider ─────────────────────────────────────────────────────────

  group('ModuleProvider', () {
    const provider = ModuleProvider();

    test('detects module name', () async {
      final r = await provider.analyze(_ctx(_moduleRtl));
      expect(r.modules, isNotEmpty);
      expect(r.modules.first.name, 'adder');
    });

    test('detects input and output ports', () async {
      final r   = await provider.analyze(_ctx(_moduleRtl));
      final mod = r.modules.first;
      expect(mod.inputs.map((p) => p.name), containsAll(['a', 'b']));
      expect(mod.outputs.map((p) => p.name), contains('sum'));
    });

    test('detects parameter WIDTH', () async {
      final r = await provider.analyze(_ctx(_moduleRtl));
      expect(r.modules.first.parameters['WIDTH'], '8');
    });

    test('detects counter module name', () async {
      final r = await provider.analyze(_ctx(_counterRtl));
      expect(r.modules.any((m) => m.name == 'counter'), isTrue);
    });

    test('input count for counter module', () async {
      final r   = await provider.analyze(_ctx(_counterRtl));
      final mod = r.modules.firstWhere((m) => m.name == 'counter');
      expect(mod.inputs, isNotEmpty);
    });

    test('providerKey is module', () {
      expect(provider.providerKey, 'module');
    });
  });

  // ── HandshakeProvider ──────────────────────────────────────────────────────

  group('HandshakeProvider', () {
    const provider = HandshakeProvider();

    test('detects valid/ready protocol', () async {
      final r = await provider.analyze(_ctx(_handshakeRtl));
      expect(r.handshakes, isNotEmpty);
      final hs = r.handshakes.firstWhere(
          (h) => h.protocolHint == 'valid_ready');
      expect(hs.signals, isNotEmpty);
    });

    test('valid/ready signals are listed in HandshakeInfo.signals', () async {
      final r  = await provider.analyze(_ctx(_handshakeRtl));
      final hs = r.handshakes.firstWhere(
          (h) => h.protocolHint == 'valid_ready');
      final sigNames = hs.signals.map((s) => s.toLowerCase()).toList();
      expect(sigNames.any((s) => s.contains('valid')), isTrue);
      expect(sigNames.any((s) => s.contains('ready')), isTrue);
    });

    test('detects req/ack protocol', () async {
      final r = await provider.analyze(_ctx(_reqAckRtl));
      expect(r.handshakes.any((h) => h.protocolHint == 'req_ack'), isTrue);
    });

    test('detects start/done protocol', () async {
      final r = await provider.analyze(_ctx(_startDoneRtl));
      expect(r.handshakes.any((h) => h.protocolHint == 'start_done'), isTrue);
    });

    test('no handshakes in plain counter RTL', () async {
      final r = await provider.analyze(_ctx(_counterRtl));
      expect(r.handshakes, isEmpty);
    });

    test('providerKey is handshake', () {
      expect(provider.providerKey, 'handshake');
    });
  });

  // ── Knowledge merging ──────────────────────────────────────────────────────

  group('Knowledge merging', () {
    test('merging two results combines their respective lists', () {
      final a = KnowledgeResult(
        providerKey: 'a',
        clocks:  [const ClockInfo(name: 'clk', isPrimaryClock: true)],
      );
      final b = KnowledgeResult(
        providerKey: 'b',
        resets: [const ResetInfo(name: 'rst', isSynchronous: true, isActiveHigh: true)],
      );

      // Simulate what DesignRunner._merge does.
      final merged = DesignKnowledge(
        clocks:  [...a.clocks,  ...b.clocks],
        resets:  [...a.resets,  ...b.resets],
        fsms:    [...a.fsms,    ...b.fsms],
        counters: [...a.counters, ...b.counters],
        registers: [...a.registers, ...b.registers],
        modules:  [...a.modules,  ...b.modules],
        handshakes: [...a.handshakes, ...b.handshakes],
      );

      expect(merged.clocks.length, 1);
      expect(merged.resets.length, 1);
      expect(merged.hasClock,   isTrue);
      expect(merged.hasReset,   isTrue);
      expect(merged.hasFSM,     isFalse);
    });

    test('empty result.isEmpty is true', () {
      expect(KnowledgeResult.empty('x').isEmpty, isTrue);
    });

    test('non-empty result.isEmpty is false', () {
      final r = KnowledgeResult(
        providerKey: 'x',
        clocks: [const ClockInfo(name: 'clk')],
      );
      expect(r.isEmpty, isFalse);
    });

    test('DesignKnowledge convenience accessors work', () {
      const k = DesignKnowledge(
        clocks: [
          ClockInfo(name: 'clk', isPrimaryClock: true),
          ClockInfo(name: 'gen', isCandidate: true),
        ],
        resets: [
          ResetInfo(name: 'rst', isSynchronous:  true,  isActiveHigh: true),
          ResetInfo(name: 'arst', isAsynchronous: true, isActiveHigh: true),
        ],
      );
      expect(k.primaryClocks.length, 1);
      expect(k.primaryClocks.first.name, 'clk');
      expect(k.asyncResets.length, 1);
      expect(k.syncResets.length,  1);
    });
  });

  // ── DesignRunner orchestration ─────────────────────────────────────────────

  group('DesignRunner orchestration', () {
    test('default providers produce non-empty knowledge for counter RTL', () async {
      final k = await DesignRunner.analyze(_ctx(_counterRtl));
      expect(k.hasClock,   isTrue);
      expect(k.hasReset,   isTrue);
      expect(k.hasCounter, isTrue);
    });

    test('custom provider list: only supplied providers run', () async {
      final k = await DesignRunner.analyze(
        _ctx(_counterRtl),
        providers: [const ClockProvider()],
      );
      expect(k.hasClock,   isTrue);
      expect(k.hasReset,   isFalse);
      expect(k.hasCounter, isFalse);
    });

    test('failing provider is swallowed — others still contribute', () async {
      final k = await DesignRunner.analyze(
        _ctx(_counterRtl),
        providers: [const ClockProvider(), _ThrowingProvider()],
      );
      expect(k.hasClock, isTrue);
    });

    test('empty provider list yields empty DesignKnowledge', () async {
      final k = await DesignRunner.analyze(_ctx(_counterRtl), providers: []);
      expect(k.clocks,     isEmpty);
      expect(k.resets,     isEmpty);
      expect(k.hasClock,   isFalse);
      expect(k.hasCounter, isFalse);
    });

    test('concurrent execution: all seven providers run on FSM RTL', () async {
      final k = await DesignRunner.analyze(_ctx(_fsmRtl));
      expect(k.hasClock, isTrue);
      expect(k.hasReset, isTrue);
      expect(k.hasFSM,   isTrue);
    });

    test('runner with full RTL: handshake in arbiter', () async {
      final k = await DesignRunner.analyze(_ctx(_handshakeRtl));
      expect(k.hasHandshake, isTrue);
    });
  });

  // ── Provider independence ──────────────────────────────────────────────────

  group('Provider independence', () {
    test('each provider has a unique providerKey', () {
      const providers = [
        ClockProvider(),
        ResetProvider(),
        FSMProvider(),
        CounterProvider(),
        RegisterProvider(),
        ModuleProvider(),
        HandshakeProvider(),
      ];
      final keys = providers.map((p) => p.providerKey).toSet();
      expect(keys.length, providers.length);
    });

    test('ClockProvider result contains no resets', () async {
      final r = await const ClockProvider().analyze(_ctx(_counterRtl));
      expect(r.resets, isEmpty);
    });

    test('ResetProvider result contains no clocks', () async {
      final r = await const ResetProvider().analyze(_ctx(_counterRtl));
      expect(r.clocks, isEmpty);
    });

    test('FSMProvider result contains no counters', () async {
      final r = await const FSMProvider().analyze(_ctx(_fsmRtl));
      expect(r.counters, isEmpty);
    });

    test('CounterProvider result contains no FSMs', () async {
      final r = await const CounterProvider().analyze(_ctx(_counterRtl));
      expect(r.fsms, isEmpty);
    });

    test('running providers sequentially vs concurrently yields same knowledge',
        () async {
      final sequential = DesignKnowledge(
        clocks:  (await const ClockProvider().analyze(_ctx(_counterRtl))).clocks,
        resets:  (await const ResetProvider().analyze(_ctx(_counterRtl))).resets,
        counters: (await const CounterProvider().analyze(_ctx(_counterRtl))).counters,
      );

      final concurrent = await DesignRunner.analyze(
        _ctx(_counterRtl),
        providers: [const ClockProvider(), const ResetProvider(), const CounterProvider()],
      );

      expect(concurrent.clocks.length,   sequential.clocks.length);
      expect(concurrent.resets.length,   sequential.resets.length);
      expect(concurrent.counters.length, sequential.counters.length);
    });
  });
}

// ── Stub implementations ──────────────────────────────────────────────────────

class _ThrowingProvider implements KnowledgeProvider {
  @override
  String get providerKey => 'throwing';

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async =>
      throw Exception('deliberate failure for test');
}
