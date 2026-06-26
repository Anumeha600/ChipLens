# Verification Productivity Methodology

**Sprint I Task 1 — Evaluation Framework**  
**Date:** 2026-06-25  
**Status:** Baseline methodology — no numerical claims

---

## 1. Research Question

> Can a compiler-inspired semantic reasoning pipeline reduce manual verification engineering effort while preserving deterministic, explainable verification?

This question is not answered in this document. This document establishes how it will be measured.

The question has two clauses that must be evaluated independently:

1. **Reduction in manual effort** — does ChipLens eliminate or reduce manual steps in the verification workflow?
2. **Preservation of correctness** — do the automated outputs remain deterministic and explainable?

Both clauses are necessary. A system that reduces effort but produces non-deterministic or unexplainable outputs does not satisfy the research question.

---

## 2. Scope of ChipLens

ChipLens is not a formal verification engine. It does not replace SymbiYosys, Yosys, Verilator, or Icarus Verilog. It does not solve SAT problems or execute model checking.

ChipLens targets the reasoning that surrounds formal verification:

- understanding what a design contains
- identifying what needs to be verified
- generating candidate properties
- prioritizing verification effort
- interpreting what failures mean
- planning how to address identified gaps

This scope must be stated clearly in any productivity evaluation, because measuring ChipLens against solver performance would be a category error.

---

## 3. Two Categories of Verification Effort

### Category A — Manual Engineering Activities

Activities performed by a verification engineer that require domain knowledge, interpretation, or judgment. These are the primary target of ChipLens.

| Activity | Description |
|----------|-------------|
| RTL comprehension | Reading and understanding the design structure — identifying registers, FSMs, memories, interfaces, and clocking |
| Verification target identification | Deciding what properties are worth verifying given design complexity |
| Assertion authoring | Writing SVA, PSL, or formal properties by hand |
| Verification planning | Choosing what to verify, in what order, and with what depth |
| Failure interpretation | Understanding why a formal run failed, what the counterexample means, and what it implies about the design |
| Repair planning | Deciding how to address coverage gaps, design bugs, or inadequate specifications |
| Status reporting | Communicating verification completeness and risk to stakeholders |

### Category B — Tool Execution

Activities performed by automated tools that are not the primary target of ChipLens.

| Activity | Tool |
|----------|------|
| SAT solving / model checking | SymbiYosys, Yosys |
| RTL elaboration | Yosys |
| Simulation | Verilator, Icarus Verilog |
| Linting | Verilator, other lint tools |
| Synthesis | Yosys, commercial tools |

ChipLens has no impact on Category B performance. Evaluating ChipLens against solver speed or formal verification capacity is invalid.

---

## 4. Traditional Verification Workflow

This is the workflow that ChipLens is compared against. It represents common practice in formal verification for small-to-medium RTL designs.

```
RTL Source
     │
     ▼
Engineer studies design (manual)
     │  — reads module hierarchy
     │  — traces clocking structure
     │  — identifies register types
     │  — maps memory organization
     │  — locates interface boundaries
     ▼
Engineer identifies verification targets (manual)
     │  — selects properties worth proving
     │  — estimates design complexity
     │  — scopes verification depth
     ▼
Engineer writes assertions (manual)
     │  — authors SVA/PSL properties
     │  — writes covers, assumes, asserts
     │  — documents rationale
     ▼
Formal verification (tool)
     │  — SymbiYosys / bounded model check
     │  — result: pass, fail, timeout
     ▼
Engineer interprets results (manual)
     │  — reads counterexample traces
     │  — classifies failure cause
     │  — determines design vs. spec issue
     ▼
Engineer plans repairs (manual)
     │  — decides what to fix
     │  — sequences corrections
     │  — re-scopes verification
     ▼
Documentation (manual)
```

The manual steps (marked above) are the primary target of the productivity evaluation.

---

## 5. ChipLens Workflow

```
RTL Source
     │
     ▼
Design Intelligence (automated)
     │  — register extraction (sequential / combinational)
     │  — clock domain identification
     │  — reset topology
     │  — FSM detection
     │  — counter detection
     │  — handshake detection
     │  — memory array identification
     │  — module boundary detection
     ▼
Semantic Evidence (structured output)
     │
     ▼
Candidate Property Synthesis (automated)
     │  — safety properties from detected state
     │  — liveness candidates from FSMs
     │  — interface protocol properties
     ▼
Property Ranking (automated)
     │  — deterministic priority ordering
     │  — evidence-backed rationale
     ▼
Property Emitter (automated)
     │  — SymbiYosys .sby configuration
     │  — formal property file
     ▼
Explainability (automated)
     │  — rationale for each property
     │  — evidence citations
     ▼
Verification Planner (automated)
     │  — task list with priorities
     │  — dependency ordering
     ▼
Formal Verification (tool — unchanged)
     │
     ▼
Coverage Intelligence (automated)
     │  — coverage assessment from structural complexity
     │  — gap identification
     ▼
Counterexample Analysis (automated)
     │  — trace classification
     │  — failure categorization
     ▼
Diagnostics Intelligence (automated)
     │  — issue grouping
     │  — severity assessment
     │  — verification health summary
     ▼
Repair Planning (automated)
     │  — ordered repair steps
     │  — dependency-aware sequencing
     ▼
Verification Orchestrator (automated)
```

---

## 6. Mapping ChipLens Outputs to Manual Effort

Each ChipLens output corresponds to a category of manual engineering activity that it eliminates or reduces.

| ChipLens Output | Manual Activity Addressed | Elimination / Reduction |
|-----------------|--------------------------|------------------------|
| `registers`, `clocks`, `resets` | RTL comprehension | Eliminates structural survey |
| `fsms`, `counters`, `handshakes` | RTL comprehension | Surfaces non-obvious state machines and protocols |
| Candidate properties | Assertion authoring | Eliminates initial property drafting |
| Ranked properties | Verification planning | Eliminates prioritization analysis |
| Emitted `.sby` + SVA files | Assertion authoring | Eliminates manual file construction |
| Explainability rationale | Documentation | Eliminates manual rationale writing |
| Verification plan | Verification planning | Eliminates manual task decomposition |
| Coverage assessment | Status reporting | Provides heuristic coverage estimate without simulation |
| Counterexample classification | Failure interpretation | Reduces trace-reading effort |
| Diagnostic report | Failure interpretation | Groups issues by category and severity |
| Repair plan | Repair planning | Provides ordered correction steps |

---

## 7. Productivity Definition

For the purposes of this research, **verification productivity** is defined as:

> The ratio of structured verification artifacts produced to manual engineering time invested.

A higher-productivity workflow produces more verification coverage, more actionable diagnostics, and more complete repair guidance per unit of engineer time.

ChipLens increases this ratio by automating the artifact-production steps listed in Section 6.

**This definition explicitly excludes:**
- Formal solver throughput (BMC depth, SAT performance)
- RTL complexity reduction
- Property strength or coverage guarantees
- Any claim that ChipLens produces correct properties

**What ChipLens can claim:**
- Deterministic structural extraction for Verilog designs
- Reproducible artifact generation from identical inputs
- Explainable property rationale traceable to structural evidence
- Consistent coverage heuristic from complexity model

---

## 8. What This Methodology Does Not Claim

This methodology does not claim that ChipLens:

- Reduces formal verification time (solver performance is not affected)
- Produces bug-free properties (heuristic synthesis has known limitations)
- Guarantees coverage completeness (coverage heuristic is an estimate)
- Replaces human judgment (repair planning requires engineer review)
- Scales to arbitrary RTL complexity (parser has documented limitations)

Any future empirical study must be designed to avoid these confounds.

---

## 9. Pre-Conditions for Evaluation

Before any productivity measurement study can proceed, the following pre-conditions must be satisfied:

1. **Parser accuracy baseline established** — false positive and false negative rates measured on a representative design set (completed: wb2axip, PicoRV32, SERV, Ibex — see `docs/evaluation/open_source/`)
2. **Workflow instrumented** — ChipLens pipeline produces measurable artifact counts
3. **Baseline workflow documented** — the manual workflow it replaces is described with sufficient specificity to estimate effort
4. **Design corpus defined** — evaluation set is fixed before measurement begins
5. **Metrics defined** — specific measurements are agreed upon before data collection (see `verification_metrics.md`)

---

## 10. Sprint I Deliverable

This document establishes the methodology. The research question remains open. Numerical productivity claims require a future empirical study with human participants or detailed effort-logging against a fixed design corpus.

**Next step after Sprint I:** Sprint I Task 2 should define the specific evaluation protocol for at least one complete design study using the methodology established here.
