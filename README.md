# ChipLens

> **Compiler-Inspired Semantic RTL Verification Research Platform**

<p align="center">

![Version](https://img.shields.io/badge/version-v1.0.0-blue)
![Status](https://img.shields.io/badge/status-active-success)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-MIT-green)
![Tests](https://img.shields.io/badge/tests-1328%2B-success)

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
- **1328+ automated tests**
- **0 failing tests**
- Active research and development

---

## Current Status

| Item | Status |
|------|--------|
| Current Release | **v1.0.0 – Core Reasoning Platform** |
| Development | Active |
| Platform | Flutter + Dart |
| License | MIT |
| Automated Tests | **1328+ Passing** |
| Test Failures | **0** |
| Architecture | Layered & Modular |
| Verification Pipeline | Complete |
| Research Direction | Ongoing |

## Table of Contents

- [Why ChipLens?](#why-chiplens)
- [System Architecture](#system-architecture)
- [Verification Pipeline](#verification-pipeline)
- [Core Frameworks](#core-frameworks)
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

ChipLens has reached **v1.0.0 — Core Reasoning Platform**.

The implementation now provides a complete end-to-end verification reasoning pipeline, spanning RTL understanding through verification orchestration. The current focus has shifted from building core frameworks to refining the platform, improving usability, benchmarking verification workflows, and conducting experimental evaluation.

---

# Project Statistics

| Metric | Value |
|---------|------:|
| Current Version | **v1.0.0** |
| Development Status | Active |
| Core Reasoning Frameworks | 14 |
| Automated Tests | **1328+ Passing Tests** |
| Test Failures | **0** |
| Layered Architecture | ✅ |
| Deterministic Pipeline | ✅ |
| Immutable Public Models | ✅ |
| Modular Frameworks | ✅ |
| Explainability Support | ✅ |
| Cross-Framework Diagnostics | ✅ |
| Verification Planning | ✅ |
| Repair Planning | ✅ |

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
│   └── test/
│
├── docs/
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

Every major reasoning framework is independently unit tested. The complete platform currently contains **1328+ automated tests**, helping ensure architectural stability as the project evolves.

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

## Phase 3 — Experimental Evaluation

Planned work includes:

- Benchmark suite development
- Performance evaluation
- Coverage evaluation
- Property ranking evaluation
- Explainability assessment
- Reproducible experiments

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
