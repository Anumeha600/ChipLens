# Framework Output Inventory — Sprint I Baseline

**Sprint I Task 2 — Framework Analysis**  
**Date:** 2026-06-25  
**Purpose:** Per-framework description of inputs, outputs, immutable objects produced, and contribution to verification productivity

---

## Overview

ChipLens consists of 7 pipeline stages that are executed sequentially for each RTL design. Each stage produces one or more immutable result objects that are passed to downstream stages. This document inventories what each framework stage produces and how it contributes to the verification productivity model defined in `verification_productivity_methodology.md`.

**Pipeline execution order:**
```
RTL Source
    │
    ▼
[1] Design Intelligence     → DesignKnowledge
    │
    ▼
[2] Property Inference      → FormalPropertySet
    │
    ▼
[3] Explainability          → VerificationExplanationSet
    │
    ▼
[4] Verification Planning   → PlanningResult (VerificationPlan + statistics)
    │
[5] Coverage Intelligence   → CoverageAssessment
    │
    ▼
[6] Diagnostics             → DiagnosticReport
    │
    ▼
[7] Repair Planning         → RepairPlan
```

---

## Framework 1: Design Intelligence (`lib/backend/design_intelligence/`)

### Purpose

Extracts structural characteristics from RTL source text using regex-based providers. No formal analysis — purely syntactic extraction.

### Input

- `DesignContext(rtlSource: String)` — raw RTL text (Verilog or SystemVerilog)
- No configuration required; all 10 providers run by default

### Providers (10 total)

| Provider | What it extracts |
|----------|-----------------|
| `ClockProvider` | Clock signals from posedge sensitivity lists; classifies as primary or candidate |
| `ResetProvider` | Reset signals from sensitivity lists and conditional expressions; async vs. sync, active polarity |
| `RegisterProvider` | `reg` declarations, assign targets, and concatenation-assign LHS signals; sequential vs. combinational |
| `FSMProvider` | State machines from `case` statements on sequential registers |
| `CounterProvider` | Counting patterns (increment/decrement on sequential registers) |
| `HandshakeProvider` | Protocol signal pairs (valid/ready) |
| `ModuleProvider` | Module names from `module` declarations |
| `PortProvider` | Module ports with direction and width |
| `CoverageProvider` | Coverage structural metrics (delegated to CoverageIntelligenceEngine) |
| `DiagnosticProvider` | Structural health markers |

### Output

`DesignKnowledge` — immutable aggregate of all provider outputs:
- `registers: List<RegisterInfo>` (name, width, widthIsKnown, isSequential, isCombinational, isMemoryArray)
- `clocks: List<ClockInfo>` (name, isPrimary, isCandidate)
- `resets: List<ResetInfo>` (name, isAsynchronous, isActiveLow)
- `fsms: List<FsmInfo>` (name, states, transitions)
- `counters: List<CounterInfo>` (name, direction)
- `handshakes: List<HandshakeInfo>` (protocolHint)
- `modules: List<ModuleInfo>` (name)
- Boolean flags: hasClock, hasReset, hasFSM, hasCounter, hasHandshake

### Measurements (this study)

| Design | Registers | Clocks | Resets | FSMs | Counters | Handshakes | Runtime |
|--------|-----------|--------|--------|------|---------|-----------|---------|
| wb2axip | 5 | 1 | 1 | 0 | 0 | 1 | ~16 ms |
| PicoRV32 | 3 | 1 | 0 | 0 | 0 | 0 | ~1 ms |
| SERV | 6 | 1 | 0 | 0 | 0 | 0 | ~1 ms |
| Ibex | 2 | 1 | 1 | 0 | 0 | 0 | ~1 ms |

### Productivity contribution

Addresses **Category A manual activity:** Structural Survey  
- Traditional workflow: engineer reads entire RTL manually, documents all registers, clocks, resets, FSMs
- ChipLens: automated structural extraction in 1–30 ms
- **Eliminates manual artifact:** `DesignKnowledge` replaces the structural survey document

**Limitations documented:**
- `logic` declarations (SystemVerilog) not detected as sequential registers
- Memory array depth dimension not captured (only flat depth=1 representation)
- Width of assign-target signals not cross-referenced with port declarations
- `always @(*)` blocks classified as sequential (false positive for combinational signals)
- Comment stripping may be incomplete in edge cases (legacy — was documented in wb2axip Task 3 evaluation)

---

## Framework 2: Property Inference (`lib/backend/property_inference/`)

### Purpose

Generates formal property candidates from `DesignKnowledge`. Five independent providers each examine a different structural aspect.

### Input

- `PropertyContext(knowledge: DesignKnowledge, config: Map<String,dynamic>)`

### Providers (5 total)

| Provider | What it generates | Trigger condition |
|----------|-----------------|-----------------|
| `ResetPropertyProvider` | Reset release liveness + reset initialization safety per sequential register | `asyncResets` or `syncResets` not empty |
| `FSMPropertyProvider` | State reachability, transition validity | `fsms` not empty |
| `CounterPropertyProvider` | Counter bounds safety | `counters` not empty |
| `HandshakePropertyProvider` | Protocol correctness (valid before ready) | `handshakes` not empty |
| `SafetyPropertyProvider` | Module-level output definition safety | Always — at least one property per module |

### Output

`FormalPropertySet` — ordered, mutable set of `FormalProperty` objects:
- `id: String` — stable unique identifier (e.g., `inferred.reset.i_reset.releases`)
- `name: String` — short display name
- `description: String` — what the property checks
- `propertyType: FormalPropertyType` — (safety, liveness, assertion, assumption, cover)
- `expression: String` — backend-agnostic logical expression
- `severity: String` — error/warning/info
- `enabled: bool` — whether to emit to formal files
- `metadata: Map<String,dynamic>` — confidence and other annotations

### Measurements (this study)

| Design | PG-1 (all) | PG-2 (ranked) | PG-3 (emitted) | Providers that fired |
|--------|-----------|--------------|---------------|----------------------|
| wb2axip | 10 | 10 | 10 | Reset, Handshake, Safety |
| PicoRV32 | 2 | 2 | 2 | Safety |
| SERV | 1 | 1 | 1 | Safety |
| Ibex | 2 | 2 | 2 | Reset, Safety |

**All properties are ranked (PG-2 = PG-1) and all are emitted (PG-3 = PG-2).** The current implementation does not filter or disable properties.

### Productivity contribution

Addresses **Category A manual activities:** Assertion List, Priority Ordering, SVA/sby File Creation  
- Traditional workflow: engineer manually writes SVA assertions for each structural element
- ChipLens: automated inference of 1–10 property candidates in <1 ms
- **Eliminates manual artifact:** `FormalPropertySet` replaces the manual assertion list

**Gap identified:** Property coverage is low for designs without detected resets or handshakes. SERV ALU receives only 1 property for 6 detected signals. Per-register safety properties (not currently generated) would substantially increase coverage.

---

## Framework 3: Explainability (`lib/backend/explainability/`)

### Purpose

Generates human-readable explanation for each formal property, tracing the reasoning from design structure to property expression.

### Input

- `FormalPropertySet properties`
- `ExplanationContext context` — controls which fields are included (evidence, ranking, confidence, metadata)

### Output

`VerificationExplanationSet` — ordered list of `VerificationExplanation` objects, one per property:
- `propertyId: String` — links to `FormalProperty.id`
- `trace: ExplanationTrace` — evidence chain with confidence score
- `metadata: Map<String,dynamic>` — carries property metadata

### Measurements (this study)

| Design | Explanations | confidence (avg) |
|--------|-------------|-----------------|
| wb2axip | 10 | 0.00 (baseline: no formal run) |
| PicoRV32 | 2 | 0.00 |
| SERV | 1 | 0.00 |
| Ibex | 2 | 0.00 |

**Note:** `trace.confidence` = 0.00 in all cases because confidence is set by formal solver results, which are not available in this baseline. This is the root cause of the "Low property confidence" diagnostic issue seen in all 4 designs.

### Productivity contribution

Addresses **Category A manual activity:** Rationale Documentation  
- Traditional workflow: engineer writes comments or documentation explaining why each assertion was written
- ChipLens: `VerificationExplanation` provides the reasoning trace automatically
- **Eliminates manual artifact:** Explanation set replaces rationale notes

---

## Framework 4: Verification Planning (`lib/backend/planning/`)

### Purpose

Converts `FormalPropertySet` into an ordered execution plan with batching strategy.

### Input

- `FormalPropertySet properties`
- `VerificationExplanationSet explanations`
- `PlanningContext context` — batching strategy, ordering, statistics

### Output

`PlanningResult`:
- `plan: VerificationPlan` — ordered list of `VerificationPlanItem` objects
- `statistics: PlanningStatistics` — batch count, strategy summary
- `warnings: List<String>` — non-fatal anomalies (e.g., properties without explanations)
- `planningTime: Duration`

### Measurements (this study)

| Design | Tasks | Batches | Warnings | Planning time |
|--------|-------|---------|---------|--------------|
| wb2axip | 10 | 1 | 0 | 1 ms |
| PicoRV32 | 2 | 1 | 0 | <1 ms |
| SERV | 1 | 1 | 0 | <1 ms |
| Ibex | 2 | 1 | 0 | <1 ms |

**Current strategy:** `BatchStrategy.sequential` — all properties in one batch per design. This is appropriate for small modules (1–10 properties). For larger designs, `BatchStrategy.propertyType` or `BatchStrategy.fixedSize` would be more efficient.

### Productivity contribution

Addresses **Category A manual activity:** Verification Task List  
- Traditional workflow: engineer manually sequences verification jobs (which properties to run first, in what order, in which tool invocations)
- ChipLens: automated planning with dependency ordering in <1 ms
- **Eliminates manual artifact:** `VerificationPlan` replaces manual scheduling

---

## Framework 5: Coverage Intelligence (`lib/backend/coverage_intelligence/`)

### Purpose

Assesses structural coverage completeness using a complexity heuristic. In this baseline, no formal verification engine is available, so coverage is estimated from structural complexity.

### Input (two modes)

**Baseline mode (used in this study):** Derived from `DesignKnowledge`:
```
complexity = fsms.length + counters.length + registers.length
coverage   = max(0.55, min(0.94, 0.97 - 0.05 × complexity))
```

**Full mode (requires formal engine):** `CoverageReport` from `SymbiYosys` or other solver.

### Output

`CoverageAssessment`:
- `risk: CoverageRisk` — minimal / low / moderate / high / critical
- `confidence: CoverageConfidence` — veryHigh / high / medium / low / veryLow
- `statistics.overallCoverage: double` — coverage fraction (0.0–1.0)
- `recommendations: List<CoverageRecommendation>`
- `summary: CoverageSummary`

### Measurements (this study)

| Design | Complexity | Coverage | Risk | Confidence |
|--------|-----------|---------|------|-----------|
| wb2axip | 5 | 72.0% | moderate | medium |
| PicoRV32 | 3 | 82.0% | low | high |
| SERV | 6 | 67.0% | moderate | medium |
| Ibex | 2 | 87.0% | low | high |

**Heuristic validity:** The heuristic assumes coverage decreases linearly with structural complexity. This has not been validated against actual formal solver coverage results. It is a rough estimate that will be replaced by real coverage data once SymbiYosys is integrated (see Experiment D in `experimental_protocol.md`).

### Productivity contribution

Addresses **Category A manual activity:** Coverage Report  
- Traditional workflow: engineer reviews formal tool coverage output and summarizes gaps
- ChipLens: automated coverage assessment from structural analysis
- **Limitation:** Without a formal engine, the coverage report is heuristic only. The productivity gain for this artifact is deferred to the post-SymbiYosys integration phase.

---

## Framework 6: Diagnostics Intelligence (`lib/backend/diagnostics_intelligence/`)

### Purpose

Fuses outputs from Coverage, Counterexample, Explainability, and Planning into a unified diagnostic report ordered by severity.

### Input

- `CoverageAssessment coverage`
- `CounterexampleReport counterexample` (in this baseline: classification=unknown, no failures)
- `VerificationExplanationSet explanations`
- `VerificationPlan plan`
- `DiagnosticContext context`

### Issue generators (4)

| Generator | What it checks |
|-----------|--------------|
| `_addCounterexampleIssue` | Engine failure, timeout, assertion failure, assumption violation |
| `_addCoverageIssue` | Coverage below threshold (risk = low/moderate/high/critical) |
| `_addPlanningIssue` | Empty plan with non-empty explanations; all properties use induction |
| `_addPropertyQualityIssue` | Average property confidence < 0.3 (critical) or < 0.5 (borderline) |

### Output

`DiagnosticReport`:
- `issues: List<DiagnosticIssue>` — ordered by severity desc, category, title
- `summary: DiagnosticSummary` — overview, primaryIssue, verificationHealth label
- `statistics: DiagnosticStatistics`
- `overallSeverity: DiagnosticSeverity`
- `overallConfidence: DiagnosticConfidence`

### Measurements (this study)

| Design | Issues | Health | Severity | Issue Types |
|--------|--------|--------|---------|------------|
| wb2axip | 2 | reduced | medium | coverage(moderate) + property(confidence) |
| PicoRV32 | 2 | reduced | medium | property(confidence) + coverage(low) |
| SERV | 2 | reduced | medium | coverage(moderate) + property(confidence) |
| Ibex | 2 | reduced | medium | property(confidence) + coverage(low) |

**Systematic artifact:** "Low property confidence (0.00)" appears in all 4 designs because `trace.confidence = 0.0` when no formal verification run has been performed. This is a known gap in the baseline protocol — the diagnostic framework treats "no formal run" the same as "properties have zero formal evidence." A context flag (`DiagnosticContext.formalRunPerformed = false`) would suppress this issue in baseline measurements.

### Productivity contribution

Addresses **Category A manual activities:** Failure Classification, Issue List  
- Traditional workflow: engineer reads raw solver output, classifies failures by type, severity, and root cause
- ChipLens: `DiagnosticReport` provides pre-classified, severity-ordered issues with evidence
- **Current limitation:** All 4 designs receive identical diagnostic output in the no-formal-run baseline, making it impossible to distinguish between designs by diagnostic health alone.

---

## Framework 7: Repair Planning (`lib/backend/repair_planning/`)

### Purpose

Converts `DiagnosticReport` into an ordered repair sequence with dependencies and complexity estimates.

### Input

- `DiagnosticReport report`
- `RepairContext context` — controls dependencies, complexity, step limit

### Mapping rules

| DiagnosticSeverity | RepairPriority |
|-------------------|---------------|
| critical | critical |
| high | high |
| medium | medium |
| low | low |
| informational | (skipped) |

| DiagnosticCategory | RepairCategory | Complexity |
|-------------------|---------------|-----------|
| verification | verification | high |
| counterexample | verification | high |
| coverage | coverage | medium |
| planning | planning | low |
| property | property | medium |
| configuration | configuration | low |

### Dependency injection

- `verification` steps depend on all `configuration` steps (must fix config before verifying)
- `coverage` steps depend on all `property` steps (property quality affects coverage)

### Output

`RepairPlan`:
- `steps: List<RepairStep>` — ordered by priority, dependency level, category, title
- `statistics: RepairStatistics`
- `overallPriority: RepairPriority`
- `overallComplexity: RepairComplexity`

### Measurements (this study)

| Design | Steps | Priority | Complexity | Step types |
|--------|-------|---------|-----------|-----------|
| wb2axip | 2 | medium | medium | property + coverage |
| PicoRV32 | 2 | medium | medium | property + coverage |
| SERV | 2 | medium | medium | property + coverage |
| Ibex | 2 | medium | medium | property + coverage |

**Note:** The repair plan is entirely determined by the diagnostic output. Since all 4 designs produce identical diagnostics (property confidence + coverage), all 4 produce identical repair plans. This is not a fault of the Repair Planner — it correctly reflects the diagnostic input. The fix is upstream: suppress the property confidence issue in no-formal-run baselines.

### Productivity contribution

Addresses **Category A manual activity:** Repair Sequence  
- Traditional workflow: engineer manually decides which issues to fix first and in what order, based on experience and knowledge of dependencies
- ChipLens: automated dependency-aware repair sequencing
- **Current value:** In the no-formal-run baseline, all repair plans are identical (property confidence + coverage), limiting differentiating value. In a post-formal-run scenario with counterexample failures, the repair planner would generate design-specific sequences.

---

## Summary: Immutable Objects Produced per Pipeline Run

| Object | Class | Produced by | Downstream consumer(s) |
|--------|-------|------------|----------------------|
| `DesignKnowledge` | `DesignKnowledge` | Framework 1 | Frameworks 2, 5 |
| `FormalPropertySet` | `FormalPropertySet` | Framework 2 | Frameworks 3, 4 |
| `VerificationExplanationSet` | `VerificationExplanationSet` | Framework 3 | Frameworks 4, 6 |
| `PlanningResult` | `PlanningResult` | Framework 4 | Framework 6 (plan) |
| `CoverageAssessment` | `CoverageAssessment` | Framework 5 | Framework 6 |
| `CounterexampleReport` | `CounterexampleReport` | (formal engine) | Framework 6 |
| `DiagnosticReport` | `DiagnosticReport` | Framework 6 | Framework 7 |
| `RepairPlan` | `RepairPlan` | Framework 7 | (output) |

**Total immutable objects per design run:** 8 (7 ChipLens + 1 formal engine stub)

All objects are deterministic for identical inputs and stateless (no side effects, no shared mutable state across calls).

---

## Productivity Model Alignment

From `verification_productivity_methodology.md` (Section 6), the 10 manual artifact categories and their ChipLens replacements are verified in this study:

| # | Manual artifact | ChipLens replacement | Status |
|---|----------------|---------------------|--------|
| 1 | Structural survey | `DesignKnowledge` | **Functional** (all 4 designs) |
| 2 | Assertion list | `FormalPropertySet.properties` | **Functional** (1–10 per design) |
| 3 | Priority ordering | Ranked properties (PG-2) | **Functional** (all ranked) |
| 4 | SVA/sby files | Emitted properties (PG-3) | **Functional** (all emitted) |
| 5 | Rationale documentation | `VerificationExplanationSet` | **Functional** (1–10 per design) |
| 6 | Verification task list | `VerificationPlan` | **Functional** (1–10 tasks) |
| 7 | Coverage report | `CoverageAssessment` | **Heuristic only** (no formal engine) |
| 8 | Failure classification | `CounterexampleReport` | **Stub only** (no formal engine) |
| 9 | Issue list | `DiagnosticReport.issues` | **Functional** (uniform baseline) |
| 10 | Repair sequence | `RepairPlan.steps` | **Functional** (uniform baseline) |

**WF-1 score:** 10/10 categories addressed. Categories 7 and 8 are functional stubs awaiting SymbiYosys integration.

---

## Known Baseline Limitations

1. **No formal verification engine.** Categories 7 and 8 above rely on heuristics and stubs. The full productivity value of ChipLens's Coverage, Counterexample, Diagnostics, and Repair stages cannot be demonstrated without a real formal solver.

2. **Property confidence = 0.00 for all designs.** This is a systematic baseline artifact that will be resolved when formal solver results populate `trace.confidence`.

3. **Uniform diagnostics and repair plans.** All 4 designs receive the same diagnostic and repair output. This limits the ability to differentiate designs by their verification readiness.

4. **Property coverage gap for designs without resets or handshakes.** SERV and PicoRV32 receive 1–2 properties for 3–6 detected signals. Additional property providers (per-register safety, sequential liveness) would substantially increase coverage.
