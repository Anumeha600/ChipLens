// ─── Benchmark ────────────────────────────────────────────────────────────────

/// Specification for a single benchmark run against one RTL fixture.
///
/// [fixturePath] is relative to the project root and is resolved at run-time
/// by [BenchmarkRunner] using [dart:io].
class Benchmark {
  /// Short identifier used in report tables and result keys.
  final String designName;

  /// Path to the Verilog fixture file, relative to the project root.
  final String fixturePath;

  const Benchmark({
    required this.designName,
    required this.fixturePath,
  });

  @override
  String toString() => 'Benchmark($designName @ $fixturePath)';
}

// ── Default benchmark suite ───────────────────────────────────────────────────

/// All five RTL fixtures from the Sprint G integration test corpus.
///
/// Paths are relative to the Flutter project root so [BenchmarkRunner] can
/// resolve them with `dart:io` during `flutter test` or a standalone run.
const List<Benchmark> kDefaultBenchmarks = [
  Benchmark(designName: 'counter', fixturePath: 'test/fixtures/rtl/counter.v'),
  Benchmark(designName: 'fsm',     fixturePath: 'test/fixtures/rtl/fsm.v'),
  Benchmark(designName: 'alu',     fixturePath: 'test/fixtures/rtl/alu.v'),
  Benchmark(designName: 'fifo',    fixturePath: 'test/fixtures/rtl/fifo.v'),
  Benchmark(designName: 'uart',    fixturePath: 'test/fixtures/rtl/uart.v'),
];
