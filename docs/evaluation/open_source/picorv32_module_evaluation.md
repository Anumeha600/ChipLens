# ChipLens Evaluation: PicoRV32 — picorv32_regs Module

**Status:** Complete — Updated post-Sprint-H-Task-5  
**Initial evaluation date:** 2026-06-25 (Sprint H Task 4)  
**Parser calibration date:** 2026-06-25 (Sprint H Task 5)  
**Tier:** 1 (Small — < 200 lines)  
**ChipLens version:** post-Sprint-H-Task-5 parser robustness calibration

---

## Metadata

| Field | Value |
|-------|-------|
| Design name | picorv32_regs |
| Module name | `picorv32_regs` |
| Repository | https://github.com/YosysHQ/picorv32 |
| Repository commit | Main branch circa 2024 (ISC License) |
| File evaluated | `picorv32.v` (module extracted) |
| License | ISC — Copyright (c) 2015-2016 Claire Wolf |
| Evaluation date | 2026-06-25 |
| ChipLens version | v1.0.0 + Sprint H Task 3 heuristic calibration |
| Tier | 1 |

---

## 1. Design Overview

The PicoRV32 is a compact RISC-V RV32IMC soft-processor implementation written in Verilog by Claire Wolf. It is widely used as a reference design in FPGA and ASIC projects and is the most recognized open-source RISC-V CPU implementation in the Verilog ecosystem.

The `picorv32_regs` module implements the 32-entry general-purpose register file for the RV32 ISA. It provides:
- **Synchronous write**: on `posedge clk` when `wen` (write enable) is asserted
- **Asynchronous read**: via continuous `assign` statements (zero-cycle read latency)
- **Dual read ports**: `rdata1` and `rdata2` for the two source operands
- **Single write port**: `wdata` addressed by `waddr[4:0]` (5-bit = 32 entries)

The module has no reset — register file contents after power-on are undefined, which is the correct RISC-V behavior. Software initializes registers explicitly.

This module was selected as the evaluation target because:
1. It is the only standalone self-contained submodule in the standard `picorv32.v` file
2. It represents a fundamental hardware structure (register file) common to all RISC-V implementations
3. Its small size and well-known behavior make ChipLens outputs directly verifiable
4. It demonstrates specific structural patterns (memory array, dual-port async read) that differ from the wb2axip skidbuffer evaluation

---

## 2. Design Statistics

| Property | Value |
|----------|-------|
| Full RTL lines (with `ifdef` guard) | 20 |
| Evaluated RTL lines | 16 |
| Module count | 1 |
| Language | Verilog |
| Clock domains | 1 (`clk`, posedge, synchronous write) |
| Reset | None (intentional — RV32 ISA behavior) |
| Register file depth | 32 entries |
| Register file width | 32 bits |
| Read ports | 2 (asynchronous) |
| Write ports | 1 (synchronous) |

**Preprocessing applied:**

The standard `picorv32_regs` module in `picorv32.v` wraps its body in a `` `ifndef PICORV32_REGS `` / `` `endif `` guard. This guard allows integrators to substitute an alternative implementation (e.g., FPGA BRAM, latch-based). The content inside the guard is the default flip-flop register file, which is what this evaluation uses.

Preprocessing step: removed `` `ifndef PICORV32_REGS `` and `` `endif `` lines, retaining the body unconditionally.

**Parameters:** None. The module is not parameterized.

---

## 3. ChipLens Design Intelligence Output

> All values are actual outputs from `DesignRunner.analyze()`. None are estimated.

### Raw DesignKnowledge

| Field | Value |
|-------|-------|
| `hasClock` | `true` |
| `hasReset` | `false` |
| `hasFSM` | `false` |
| `hasCounter` | `false` |
| `hasHandshake` | `false` |
| `clocks.length` | 1 |
| `primaryClocks.length` | 1 |
| `syncResets.length` | 0 |
| `asyncResets.length` | 0 |
| `fsms.length` | 0 |
| `counters.length` | 0 |
| `registers.length` | **4** |

**Clock detected:** `clk` (classified as primary — starts with `clk`)  
**Registers detected:** `regs` (sequential), `s` (sequential, **false positive**), `rdata1` (combinational), `rdata2` (combinational)  
**Handshakes:** None

### Register Detection Detail

| Detected name | IsSequential | IsCombinational | Detected width | Actual structure |
|---------------|-------------|-----------------|----------------|-----------------|
| `regs` | true | false | 32 bits | Memory array: 32 × 32-bit registers (`reg [31:0] regs [0:31]`) — **depth dimension not captured** |
| `s` | true | false | 1 bit | **False positive** — captured from expression `regs[...]` where `reg` prefix matches `\breg` regex |
| `rdata1` | false | true | 1 bit | Assign target: `assign rdata1 = regs[raddr1[4:0]]` — **width not captured (actual: 32-bit)** |
| `rdata2` | false | true | 1 bit | Assign target: `assign rdata2 = regs[raddr2[4:0]]` — **width not captured (actual: 32-bit)** |

### Structure Detection Assessment

| Feature | Expected | Detected | Accurate? | Notes |
|---------|----------|----------|-----------|-------|
| Clock (`clk`) | Yes | Yes | **Correct** | Primary clock ✓ |
| Reset | No | No | **Correct** | No reset in this module (RV32 convention) |
| FSM | No | No | **Correct** | |
| Counter | No | No | **Correct** | |
| Handshake | No | No | **Correct** | No protocol signals |
| Register file (memory array) | 32×32-bit | 1×32-bit | **Partial** | `regs` detected as flat register; depth (`[0:31]`) ignored |
| Register `s` | No | Yes | **False positive** | `\breg` regex matches `reg` prefix inside expression `regs[...]` |
| `rdata1` width | 32 bits | 1 bit | **Incorrect** | Assign-target width not inferred from port declaration |
| `rdata2` width | 32 bits | 1 bit | **Incorrect** | Same limitation |

---

## 4. Analysis of False Positives

### §4.1 — False positive register `s` (root cause: `\breg` word-prefix match)

The `RegisterProvider` uses the regex `\breg\s*(?:\[(\d+):\d+\])?\s*(\w+)` to detect registers. The `\b` (word boundary) anchor matches the position before any word character. This means it matches `reg` at the START of longer identifiers like `regs`.

In the expression `regs[waddr[4:0]] <= wdata`:
- `\breg` matches the first three characters `reg` of `regs` (valid word boundary before `r`)
- `\s*` consumes 0 characters (`s` follows immediately)
- `(?:\[...\])?` fails (`s` is not `[`) → optional group skipped
- `(\w+)` matches `s` (the remaining characters of `regs`)

Result: a spurious register named `s` with `isSequential=true` (because a posedge block exists) and width=1 (default, no declaration found).

**Why comment stripping does not fix this:** The expression `regs[...]` is in the actual RTL code, not in a comment. The character-level comment stripper correctly preserves this expression.

**Fix required:** Change `\breg` to `\breg(?!\w)` (negative lookahead: `reg` not followed by a word character). This would exclude matches where `reg` appears as a prefix of a longer identifier. For declaration `reg [31:0] regs`, the match at `reg ` succeeds because `reg` is followed by a space. For expression `regs[...]`, the match at `reg` inside `regs` fails because `s` is a word character.

**Impact of this bug on larger PicoRV32 modules:** The main `picorv32` module uses many signals prefixed with `reg_`: `reg_op1`, `reg_op2`, `reg_pc`, `reg_next_pc`, `reg_wren`, `reg_out`, etc. Each such signal appearing in RTL expressions would produce a false-positive register (`_op1`, `_op2`, `_pc`, `_next_pc`, etc.). This would severely inflate the register count and complexity estimate for the full PicoRV32.

### §4.2 — Memory array depth dimension lost

`reg [31:0] regs [0:31]` declares a 32×32 register file. The RegisterProvider captures `regs` as a single register with width=32 — it does not parse the depth dimension `[0:31]`. ChipLens cannot distinguish between a scalar register and a memory array from the current regex.

### §4.3 — Assign-target width not inferred

`rdata1` and `rdata2` are declared as `output [31:0]` ports and driven by `assign` statements. The RegisterProvider adds them to the register list with default width=1 because:
1. The assign-target regex `\bassign\s+(\w+)\s*=` captures only the signal name, not the width
2. Port declaration widths (`output [31:0] rdata1`) are not cross-referenced

This is a width-accuracy limitation for all assign-target signals.

---

## 5. Diagnostics

> All values are actual outputs from `DiagnosticsEngine.analyze()`.

### Coverage Heuristic

| Field | Value |
|-------|-------|
| Complexity (fsms + counters + registers) | 4 (0 + 0 + 4) |
| Estimated coverage | 77.0% |
| CoverageRisk | `moderate` |
| Confidence | `medium` |

**Note:** The complexity of 4 includes `s` (false positive). Without `s`, complexity would be 3, coverage 82%, and CoverageRisk.low — consistent with the post-calibration wb2axip result.

### DiagnosticReport

| Field | Value |
|-------|-------|
| `overallSeverity` | `medium` |
| `summary.verificationHealth` | `reduced` |
| `issues.length` | **1** |

**Issue #0:**

| Field | Value |
|-------|-------|
| Title | "Coverage moderate" |
| Category | `coverage` |
| Severity | `medium` |
| Description | "Coverage is below acceptable levels at 77.0%. Some state space is unexplored." |

**Is this a false positive?** Yes — `picorv32_regs` is a simple synchronous flip-flop register file with well-understood behavior. The moderate-severity diagnostic does not correspond to a real verification gap. Its severity is inflated by the `s` false-positive register (§4.1).

---

## 6. Repair Suggestions

> All values are actual outputs from `RepairPlanner.plan()`.

| Field | Value |
|-------|-------|
| `overallPriority` | `medium` |
| `overallComplexity` | `medium` |
| `steps.length` | **1** |

**Step #0:**

| Field | Value |
|-------|-------|
| Title | "Fix: Coverage moderate" |
| Category | `coverage` |
| Priority | `medium` |
| Complexity | `medium` |

---

## 7. Runtime

| Metric | Value |
|--------|-------|
| RTL lines | 16 |
| Total pipeline runtime | **25 ms** |
| Design Intelligence runtime | 13 ms |
| Pipeline success | Yes |
| Exception | None |
| Diagnostics per 100 RTL lines | 6.25 |
| Repairs per 100 RTL lines | 6.25 |

**Note on runtime:** The 25 ms total is dominated by cold-start overhead (test infrastructure startup), not by analysis of the 16-line module. The Design Intelligence portion takes 13 ms. For context, the wb2axip skidbuffer (57 lines) also took 23 ms. Runtime does not scale linearly with line count at this scale — cold-start costs dominate.

---

## 8. Comparison with wb2axip Skidbuffer

| Metric | wb2axip skidbuffer | picorv32_regs | Notes |
|--------|-------------------|---------------|-------|
| RTL lines | 57 | 16 | picorv32_regs is 3.5× smaller |
| Total runtime | 23 ms | 25 ms | Both dominated by cold-start overhead |
| `hasClock` | true | true | Both have synchronous logic |
| `primaryClocks` | `[i_clk]` | `[clk]` | Both now correctly primary |
| `hasReset` | true | false | Register file has no reset (by design) |
| `hasFSM` | false | false | Neither has FSM |
| `hasCounter` | false | false | Neither has counter |
| `hasHandshake` | true | false | wb2axip is an AXI component |
| `registers.length` | 3 | 4 | picorv32_regs inflated by `s` false positive |
| False positive registers | 0 | 1 (`s`) | Different root cause |
| Correct registers | 3 | 3 (`regs`, `rdata1`, `rdata2`) | Same structural count |
| complexity | 3 | 4 | Inflated by FP |
| `overallCoverage` | 82.0% | 77.0% | 5 pp difference from FP |
| `CoverageRisk` | `low` | `moderate` | Tier jump from FP |
| Diagnostic count | 1 | 1 | Both produce 1 diagnostic |
| Diagnostic severity | `low` | `medium` | Severity elevated by FP |
| False positive diagnostics | 1/1 | 1/1 | Both: formally simple, diagnostics not actionable |

**Key observation:** Both designs produce 1 diagnostic each, and both diagnostics are false positives — neither design has actionable coverage gaps. The severity difference (low vs. medium) is an artifact of the `\breg` prefix match false positive in picorv32_regs. Without the `s` false positive, both would produce "Coverage low" (severity=low).

**New failure mode (not seen in wb2axip):** The `\breg` word-prefix match that generates `s` from `regs` expressions. The wb2axip evaluation's `istered` was from a comment; this is from RTL code — a distinct root cause requiring a distinct fix.

---

## 9. Findings

**Strengths:**

- Clock correctly detected and classified as primary (`clk` → primary) ✓
- No reset correctly detected — the absence is intentional in this design ✓
- No FSM, no counter, no handshake — all correctly negative ✓
- Memory array `regs` is detected as a register (partial detection — better than not detecting it at all) ✓
- Dual read ports correctly classified as combinational (`rdata1`, `rdata2` from `assign`) ✓
- Pipeline completes on real-world published RTL without error ✓

**Weaknesses:**

- `\breg` regex matches `reg` as a word prefix inside identifiers → `s` false positive. This will cause severe inflation in larger modules with `reg_`-prefixed signals.
- Memory array depth (`[0:31]`) not captured — `regs` appears as a flat 32-bit register rather than a 32×32-bit array.
- Assign-target widths not inferred from port declarations → `rdata1` and `rdata2` show width=1 instead of 32.

**New failure mode identified:**

The `\breg` word-prefix issue is a NEW root cause not previously identified. In wb2axip, the `istered` false positive came from comment text. Here, `s` comes from RTL expression text (`regs[...]`). The two bugs are distinct:
- `istered`: fixed by comment stripping (implemented in Sprint H Task 3)
- `s` from `regs`: requires a negative lookahead in the regex → `\breg(?!\w)` instead of `\breg`

**Implications for larger PicoRV32 modules:**

The main `picorv32` module uses signals prefixed with `reg_` extensively:
- `reg_op1`, `reg_op2` — operand registers
- `reg_pc`, `reg_next_pc` — program counter
- `reg_wren` — register write enable
- `reg_out` — output register
- `regfile_we` — register file write enable

Each of these, when appearing in RTL expressions, would produce false-positive register names: `_op1`, `_op2`, `_pc`, `_next_pc`, `_wren`, `_out`, `ile_we`. This would add 6+ false-positive registers to the count, inflating complexity by 6+, and pushing coverage to 0.97 - (actual + 6) × 0.05, potentially reaching CoverageRisk.high for a correctly-designed processor core.

**Improved behavior since wb2axip:**

- Clock classification improved: `clk` is primary (as expected — no naming convention mismatch here)
- Comment stripping working correctly: no comment-text false positives
- Reset correctly absent: `wen` (write enable) is correctly NOT classified as a reset

---

## 10. Limitations

**Design-specific:**
- Only the `picorv32_regs` module is evaluated. The register file is the simplest submodule in PicoRV32 and is not representative of the complexity of the main core.
- The memory array structure (`regs [0:31]`) is not formally verified in the PicoRV32 repository; there is no formal ground truth for FP/FN measurement comparable to the wb2axip `.sby` files.

**General methodology limitations:**
- `\breg` as a word boundary matches inside identifiers starting with `reg` — not specific to this design.
- Assign-target widths are not inferred from port declarations — widths for `rdata1`, `rdata2` are shown as 1 rather than 32.
- Memory array depth dimensions are not captured — `regs [0:31]` appears as a flat register.

---

## 11. Recommendation

**Question: Is ChipLens ready to evaluate larger PicoRV32 components?**

**Answer (post-Sprint-H-Task-5): Proceed.**

**Evidence:**

All three parser bugs discovered during this evaluation have been fixed in Sprint H Task 5:
1. `\breg(?!\w)` — keyword boundary fix eliminates `s` false positive
2. Memory array depth capture — `reg [31:0] regs [0:31]` now correctly yields `depth=32`
3. Width inference from port declarations — `rdata1` and `rdata2` now correctly show `width=32`

Post-fix results for `picorv32_regs` match ground truth exactly:
- `registers: [regs, rdata1, rdata2]` — no false positives
- `regs.isMemoryArray = true`, `regs.depth = 32`, `regs.width = 32`
- `rdata1.width = 32`, `rdata2.width = 32`
- `complexity = 3`, `overallCoverage = 82.0%`, `CoverageRisk = low`

The three fixes are accompanied by 100 regression tests in `test/parser_regressions/` (keyword_boundary, memory_array, width_inference, picorv32_regression, fsm_counter_keyword_boundary). The `reg_op1`, `reg_pc`, `reg_wren` patterns that would have generated false positives in the main `picorv32` module are also tested and confirmed clean.

**Recommendation: Proceed to evaluate the main `picorv32` module or a larger submodule such as `picorv32_pcpi_mul`.** The parser is now calibrated against the specific patterns used in that codebase.

---

## Before / After Comparison (Sprint H Task 4 → Task 5)

| Metric | Task 4 (pre-fix) | Task 5 (post-fix) | Delta |
|--------|-----------------|-------------------|-------|
| `registers` | `[regs, s, rdata1, rdata2]` | `[regs, rdata1, rdata2]` | FP eliminated |
| `registers.length` | 4 | **3** | −1 |
| `regs.isMemoryArray` | false | **true** | Fixed |
| `regs.depth` | 0 | **32** | Fixed |
| `rdata1.width` | 1 | **32** | Fixed |
| `rdata2.width` | 1 | **32** | Fixed |
| `s` false positive | present | **absent** | Eliminated |
| `complexity` | 4 | **3** | −1 |
| `overallCoverage` | 77.0% | **82.0%** | +5 pp |
| `CoverageRisk` | `moderate` | **`low`** | Improved |
| `overallSeverity` | `medium` | **`low`** | Improved |
| `verificationHealth` | `reduced` | **`acceptable`** | Improved |
| Diagnostic | "Coverage moderate" | **"Coverage low"** | More accurate |

---

## Raw Pipeline Output (Task 4 — pre-fix)

```
=== PICORV32_REGS ANALYSIS RESULTS ===
RTL lines: 16
Total runtime: 25 ms
Design Intelligence runtime: 13 ms

--- DesignKnowledge ---
hasClock:      true
hasReset:      false
hasFSM:        false
hasCounter:    false
hasHandshake:  false
clocks.length:     1
primaryClocks:     [clk]
syncResets:        []
asyncResets:       []
fsms.length:       0
counters.length:   0
counters:          []
registers.length:  4
registers:         [regs, s, rdata1, rdata2]
  (sequential):    [regs, s]
  (combinational): [rdata1, rdata2]
  (widths):        [regs=32, s=1, rdata1=1, rdata2=1]
handshakes:        []
modules:           [picorv32_regs]

--- Coverage heuristic ---
complexity:        4
overallCoverage:   77.0%
CoverageRisk:      moderate
confidence:        medium

--- DiagnosticReport ---
overallSeverity:       medium
verificationHealth:    reduced
issues.length:         1
  issue[0]: title="Coverage moderate" category=coverage severity=medium
            description="Coverage is below acceptable levels at 77.0%. Some state space is unexplored."

--- RepairPlan ---
overallPriority:   medium
overallComplexity: medium
steps.length:      1
  step[0]: title="Fix: Coverage moderate" category=coverage priority=medium complexity=medium
=== END ===
```

## Raw Pipeline Output (Task 5 — post-fix)

```
=== PICORV32_REGS ANALYSIS RESULTS ===
RTL lines: 16
Total runtime: 32 ms
Design Intelligence runtime: 20 ms

--- DesignKnowledge ---
hasClock:      true
hasReset:      false
hasFSM:        false
hasCounter:    false
hasHandshake:  false
clocks.length:     1
primaryClocks:     [clk]
syncResets:        []
asyncResets:       []
fsms.length:       0
counters.length:   0
counters:          []
registers.length:  3
registers:         [regs, rdata1, rdata2]
  (sequential):    [regs]
  (combinational): [rdata1, rdata2]
  (widths):        [regs=32, rdata1=32, rdata2=32]
  (isMemoryArray): [regs=true, rdata1=false, rdata2=false]
  (depth):         [regs=32, rdata1=0, rdata2=0]
handshakes:        []
modules:           [picorv32_regs]

--- Coverage heuristic ---
complexity:        3
overallCoverage:   82.0%
CoverageRisk:      low
confidence:        high

--- DiagnosticReport ---
overallSeverity:       low
verificationHealth:    acceptable
issues.length:         1
  issue[0]: title="Coverage low" category=coverage severity=low
            description="Coverage is slightly below target at 82.0%."

--- RepairPlan ---
overallPriority:   low
overallComplexity: medium
steps.length:      1
  step[0]: title="Fix: Coverage low" category=coverage priority=low complexity=medium
=== END ===
```
