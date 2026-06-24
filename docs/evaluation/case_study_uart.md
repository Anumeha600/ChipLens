# Case Study: UART Transmitter

**File:** `test/fixtures/rtl/uart.v`  
**Pipeline run date:** 2026-06-24  
**Benchmark runtime:** 4 ms

---

## 1. Design Overview

A parameterized UART transmitter implementing the standard 8N1 serial protocol (8 data bits, no parity, 1 stop bit). The transmitter is driven by a 4-state FSM that sequences through IDLE, START, DATA, and STOP phases, with a clock divider to produce the correct baud rate.

| Property | Value |
|----------|-------|
| Module name | `uart_tx` |
| Parameters | `CLK_FREQ=50_000_000`, `BAUD_RATE=115_200` |
| Clock edge | Positive (posedge clk) |
| Reset type | Asynchronous, active-low (negedge rst_n) |
| FSM states | 4: IDLE, START, DATA, STOP |
| Internal registers | `state`, `clk_count`, `bit_index`, `tx_shift` |
| Outputs | `tx_out` (serial line), `tx_busy` (status) |
| RTL lines | 78 |

**Behavioral intent:**
- **IDLE:** Wait for `tx_start`. When asserted, latch `tx_data` into `tx_shift`, assert `tx_busy`, and transition to START.
- **START:** Drive `tx_out` low (start bit) for one full bit period (`CLKS_PER_BIT` clocks), then transition to DATA.
- **DATA:** Shift out each of the 8 data bits LSB-first, one bit per bit period. Transition to STOP after the 8th bit.
- **STOP:** Drive `tx_out` high (stop bit) for one full bit period, de-assert `tx_busy`, return to IDLE.

---

## 2. RTL Input

```verilog
module uart_tx #(
  parameter CLK_FREQ  = 50_000_000,
  parameter BAUD_RATE = 115_200
)(
  input  wire       clk,
  input  wire       rst_n,
  input  wire [7:0] tx_data,
  input  wire       tx_start,
  output reg        tx_out,
  output reg        tx_busy
);
  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  localparam IDLE  = 2'b00;
  localparam START = 2'b01;
  localparam DATA  = 2'b10;
  localparam STOP  = 2'b11;

  reg [1:0]  state;
  reg [15:0] clk_count;
  reg [2:0]  bit_index;
  reg [7:0]  tx_shift;
  // ...always block: 4-state FSM with clock divider
endmodule
```

Key structural features:
- Clock divider (`clk_count` counts from 0 to `CLKS_PER_BIT - 1`)
- 4-state FSM with `case(state)` and explicit `default` branch
- Bit shift register (`tx_shift`) for serial output
- Bit counter (`bit_index`) for tracking position within the 8 data bits

---

## 3. Design Intelligence Output

`DesignRunner.analyze()` is the most structurally informative stage for this design because the UART contains multiple detectable patterns.

**Detected structural features:**

| Feature | Detected | Notes |
|---------|----------|-------|
| Clock signal | Yes | `clk` — positive edge trigger |
| Async reset | Yes | `rst_n` — active-low, in sensitivity list |
| FSM | Yes | `case(state)` with 4-state encoding |
| States | 4 | IDLE, START, DATA, STOP |
| Registers | Yes | `state`, `clk_count`, `bit_index`, `tx_shift`, `tx_out`, `tx_busy` |
| Counter pattern | Possible | `clk_count` and `bit_index` are counting registers, detection depends on name matching |

The UART is the most structurally complex design in the benchmark suite, with 4 FSM states, 6 registered signals, and inter-register dependencies (e.g., `clk_count` gating the `bit_index` increment and state transitions).

---

## 4. Diagnostics Analysis

**Note:** The benchmark uses a heuristic coverage estimate, not actual formal verification output.

The UART has the highest structural complexity in the benchmark corpus (FSM + multiple registers), which pushes the heuristic coverage estimate lower than simpler designs. It receives the same diagnostic tier (low risk) but the runtime is 4 ms — slightly higher than the other designs, reflecting the larger parse tree.

| Field | Value |
|-------|-------|
| Issue count | 1 |
| Issue title | Coverage low |
| Category | coverage |
| Severity | low |
| Coverage risk | CoverageRisk.low |
| Pipeline runtime | 4 ms |

**Issue description:** "Coverage is slightly below target."

**What this means:** The UART has a rich set of behaviors that would benefit from formal verification: correct byte framing, baud rate accuracy, `tx_busy` signaling, behavior when `tx_start` is asserted during transmission, and the transition from DATA to STOP at bit 7. The diagnostic flags that none of these have been formally confirmed.

---

## 5. Repair Planning

| Field | Value |
|-------|-------|
| Step count | 1 |
| Step title | Fix: Coverage low |
| Category | coverage |
| Priority | low |
| Complexity | medium |
| Dependencies | none |

**Reasoning:** Coverage repair for a UART would typically involve writing cover properties for each FSM state and transition, plus assertions for protocol invariants (e.g., `tx_out` is low exactly during the start bit, `tx_busy` de-asserts only in the STOP state). These represent medium-complexity formal verification tasks.

---

## 6. Verification Workflow

```text
uart_tx.v (78 lines, 4-state FSM, clock divider, shift register)
     │
     ▼
Design Intelligence (DesignRunner.analyze)
     │  Detected: clock, async reset, FSM (4 states: IDLE/START/DATA/STOP),
     │            registers (state, clk_count, bit_index, tx_shift, tx_out, tx_busy)
     ▼
Coverage Assessment (heuristic)
     │  FSM + multiple registers → highest complexity in benchmark corpus
     │  Estimated coverage → CoverageRisk.low
     ▼
Diagnostics Intelligence (DiagnosticsEngine.analyze)
     │  1 issue: "Coverage low" (severity: low)
     │  Summary: "Minor verification concerns detected."
     ▼
Repair Planning (RepairPlanner.plan)
     │  1 step: "Fix: Coverage low" (priority: low, complexity: medium)
     ▼
BenchmarkResult
     designName: uart
     diagnostics: 1   repairs: 1   runtime: 4 ms   success: true
```

---

## 7. Observations

**Strengths:**
- Design Intelligence correctly identifies the 4-state FSM from the `case(state)` construct and the asynchronous reset from the sensitivity list. Both are accurate structural observations.
- The UART has the most internal registers of any design in the benchmark suite, and the pipeline handles all of them without errors.
- At 78 lines, the UART is the largest design in the benchmark corpus, yet still completes in 4 ms.

**Limitations:**
- The clock divider (`clk_count < CLKS_PER_BIT - 1`) is a timing-critical element that cannot be analyzed without knowing the parameter values. ChipLens detects `clk_count` as a register but does not reason about the baud rate relationship `CLKS_PER_BIT = CLK_FREQ / BAUD_RATE`.
- The UART is the most verification-valuable design in the benchmark because it has a real protocol specification (8N1), but the benchmark harness does not generate or check any protocol properties.
- The shift register's correctness (LSB-first serial output) is not verified. This is a meaningful property that formal verification could confirm.

**Future improvement:** The UART is an ideal candidate for protocol-level formal verification. Properties like "if `tx_start` is asserted, exactly 10 bits are transmitted in the correct order (start + 8 data + stop)" are expressible as SystemVerilog Assertions (SVA) and would be generated by ChipLens's full property synthesis pipeline if run in non-benchmark mode.

**Performance note:** The UART's 4 ms runtime is slightly higher than the simpler designs (2–3 ms). This reflects the larger RTL parse tree rather than any algorithmic scaling issue. The Design Intelligence framework is the dominant cost, with Diagnostics and Repair Planning each taking sub-millisecond time.
