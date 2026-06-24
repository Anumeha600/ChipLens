# Benchmark Fixtures

RTL fixtures for the ChipLens benchmark suite live in:

```
test/fixtures/rtl/
├── counter.v   — 4-bit synchronous counter with active-low reset
├── fsm.v       — 3-state traffic light FSM
├── alu.v       — 32-bit combinational ALU (8 operations)
├── fifo.v      — Synchronous FIFO with full/empty flags
└── uart.v      — UART transmitter with baud-rate generator
```

The benchmark runner references these files via relative paths from the
Flutter project root. Do not duplicate them here.

To add a new fixture:

1. Place the `.v` file in `test/fixtures/rtl/`.
2. Add a `Benchmark` entry to `kDefaultBenchmarks` in
   `benchmarks/runner/benchmark.dart`.
3. Run `flutter test test/benchmarks/` to verify the new benchmark.
