# ChipLens Evaluation Summary

**Date:** 2026-06-24  
**Platform:** ChipLens v1.0.0  
**Total automated tests:** 2187 passing, 0 failing

---

## Benchmark Overview

The ChipLens benchmark harness (`benchmarks/`) measures the complete analysis pipeline — Design Intelligence, Diagnostics, and Repair Planning — against a set of representative RTL designs.

**Note:** The benchmark pipeline does not execute formal verification. Coverage assessments are derived from a structural complexity heuristic based on `DesignKnowledge`. The results represent the performance of ChipLens's reasoning frameworks in isolation, not the output of a complete formal verification workflow.

| Design | Description | Lines | Diagnostics | Repairs | Runtime (ms) | Success |
|--------|-------------|-------|-------------|---------|--------------|---------|
| counter | 4-bit sync counter, async reset | 13 | 1 | 1 | 3 | Yes |
| fsm | 3-state traffic light FSM, sync reset | 23 | 1 | 1 | 2 | Yes |
| alu | 32-bit combinational ALU, 8 ops | 26 | 1 | 1 | 2 | Yes |
| fifo | Parameterized sync FIFO, depth=8 | 41 | 1 | 1 | 3 | Yes |
| uart | UART TX, 4-state FSM, 8N1 protocol | 78 | 1 | 1 | 4 | Yes |

---

## Aggregate Results

| Metric | Value |
|--------|-------|
| Total designs | 5 |
| Successful pipeline runs | 5 (100%) |
| Failed pipeline runs | 0 |
| Average runtime | 3 ms |
| Total diagnostics produced | 5 |
| Total repair steps produced | 5 |
| Diagnostics per design | 1 (uniform) |
| Repairs per design | 1 (uniform) |

**Why all designs produce 1 diagnostic:** Each design has at least one detected register or counter. The heuristic assigns `CoverageRisk.low` when structural complexity exceeds zero, and DiagnosticsEngine generates exactly one coverage issue for this risk level. A design with no detected structures (or a design that has already been verified with formal tools to have `CoverageRisk.minimal`) would produce zero diagnostics.

**Why the alu produces a diagnostic:** The ALU declares `output reg [WIDTH-1:0] result`. Although the ALU is purely combinational (always @(*)), the `reg` keyword causes the register heuristic to detect a registered signal. This is a known limitation of keyword-based structural extraction.

---

## Architectural Findings

### Deterministic Execution

Every benchmark run produces identical outputs for identical inputs. The `DiagnosticsEngine` and `RepairPlanner` are stateless (`const` constructors) and contain no mutable state. Repeated executions of the full suite produce identical diagnostic and repair counts.

This property is important for reproducible research: ChipLens results can be compared across runs, platforms, and time without concern for non-deterministic behavior.

### Explainability

Each diagnostic issue includes a title, description, severity classification, and category. Each repair step carries a description, priority, complexity estimate, and list of supporting evidence drawn from the upstream diagnostic. This allows users to trace a repair suggestion back to the diagnostic that generated it, and the diagnostic back to the coverage assessment that triggered it.

The benchmark results are sparse (all designs produce the same coverage diagnostic), which limits the diversity of explainability outputs in this evaluation. Designs that fail formal verification would produce richer outputs including counterexample-derived diagnostics and verification-category repair steps.

### Modularity

The benchmark harness exercises three independent frameworks:

1. **Design Intelligence** (`DesignRunner.analyze`) — extracts structural knowledge from RTL text
2. **Diagnostics Intelligence** (`DiagnosticsEngine.analyze`) — maps coverage, counterexample, and planning information to diagnostic issues
3. **Repair Planning** (`RepairPlanner.plan`) — maps diagnostics to ordered repair steps

Each framework can be called independently with any conforming input. The benchmark confirms that all three compose correctly end-to-end.

### Testability

The full platform has 2187 automated tests across unit tests, integration tests, and benchmark tests. The benchmark suite itself contributes 136 tests covering:
- Model data integrity (`BenchmarkResult`, `BenchmarkSuiteResult`)
- Pipeline execution (`BenchmarkRunner`)
- Report generation (`BenchmarkReportGenerator`)
- End-to-end suite execution with all 5 fixtures

---

## Limitations

The following limitations should be understood before interpreting the benchmark results.

### Small benchmark corpus

The benchmark suite contains 5 designs, totaling 181 lines of RTL. These are small, purpose-built examples. No industrial RTL has been evaluated. Results on larger, more complex designs (multi-clock, parameterized hierarchies, large state machines) are unknown.

### Heuristic-based diagnostics

The benchmark pipeline does not run formal verification. Coverage assessments come from a structural complexity heuristic, not from a coverage tool or model checker. The 91% coverage figure in the counter case study is an estimate derived from detected register counts, not a measurement.

The practical consequence: all 5 benchmark designs produce identical diagnostic types (coverage low, severity low) regardless of their actual verification difficulty. A design that is trivially verifiable and one that is fundamentally broken would produce the same benchmark output.

### No property generation or verification

ChipLens has a full property synthesis pipeline (candidate generation, ranking, emitter, verification planning) that is not exercised by the benchmark harness. The benchmark measures the Design Intelligence → Diagnostics → Repair path only.

### Limited formal evaluation

The benchmark does not measure:
- Property synthesis quality (number, correctness, or completeness of generated properties)
- Counterexample analysis (no formal tool is run)
- Coverage improvement after applying repair suggestions (no follow-up verification)
- Scalability beyond 78-line RTL modules

### Register keyword false positives

The ALU uses `output reg` for combinational outputs (driven by `always @(*)`), causing the register heuristic to detect a registered signal and assign non-minimal coverage risk. This is a false positive: the signal is not a sequential register. The limitation is inherent to keyword-based structural analysis without type inference.

---

## Future Work

The following directions would strengthen the evaluation and expand ChipLens's applicability.

### Larger benchmark suite

Evaluate against open-source RTL designs of increasing complexity:
- **PicoRV32** — a compact RISC-V core (~2,500 lines, multiple FSMs, memory interface)
- **OpenTitan** subsystems — production-quality RTL with real verification requirements
- **RISC-V Formal verification benchmarks** — designs with known verification challenges

### Property quality study

Run the full ChipLens property synthesis pipeline against the benchmark designs and measure:
- How many candidate properties are generated per design
- What fraction of generated properties are meaningful (non-trivial)
- How property ranking compares to manual expert ranking

### Coverage improvement study

Apply the repair suggestions from the benchmark and measure whether following the repair advice leads to measurable coverage improvement in a formal or simulation tool.

### Formal verification integration study

Run SymbiYosys against ChipLens-synthesized properties for the benchmark designs and measure:
- Verification time
- Pass/fail rate of synthesized properties
- Counterexample quality for failing properties

### Scalability study

Measure Design Intelligence runtime against designs of increasing size (100, 1000, 10000 lines) to characterize the analysis cost relative to design complexity.

### Property synthesis evaluation

Use the UART or FIFO as a reference design with a known specification (8N1 protocol, FIFO ordering invariant) and evaluate whether ChipLens generates properties that capture the specification intent.

---

## Case Studies

Individual case studies with RTL excerpts, Design Intelligence outputs, diagnostics, and observations are available for the following designs:

- [Counter](case_study_counter.md) — 4-bit synchronous counter
- [FSM](case_study_fsm.md) — Traffic light finite state machine
- [FIFO](case_study_fifo.md) — Synchronous FIFO queue
- [UART](case_study_uart.md) — UART transmitter (8N1)

---

## Raw Benchmark Data

The raw benchmark results (generated by running `runBenchmarkSuite()` against all 5 fixture files) are available in:

[benchmark_results.md](benchmark_results.md)
