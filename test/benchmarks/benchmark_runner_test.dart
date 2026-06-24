import 'package:flutter_test/flutter_test.dart';
import '../../benchmarks/models/benchmark_result.dart';
import '../../benchmarks/runner/benchmark_runner.dart';
import '../../benchmarks/runner/benchmark.dart';

// ── Inline RTL fixtures ────────────────────────────────────────────────────────

const _counterRtl = '''
module counter (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       en,
  output reg  [3:0] count
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) count <= 4'b0;
    else if (en) count <= count + 1'b1;
endmodule
''';

const _fsmRtl = '''
module fsm (input clk, input rst, output reg [1:0] state);
  localparam A = 2'b00;
  localparam B = 2'b01;
  localparam C = 2'b10;
  always @(posedge clk)
    if (rst) state <= A;
    else case (state)
      A: state <= B;
      B: state <= C;
      C: state <= A;
      default: state <= A;
    endcase
endmodule
''';

const _emptyRtl = '';

const _minimalRtl = 'module top; endmodule';

const _runner = BenchmarkRunner();

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Single design run ────────────────────────────────────────────────────────

  group('BenchmarkRunner.runFromSource — return structure', () {
    late BenchmarkResult result;

    setUpAll(() async {
      result = await _runner.runFromSource('counter', _counterRtl);
    });

    test('returns BenchmarkResult', () {
      expect(result, isNotNull);
    });

    test('designName matches argument', () {
      expect(result.designName, 'counter');
    });

    test('success is true for valid RTL', () {
      expect(result.success, isTrue);
    });

    test('runtimeMs is non-negative', () {
      expect(result.runtimeMs, greaterThanOrEqualTo(0));
    });

    test('diagnosticCount is non-negative', () {
      expect(result.diagnosticCount, greaterThanOrEqualTo(0));
    });

    test('repairCount is non-negative', () {
      expect(result.repairCount, greaterThanOrEqualTo(0));
    });

    test('notes is null on success', () {
      expect(result.notes, isNull);
    });

    test('repairCount <= diagnosticCount (no repairs without diagnostics)', () {
      expect(result.repairCount, lessThanOrEqualTo(result.diagnosticCount));
    });
  });

  // ── FSM design ───────────────────────────────────────────────────────────────

  group('BenchmarkRunner.runFromSource — FSM design', () {
    late BenchmarkResult result;

    setUpAll(() async {
      result = await _runner.runFromSource('fsm', _fsmRtl);
    });

    test('succeeds', () => expect(result.success, isTrue));

    test('designName is fsm', () => expect(result.designName, 'fsm'));

    test('diagnosticCount is non-negative', () {
      expect(result.diagnosticCount, greaterThanOrEqualTo(0));
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────────────

  group('BenchmarkRunner.runFromSource — edge cases', () {
    test('empty RTL succeeds', () async {
      final r = await _runner.runFromSource('empty', _emptyRtl);
      expect(r.success, isTrue);
      expect(r.designName, 'empty');
    });

    test('minimal module succeeds', () async {
      final r = await _runner.runFromSource('minimal', _minimalRtl);
      expect(r.success, isTrue);
    });

    test('empty RTL has runtimeMs >= 0', () async {
      final r = await _runner.runFromSource('empty', _emptyRtl);
      expect(r.runtimeMs, greaterThanOrEqualTo(0));
    });
  });

  // ── Benchmark.run with file path ─────────────────────────────────────────────

  group('BenchmarkRunner.run — fixture files', () {
    test('counter.v fixture succeeds', () async {
      const bench = Benchmark(
        designName:  'counter',
        fixturePath: 'test/fixtures/rtl/counter.v',
      );
      final r = await _runner.run(bench);
      expect(r.success, isTrue);
    });

    test('fsm.v fixture succeeds', () async {
      const bench = Benchmark(
        designName:  'fsm',
        fixturePath: 'test/fixtures/rtl/fsm.v',
      );
      final r = await _runner.run(bench);
      expect(r.success, isTrue);
    });

    test('missing fixture returns failed result', () async {
      const bench = Benchmark(
        designName:  'missing',
        fixturePath: 'test/fixtures/rtl/does_not_exist.v',
      );
      final r = await _runner.run(bench);
      expect(r.success, isFalse);
      expect(r.notes, isNotNull);
    });

    test('missing fixture has zero diagnostics', () async {
      const bench = Benchmark(
        designName:  'missing',
        fixturePath: 'test/fixtures/rtl/does_not_exist.v',
      );
      final r = await _runner.run(bench);
      expect(r.diagnosticCount, 0);
    });

    test('missing fixture has zero runtimeMs', () async {
      const bench = Benchmark(
        designName:  'missing',
        fixturePath: 'test/fixtures/rtl/does_not_exist.v',
      );
      final r = await _runner.run(bench);
      expect(r.runtimeMs, 0);
    });
  });

  // ── Determinism ──────────────────────────────────────────────────────────────

  group('BenchmarkRunner — determinism', () {
    test('two runs produce equal diagnosticCount and repairCount', () async {
      final r1 = await _runner.runFromSource('counter', _counterRtl);
      final r2 = await _runner.runFromSource('counter', _counterRtl);
      expect(r1.diagnosticCount, r2.diagnosticCount);
      expect(r1.repairCount,     r2.repairCount);
    });

    test('two runs produce same success flag', () async {
      final r1 = await _runner.runFromSource('fsm', _fsmRtl);
      final r2 = await _runner.runFromSource('fsm', _fsmRtl);
      expect(r1.success, r2.success);
    });
  });
}
