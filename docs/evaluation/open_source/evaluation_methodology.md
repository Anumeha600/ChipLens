# ChipLens Open-Source Evaluation Methodology

**Status:** Planning  
**Date:** 2026-06-24  
**Applies to:** External RTL evaluation (Sprint H and beyond)

---

## Purpose

This document defines how ChipLens will be applied to external open-source RTL designs, what outputs will be collected, which metrics will be used to assess results, and how limitations will be documented.

The methodology is designed to be reproducible: given the same RTL source and the same ChipLens version, the evaluation procedure should produce identical results.

---

## Scope

This methodology covers the Design Intelligence → Diagnostics → Repair Planning pipeline, which is the same path exercised by the existing benchmark harness. It does not cover formal verification execution (SymbiYosys integration), property synthesis quality, or UI interaction.

---

## 1. Inputs

### 1.1 RTL Source

Each evaluated design is represented as a string of Verilog or SystemVerilog source text provided to `DesignRunner.analyze()`.

**Preparation steps:**

1. **File selection:** For multi-file designs, select the top-level module file or the most structurally representative single file. Document which file was chosen and why.
2. **Preprocessing:** Remove any lines that depend on external include files or define macros not present in the selected file. Document all removals.
3. **Parameterization:** Use default parameter values unless a specific instantiation is being evaluated. Document the parameter values used.
4. **No modification:** Do not modify the RTL logic, module boundaries, or signal names. Only preprocessor-level removals (includes, undefined macros) are permitted.

### 1.2 ChipLens Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| ChipLens version | v1.0.0 | Record exact git commit |
| DiagnosticContext | default | `includeEvidence=false`, `includeConfidence=false` |
| RepairContext | default | `includeDependencies=false`, `includeComplexity=false` |
| Providers | default | All registered DesignRunner providers active |

Use the `BenchmarkRunner.runFromSource()` method to ensure consistent execution across all evaluated designs.

### 1.3 Ground Truth (when available)

For designs with existing formal verification artifacts (wb2axip `.sby` files, OpenTitan FPV results), record the formal verification outcome as the ground truth. This enables false positive and false negative computation.

---

## 2. Outputs

For each design, collect the following outputs from the pipeline:

### 2.1 DesignRunner.analyze() → DesignKnowledge

| Field | Collect |
|-------|---------|
| `hasClock` | Yes |
| `hasReset` | Yes |
| `hasFSM` | Yes |
| `hasCounter` | Yes |
| `hasHandshake` | Yes |
| `primaryClocks.length` | Yes |
| `syncResets.length` | Yes |
| `asyncResets.length` | Yes |
| `fsms.length` | Yes |
| `counters.length` | Yes |
| `registers.length` | Yes |

### 2.2 DiagnosticsEngine.analyze() → DiagnosticReport

| Field | Collect |
|-------|---------|
| `issues.length` | Yes |
| `issues[i].title` (each) | Yes |
| `issues[i].category.name` (each) | Yes |
| `issues[i].severity.name` (each) | Yes |
| `overallSeverity.name` | Yes |
| `summary.verificationHealth` | Yes |

### 2.3 RepairPlanner.plan() → RepairPlan

| Field | Collect |
|-------|---------|
| `steps.length` | Yes |
| `steps[i].title` (each) | Yes |
| `steps[i].category.name` (each) | Yes |
| `steps[i].priority.name` (each) | Yes |
| `steps[i].complexity.name` (each) | Yes |
| `overallPriority.name` | Yes |
| `overallComplexity.name` | Yes |

### 2.4 Execution Metrics

| Field | Collect |
|-------|---------|
| Total pipeline runtime (ms) | Yes |
| Pipeline success (no exception) | Yes |
| Exception message (if failure) | Yes |

---

## 3. Metrics

### 3.1 Primary Metrics

These metrics are collected for every evaluated design.

| Metric | Definition | Notes |
|--------|------------|-------|
| **Diagnostic count** | `issues.length` | Total diagnostics produced by DiagnosticsEngine |
| **Repair count** | `steps.length` | Total repair steps produced by RepairPlanner |
| **Runtime (ms)** | Wall-clock time for full pipeline | Measured by `Stopwatch` in BenchmarkRunner |
| **Analysis success rate** | Fraction of designs that complete without exception | Per tier; target: 100% |
| **Detected structure count** | Sum of detected FSMs, counters, registers, clocks | Indicates extraction depth |

### 3.2 Quality Metrics (when ground truth is available)

These metrics require a formal verification reference result (e.g., from an author-provided `.sby` run).

| Metric | Definition | How to Measure |
|--------|------------|----------------|
| **False positive rate** | Fraction of ChipLens diagnostics that do not correspond to a real verification problem | Compare against formal pass/fail; diagnostics on formally-verified designs are FPs |
| **False negative rate** | Fraction of real verification problems not flagged by ChipLens | Requires knowing which aspects of the design are defective; difficult without formal results |
| **Severity calibration** | Whether ChipLens severity matches the actual difficulty of the verification problem | Qualitative; compare ChipLens severity.name against formal verification effort required |

### 3.3 Comparative Metrics

These metrics compare results across designs or between external designs and the existing benchmark corpus.

| Metric | Definition |
|--------|------------|
| **Diagnostic rate vs. design size** | Diagnostics per 100 RTL lines |
| **Runtime vs. design size** | Ms per 100 RTL lines |
| **Structure detection rate** | Detected structures per 100 RTL lines |
| **Repair-to-diagnostic ratio** | Repair steps / diagnostic count (should equal 1.0 in current implementation for non-informational severities) |

### 3.4 Structural Detection Metrics

These metrics assess the accuracy of Design Intelligence.

| Metric | How to Assess |
|--------|---------------|
| **Clock detection accuracy** | Manually verify `hasClock` against RTL; a design with `always @(posedge clk)` should detect true |
| **Reset detection accuracy** | Manually verify `hasReset` against RTL |
| **FSM detection accuracy** | Manually verify `hasFSM` for designs with explicit case-statement FSMs |
| **Counter detection accuracy** | Manually verify `hasCounter` for designs with named counter registers |
| **False FSM detection** | Detect when `hasFSM=true` for a design with no behavioral FSM |
| **False counter detection** | Detect when `hasCounter=true` for a register that is not a counter |

---

## 4. Procedure

### 4.1 Per-Design Evaluation Steps

1. **Record design metadata:** Repository, commit hash, file path, license, line count, module name.
2. **Prepare RTL source:** Apply preprocessing rules documented in Section 1.1.
3. **Run BenchmarkRunner.runFromSource():** Pass the prepared source. Record all outputs from Section 2.
4. **Inspect DesignKnowledge:** Manually review detected structures against the RTL.
5. **Inspect diagnostics and repairs:** Record each issue and step with its category, severity, and description.
6. **Compare against ground truth** (if available): Determine FP/FN status of each diagnostic.
7. **Record observations:** Note unexpected behaviors, detection failures, false positives, runtime anomalies.
8. **Complete results template:** Fill in `results_template.md` for the design.

### 4.2 Tier-Level Aggregation

After completing all designs in a tier:

1. Compute aggregate metrics (mean diagnostic count, mean runtime, analysis success rate).
2. Identify the most common diagnostic categories across the tier.
3. Identify designs where structure detection was notably accurate or inaccurate.
4. Summarize FP/FN rates (if ground truth available).
5. Document lessons learned for the next tier.

### 4.3 Cross-Tier Comparison

After completing all tiers:

1. Plot diagnostic count vs. RTL line count to assess scaling behavior.
2. Plot runtime vs. RTL line count to assess performance scaling.
3. Identify structural patterns that ChipLens handles well vs. poorly.
4. Produce an updated evaluation summary (extending `evaluation_summary.md`).

---

## 5. Limitations and Biases

The following limitations apply to this methodology. They should be acknowledged in every evaluation result.

### 5.1 Heuristic coverage estimate

The coverage assessment used in benchmark mode is a structural complexity heuristic, not a measurement from a formal verification or simulation tool. All coverage diagnostics reflect heuristic estimates, not actual verification gaps. This is the dominant source of false positives.

### 5.2 Single-file analysis

ChipLens's `DesignRunner.analyze()` operates on a single RTL source string. For multi-file hierarchical designs, only the top-level or selected file is analyzed. Cross-module structural patterns (e.g., clocks crossing module boundaries, inter-module FSM dependencies) are not detected.

### 5.3 Text-based structural extraction

All structural detection in ChipLens uses text pattern matching and regular expressions. Features that require elaboration (generate blocks, `ifdef` conditional compilation, parameters resolved at elaboration time) may not be detected correctly.

### 5.4 SystemVerilog limited support

ChipLens's heuristics were developed primarily for Verilog. SystemVerilog-specific constructs (interfaces, packages, structs, enums, always_ff, always_comb) may cause incorrect detection or missed detection.

### 5.5 No formal verification execution

The evaluation does not include a formal verification run. ChipLens's property synthesis, verification planning, and counterexample analysis frameworks are not exercised. The results reflect Design Intelligence + Diagnostics + Repair Planning only.

### 5.6 No simulation data

Coverage estimates are structural heuristics, not derived from simulation or formal coverage tools. The relationship between heuristic complexity and actual verification effort is not calibrated against measured data.

---

## 6. Reproducibility Requirements

All evaluation results must include:

1. **ChipLens version:** Git commit hash
2. **Design version:** Repository URL + commit hash
3. **File path:** Exact file selected for analysis
4. **Preprocessing:** Description of any lines removed or modified
5. **Parameters:** Default parameter values used
6. **Execution date:** ISO 8601 date
7. **Raw outputs:** Complete DesignKnowledge, DiagnosticReport, and RepairPlan field values as collected in Section 2

Results that omit any of these fields are not reproducible and should not be cited in comparative analysis.
