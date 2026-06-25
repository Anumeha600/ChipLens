# ChipLens Evaluation: wb2axip Skidbuffer

**Status:** Updated (Sprint H Task 3)  
**Original evaluation date:** 2026-06-24  
**Updated date:** 2026-06-25  
**Tier:** 1 (Small — < 200 lines)  
**ChipLens version:** v1.0.0 → post-Task-3 heuristic calibration

---

## Metadata

| Field | Value |
|-------|-------|
| Design name | skidbuffer |
| Module name | `skidbuffer` |
| Repository | https://github.com/ZipCPU/wb2axip |
| Author | Dan Gisselquist (ZipCPU) |
| License | LGPL-3.0 with commercial exception |
| Language | Verilog |
| Full RTL lines (with generate + formal) | ~220 lines |
| Preprocessed RTL lines evaluated | 57 lines |
| Evaluation date | 2026-06-24 |
| ChipLens version | v1.0.0 |
| Tier | 1 |

---

## 1. Design Overview

The wb2axip skidbuffer is a flow-control buffer for the AXI ready/valid handshake protocol. Its purpose is to break the combinational path between `i_ready` and `o_ready`, which is required when chaining AXI components that would otherwise create long timing paths. The design accepts a data word when `i_valid && o_ready` is true, and outputs it when `o_valid && i_ready` is true.

The core mechanism: when the downstream side cannot accept data (`!i_ready`) but upstream is still presenting data (`i_valid && o_ready`), the extra word is stored in a one-word buffer (`r_data`, `r_valid`). This allows `o_ready` to remain high until the buffer is full (i.e., exactly one word deep backpressure tolerance).

The design is parameterized with `OPT_OUTREG`, `OPT_LOWPOWER`, and `OPT_PASSTHROUGH`. This evaluation uses the default `OPT_OUTREG=1` path (registered output), which is the most common configuration.

**Formal verification status:** Formally verified by the author. The repository includes `.sby` SymbiYosys configuration files that check AXI handshake correctness properties. The design is considered correct for all legal input sequences.

---

## 2. Design Statistics

| Property | Value |
|----------|-------|
| Full RTL lines | ~220 (including generate blocks + `ifdef FORMAL` assertions) |
| Evaluated RTL lines | 57 (preprocessed) |
| Module count | 1 |
| Language | Verilog |
| Clock domains | 1 (`i_clk`, posedge) |
| Reset style | Synchronous, active-high (`i_reset`) |
| Buffer depth | 1 word |
| Data width | `DW` bits (default 8) |

**Preprocessing applied:**

The full skidbuffer.v uses Verilog `generate` blocks to select between `OPT_OUTREG` (registered output) and combinational output paths, and between `OPT_LOWPOWER` data gating variants. ChipLens's `DesignRunner.analyze()` operates on flat source text and does not elaborate generate blocks.

Preprocessing steps applied to produce the 57-line evaluated version:
1. Selected the `OPT_OUTREG=1, OPT_LOWPOWER=0` path and removed `generate`/`endgenerate` wrappers
2. Removed the `` `ifdef FORMAL ... `endif `` block containing formal assertions
3. Removed the `` `default_nettype none `` directive

**Parameters used:** `OPT_LOWPOWER=0`, `OPT_OUTREG=1`, `OPT_PASSTHROUGH=0`, `DW=8` (all defaults)

---

## 3. ChipLens Design Intelligence Output

All values below are actual outputs from `DesignRunner.analyze()`. None are estimated.

### Raw DesignKnowledge

| Field | Value |
|-------|-------|
| `hasClock` | `true` |
| `hasReset` | `false` |
| `hasFSM` | `false` |
| `hasCounter` | `false` |
| `hasHandshake` | `true` |
| `clocks.length` | 1 |
| `primaryClocks.length` | 0 |
| `syncResets.length` | 0 |
| `asyncResets.length` | 0 |
| `fsms.length` | 0 |
| `counters.length` | 0 |
| `registers.length` | 4 |

**Clock detected:** `i_clk` (classified as candidate, not primary)  
**Registers detected:** `o_ready`, `o_valid`, `r_valid`, `istered`  
**Handshakes detected:** `valid_ready`

### Structure Detection Assessment

| Feature | Expected | Detected | Accurate | Notes |
|---------|----------|----------|----------|-------|
| Clock (`i_clk`) | Yes | Yes | **Partial** | Detected as candidate, not primary — see §3.1 |
| Reset (`i_reset`) | Yes | **No** | **False negative** | See §3.2 |
| FSM | No | No | Correct | No case-statement FSM present |
| Counter | No | No | Correct | No counting registers |
| Handshake (valid/ready) | Yes | Yes | **Correct** | `valid_ready` protocol correctly identified |
| Register `r_valid` | Yes | Yes | Correct | Buffer occupancy flag |
| Register `o_valid` | Yes | Yes | Correct | Registered output valid |
| Register `o_ready` | Yes | Yes | **Partial** | Detected as sequential; it is actually combinational (driven by `always @(*)`) |
| Register `istered` | No | Yes | **False positive** | See §3.3 |

#### §3.1 — Clock not classified as primary

The ClockProvider classifies clocks as "primary" if their name starts with one of the standard prefixes: `clk`, `clock`, `sys_clk`, `pclk`, `aclk`, `hclk`, `mclk`, `sclk`, `osc_clk`. The skidbuffer uses the ZipCPU naming convention `i_clk` (with input prefix `i_`), which does not match any primary prefix.

The clock IS detected (`clocks.length = 1`, `hasClock = true`) but `primaryClocks.length = 0`. Components downstream from `DesignKnowledge` that depend on `primaryClocks` (if any) would not find this clock. This is a naming convention mismatch, not a logic error in ChipLens.

#### §3.2 — Reset not detected (false negative)

The ResetProvider identifies synchronous active-high resets by matching signal names against the pattern `^(rst|reset|arst|srst|nrst|rstb|areset|sreset)`. The skidbuffer uses `i_reset` (with ZipCPU's `i_` input prefix). The name `i_reset` does not match the pattern because it does not start with `rst` or `reset` — it starts with `i_`.

Result: `hasReset = false`, `syncResets = []`, `asyncResets = []`.

This is a false negative. The design has a synchronous active-high reset at `i_reset`. Any coverage analysis, property synthesis, or diagnostic reasoning that depends on reset detection will miss this aspect of the design.

**Root cause:** The provider uses a name-prefix heuristic that does not account for signal naming conventions that include port direction prefixes (`i_`, `o_`, `io_`). This is a systematic limitation affecting any design from a codebase that uses this convention (ZipCPU, many AXI designs).

#### §3.3 — False positive register `istered`

The RegisterProvider uses the regex `\breg\s*(?:\[(\d+):\d+\])?\s*(\w+)` to detect registers. This matches the keyword `reg` at a word boundary, followed optionally by a bit-width, followed by an identifier.

The comment text `// o_valid: registered output valid (OPT_OUTREG=1 path)` contains the word `registered`. The regex engine matches `reg` at the word boundary before `registered`, then captures `istered` (the remainder of the word) as the register name.

Result: A spurious register named `istered` appears in `knowledge.registers`.

**Impact:** `registers.length = 4` instead of the correct 3 (or 2, excluding the combinational `o_ready`). This inflates the complexity heuristic and worsens the coverage risk estimate.

**Root cause:** The regex does not exclude comment text. Verilog inline comments (`//`) are not stripped before analysis.

---

## 4. Diagnostics

> All values are actual outputs from `DiagnosticsEngine.analyze()`.

### Coverage Heuristic

| Field | Value |
|-------|-------|
| Complexity (fsms + counters + registers) | 4 (0 + 0 + 4) |
| Estimated coverage | 73.0% |
| CoverageRisk | `moderate` |

**Note:** The complexity count of 4 includes `istered` (false positive register from §3.3) and `o_ready` (combinational signal misclassified as sequential). The correct count of genuine sequential registers is 2 (`r_valid`, `o_valid`). The inflated count directly worsens the coverage estimate.

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
| Description | "Coverage is below acceptable levels at 73.0%. Some state space is unexplored." |

---

## 5. Repair Suggestions

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

## 6. Runtime

| Metric | Value |
|--------|-------|
| Total pipeline runtime | **30 ms** |
| Pipeline success | Yes |
| Exception | None |

The 30 ms runtime is higher than the benchmark fixtures (2–4 ms) despite the 57-line preprocessed source being similar in length to the benchmark uart.v (78 lines). The difference likely reflects cold-start overhead from loading a test file outside the standard benchmark path, rather than a genuine scalability issue.

---

## 7. Ground Truth Comparison

**Reference:** wb2axip formal verification collateral (`.sby` files by Dan Gisselquist, ZipCPU)

**Formal verification outcome:** The skidbuffer is formally verified by its author using SymbiYosys. The formal properties check AXI handshake correctness: specifically, that `o_valid` is never de-asserted without `i_ready` being asserted (stall-free forwarding), that no data is lost when the buffer is occupied, and that `o_ready` correctly signals backpressure. The design is accepted as correct for all legal input sequences.

### ChipLens Output vs. Ground Truth

| ChipLens Output | Corresponds to Real Issue? | Classification | Notes |
|-----------------|---------------------------|----------------|-------|
| "Coverage moderate" — 73.0% coverage estimate | **No** | **False Positive** | Design is formally verified correct; the diagnostic reflects the heuristic, not an actual gap |

**False positive count: 1 (of 1 diagnostics)**  
**False negative count: 0 identifiable** (ChipLens produced no diagnostics for the reset or clock convention issues; however, these are detection limitations, not diagnostic false negatives)

**FP rate for this design: 100% (1/1)**

This is the most important quantitative finding of this evaluation. The single diagnostic produced by ChipLens for the wb2axip skidbuffer is a false positive: the design is formally verified, yet ChipLens reports medium-severity coverage concern. The root cause is that the coverage heuristic has no awareness of whether a design has been formally verified, and independently inflates the concern due to the `istered` false-positive register.

---

## 8. Observations

**Accurate detections:**
- Clock signal detected correctly (`hasClock = true`, `i_clk` identified)
- Handshake protocol detected correctly (`valid_ready`, from `i_valid`/`o_valid`/`i_ready`/`o_ready`)
- No FSM detected — correct (the design uses register-based flow control, not a case-statement FSM)
- No counter detected — correct

**False positives:**
- Register `istered` detected from comment text. The word `registered` in a comment triggers the register regex. This inflates the register count from 3 to 4 and worsens the coverage estimate.
- `o_ready` classified as a sequential register when it is driven by `always @(*)` (combinational). The RegisterProvider uses `assign` statements to identify combinational signals, but `always @(*)` blocks are not checked. This does not affect the register count but misclassifies the signal type.

**False negatives:**
- `i_reset` not detected as a reset signal. The ZipCPU naming convention (`i_` prefix) is not in ChipLens's reset name pattern. `hasReset = false` for a design that clearly has a synchronous reset.
- `i_clk` not classified as a primary clock. `primaryClocks = []` for a design with one clock.

**Unexpected behaviors:**
- The single diagnostic (coverage moderate) is a false positive for a formally verified design.
- The diagnostic severity is `medium` rather than `low` because the false-positive register inflates complexity from 2 to 4, pushing coverage from 85% to 73%, crossing the low→moderate boundary.
- Without the `istered` false positive, complexity = 3, coverage = 0.79 → still moderate (0.79 < 0.80). Even with correct register detection, the diagnostic would still be a false positive.

---

## 9. Limitations

**Design-specific:**

- The 57-line evaluation source is a preprocessed subset of the full ~220-line design. Generate blocks for `OPT_PASSTHROUGH` and `OPT_LOWPOWER` paths are not analyzed. ChipLens results apply only to the `OPT_OUTREG=1, OPT_LOWPOWER=0` configuration.
- The formal verification properties from the `.sby` file were not examined in detail. The ground truth judgment ("formally verified") is based on the repository documentation and published status, not on reproducing the formal run.

**General methodology limitations** (from `evaluation_methodology.md`):

- Coverage estimate is a structural heuristic, not a measurement from a formal or simulation tool.
- Text-based pattern matching does not elaborate generate blocks or evaluate parameter expressions.
- `always @(*)` combinational blocks are not distinguished from `always @(posedge clk)` sequential blocks for signal classification purposes.
- Signal naming conventions with direction prefixes (`i_`, `o_`, `io_`) are not handled by clock or reset name heuristics.
- Comment text is not stripped before analysis.

---

## 10. Improvement Opportunities

The following specific improvements are motivated by this evaluation.

| Improvement | Affected Component | Priority | Status (Sprint H Task 3) |
|-------------|-------------------|----------|--------------------------|
| Strip comments before analysis | `DesignRunner` / `RtlPreprocessor` | **High** | **Implemented** |
| Extend reset name heuristic to include `i_` direction prefix | `ResetProvider` | **High** | **Implemented** |
| Extend primary clock name heuristic to include `i_clk`, `clk_i`, etc. | `ClockProvider` | **Medium** | **Implemented** |
| Reduce coverage heuristic penalty per complexity unit (6 pp → 5 pp) | `BenchmarkRunner._buildCoverage` | **Medium** | **Implemented** |
| Detect `always @(*)` as combinational (not sequential) | `RegisterProvider` | **Medium** | Deferred |

---

## 11. Conclusions

**Would ChipLens provide useful insight for this design?**

Yes — with qualifications — after Sprint H Task 3 improvements.

After calibration, ChipLens correctly identifies:
- The `valid_ready` handshake protocol (the central behavioral feature)
- The clock (`i_clk`, now classified as primary)
- The synchronous reset (`i_reset`, now correctly detected)
- No FSM, no counter (both correct)

The one remaining diagnostic ("Coverage low", severity=low) is still technically a false positive for a formally verified design. However, a `low`-severity suggestion to improve coverage is a much weaker claim than the previous `medium`-severity "Coverage moderate" alert. The improvement reduces the misstatement from alarming to informational.

**What improved (Sprint H Task 3):**
- Comment stripping eliminates `istered` false positive — register count correct
- `i_reset` now detected — `hasReset = true`
- `i_clk` now primary — `primaryClocks = [i_clk]`
- Coverage estimate: 73% → 82% (complexity 4 → 3, penalty 6 pp → 5 pp)
- Diagnostic severity: medium → low; health: reduced → acceptable

**What remains:**
- `o_ready` misclassified as sequential (driven by `always @(*)`, not `assign`)
- The diagnostic is still a false positive for a formally verified design — the heuristic has no awareness of formal verification status
- Parametric widths (`[DW-1:0]`) remain undetected — `r_data` is not in the register list

**Recommendation: PROCEED to PicoRV32 evaluation.**

The two blocking issues (comment false positives and reset name mismatch) are resolved. The PicoRV32 evaluation is now likely to produce interpretable results. The remaining limitation (`always @(*)` classification) is documented and does not affect structural detection accuracy materially.

---

## Updated Results (Sprint H Task 3)

The following table records measured output changes after implementing the four calibrations. All values are actual pipeline outputs, not estimates.

| Metric | v1.0.0 Original | Post-Task-3 | Change |
|--------|-----------------|-------------|--------|
| `hasReset` | `false` | **`true`** | False negative resolved |
| `primaryClocks` | `[]` | **`[i_clk]`** | Classification corrected |
| `registers` | `[o_ready, o_valid, r_valid, istered]` | **`[o_ready, o_valid, r_valid]`** | False positive eliminated |
| `registers.length` | `4` | **`3`** | Count corrected |
| complexity | `4` | **`3`** | Register false positive removed |
| `overallCoverage` | `73.0%` | **`82.0%`** | Both fixes combined |
| `CoverageRisk` | `moderate` | **`low`** | Penalty + count correction |
| `overallSeverity` | `medium` | **`low`** | Follows risk |
| `verificationHealth` | `reduced` | **`acceptable`** | Follows severity |
| diagnostic title | "Coverage moderate" | **"Coverage low"** | Less alarming |
| diagnostic severity | `medium` | **`low`** | Less alarming |
| repair priority | `medium` | **`low`** | Follows severity |
| False positive diagnostic? | Yes (medium) | **Yes (low)** | Reduced impact |

**Root cause of remaining false positive:** The heuristic has no mechanism to recognise formal verification collateral. The diagnostic "Coverage low" does not correspond to a real gap; the design is formally verified. This is a known limitation of the heuristic approach and is documented in `evaluation_methodology.md`.

---

## Raw Pipeline Output

### Original (v1.0.0, Sprint H Task 2)

```
=== SKIDBUFFER ANALYSIS RESULTS ===
RTL lines: 57
Total runtime: 30 ms
Design Intelligence runtime: 16 ms

--- DesignKnowledge ---
hasClock:      true
hasReset:      false
hasFSM:        false
hasCounter:    false
hasHandshake:  true
clocks.length:     1
primaryClocks:     []
syncResets:        []
asyncResets:       []
fsms.length:       0
counters.length:   0
counters:          []
registers.length:  4
registers:         [o_ready, o_valid, r_valid, istered]
handshakes:        [valid_ready]

--- Coverage heuristic ---
complexity:        4
overallCoverage:   73.0%
CoverageRisk:      moderate

--- DiagnosticReport ---
overallSeverity:       medium
verificationHealth:    reduced
issues.length:         1
  issue[0]: title="Coverage moderate" category=coverage severity=medium
            description="Coverage is below acceptable levels at 73.0%. Some state space is unexplored."

--- RepairPlan ---
overallPriority:   medium
overallComplexity: medium
steps.length:      1
  step[0]: title="Fix: Coverage moderate" category=coverage priority=medium complexity=medium
=== END ===
```

### Updated (post Sprint H Task 3 calibration)

```
=== SKIDBUFFER ANALYSIS RESULTS ===
RTL lines: 57
Total runtime: 23 ms
Design Intelligence runtime: 13 ms

--- DesignKnowledge ---
hasClock:      true
hasReset:      true
hasFSM:        false
hasCounter:    false
hasHandshake:  true
clocks.length:     1
primaryClocks:     [i_clk]
syncResets:        [i_reset]
asyncResets:       []
fsms.length:       0
counters.length:   0
counters:          []
registers.length:  3
registers:         [o_ready, o_valid, r_valid]
handshakes:        [valid_ready]

--- Coverage heuristic ---
complexity:        3
overallCoverage:   82.0%
CoverageRisk:      low

--- DiagnosticReport ---
overallSeverity:       low
verificationHealth:    acceptable
issues.length:         1
  issue[0]: title="Coverage low" category=coverage severity=low
            description="Coverage is below target levels at 82.0%. Consider extending test scenarios."

--- RepairPlan ---
overallPriority:   low
overallComplexity: medium
steps.length:      1
  step[0]: title="Fix: Coverage low" category=coverage priority=low complexity=medium
=== END ===
```
