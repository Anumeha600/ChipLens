# Case Study: 4-bit Synchronous Counter

**File:** `test/fixtures/rtl/counter.v`  
**Pipeline run date:** 2026-06-24  
**Benchmark runtime:** 3 ms

---

## 1. Design Overview

The counter is a 4-bit synchronous up-counter with active-low asynchronous reset and clock-enable control. It counts from 0 to 15 and wraps on overflow.

| Property | Value |
|----------|-------|
| Module name | `counter` |
| Output width | 4 bits |
| Clock edge | Positive (posedge clk) |
| Reset type | Asynchronous, active-low (negedge rst_n) |
| Enable | `en` — gates counting when de-asserted |
| RTL lines | 13 |

**Behavioral intent:** When reset is de-asserted and `en` is high, `count` increments by 1 on each rising clock edge. The counter wraps naturally at 15 (4-bit overflow). When `en` is low, the count holds its current value.

---

## 2. RTL Input

```verilog
module counter (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        en,
  output reg  [3:0]  count
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      count <= 4'b0;
    else if (en)
      count <= count + 1'b1;
  end
endmodule
```

Key structural features visible in the RTL:
- Single always block with clock and reset sensitivity
- Asynchronous reset branch (`if (!rst_n)`)
- Conditional increment controlled by `en`
- Output is a registered signal (`output reg`)

---

## 3. Design Intelligence Output

ChipLens runs `DesignRunner.analyze()` against the RTL source. The Design Intelligence framework extracts structural and behavioral knowledge without simulating or executing the design.

**Detected structural features:**

| Feature | Detected | Notes |
|---------|----------|-------|
| Clock signal | Yes | `clk` — positive edge trigger |
| Async reset | Yes | `rst_n` — active-low, in sensitivity list |
| Counter pattern | Yes | `count` — literal 4-bit width matched by counter heuristic |
| Register | Yes | `count` — clocked assignment target |
| FSM | No | No case statement or state register |
| Handshake | No | No ready/valid pair |

The counter pattern is detected because `count` uses a literal integer width (`[3:0]`) rather than a parametric expression. ChipLens's counter heuristic matches register names containing `cnt`, `count`, or `counter` with literal bit widths.

---

## 4. Diagnostics Analysis

**Note:** The benchmark pipeline does not execute formal verification. The coverage assessment is derived from a structural complexity heuristic based on `DesignKnowledge`.

**Heuristic:** `complexity = counters.length + registers.length`. Coverage estimate falls with complexity. For this design, complexity is low, placing estimated coverage in the `low` risk tier.

| Field | Value |
|-------|-------|
| Issue count | 1 |
| Issue title | Coverage low |
| Category | coverage |
| Severity | low |
| Estimated coverage | ~91% |
| Coverage risk | CoverageRisk.low |

**Issue description:** "Coverage is slightly below target at 91.0%."

**What this means:** The design has detected structural elements (the `count` register) that cause the heuristic to estimate non-trivial state space. Without actual formal verification, ChipLens cannot confirm whether the count register's full value range is exercised.

---

## 5. Repair Planning

The `RepairPlanner` maps each diagnostic to a concrete repair suggestion.

| Field | Value |
|-------|-------|
| Step count | 1 |
| Step title | Fix: Coverage low |
| Category | coverage |
| Priority | low |
| Complexity | medium |
| Dependencies | none |

**Repair description:** "Coverage is slightly below target at 91.0%."

**Reasoning:** `RepairPlanner` maps `DiagnosticCategory.coverage` → `RepairCategory.coverage` and `DiagnosticSeverity.low` → `RepairPriority.low`. Coverage repairs are assigned medium complexity because they typically require adding test sequences or formal cover properties rather than simple configuration changes.

---

## 6. Verification Workflow

```text
counter.v (13 lines, 4-bit counter)
     │
     ▼
Design Intelligence (DesignRunner.analyze)
     │  Detected: clock, async reset, counter pattern, register
     ▼
Coverage Assessment (heuristic)
     │  Estimated coverage: 91.0%  →  CoverageRisk.low
     ▼
Diagnostics Intelligence (DiagnosticsEngine.analyze)
     │  1 issue: "Coverage low" (severity: low)
     ▼
Repair Planning (RepairPlanner.plan)
     │  1 step: "Fix: Coverage low" (priority: low, complexity: medium)
     ▼
BenchmarkResult
     designName: counter
     diagnostics: 1   repairs: 1   runtime: 3 ms   success: true
```

---

## 7. Observations

**Strengths:**
- Design Intelligence correctly identifies the counter pattern, clock, and asynchronous reset. The structural extraction is fast (sub-millisecond for a 13-line module).
- The full pipeline completes end-to-end without errors.
- Results are deterministic: repeated runs produce identical outputs.

**Limitations:**
- The coverage assessment is a heuristic estimate, not a measurement from formal verification or simulation. The 91% figure does not correspond to any actual coverage metric run against the design.
- The counter heuristic requires literal integer widths. A parametric `output reg [WIDTH-1:0] count` would not be detected as a counter.
- No properties are synthesized or verified in benchmark mode. ChipLens identifies that the counter exists but does not generate or check properties like "count resets to zero on rst_n" or "count increments by 1 when en is asserted."

**Future improvement:** Running ChipLens's full property synthesis pipeline against this design would generate and rank candidate properties for the counter increment behavior, reset behavior, and overflow invariant.
