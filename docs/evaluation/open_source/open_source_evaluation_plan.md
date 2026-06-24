# ChipLens Open-Source RTL Evaluation Plan

**Status:** Planning  
**Date:** 2026-06-24  
**Sprint:** H — Task 1

---

## Objective

Evaluate ChipLens against external open-source RTL designs that were not created specifically for ChipLens. The goal is to answer:

> How does ChipLens behave on designs written by real engineers for real purposes?

The benchmark fixtures (counter, fsm, alu, fifo, uart) demonstrate that ChipLens's pipeline executes correctly end-to-end. They do not demonstrate that ChipLens produces useful or accurate outputs on arbitrary RTL. This evaluation plan closes that gap.

---

## Non-Goals

This plan does not include:

- Modifications to ChipLens production code
- Downloading or integrating external design repositories
- Formal verification execution (no SymbiYosys runs)
- UI evaluation or workbench testing
- SystemVerilog elaboration or multi-file hierarchical analysis
- Generation of new verification properties

---

## Success Criteria

The open-source evaluation is considered successful when:

1. At least one design from each of Phases 1, 2, and 3 has been evaluated
2. A completed results document exists for each evaluated design
3. False positive and false negative counts have been determined for at least one design with a formal verification ground truth
4. The evaluation summary has been updated with cross-design findings
5. At least three ChipLens improvement suggestions have been identified and documented

---

## Phased Roadmap

### Phase 1 — Small External Modules

**Target:** Designs of 20–200 lines, closest in size to the existing benchmark corpus.

**Goals:**
- Confirm ChipLens handles real-world RTL coding conventions without errors
- Identify false positives on designs that are already formally correct
- Establish a baseline diagnostic count and runtime for small external modules
- Validate that structure detection accuracy is comparable to the benchmark fixtures

**Candidate designs:**

| Design | Lines (est.) | Why |
|--------|-------------|-----|
| TinyTapeout counter example | 20–50 | Closest to benchmark counter.v |
| TinyTapeout seven-segment controller | 50–120 | Small FSM + combinational |
| wb2axip skidbuffer | ~200 | Formally verified; ground truth available |

**Evaluation procedure:** Follow `evaluation_methodology.md` Section 4.1 for each design. Complete one `results_<name>.md` per design.

**Completion criteria:** Three designs evaluated, results documented, tier-level aggregation complete.

**Estimated effort:** Low. Designs are small and similar to existing fixtures.

---

### Phase 2 — Medium-Size Components

**Target:** Designs of 200–2,000 lines, including processor building blocks and protocol implementations.

**Goals:**
- Test structural detection on designs with multiple FSMs and complex register usage
- Assess runtime scaling: does ChipLens remain fast (< 100 ms) at this scale?
- Compare OpenTitan UART results against the existing `uart.v` case study
- Evaluate SERV's unusual bit-serial architecture against ChipLens heuristics

**Candidate designs:**

| Design | Lines (est.) | Why |
|--------|-------------|-----|
| SERV serial RISC-V core | ~800 | Unusual architecture; stress-tests heuristics |
| PicoRV32 | ~3,000 | Most widely known small RISC-V; broadest comparability |
| OpenTitan UART | 400–800 | Direct comparison to uart.v case study |

**Evaluation procedure:** Same as Phase 1, plus comparative analysis against relevant benchmark case studies.

**Completion criteria:** Three designs evaluated, cross-design runtime scaling plotted, comparison to benchmark uart.v case study documented.

**Estimated effort:** Medium. Designs require preprocessing (PicoRV32 uses `ifdef`, OpenTitan uses SystemVerilog includes).

---

### Phase 3 — Processor-Scale Designs

**Target:** Complete processor cores of 2,000–20,000 lines.

**Goals:**
- Establish scalability limits: at what line count does DesignRunner analysis become slow (> 1 s)?
- Determine whether diagnostic diversity increases with design complexity (or whether the coverage heuristic saturates)
- Identify structural patterns in processor RTL that ChipLens cannot detect (e.g., multi-file hierarchies, generate blocks)
- Produce the most realistic assessment of ChipLens's capabilities at production scale

**Candidate designs:**

| Design | Lines (est.) | Why |
|--------|-------------|-----|
| Ibex RISC-V core | ~10,000 | Production-grade; lowRISC verification history |
| OpenTitan AES block | 1,000–3,000 | Cryptographic; verification-critical |

**Evaluation procedure:** Same as Phases 1–2, plus scalability timing analysis.

**Completion criteria:** At least one design evaluated end-to-end; scalability findings documented.

**Estimated effort:** High. These designs require careful preprocessing and understanding of multi-file structure. Single-file analysis of the top module is the practical approach.

---

### Phase 4 — Industrial-Scale Case Studies

**Target:** Full subsystems or chips of > 20,000 lines.

**Status:** Aspirational. Not planned for near-term execution.

**Goals:**
- Evaluate whether per-module analysis of a full chip produces coherent results
- Assess ChipLens as an entry point for engineers unfamiliar with a large codebase
- Produce evaluation artifacts useful to the hardware verification community

**Prerequisites before Phase 4 can begin:**
- ChipLens must support multi-file analysis or hierarchical elaboration
- Runtime must scale to individual module analysis in < 10 ms per module
- False positive rate at Phase 3 must be below a threshold (TBD) for Phase 4 results to be meaningful

---

## Metrics Summary

The following metrics will be collected across all phases. See `evaluation_methodology.md` for full definitions.

### Per-Design Metrics

| Metric | Phase 1 | Phase 2 | Phase 3 |
|--------|---------|---------|---------|
| Diagnostic count | Collect | Collect | Collect |
| Repair count | Collect | Collect | Collect |
| Runtime (ms) | Collect | Collect | Collect |
| Analysis success | Collect | Collect | Collect |
| Detected structure count | Collect | Collect | Collect |
| Clock detection accuracy | Assess | Assess | Assess |
| FSM detection accuracy | Assess | Assess | Spot-check |
| Counter detection accuracy | Assess | Assess | Spot-check |
| False positives | Measure (wb2axip) | Measure (OpenTitan UART) | Best effort |
| False negatives | Best effort | Best effort | Best effort |

### Tier-Level Aggregates

After completing each phase:

| Aggregate | Definition |
|-----------|------------|
| Mean diagnostic count | Average `issues.length` across tier |
| Mean runtime | Average ms across tier |
| Analysis success rate | Fraction completing without exception |
| FP rate | FP diagnostics / total diagnostics (where ground truth available) |
| Structure detection accuracy | Correct detections / expected detections |

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| SystemVerilog syntax causes DesignRunner exception | High (Phase 2–3) | Preprocess to remove unsupported constructs; document as limitation |
| External repository URLs change | Low | Record commit hash at evaluation time |
| Parametric designs produce unexpected DesignKnowledge | Medium | Use concrete default parameters; document |
| Large designs (> 5,000 lines) cause memory or timeout issues | Unknown | Set a 30-second timeout; report as analysis failure if exceeded |
| All designs produce the same coverage diagnostic (saturation) | Medium | Document as a limitation of the heuristic approach; distinguish by structure count |

---

## Relationship to Existing Evaluation Artifacts

This evaluation plan builds on and extends the existing evaluation framework:

| Existing artifact | Role in open-source evaluation |
|-------------------|-------------------------------|
| `benchmark_results.md` | Baseline for comparing new design results |
| `evaluation_summary.md` | Will be extended with cross-design open-source findings |
| `case_study_counter.md` etc. | Template structure reused for external design case studies |
| `evaluation_methodology.md` | Governing methodology document |
| `design_selection.md` | Design inventory and selection rationale |
| `results_template.md` | Per-design result document template |

---

## Output Documents

Each phase will produce:

1. One `results_<design>.md` per evaluated design (using `results_template.md`)
2. A phase-level summary appended to `evaluation_summary.md`
3. Updated `design_selection.md` with status column (planned / in progress / complete)

After all phases:

4. A cross-phase analysis document summarizing scalability, false positive rates, and structural detection accuracy across all evaluated designs

---

## Open Research Questions

The evaluation is expected to generate data relevant to the following research questions. These are documented here so that evaluation results can be interpreted in context.

**Q1 — Structural extraction accuracy**  
What fraction of clock signals, reset signals, FSMs, and counters in real-world RTL does ChipLens correctly detect? Where do the heuristics fail?

**Q2 — Coverage heuristic calibration**  
Is the structural complexity heuristic correlated with actual verification difficulty? Do more complex designs (by heuristic complexity) actually require more formal verification effort?

**Q3 — Diagnostic utility**  
Are ChipLens's diagnostic outputs useful to a verification engineer approaching an unfamiliar design? Do the diagnostics point to the right areas of the design?

**Q4 — Runtime scalability**  
How does DesignRunner runtime scale with RTL line count? Is the relationship linear? Where does it become a practical bottleneck?

**Q5 — False positive characterization**  
What is the dominant cause of false positive diagnostics? Is it the coverage heuristic, keyword-based structural extraction, or something else?

**Q6 — Protocol detection**  
Can ChipLens identify protocol-level structures (AXI handshake, UART framing, SPI protocol) from structural patterns alone, or does protocol detection require semantic understanding beyond keyword matching?
