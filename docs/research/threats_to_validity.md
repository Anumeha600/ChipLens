# Threats to Validity

**Sprint I Task 1 — Validity Analysis**  
**Date:** 2026-06-25  
**Status:** Framework — identifies risks before empirical measurement begins

---

## Overview

This document applies standard research validity analysis to the ChipLens productivity evaluation methodology. Identifying threats before data collection prevents post-hoc rationalization of unexpected results.

Validity threats are categorized as:

- **Internal validity** — does the study measure what it claims to measure?
- **External validity** — do results generalize beyond the evaluation set?
- **Construct validity** — are the constructs (productivity, effort, completeness) operationalized correctly?
- **Conclusion validity** — are conclusions drawn from data statistically supportable?

---

## 1. Internal Validity Threats

### IV-1: Parser Accuracy Limits Structural Metrics

**Threat:** DU-7 (structural extraction accuracy) depends on parser correctness. If the parser has false positives or false negatives, all downstream metrics (property count, plan count, diagnostic count) are built on inaccurate foundations.

**Current state (from Sprint H evaluation):**

| Design | False Positives | False Negatives | Root Cause |
|--------|----------------|-----------------|------------|
| wb2axip skidbuffer | 1 (`istered` from comment) | 1 (reset `i_reset`) | Comment not stripped; reset name heuristic gap |
| PicoRV32 regs | 0 (post-Task-5) | 0 (within Verilog scope) | Fixed in Task 5 |
| SERV serv_alu | 0 | 0 (post-Task-7) | All 6 signals detected |
| Ibex register file | 0 | 32 (rf_reg_q logic array) | Architecture scope: logic declarations |

**Mitigation:** Document parser limitations explicitly. Exclude known-undetected elements from productivity claims. Define "in scope" and "out of scope" before measurement.

**Residual risk:** Any undocumented parser limitation that affects the measured design will silently distort structural metrics.

---

### IV-2: Heuristic Coverage Is Not Real Coverage

**Threat:** `WF-4` and coverage metrics use a structural complexity heuristic (`0.97 - 0.05 × complexity`). This is NOT a measurement of actual formal verification coverage. Using it as a coverage metric conflates heuristic estimation with verified coverage.

**Current handling:** The heuristic is labeled as "estimate" in all documentation. It is computed from structural complexity, not from any formal verification result.

**Mitigation:** In any publication or comparison, clearly state that ChipLens coverage numbers are structural heuristics, not formal proofs. Use `CoverageConfidence` field as an explicit uncertainty indicator.

**Residual risk:** Users may interpret coverage numbers as formal results without reading the confidence field.

---

### IV-3: Ground Truth Contamination

**Threat:** If the ground truth for DU-7 is established by inspecting ChipLens output, the evaluation is circular. The parser will appear more accurate than it is because the evaluator is unconsciously anchored to what the tool found.

**Mitigation:** Ground truth must be established from independent sources:
- RTL manual inspection by someone who has NOT seen ChipLens output
- Architecture documentation (e.g., Ibex register file specification)
- Synthesis tool reports (netlist register count)
- Author documentation of the design

**Process requirement:** Lock ground truth before running ChipLens on evaluation designs. Do not adjust ground truth after observing ChipLens results.

---

### IV-4: Confounding Between Parser Fixes and Productivity Claims

**Threat:** Sprint H applied 10+ parser improvements while evaluating designs. The evaluation results therefore reflect a moving target — the parser improved between evaluations. Any cross-design comparison may reflect parser calibration rather than genuine generalization.

**Current state:** This confound exists in the evaluation set as documented. The SERV results pre-Task-7 and post-Task-7 are documented separately, which partially mitigates this.

**Mitigation:** For future empirical studies, freeze the parser version before beginning data collection. Do not make parser changes during an evaluation sprint.

**Residual risk:** The Sprint H evaluation data reflects a calibrated parser that was tuned on the evaluation designs. Holdout validation on new designs has not been performed.

---

### IV-5: Single Evaluator

**Threat:** All Sprint H evaluations were performed by the same system (ChipLens + Claude). There was no independent human replication of structural extraction or ground truth establishment.

**Mitigation:** For any published results, require independent replication by at least one human verification engineer.

---

## 2. External Validity Threats

### EV-1: Benchmark Selection Bias

**Threat:** The current evaluation set (wb2axip, PicoRV32, SERV, Ibex) was selected for technical variety. However:

- All are open-source designs with clean, well-commented RTL
- All are small-to-medium modules (16–106 lines, preprocessed)
- All are widely known with publicly available documentation
- None are proprietary or industrial designs
- None represent the most complex real-world verification targets

Results from this dataset may not generalize to:
- Industrial RTL with mixed analog/digital content
- Designs with complex interface protocols (AXI4, PCIe, DDR)
- Auto-generated RTL (LiteX, SpinalHDL)
- RTL with deep hierarchy and many submodules
- Designs with hundreds of FSMs or thousands of registers

**Mitigation:** Document evaluation set characteristics explicitly. Qualify all conclusions with "for small-to-medium open-source Verilog designs."

---

### EV-2: Verilog Bias

**Threat:** Three of four designs (wb2axip, PicoRV32, SERV) use pure Verilog. The parser was calibrated primarily on Verilog patterns. The one SystemVerilog design (Ibex) revealed three parser defects, all of which were fixed.

However, the Ibex evaluation also revealed a deep limitation (logic declarations) that was NOT fixed. Industrial SystemVerilog designs routinely use `logic` for all state elements.

**Implication:** External validity for SystemVerilog is currently low. Productivity claims are strongest for Verilog designs.

---

### EV-3: Module-Level Scope

**Threat:** All evaluations targeted individual modules extracted from larger designs. Real verification workflows operate on complete design hierarchies, not isolated modules. Extracting a module and evaluating it ignores:
- Inter-module interfaces
- Hierarchical coverage
- Cross-module formal assumptions

**Mitigation:** Document scope as "module-level structural analysis." Do not claim hierarchy-level or full-chip validity.

---

### EV-4: No Controlled Comparison with Traditional Workflow

**Threat:** The research question asks whether ChipLens reduces manual effort compared to a traditional workflow. However, no side-by-side controlled experiment exists in the current evaluation. There is no measurement of how long a verification engineer would spend on the same tasks manually.

**Mitigation:** This is a known gap. The Sprint I methodology defines what such a study would require. An empirical comparison would need:
- A fixed design corpus
- Two groups: ChipLens-assisted vs. manual
- Standardized timing methodology
- Standardized artifact quality measurement

**Status:** No such study exists yet. This document establishes the framework for it.

---

## 3. Construct Validity Threats

### CV-1: Productivity Operationalization

**Threat:** "Verification productivity" is defined in `verification_productivity_methodology.md` as artifacts-produced per engineer-time. However:
- Artifact count is measurable; engineer-time is not currently measured
- Two ChipLens reports with identical artifact counts may differ significantly in quality
- A high-quality manual plan may outperform a high-quantity automated one

**Mitigation:** The current methodology is explicit that WF-4 (artifact elimination) is a structural count, not a quality measure. Quality assessment requires human study.

---

### CV-2: "Manual Effort" Is Heterogeneous

**Threat:** The 10 categories of manual effort in the productivity model (Section 6 of the methodology document) have very different actual costs:
- Writing an SVA property takes minutes to hours
- Reading a counterexample trace takes minutes
- Planning verification scope may take days

Treating them as interchangeable categories overstates ChipLens impact on high-cost activities and understates it on low-cost ones.

**Mitigation:** When effort-reduction claims are made, they must be decomposed by category. Do not aggregate.

---

### CV-3: Coverage Is Not Correctness

**Threat:** ChipLens coverage metrics measure structural completeness of verification planning. They do not measure:
- Whether generated properties are correct
- Whether generated properties are sufficient to catch the design's bugs
- Whether formal verification of the generated properties proves anything about the design

A 95% structural coverage heuristic could coexist with a design that has a critical bug that none of the generated properties address.

**Mitigation:** State explicitly that ChipLens coverage is a structural heuristic. It is a proxy for verification effort completeness, not a correctness guarantee.

---

### CV-4: False Positive / False Negative Asymmetry

**Threat:** For productivity evaluation, false positives and false negatives have asymmetric costs:
- A false positive (spurious register detected) generates a spurious property and repair step — wasted engineer review time
- A false negative (missed register) means a verification gap that may not be discovered

For safety-critical applications, false negatives are far more costly. Treating them symmetrically in F1 score may misrepresent the practical impact.

**Mitigation:** Report precision and recall separately. For safety-critical contexts, weight recall more heavily in any composite score.

---

## 4. Conclusion Validity Threats

### CnV-1: N=4 Is Not Sufficient for Statistical Claims

**Threat:** The current evaluation dataset has four designs. No statistical conclusions about distribution of parser accuracy, coverage heuristic calibration, or productivity impact can be drawn from N=4.

**Mitigation:** All current results are case studies, not statistical studies. No quantitative claims should be made about "ChipLens accuracy is X%" without N ≥ 20 and appropriate confidence intervals.

---

### CnV-2: No Baseline Measurement

**Threat:** No measurement of the traditional workflow exists for any of the four evaluation designs. There is no data point for "how long it would take manually." Productivity improvement claims without this baseline are meaningless.

**Mitigation:** Future studies must include baseline timing data. The current evaluation documents what ChipLens produces, not how much faster it is than manual effort.

---

### CnV-3: Self-Evaluation Bias

**Threat:** ChipLens was designed and evaluated by the same development process. There is no independent assessor. The evaluation documents what ChipLens produces; they do not independently verify that the outputs are useful or correct.

**Mitigation:** Require external review of evaluation methodology and results before any publication. Design external validity studies with independent participants.

---

## 5. Mitigation Priority

Threats are ranked by impact on conclusion validity:

| Threat | Impact | Status | Mitigation Priority |
|--------|--------|--------|-------------------|
| EV-4: No controlled comparison | Critical | Gap | Sprint I Task 2 |
| CV-3: Coverage ≠ Correctness | High | Documented | Label in all outputs |
| IV-1: Parser accuracy limits metrics | High | Partially mitigated | Continue evaluation |
| IV-3: Ground truth contamination | High | Not yet mitigated | Next evaluation study |
| CnV-1: N=4 insufficient | High | Acknowledged | Expand corpus |
| CnV-2: No baseline measurement | High | Gap | Human study design |
| EV-1: Benchmark selection bias | Medium | Documented | Expand corpus |
| EV-2: Verilog bias | Medium | Documented | SV calibration sprint |
| CV-1: Productivity operationalization | Medium | Partially mitigated | Define in protocol |
| IV-2: Heuristic coverage | Medium | Documented | Labels in outputs |

---

## 6. Summary Statement

The ChipLens evaluation methodology is designed to measure structural extraction accuracy and artifact production completeness for small-to-medium Verilog RTL designs. The four-design evaluation corpus supports case study conclusions but not statistical claims. Productivity impact relative to a traditional workflow cannot be quantified without a controlled empirical study. All current results should be interpreted as characterization data for future study design, not as evidence of productivity improvement.
