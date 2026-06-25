# ChipLens

> **Compiler-Inspired Semantic RTL Verification Research Platform**

<p align="center">

![Version](https://img.shields.io/badge/version-v1.5.0-blue)
![Status](https://img.shields.io/badge/status-active-success)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-MIT-green)
![Tests](https://img.shields.io/badge/tests-2514%2B-success)

</p>

ChipLens is an open-source research platform that investigates compiler-inspired approaches to Register Transfer Level (RTL) verification.

Rather than treating hardware verification as a sequence of independent tool invocations, ChipLens incrementally constructs semantic knowledge about an RTL design before generating verification artifacts. Each framework contributes structured information that is propagated through a deterministic reasoning pipeline, enabling explainable verification decisions, reproducible analysis, and modular extensibility.

The project combines semantic analysis, deterministic property synthesis, explainability, verification planning, coverage intelligence, diagnostics, repair planning, and orchestration into a unified verification workflow while remaining independent of any single formal verification engine.

---

## Highlights

- Compiler-inspired layered verification architecture
- Semantic RTL analysis and evidence extraction
- Deterministic candidate property synthesis
- Explainable verification decisions
- Formal verification planning
- Coverage intelligence and interpretation
- Counterexample analysis
- Diagnostics intelligence
- Dependency-aware repair planning
- End-to-end verification orchestration
- Immutable data models
- Deterministic execution pipeline
- Benchmark harness with reproducible results
- Case studies with honest evaluation
- **2514+ automated tests**
- **0 failing tests**
- Active research and development

---

## Current Status

| Item | Status |
|------|--------|
| Current Release | **v1.5.0 – Core Reasoning Platform** |
| Development | Active |
| Platform | Flutter + Dart |
| License | MIT |
| Automated Tests | **2514+ Passing** |
| Test Failures | **0** |
| Architecture | Layered & Modular |
| Verification Pipeline | Complete |
| Research Direction | Ongoing |

## Table of Contents

- [Why ChipLens?](#why-chiplens)
- [System Architecture](#system-architecture)
- [Verification Pipeline](#verification-pipeline)
- [Core Frameworks](#core-frameworks)
- [Evaluation](#evaluation)
- [Project Status](#project-status)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Engineering Principles](#engineering-principles)
- [Getting Started](#getting-started)
- [Project Roadmap](#project-roadmap)
- [Documentation](#documentation)
- [Research Vision](#research-vision)
- [Contributing](#contributing)
- [License](#license)

---
## Why ChipLens?

Modern RTL verification relies on a diverse ecosystem of simulation, linting, and formal verification tools. While these tools are individually powerful, verification engineers are often responsible for connecting them into a complete workflow, interpreting results, identifying verification gaps, and deciding what should be verified next.

Many of these activities remain manual, fragmented, and difficult to reproduce.

ChipLens investigates a different approach.

Instead of treating verification as a collection of isolated tools, ChipLens models verification as a structured reasoning pipeline. Each stage performs a single, well-defined transformation, progressively enriching the understanding of the design before passing immutable knowledge to the next stage.

The result is a verification workflow that emphasizes transparency, determinism, modularity, and explainability.

---

## Motivation

The project explores a simple question:

> **Can compiler-inspired semantic analysis improve the organization, transparency, and explainability of RTL verification workflows?**

To investigate this question, ChipLens applies several software engineering principles commonly found in modern compiler infrastructures:

- Layered analysis instead of monolithic processing
- Immutable intermediate representations
- Deterministic transformations
- Clearly defined framework boundaries
- Explainable reasoning at every stage
- Reproducible verification workflows

Rather than replacing existing formal verification engines, ChipLens complements them by organizing the reasoning that occurs before and after verification.

---

## Engineering Philosophy

ChipLens is built around a small set of architectural principles that guide every framework in the system.

### Single Responsibility

Each framework performs one clearly defined task and communicates through immutable value objects.

### Deterministic Execution

Given identical inputs, ChipLens produces identical outputs. Verification decisions are reproducible across repeated executions.

### Explainability

Verification artifacts are accompanied by supporting evidence and reasoning whenever possible, making the verification process easier to understand and inspect.

### Modularity

Frameworks are designed to evolve independently. New reasoning stages can be integrated without modifying existing components.

### Extensibility

The architecture is intended to support future research in semantic analysis, formal verification, diagnostics, planning, and intelligent hardware verification.

---

## What Makes ChipLens Different?

ChipLens is **not** a replacement for established formal verification tools.

Instead, it acts as an intelligent verification layer that organizes knowledge before, during, and after formal verification.

Instead of focusing solely on proving properties, ChipLens focuses on understanding the verification process itself.

The platform combines:

- Semantic RTL understanding
- Candidate property synthesis
- Deterministic property ranking
- Explainable property generation
- Verification planning
- Coverage interpretation
- Counterexample analysis
- Cross-framework diagnostics
- Dependency-aware repair planning
- End-to-end verification orchestration

This layered architecture enables verification workflows that are easier to understand, reproduce, extend, and evaluate than traditional tool-centric approaches.

## System Architecture

ChipLens follows a layered architecture inspired by modern compiler infrastructures. Instead of combining all verification functionality into a single engine, the platform decomposes verification into independent reasoning frameworks.

Each framework performs one well-defined transformation and produces immutable outputs that become structured inputs for the next stage. This separation of concerns improves maintainability, reproducibility, explainability, and extensibility while allowing new reasoning modules to be integrated without changing existing components.

Every framework is:

- Deterministic
- Independently testable
- Side-effect free
- Engine-independent
- Built around immutable value objects

---

## Verification Pipeline

```text
RTL Source
     │
     ▼
Design Intelligence
     │
     ▼
Semantic Evidence
     │
     ▼
Candidate Property Synthesis
     │
     ▼
Property Ranking
     │
     ▼
Property Emitter
     │
     ▼
Explainability
     │
     ▼
Verification Planner
     │
     ▼
Formal Verification
     │
     ▼
Coverage Analyzer
     │
     ▼
Coverage Intelligence
     │
     ▼
Counterexample Analysis
     │
     ▼
Diagnostics Intelligence
     │
     ▼
Repair Planning
     │
     ▼
Verification Orchestrator
     │
     ▼
Verification Session Result
```

---

## Core Frameworks

| Framework | Primary Responsibility |
|-----------|------------------------|
| **Design Intelligence** | Extracts structural and behavioral knowledge from RTL designs, providing the foundation for subsequent reasoning stages. |
| **Semantic Evidence** | Builds structured semantic evidence describing signals, state machines, control flow, and design behavior. |
| **Candidate Property Synthesis** | Generates candidate verification properties from semantic evidence using deterministic synthesis strategies. |
| **Property Ranking** | Prioritizes synthesized properties according to deterministic ranking policies and semantic evidence. |
| **Property Emitter** | Converts ranked candidate properties into formal verification properties suitable for downstream verification engines. |
| **Explainability** | Produces traceable explanations describing why each verification property was generated and which semantic evidence contributed to it. |
| **Verification Planner** | Organizes formal properties into deterministic verification plans prior to execution. |
| **Formal Verification** | Interfaces with external formal verification engines while remaining independent of any specific backend implementation. |
| **Coverage Analyzer** | Collects verification coverage information, execution statistics, and structural coverage metrics. |
| **Coverage Intelligence** | Interprets coverage results, identifies verification gaps, and generates structured coverage recommendations. |
| **Counterexample Analysis** | Interprets failed verification results and reconstructs structured summaries of counterexamples for downstream analysis. |
| **Diagnostics Intelligence** | Correlates information from multiple reasoning frameworks to identify verification issues and their likely causes. |
| **Repair Planning** | Converts diagnostics into dependency-aware repair plans that prioritize verification activities without modifying RTL designs. |
| **Verification Orchestrator** | Coordinates the complete verification workflow and assembles an immutable verification session result representing the entire reasoning process. |

---

## Evaluation

ChipLens includes a benchmark harness that measures the complete analysis pipeline against representative RTL designs and generates reproducible evaluation reports.

### Benchmark Results (2026-06-24)

| Design | Description | Diagnostics | Repairs | Runtime (ms) |
|--------|-------------|-------------|---------|--------------|
| counter | 4-bit sync counter | 1 | 1 | 3 |
| fsm | 3-state traffic light FSM | 1 | 1 | 2 |
| alu | 32-bit combinational ALU | 1 | 1 | 2 |
| fifo | Parameterized sync FIFO | 1 | 1 | 3 |
| uart | UART TX, 4-state FSM | 1 | 1 | 4 |

All 5 designs complete successfully. Average pipeline runtime: **3 ms** per design.

> **Note:** The benchmark pipeline does not execute formal verification. Coverage assessments are derived from a structural complexity heuristic. These results measure the performance of ChipLens's reasoning frameworks, not the output of a complete formal verification run.

### Evaluation Artifacts

| Document | Description |
|----------|-------------|
| [docs/evaluation/benchmark_results.md](docs/evaluation/benchmark_results.md) | Raw benchmark output from actual pipeline execution |
| [docs/evaluation/evaluation_summary.md](docs/evaluation/evaluation_summary.md) | Aggregate results, architectural findings, and limitations |
| [docs/evaluation/case_study_counter.md](docs/evaluation/case_study_counter.md) | Case study: 4-bit synchronous counter |
| [docs/evaluation/case_study_fsm.md](docs/evaluation/case_study_fsm.md) | Case study: 3-state traffic light FSM |
| [docs/evaluation/case_study_fifo.md](docs/evaluation/case_study_fifo.md) | Case study: Parameterized synchronous FIFO |
| [docs/evaluation/case_study_uart.md](docs/evaluation/case_study_uart.md) | Case study: UART transmitter (8N1 protocol) |

### Running the Benchmark

```bash
# Run the benchmark suite (generates docs/evaluation/benchmark_results.md)
flutter test test/benchmarks/benchmark_suite_test.dart
```

---

### Evaluation Progress

ChipLens is being evaluated against external open-source RTL designs that were not created for ChipLens. These evaluations measure structural detection accuracy and diagnostic reliability on real-world designs.

**Completed evaluations:**

| Design | Tier | Lines | Runtime | Diagnostics | FP Severity | Status |
|--------|------|-------|---------|-------------|-------------|--------|
| [wb2axip skidbuffer](docs/evaluation/open_source/wb2axip_skidbuffer_evaluation.md) | 1 | 57 | 23 ms | 1 (low) | low | Updated post-calibration |
| [PicoRV32 register file](docs/evaluation/open_source/picorv32_module_evaluation.md) | 1 | 16 | 32 ms | 1 (low) | low | Updated post-parser-calibration |
| [SERV ALU](docs/evaluation/open_source/serv_module_evaluation.md) | 1 | 88 | 30 ms | 1 (medium) | 0 | Updated post-Task-7 (6 regs, moderate) |

**Open-source evaluation artifacts:**

| Document | Description |
|----------|-------------|
| [docs/evaluation/open_source/open_source_evaluation_plan.md](docs/evaluation/open_source/open_source_evaluation_plan.md) | 4-phase evaluation roadmap |
| [docs/evaluation/open_source/design_selection.md](docs/evaluation/open_source/design_selection.md) | Candidate designs and selection rationale |
| [docs/evaluation/open_source/evaluation_methodology.md](docs/evaluation/open_source/evaluation_methodology.md) | Inputs, outputs, metrics, and procedure |
| [docs/evaluation/open_source/wb2axip_skidbuffer_evaluation.md](docs/evaluation/open_source/wb2axip_skidbuffer_evaluation.md) | Phase 1 evaluation: formally verified AXI flow-control buffer (with before/after calibration table) |
| [docs/evaluation/open_source/picorv32_module_evaluation.md](docs/evaluation/open_source/picorv32_module_evaluation.md) | Phase 1 evaluation: PicoRV32 register file — before/after parser calibration table |
| [docs/evaluation/open_source/serv_module_evaluation.md](docs/evaluation/open_source/serv_module_evaluation.md) | Phase 1 evaluation: SERV ALU — cross-project generalization validation; parameterized-width false negative |

**Heuristic calibration (Sprint H Task 3) — measured improvements on wb2axip skidbuffer:**

| Issue | Before | After |
|-------|--------|-------|
| Comment false positive (`istered`) | registers = 4 | registers = 3 (resolved) |
| Reset not detected (`i_reset`) | `hasReset = false` | `hasReset = true` (resolved) |
| Clock not primary (`i_clk`) | `primaryClocks = []` | `primaryClocks = [i_clk]` (resolved) |
| Coverage estimate | 73% (moderate) | 82% (low) (improved) |
| Diagnostic severity | medium | low (less alarming) |

**What still applies after calibration:**
- 1 diagnostic still produced for a formally verified design — the heuristic has no knowledge of formal verification status
- `o_ready` still misclassified as sequential (driven by `always @(*)`); deferred improvement

**PicoRV32 register file evaluation (Sprint H Task 4) — three parser bugs identified:**

| Failure mode | Root cause | Fixed in |
|-------------|------------|----------|
| `s` false positive from `regs[...]` | `\breg` word-prefix match inside identifiers | Sprint H Task 5 |
| Memory array depth not captured | `[0:31]` dimension ignored | Sprint H Task 5 |
| Assign-target width = 1 | Port widths not cross-referenced | Sprint H Task 5 |

**Parser robustness calibration (Sprint H Task 5) — measured improvements on picorv32_regs:**

| Metric | Before (Task 4) | After (Task 5) |
|--------|----------------|----------------|
| False positive `s` | present | **absent** |
| `regs.isMemoryArray` | false | **true** |
| `regs.depth` | 0 | **32** |
| `rdata1.width`, `rdata2.width` | 1 | **32** |
| `registers.length` | 4 | **3** |
| `complexity` | 4 | **3** |
| `overallCoverage` | 77% (moderate) | **82% (low)** |
| `verificationHealth` | reduced | **acceptable** |

100 new regression tests added in `test/parser_regressions/` (keyword_boundary, memory_array, width_inference, picorv32_regression, fsm_counter_keyword_boundary). 2397 total tests pass.

**Cross-project generalization (Sprint H Task 6 — SERV ALU validation):**

| Metric | wb2axip | PicoRV32 regs | SERV ALU |
|--------|---------|--------------|----------|
| False positives | 0 | 0 | **0** — keyword fix generalizes |
| False negatives | 0 | 0 | **1** (`add_cy_r` — parameterized width) |
| `CoverageRisk` | low | low | low |
| New parser issue | — | `\breg` prefix | none (Task 7 fixed prior FNs) |

Parser improvements from wb2axip and PicoRV32 generalize: zero false positives across all three designs. SERV revealed a limitation (parameterized-width FN) that was fixed in Task 7.

**Parameterized RTL support (Sprint H Task 7) — four fixes applied to SERV:**

| Priority | Fix | SERV impact |
|----------|-----|-------------|
| P1 — Symbolic reg width | `reg [B:0] add_cy_r` now detected (widthIsKnown=false) | `add_cy_r` was silently dropped |
| P2 — Symbolic port/wire width | `output wire [B:0] o_rd` widthIsKnown tracked | `o_rd`, `result_add` now widthIsKnown=false |
| P2 — `output wire [N:M]` | wire qualifier no longer consumed as signal name | Numeric port widths inferred correctly |
| P4 — Concatenation assign | `{add_cy, result_add} = …` LHS extracted | `add_cy`, `result_add` now detected |

117 new tests in `test/parameterized_rtl/` (registers, ports, memories, concatenation, SERV). 2514 total tests pass. SERV post-Task-7: 6 registers, complexity=6, 67% coverage, moderate risk.

**Next:** Proceed to Ibex evaluation — parameterized RTL is no longer a blind spot.

---

# Architectural Characteristics

The architecture intentionally separates **reasoning** from **execution**.

ChipLens performs semantic reasoning, property generation, planning, diagnostics, and orchestration, while external verification engines remain responsible for executing formal verification tasks.

This separation enables:

- Modular framework development
- Independent testing of each reasoning stage
- Reproducible verification workflows
- Explainable verification decisions
- Flexible integration with multiple verification backends
- Long-term extensibility for future research

The Verification Orchestrator serves as the coordination layer that assembles the outputs of every reasoning framework into a single immutable verification session without duplicating framework-specific logic.

---
## Project Status

ChipLens has reached **v1.5.0 — Core Reasoning Platform**.

The implementation now provides a complete end-to-end verification reasoning pipeline, spanning RTL understanding through verification orchestration. The current focus has shifted from building core frameworks to refining the platform, improving usability, benchmarking verification workflows, and conducting experimental evaluation.

---

# Project Statistics

| Metric | Value |
|---------|------:|
| Current Version | **v1.5.0** |
| Development Status | Active |
| Core Reasoning Frameworks | 14 |
| Automated Tests | **2514+ Passing Tests** |
| Test Failures | **0** |
| Layered Architecture | ✅ |
| Deterministic Pipeline | ✅ |
| Immutable Public Models | ✅ |
| Modular Frameworks | ✅ |
| Explainability Support | ✅ |
| Cross-Framework Diagnostics | ✅ |
| Verification Planning | ✅ |
| Repair Planning | ✅ |
| Benchmark Harness | ✅ |
| Evaluation Artifacts | ✅ |

---

## Technology Stack

| Category | Technologies |
|----------|--------------|
| **Frontend** | Flutter, Dart |
| **Formal Verification** | SymbiYosys, Yosys, Verilator, Icarus Verilog |
| **Testing** | flutter_test |
| **Static Analysis** | flutter analyze |
| **Version Control** | Git, GitHub |

---

## Repository Structure

```text
ChipLens/
│
├── frontend/
│   ├── lib/
│   │   ├── backend/
│   │   │   ├── design_intelligence/
│   │   │   ├── property_inference/
│   │   │   │   ├── semantic/
│   │   │   │   ├── synthesizer/
│   │   │   │   └── ranking/
│   │   │   ├── explainability/
│   │   │   ├── planning/
│   │   │   ├── formal/
│   │   │   ├── coverage/
│   │   │   ├── coverage_intelligence/
│   │   │   ├── counterexample/
│   │   │   ├── diagnostics/
│   │   │   ├── diagnostics_intelligence/
│   │   │   ├── repair/
│   │   │   ├── repair_planning/
│   │   │   └── orchestrator/
│   │   │
│   │   ├── models/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── screens/
│   │
│   ├── benchmarks/             ← benchmark harness (outside lib/)
│   │   ├── models/
│   │   ├── runner/
│   │   └── reports/
│   │
│   └── test/
│       ├── integration/system/ ← system integration tests
│       ├── benchmarks/         ← benchmark tests
│       └── fixtures/rtl/       ← Verilog fixtures
│
├── docs/
│   └── evaluation/             ← benchmark results & case studies
├── LICENSE
├── README.md
└── CHANGELOG.md
```

---

## Engineering Principles

The architecture of ChipLens is guided by a small set of engineering principles that remain consistent across every framework.

## Layered Reasoning

Verification is decomposed into independent reasoning stages. Each framework performs a single transformation before passing immutable outputs to the next stage.

## Deterministic Execution

Given identical inputs, ChipLens produces identical reasoning results. No framework depends on randomness or hidden mutable state.

## Immutability

Frameworks communicate through immutable value objects, reducing unintended side effects and improving reproducibility.

## Explainability

Where possible, verification decisions are accompanied by supporting evidence and traceable explanations rather than opaque outputs.

## Modularity

Each framework has a clearly defined responsibility and can evolve independently without affecting unrelated components.

## Testability

Every major reasoning framework is independently unit tested. The complete platform currently contains **2187+ automated tests**, helping ensure architectural stability as the project evolves.

## Extensibility

The platform is designed to support future research in semantic analysis, verification planning, diagnostics, explainable verification, and intelligent hardware verification without requiring fundamental architectural changes.

---
# Getting Started

## Prerequisites

Before running ChipLens, ensure the following tools are installed:

### Required

- Flutter (latest stable release)
- Dart SDK
- Git

### Optional (Formal Verification Support)

ChipLens integrates with external formal verification tools. Install one or more of the following to enable advanced verification workflows:

- SymbiYosys
- Yosys
- Verilator
- Icarus Verilog

> **Note**
>
> The core reasoning frameworks operate independently of any specific formal verification backend. External verification tools are only required for executing formal verification tasks.

---

## Clone the Repository

```bash
git clone https://github.com/Anumeha600/ChipLens.git
cd ChipLens/frontend
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run ChipLens

```bash
flutter run
```

---

## Run the Test Suite

```bash
flutter test
```

---

## Static Analysis

```bash
flutter analyze
```

---

# Project Roadmap

ChipLens has completed its **Core Reasoning Platform (v1.0.0)**.

Development now focuses on transforming the platform into a mature research and engineering ecosystem.

## Phase 1 — Core Platform ✅

- RTL Analysis
- Design Intelligence
- Semantic Evidence
- Candidate Property Synthesis
- Property Ranking
- Property Emitter
- Explainability
- Verification Planner
- Formal Verification Integration
- Coverage Analyzer
- Coverage Intelligence
- Counterexample Analysis
- Diagnostics Intelligence
- Repair Planning
- Verification Orchestrator

---

## Phase 2 — Platform Refinement 🚧

Current priorities include:

- Cross-platform user experience (Android + Web)
- Documentation improvements
- Architecture documentation
- Repository refinement
- UI modernization
- End-to-end integration testing

---

## Phase 3 — Experimental Evaluation 🚧

In progress:

- ✅ Benchmark suite (`benchmarks/` harness, 5 RTL fixtures)
- ✅ Reproducible benchmark reports (`docs/evaluation/benchmark_results.md`)
- ✅ Case studies (counter, FSM, FIFO, UART)
- ✅ Evaluation summary with limitations and future directions
- Performance evaluation against larger RTL designs
- Coverage evaluation with formal tool integration
- Property ranking evaluation
- Explainability assessment

---

## Phase 4 — Research

Long-term research directions include:

- Compiler-inspired RTL verification
- Semantic-guided verification planning
- Explainable formal verification
- Intelligent diagnostics
- Verification workflow optimization
- Research publications

---

## Documentation

Project documentation will continue to expand alongside the platform.

Planned documentation includes:

- Architecture Guide
- Developer Guide
- User Guide
- API Reference
- Benchmark Guide
- Research Notes
- Verification Workflow Guide

---

# Contributing

ChipLens is an active research project.

Bug reports, feature requests, discussions, and contributions are welcome.

Contribution guidelines, coding standards, and development workflows will be documented in a future **CONTRIBUTING.md**.

Researchers interested in compiler technology, formal methods, hardware verification, and Electronic Design Automation (EDA) are especially encouraged to participate.

---

## Research Vision

ChipLens serves as an experimental platform for investigating compiler-inspired approaches to RTL verification.

The project explores how semantic analysis, deterministic reasoning, explainability, and modular verification workflows can improve the transparency and organization of hardware verification.

Future work will emphasize:

- Rigorous benchmarking
- Experimental evaluation
- Reproducible research artifacts
- Open benchmark datasets
- Academic collaboration
- Publication of research findings

The long-term objective is to contribute reusable ideas, software, and evaluation methodologies to the hardware verification and Electronic Design Automation (EDA) communities.

---

## License

ChipLens is released under the MIT License.

See the **LICENSE** file for additional information.

---

## Acknowledgements

ChipLens builds upon decades of research in compiler technology, formal methods, and Electronic Design Automation.

The project also benefits from the broader open-source hardware verification ecosystem, including projects such as:

- Yosys
- SymbiYosys
- Verilator
- Icarus Verilog

Their continued development has significantly advanced accessible hardware verification and research.

---

## Citation

Citation metadata will be provided through **CITATION.cff** as the project continues to mature.

---

## Support the Project

If you find ChipLens useful for learning, research, or hardware verification, consider:

- ⭐ Starring the repository
- 🐛 Reporting issues
- 💡 Suggesting improvements
- 🤝 Contributing to development
- 📖 Sharing the project with others

Every contribution helps improve the platform and supports future research.

---

<p align="center">

**ChipLens**  
*Compiler-Inspired Semantic RTL Verification Research Platform*

**Building transparent, explainable, and reproducible verification workflows for digital hardware.**

</p>
