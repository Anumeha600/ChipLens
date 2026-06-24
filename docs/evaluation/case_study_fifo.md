# Case Study: Synchronous FIFO

**File:** `test/fixtures/rtl/fifo.v`  
**Pipeline run date:** 2026-06-24  
**Benchmark runtime:** 3 ms

---

## 1. Design Overview

A parameterized synchronous first-in, first-out queue with independent read and write ports and combinational full/empty indicators. The design uses a pointer-based implementation with an explicit occupancy counter.

| Property | Value |
|----------|-------|
| Module name | `fifo` |
| Parameters | `DEPTH=8`, `WIDTH=8` (defaults) |
| Data width | `WIDTH` bits (parametric) |
| Queue depth | `DEPTH` entries (parametric) |
| Clock edge | Positive (posedge clk) |
| Reset type | Asynchronous, active-low (negedge rst_n) |
| Write port | `wr_en`, `wr_data` |
| Read port | `rd_en`, `rd_data` |
| Status | `full`, `empty` (combinational) |
| RTL lines | 41 |

**Behavioral intent:** On each clock edge, if `wr_en` is asserted and the FIFO is not full, the write pointer advances and data is written to the memory array. If `rd_en` is asserted and the FIFO is not empty, the read pointer advances and `rd_data` is loaded from memory. The occupancy counter `count` tracks how many entries are currently stored.

---

## 2. RTL Input

```verilog
module fifo #(
  parameter DEPTH = 8,
  parameter WIDTH = 8
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire             wr_en,
  input  wire             rd_en,
  input  wire [WIDTH-1:0] wr_data,
  output reg  [WIDTH-1:0] rd_data,
  output wire             full,
  output wire             empty
);
  reg [WIDTH-1:0]        mem   [0:DEPTH-1];
  reg [$clog2(DEPTH):0]  wr_ptr;
  reg [$clog2(DEPTH):0]  rd_ptr;
  reg [$clog2(DEPTH):0]  count;

  assign full  = (count == DEPTH);
  assign empty = (count == 0);
  // ...always block: synchronous wr/rd with async reset
endmodule
```

Key structural features:
- Parametric width and depth
- Pointer-based memory access using `$clog2(DEPTH)` for pointer width
- Occupancy counter `count` tracks FIFO fill level
- Simultaneous read and write handled in a single always block
- `full` and `empty` are combinational (not registered)

---

## 3. Design Intelligence Output

`DesignRunner.analyze()` extracts structural knowledge from the RTL source.

**Detected structural features:**

| Feature | Detected | Notes |
|---------|----------|-------|
| Clock signal | Yes | `clk` — positive edge trigger |
| Async reset | Yes | `rst_n` — active-low, in sensitivity list |
| Counter pattern | Yes | `count` — occupancy counter, literal name match |
| Registers | Yes | `wr_ptr`, `rd_ptr`, `count`, `rd_data` |
| Memory array | Yes | `mem [0:DEPTH-1]` detected as array structure |
| FSM | No | No case statement on a state variable |
| Handshake | Possible | `wr_en`/`rd_en` signals resemble handshake pattern |

**Note on parametric widths:** The FIFO uses `[WIDTH-1:0]` and `[$clog2(DEPTH):0]` for most register widths. ChipLens's counter heuristic requires a literal integer width (e.g., `[3:0]`). The `count`, `wr_ptr`, and `rd_ptr` registers use parametric widths. However, the register name `count` still matches the counter name heuristic, so the counter pattern is detected.

---

## 4. Diagnostics Analysis

**Note:** The benchmark uses a heuristic coverage estimate, not actual formal verification output.

The FIFO has several internal registers (`wr_ptr`, `rd_ptr`, `count`, `rd_data`) and the detected counter, giving a structural complexity above zero. The heuristic coverage estimate falls in the `low` risk tier.

| Field | Value |
|-------|-------|
| Issue count | 1 |
| Issue title | Coverage low |
| Category | coverage |
| Severity | low |
| Coverage risk | CoverageRisk.low |

**Issue description:** "Coverage is slightly below target."

**What this means:** The FIFO has several interesting coverage scenarios that formal verification or simulation would need to exercise: writing to a full FIFO, reading from an empty FIFO, simultaneous read and write, wraparound of pointers, and the boundary conditions at `count == 0` and `count == DEPTH`. The diagnostic flags that these scenarios have not been formally confirmed.

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

**Reasoning:** The repair is categorized as medium complexity. Improving coverage for a FIFO typically involves writing explicit cover properties for the boundary conditions (full, empty, simultaneous read/write, pointer wraparound) and adding formal assertions for invariants such as `count <= DEPTH` and pointer consistency.

---

## 6. Verification Workflow

```text
fifo.v (41 lines, parameterized depth=8, width=8)
     │
     ▼
Design Intelligence (DesignRunner.analyze)
     │  Detected: clock, async reset, counter (count),
     │            registers (wr_ptr, rd_ptr, count, rd_data, mem)
     ▼
Coverage Assessment (heuristic)
     │  Multiple registers detected → complexity ≥ 1
     │  Estimated coverage below minimal threshold → CoverageRisk.low
     ▼
Diagnostics Intelligence (DiagnosticsEngine.analyze)
     │  1 issue: "Coverage low" (severity: low)
     │  Summary: "Minor verification concerns detected."
     ▼
Repair Planning (RepairPlanner.plan)
     │  1 step: "Fix: Coverage low" (priority: low, complexity: medium)
     ▼
BenchmarkResult
     designName: fifo
     diagnostics: 1   repairs: 1   runtime: 3 ms   success: true
```

---

## 7. Observations

**Strengths:**
- Design Intelligence extracts the clock, reset, and counter pattern from the FIFO despite the use of parametric widths. The counter name match (`count`) works independent of bit-width syntax.
- The pipeline handles a moderately complex design (41 lines, multiple internal registers) without errors.
- Runtime is 3 ms end-to-end, including file I/O.

**Limitations:**
- The FIFO presents several interesting formal verification challenges that the benchmark harness does not address: pointer consistency invariants, no-overflow guarantees, FIFO ordering correctness, and simultaneous read/write behavior. The current pipeline identifies the structural complexity but does not generate properties for these behaviors.
- The parametric widths (`[WIDTH-1:0]`, `[$clog2(DEPTH):0]`) prevent some structural heuristics from matching. A concrete instantiation with fixed parameters would enable more precise detection.
- The memory array `mem [0:DEPTH-1]` is detected but not analyzed semantically — ChipLens does not extract read/write access patterns or verify ordering properties.

**Future improvement:** This design is a natural candidate for bounded model checking. Properties like `count == 0 ↔ empty` and `count == DEPTH ↔ full` are simple invariants that a formal tool could verify quickly. ChipLens's property synthesis pipeline would generate these as candidates if run in full mode.
