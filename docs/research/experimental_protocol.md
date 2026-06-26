# Experimental Protocol

**Sprint I Task 1 — Protocol Definition**  
**Date:** 2026-06-25  
**Status:** Protocol defined — no experiments executed yet

---

## 1. Purpose

This document defines the step-by-step protocol for conducting a reproducible verification productivity study using ChipLens. It specifies:

- How designs are selected and prepared
- How ground truth is established
- How ChipLens outputs are measured
- How results are documented
- What future experiments are planned

---

## 2. Evaluation Dataset

### Current Corpus (Sprint H)

| Design | Module | Language | Lines | Source |
|--------|--------|---------|-------|--------|
| wb2axip | `skidbuffer` | Verilog | 57 (preprocessed) | github.com/ZipCPU/wb2axip |
| PicoRV32 | `picorv32_regs` | Verilog | 16 (preprocessed) | github.com/YosysHQ/picorv32 |
| SERV | `serv_alu` | Verilog | 106 (verbatim) | github.com/olofk/serv |
| Ibex | `ibex_register_file_ff` | SystemVerilog | 63 (preprocessed) | github.com/lowrisc/ibex |

All designs are open-source with permissive licenses (Apache-2.0, ISC, MIT-compatible). All evaluations used verbatim or minimally preprocessed RTL from publicly accessible repositories.

### Future Evaluation Candidates

| Design | Module candidates | Language | Rationale |
|--------|------------------|---------|----------|
| OpenTitan | UART, SPI, I2C controllers | SystemVerilog | Industrial-scale SV; formal verification baseline exists |
| LiteX | Generated bus fabric | Verilog (generated) | Tests auto-generated RTL patterns |
| VexRiscv | Execute stage | Verilog (SpinalHDL output) | Generated RTL with unusual patterns |
| CV32E40P | Pipeline stages | SystemVerilog | OpenHW core; large-scale SV evaluation |

**Expansion criteria:** New designs should be selected to stress dimensions not covered by the current corpus:
- Larger scale (>500 lines per module)
- Deeper hierarchy (multi-level submodule instantiation)
- Complex interfaces (AXI4, TileLink)
- Formal verification ground truth available

---

## 3. Ground Truth Establishment Protocol

**This must be completed BEFORE running ChipLens on the design.**

### Step 1: Obtain canonical RTL

- Record exact repository URL, branch, and commit hash
- Record license
- Note preprocessing applied (if any) and justify each transformation

### Step 2: Manual structural inventory

An engineer familiar with the design architecture (but who has not yet seen ChipLens output on this design) performs the following and records results in a structured form:

```
STRUCTURAL INVENTORY FORM
Module: ____________
Evaluator: ____________  (must not have seen ChipLens output)
Date: ____________

Sequential registers: (list name, type, width, reset)
1.
2.
...

Combinational signals: (list name, width, driven by)
1.
2.
...

Memory arrays: (list name, width, depth)
1.
...

Clocks: (list name, edge, frequency if known)
1.
...

Resets: (list name, type async/sync, polarity)
1.
...

FSMs: (list name, encoding, state count, transition count)
1.
...

Counters: (list name, width, direction)
1.
...

Handshakes / protocols: (list signal pairs, protocol name)
1.
...
```

### Step 3: Lock ground truth

Finalize the inventory. Do not modify after ChipLens results are observed. Any post-run corrections must be logged as "evaluator correction" with justification, and must be reviewed by a second evaluator.

### Step 4: Classify elements by parser scope

For each element in the ground truth, classify as:

- `IN_SCOPE` — element type and syntax are within documented parser scope
- `OUT_OF_SCOPE` — element type or syntax is outside documented parser scope (e.g., `logic` declarations in SV, parameterized depth arrays)
- `AMBIGUOUS` — unclear whether parser should detect this element

Exclude `OUT_OF_SCOPE` elements from precision/recall calculation. Include them in a "known limitations" summary.

---

## 4. ChipLens Measurement Protocol

**Performed after ground truth is locked.**

### Step 1: Record parser version

Note the exact git commit hash of ChipLens being evaluated. Do not run ChipLens on a design if parser changes are planned — freeze the parser first.

### Step 2: Run full pipeline

Execute:
```dart
final knowledge = await DesignRunner.analyze(DesignContext(rtlSource: rtl));
```

Record the complete output of all 10 providers (clock, reset, register, FSM, counter, handshake, module, property, coverage, diagnostic).

### Step 3: Collect primary measurements

For each metric defined in `verification_metrics.md`:

```
DU-1: registers.length = ___
DU-1a: sequential count = ___
DU-1b: combinational count = ___
DU-1c: memory array count = ___
DU-1d: widthIsKnown=true count = ___
DU-1e: widthIsKnown=false count = ___
DU-2: clocks.length = ___
DU-2a: primaryClocks.length = ___
DU-2b: candidateClocks.length = ___
DU-3: resets.length = ___
DU-3a: asyncResets.length = ___
DU-3b: syncResets.length = ___
DU-4: fsms.length = ___
DU-5: counters.length = ___
DU-6: handshakes.length = ___
PG-1: candidates.length = ___
PG-2: rankedProperties.length = ___
PG-3: emittedProperties.length = ___
PL-1: plan.tasks.length = ___
DG-1: issues.length = ___
DG-2: verificationHealth = ___
RP-1: repairPlan.steps.length = ___
WF-4: totalRuntime (ms) = ___
```

### Step 4: Compute DU-7 (structural accuracy)

Against the locked ground truth (IN_SCOPE elements only):

```
For each IN_SCOPE element in ground truth:
  - If detected by ChipLens: TRUE_POSITIVE
  - If not detected: FALSE_NEGATIVE

For each element detected by ChipLens:
  - If in ground truth: TRUE_POSITIVE
  - If not in ground truth: FALSE_POSITIVE

Precision = TP / (TP + FP)
Recall    = TP / (TP + FN)
F1        = 2 * P * R / (P + R)
```

Record separately for each structural category (registers, clocks, resets, FSMs, counters, handshakes).

### Step 5: Record all anomalies

For each false positive and false negative:
- Name of the incorrectly detected / missed element
- Root cause classification:
  - `PARSER_BUG` — regex pattern error, fixable
  - `HEURISTIC_LIMITATION` — pattern correct but inference wrong
  - `UNSUPPORTED_SYNTAX` — syntax not in documented parser scope
  - `ARCHITECTURE_LIMITATION` — would require significant architectural change
  - `INTENTIONAL_SIMPLIFICATION` — known tradeoff, documented
  - `EXTERNAL_TOOL_LIMITATION` — depends on tool not available

---

## 5. Reproducibility Requirements

Any evaluation must be reproducible by an independent party. Each evaluation must document:

1. **Exact RTL text** — embedded verbatim in evaluation document or linked by commit hash
2. **ChipLens git hash** — parser version used
3. **Flutter/Dart version** — build environment
4. **Complete raw pipeline output** — all field values from `DesignKnowledge` and downstream stages
5. **Preprocessing steps** — every transformation applied to the RTL before analysis
6. **Ground truth inventory** — locked before ChipLens was run

---

## 6. Sprint I Evaluation Status

The following table shows evaluation completion status against the protocol defined above.

| Step | wb2axip | PicoRV32 | SERV | Ibex |
|------|---------|---------|------|------|
| Canonical RTL documented | ✓ | ✓ | ✓ | ✓ |
| License recorded | ✓ | ✓ | ✓ | ✓ |
| Preprocessing documented | ✓ | ✓ | ✓ | ✓ |
| Ground truth established pre-run | Partial | Partial | ✓ | Partial |
| Ground truth locked before ChipLens | Partial | Partial | ✓ | Partial |
| ChipLens version recorded | ✓ | ✓ | ✓ | ✓ |
| Raw pipeline output recorded | ✓ | ✓ | ✓ | ✓ |
| DU-7 computed | Partial | Partial | ✓ | Partial |
| FP/FN root causes classified | ✓ | ✓ | ✓ | ✓ |
| Independent replication | — | — | — | — |

**Gap:** Ground truth was partially established during or after ChipLens evaluation runs in wb2axip, PicoRV32, and Ibex cases. This is documented as a threat (IV-3 in `threats_to_validity.md`). Sprint I Task 2 should establish a fully pre-locked ground truth for at least one design.

---

## 7. Future Experiment Designs

### Experiment A: Holdout Validation

**Objective:** Validate that parser accuracy observed on the current four designs is not specific to those designs (i.e., over-fitted by calibration).

**Design:**
- Select 4–8 new open-source Verilog designs not used in Sprint H calibration
- Establish ground truth per Section 3 protocol
- Run ChipLens without any parser changes
- Measure DU-7 on holdout set
- Compare holdout F1 to Sprint H F1

**Expected outcome:** F1 on holdout set should be within ±10% of Sprint H set. If significantly lower, parser calibration is over-fitted to the Sprint H designs.

**Minimum corpus size:** 4 additional modules, ≥ 2 with formal verification ground truth.

---

### Experiment B: SystemVerilog Baseline Measurement

**Objective:** Establish DU-7 for SystemVerilog designs with the current parser (post-Task-8 fixes).

**Design:**
- Select 3–5 SystemVerilog modules from OpenTitan or CV32E40P
- Establish ground truth per Section 3 (classify logic declarations as OUT_OF_SCOPE)
- Run ChipLens (post-Task-8 parser)
- Measure DU-7 for IN_SCOPE elements (assign targets, clock/reset detection)

**Expected outcome:** Clock and reset detection should be near 100% for designs using `always_ff` (Task-8 fixes). Register detection will show high false-negative rate due to logic limitation. This establishes the pre-SV-calibration baseline.

---

### Experiment C: Controlled Productivity Comparison (Human Study)

**Objective:** Measure actual engineer time savings from ChipLens use.

**Design:**
- Select 2 modules of similar complexity from the evaluation corpus
- Recruit N ≥ 6 verification engineers (3 per condition)
- Condition A: Manual workflow — engineer analyzes RTL and writes assertions independently
- Condition B: ChipLens-assisted — engineer reviews and extends ChipLens output
- Measure: Time to first complete assertion set; number of assertions written; structural coverage
- Analysis: Compare time and coverage between conditions

**Validity requirements:**
- Randomized assignment to conditions
- Blinded quality evaluation of produced assertions
- Pre-registered analysis plan
- Pre-registered success criteria

**Note:** This experiment requires significant organizational infrastructure (participants, IRB if human subjects, design ownership). It is a medium-term research goal, not a near-term deliverable.

---

### Experiment D: Coverage Heuristic Calibration

**Objective:** Validate the `0.97 - 0.05 × complexity` coverage heuristic against actual formal verification results.

**Design:**
- Select designs where formal verification has been run (wb2axip has .sby files)
- For each design: run SymbiYosys, record actual proof success rates
- Compare heuristic coverage estimate to formal proof completion rate
- Recalibrate heuristic if systematic bias is identified

**Prerequisite:** SymbiYosys must be installed and integrated (currently `NOT_INSTALLED` in test environment). This experiment is blocked until the formal engine integration is complete.

---

## 8. Recommendation for Sprint I Task 2

Based on the protocol analysis in this document, Sprint I Task 2 should:

1. Select one design from the current corpus (recommended: SERV serv_alu — ground truth most complete)
2. Apply the full ground truth establishment protocol per Section 3, using an independent evaluator
3. Compute DU-7 per Section 4, Step 4, with full FP/FN breakdown
4. Document whether the DU-7 result changes when ground truth is established without seeing ChipLens output first
5. Identify the highest-value metric gap: is it structural accuracy (DU-7), planning completeness (PL-2), or something else?

This would establish the first fully protocol-compliant evaluation in the corpus and provide a template for all future studies.

---

## 9. Documentation Requirements for Published Results

Any publication or external report using ChipLens evaluation data must include:

- This protocol document (or a reference to it) as the evaluation methodology
- The specific version of the protocol applied
- Which steps were and were not followed, with justification for any deviations
- All threats listed in `threats_to_validity.md` relevant to the result being reported
- A clear statement of what the results claim and what they do not claim
