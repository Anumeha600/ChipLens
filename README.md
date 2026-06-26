# ChipLens

> **Compiler-Inspired Semantic RTL Verification Research Platform**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)]()
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()
[![Tests](https://img.shields.io/badge/Tests-2723%2B%20Passing-brightgreen.svg)]()

ChipLens is an open-source research platform that investigates how **compiler-inspired semantic reasoning** can improve the transparency, organization, and reproducibility of Register Transfer Level (RTL) verification.

Rather than treating hardware verification as a sequence of independent tool invocations, ChipLens incrementally constructs structured semantic knowledge about an RTL design before generating verification artifacts. Each reasoning framework contributes immutable information that is propagated through a deterministic verification pipeline, enabling explainable verification decisions, reproducible analysis, and modular extensibility.

Unlike traditional verification workflows that primarily execute external tools, ChipLens focuses on **reasoning about verification itself**—organizing semantic evidence, synthesizing candidate properties, planning verification activities, interpreting results, and generating structured diagnostics while remaining independent of any specific verification backend.

Formal verification engines such as SymbiYosys, Yosys, Verilator, and Icarus Verilog remain responsible for proof execution. ChipLens acts as an intelligent semantic layer surrounding those tools.

---

# Highlights

- Compiler-inspired layered verification architecture
- Semantic RTL understanding
- Deterministic property synthesis
- Structured property ranking
- Explainable verification decisions
- Verification planning
- Engine-independent formal verification
- Coverage intelligence
- Counterexample analysis
- Diagnostics intelligence
- Dependency-aware repair planning
- End-to-end verification orchestration
- Immutable intermediate representations
- Deterministic execution pipeline
- Reproducible benchmark framework
- Empirical evaluation using open-source RTL designs
- Research methodology for verification productivity
- Modular architecture designed for future research
- **2723+ automated tests**
- **0 failing tests**

---

# Current Status

| Item | Status |
|------|--------|
| Current Release | **v1.5.0 – Core Reasoning Platform** |
| Development | Active |
| Platform | Flutter + Dart |
| License | MIT |
| Automated Tests | **2723+ Passing** |
| Test Failures | **0** |
| Analyzer Issues | **0** |
| Core Frameworks | **14** |
| Verification Pipeline | Complete |
| Property Synthesizer | Stabilized (Sprint J) |
| External RTL Evaluation | 4 Designs Completed |
| Research Methodology | Complete |
| Benchmark Harness | Complete |
| Architecture | Stable & Modular |

---

# Research Contributions

ChipLens currently investigates several research directions in intelligent hardware verification:

- Compiler-inspired verification architectures
- Semantic RTL analysis
- Deterministic property synthesis
- Explainable verification workflows
- Immutable verification pipelines
- Verification planning
- Coverage intelligence
- Structured diagnostics generation
- Dependency-aware repair planning
- Empirical evaluation methodology
- Verification productivity measurement

These research directions are implemented as independently testable reasoning frameworks connected through immutable intermediate representations.

---

# Table of Contents

- Why ChipLens?
- Motivation
- Engineering Philosophy
- System Architecture
- Verification Pipeline
- Core Frameworks
- Evaluation
- Project Status
- Technology Stack
- Repository Structure
- Engineering Principles
- Getting Started
- Project Roadmap
- Documentation
- Research Vision
- Contributing
- License
# Why ChipLens?

Modern RTL verification relies on a diverse ecosystem of simulation, linting, model checking, and formal verification tools. While these tools are individually powerful, verification engineers are still responsible for connecting them into a complete workflow, interpreting results, deciding what should be verified next, and understanding why a verification activity succeeded or failed.

Much of this reasoning remains manual, fragmented, and difficult to reproduce.

ChipLens investigates a different perspective.

Instead of viewing verification as a sequence of independent tool invocations, ChipLens models verification as a structured reasoning process. Every framework performs one well-defined transformation, producing immutable semantic information that becomes the input to the next stage.

Rather than replacing existing verification engines, ChipLens provides a semantic reasoning layer that organizes knowledge before, during, and after formal verification.

The result is a verification workflow that emphasizes transparency, determinism, explainability, reproducibility, and modular extensibility.

---

# Motivation

ChipLens explores a central research question:

> **Can compiler-inspired semantic reasoning improve the organization, explainability, and reproducibility of RTL verification workflows?**

Compiler infrastructures have demonstrated the value of incremental semantic analysis, immutable intermediate representations, deterministic transformations, and well-defined optimization passes. These principles have enabled decades of progress in software compilation.

ChipLens investigates whether similar architectural ideas can improve hardware verification.

Instead of treating verification as isolated execution of external tools, ChipLens incrementally constructs semantic knowledge about an RTL design and propagates that knowledge through a deterministic reasoning pipeline.

Each framework contributes structured information while remaining independently testable and architecturally isolated.

The project therefore focuses on reasoning about verification rather than replacing the verification engines themselves.

---

# Engineering Philosophy

Every framework inside ChipLens follows a common set of architectural principles.

## Single Responsibility

Each reasoning framework performs one clearly defined transformation.

Frameworks communicate exclusively through immutable value objects and never duplicate responsibilities already handled elsewhere in the pipeline.

---

## Deterministic Execution

Given identical RTL input, ChipLens produces identical reasoning results.

No framework depends on randomness, hidden mutable state, or execution ordering.

Deterministic execution enables reproducible experimentation, reliable benchmarking, and predictable verification workflows.

---

## Immutability

Framework outputs are immutable.

Rather than modifying previously generated knowledge, each framework constructs new structured representations that become inputs for downstream reasoning.

This simplifies testing, improves reproducibility, and reduces unintended interactions between frameworks.

---

## Explainability

Verification artifacts should never appear without supporting evidence.

Where possible, generated properties, diagnostics, and repair recommendations are accompanied by structured explanations describing the semantic evidence that produced them.

Explainability is treated as a first-class architectural objective rather than an optional feature.

---

## Modularity

Frameworks evolve independently.

New reasoning stages can be introduced without redesigning existing architecture, while improvements to one framework remain localized and independently testable.

---

## Empirical Evaluation

Architectural decisions are guided by measurement rather than intuition.

ChipLens includes benchmark suites, external RTL evaluations, regression testing, and structured research methodology to ensure that new capabilities are supported by reproducible evidence.

---

# What Makes ChipLens Different?

ChipLens is **not** another RTL simulator.

It is **not** another formal verification engine.

It is **not** another linting tool.

Instead, ChipLens investigates how semantic reasoning can organize and improve the verification process surrounding existing verification technologies.

The platform combines:

- Design Intelligence
- Semantic Evidence
- Candidate Property Synthesis
- Deterministic Property Ranking
- Property Emission
- Explainability
- Verification Planning
- Engine-Independent Formal Verification
- Coverage Intelligence
- Counterexample Analysis
- Diagnostics Intelligence
- Dependency-Aware Repair Planning
- Verification Orchestration

Each reasoning stage contributes structured knowledge while remaining independently testable and architecturally isolated.

This layered architecture enables verification workflows that are:

- Explainable
- Deterministic
- Modular
- Reproducible
- Extensible
- Research-oriented

Rather than asking only **"Can this property be proven?"**, ChipLens investigates broader questions:

- Why was this property generated?
- Which semantic evidence supports it?
- What verification gaps remain?
- Which diagnostics are most informative?
- Which repair activities should be prioritized?
- How can verification decisions become more transparent and reproducible?

These questions extend beyond proof execution and motivate the compiler-inspired architecture explored throughout the platform.

# System Architecture

ChipLens follows a **layered compiler-inspired architecture** in which RTL verification is decomposed into a sequence of deterministic reasoning frameworks rather than a monolithic verification engine.

Each framework performs one well-defined semantic transformation before producing immutable outputs that become structured inputs for the next stage of the verification pipeline.

This architecture intentionally separates **reasoning** from **verification execution**.

ChipLens is responsible for semantic understanding, property synthesis, planning, diagnostics, explainability, and orchestration, while external formal verification engines remain responsible for proof execution.

This separation enables:

- Independent framework evolution
- Immutable intermediate representations
- Deterministic execution
- Localized testing
- Explainable verification decisions
- Engine-independent verification workflows
- Long-term research extensibility

Every framework in ChipLens is:

- Independently testable
- Deterministic
- Side-effect free
- Built around immutable value objects
- Focused on a single architectural responsibility

---

# Verification Pipeline

The complete verification workflow is illustrated below.

```text
RTL Source
     │
     ▼
┌──────────────────────────────┐
│  Design Intelligence         │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│  Semantic Evidence           │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Candidate Property Synthesis │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Property Ranking             │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Property Emitter             │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Explainability               │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Verification Planner         │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Formal Verification          │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Coverage Analyzer            │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Coverage Intelligence        │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Counterexample Analysis      │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Diagnostics Intelligence     │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Repair Planning              │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Verification Orchestrator    │
└──────────────────────────────┘
     │
     ▼
Verification Session Result
```

The pipeline is intentionally deterministic.

Each framework consumes immutable semantic knowledge, performs a single reasoning task, and produces new immutable outputs without modifying information produced by previous stages.

This design enables reproducible verification workflows while allowing individual reasoning frameworks to evolve independently.

---

# Core Frameworks

ChipLens currently consists of fourteen reasoning frameworks.

Each framework is responsible for exactly one stage of the verification pipeline.

| Framework | Primary Responsibility |
|-----------|------------------------|
| **Design Intelligence** | Extracts structural and behavioral information from RTL designs including modules, registers, ports, memories, clocks, resets, finite-state machines, and signal relationships. |
| **Semantic Evidence** | Converts raw structural information into normalized semantic evidence that can be consumed by downstream reasoning frameworks. |
| **Candidate Property Synthesis** | Generates deterministic candidate verification properties from semantic evidence using specialized synthesis providers. |
| **Property Ranking** | Orders synthesized properties according to deterministic ranking policies before formal emission. |
| **Property Emitter** | Converts ranked candidate properties into verification artifacts suitable for downstream verification engines. |
| **Explainability** | Produces structured explanations describing why each generated property exists and which semantic evidence contributed to it. |
| **Verification Planner** | Organizes generated properties into deterministic verification plans prior to execution. |
| **Formal Verification** | Interfaces with external formal verification engines while remaining independent of any specific backend implementation. |
| **Coverage Analyzer** | Collects structural coverage information, execution statistics, and verification metrics. |
| **Coverage Intelligence** | Interprets coverage results, identifies verification gaps, and generates structured recommendations. |
| **Counterexample Analysis** | Interprets failed verification results and reconstructs structured summaries suitable for downstream reasoning. |
| **Diagnostics Intelligence** | Correlates information from multiple reasoning frameworks to identify verification issues and likely root causes. |
| **Repair Planning** | Converts diagnostics into dependency-aware repair plans without modifying RTL source code. |
| **Verification Orchestrator** | Coordinates the complete reasoning pipeline and assembles an immutable verification session representing the entire verification process. |

---

# Property Synthesis Architecture

One of the primary research contributions of ChipLens is its deterministic property synthesis framework.

Rather than relying on monolithic assertion generation, ChipLens decomposes property synthesis into specialized providers that each reason about one aspect of RTL behavior.

Current synthesis providers include:

- Clock Property Provider
- Reset Property Provider
- FSM Property Provider
- Module Property Provider
- Register Property Provider
- Memory Property Provider
- Arithmetic Property Provider

Each provider:

- Operates independently
- Consumes immutable semantic evidence
- Produces deterministic candidate properties
- Contains no provider-specific special cases
- Can be tested in isolation

This architecture allows new synthesis strategies to be added without modifying existing providers or redesigning the overall synthesis pipeline.

Property generation is therefore both modular and empirically measurable, supporting systematic evaluation of provider effectiveness across independent RTL designs.

# Evaluation

ChipLens is evaluated using a multi-stage empirical methodology designed to measure the effectiveness, correctness, reproducibility, and scalability of its reasoning pipeline.

Rather than relying solely on synthetic demonstrations, the platform is evaluated using representative RTL designs, external open-source projects, benchmark suites, regression testing, and structured research methodology.

The evaluation philosophy is guided by three principles:

- **Reproducibility** — identical RTL input produces identical reasoning output.
- **Transparency** — evaluation methodology, benchmark data, and limitations are publicly documented.
- **Evidence-Based Improvement** — architectural changes are introduced only after quantitative evaluation identifies measurable deficiencies.

---

# Benchmark Suite

ChipLens includes a deterministic benchmark harness that evaluates the complete reasoning pipeline against representative RTL designs.

The benchmark framework measures:

- Analysis runtime
- Diagnostics generated
- Repair recommendations
- Coverage estimation
- Verification pipeline stability

Current benchmark designs include:

| Design | Description | Diagnostics | Repairs | Runtime (ms) |
|---------|-------------|------------:|---------:|-------------:|
| Counter | 4-bit synchronous counter | 1 | 1 | 3 |
| FSM | Traffic light controller | 1 | 1 | 2 |
| ALU | 32-bit combinational ALU | 1 | 1 | 2 |
| FIFO | Parameterized synchronous FIFO | 1 | 1 | 3 |
| UART | UART transmitter (8N1) | 1 | 1 | 4 |

Average pipeline runtime is approximately **3 ms** per benchmark on the current evaluation platform.

These benchmarks evaluate the complete reasoning pipeline rather than the performance of external formal verification engines.

---

# External Open-Source Evaluation

To reduce evaluation bias, ChipLens is continuously evaluated against RTL designs that were **not developed for ChipLens**.

These case studies validate parser robustness, semantic reasoning, diagnostics, and property synthesis across independent projects.

Completed evaluations include:

| Design | Domain | Status |
|---------|--------|--------|
| wb2axip Skid Buffer | AXI Flow Control | Completed |
| PicoRV32 Register File | RISC-V Processor | Completed |
| SERV ALU | Bit-Serial RISC-V | Completed |
| Ibex Module | Industrial RISC-V Core | Completed |

These evaluations have guided multiple architecture improvements, including parser calibration, parameterized RTL support, and property synthesis refinement.

---

# Research Methodology

ChipLens development follows an evidence-driven engineering process.

Instead of introducing architectural changes based on intuition, improvements are guided by structured empirical studies.

Completed research activities include:

- Parser calibration
- Open-source RTL evaluation
- Property generation effectiveness study
- Property provider contribution analysis
- Coverage gap analysis
- Verification productivity methodology
- Benchmark reproducibility validation

Each study produces documented findings that directly inform subsequent architectural improvements.

---

# Property Generation Effectiveness

Property synthesis is evaluated independently from parser correctness.

Current evaluation measures include:

- Total generated properties
- Weighted property coverage
- Provider contribution
- Malformed property rate
- Coverage gaps
- Remaining unsupported RTL constructs

Following Sprint J calibration:

| Metric | Before | Current |
|---------|-------:|--------:|
| Generated Properties | 15 | 25 |
| Weighted Coverage | 50% | **92%** |
| Malformed Properties | 2 | **0** |
| Passing Tests | 2553 | **2723+** |

These improvements were achieved through targeted provider calibration rather than architectural redesign.

---

# Regression Testing

Every production feature is accompanied by dedicated regression tests.

Regression testing currently exceeds **2723 automated tests**, covering:

- RTL parsing
- Semantic evidence generation
- Property synthesis
- Property ranking
- Property emission
- Explainability
- Planning
- Formal integration
- Coverage analysis
- Diagnostics
- Repair planning
- Navigation architecture
- Benchmark framework
- Parser regressions
- Open-source RTL regressions

The regression suite serves as an executable specification for the platform and supports deterministic development.

---

# Research Findings

Several architectural observations have emerged during empirical evaluation.

## Parser Calibration

External RTL evaluation revealed parser edge cases including:

- keyword-boundary ambiguities
- memory-array parsing
- parameterized signal widths
- concatenation assignments

Targeted calibration eliminated multiple false positives while improving parser generalization across independent projects.

---

## Property Synthesis

Specialized synthesis providers substantially improved property generation quality.

Property synthesis now supports:

- Module structure
- Clocks
- Resets
- FSMs
- Registers
- Memory arrays
- Arithmetic datapaths

Calibration eliminated malformed generated properties while significantly improving weighted property coverage.

---

## Deterministic Architecture

Repeated execution of identical RTL produces identical reasoning outputs.

Deterministic execution has remained a core architectural property throughout development and is continuously validated through regression testing.

---

# Threats to Validity

Current evaluation has several limitations.

- Formal verification execution is not included in benchmark runtime measurements.
- Coverage estimation remains partially heuristic in some scenarios.
- Human-subject productivity studies have been designed but not yet executed.
- Large industrial SystemVerilog designs remain future evaluation targets.
- Commercial verification toolchains have not yet been evaluated.

These limitations are intentionally documented to support transparent interpretation of experimental results.

---

# Evaluation Artifacts

Complete evaluation artifacts are maintained under:

```
docs/evaluation/
```

including:

- Benchmark reports
- Open-source case studies
- Evaluation methodology
- Property generation analysis
- Coverage gap analysis
- Parser calibration reports
- Research summaries

All evaluation documents are version-controlled to support reproducibility and future research.

# Project Status

ChipLens has reached **v1.5.0 — Core Reasoning Platform**.

The core verification reasoning pipeline is now architecturally complete, spanning RTL understanding through verification orchestration. Current development emphasizes empirical validation, workbench development, usability, and research dissemination rather than introducing new architectural layers.

Recent development has focused on:

- Stabilizing the property synthesis framework
- Expanding deterministic regression coverage
- Evaluating open-source RTL designs
- Improving parser robustness
- Calibrating property generation providers
- Building reusable navigation and workbench infrastructure
- Preparing the platform for broader community adoption

Future work will primarily emphasize user experience, empirical evaluation, publication-quality documentation, and platform accessibility.

---

# Project Statistics

| Metric | Value |
|---------|------:|
| Current Version | **v1.5.0** |
| Development Status | Active |
| Core Reasoning Frameworks | **14** |
| Property Synthesis Providers | **7** |
| Automated Tests | **2723+ Passing** |
| Test Failures | **0** |
| Analyzer Issues | **0** |
| Layered Architecture | ✅ |
| Immutable Intermediate Models | ✅ |
| Deterministic Pipeline | ✅ |
| Explainability Support | ✅ |
| Verification Planning | ✅ |
| Formal Verification Integration | ✅ |
| Coverage Intelligence | ✅ |
| Counterexample Analysis | ✅ |
| Diagnostics Intelligence | ✅ |
| Repair Planning | ✅ |
| Verification Orchestrator | ✅ |
| Benchmark Harness | ✅ |
| External RTL Evaluation | **4 Designs** |
| Research Methodology | Complete |

---

# Technology Stack

| Category | Technologies |
|----------|--------------|
| Language | Dart |
| UI Framework | Flutter |
| Desktop | Windows (primary), Linux/macOS capable |
| Web | Flutter Web (planned) |
| Testing | flutter_test |
| Static Analysis | flutter analyze |
| Version Control | Git, GitHub |
| Continuous Quality | Automated regression testing |
| Formal Verification | SymbiYosys, Yosys |
| Simulation | Verilator, Icarus Verilog |
| Documentation | Markdown |
| Benchmarking | Custom benchmark framework |

---

# Repository Structure

```text
ChipLens/
│
├── frontend/
│   │
│   ├── lib/
│   │   │
│   │   ├── backend/
│   │   │   ├── design_intelligence/
│   │   │   ├── property_inference/
│   │   │   ├── explainability/
│   │   │   ├── planning/
│   │   │   ├── formal/
│   │   │   ├── coverage/
│   │   │   ├── coverage_intelligence/
│   │   │   ├── counterexample/
│   │   │   ├── diagnostics/
│   │   │   ├── repair/
│   │   │   ├── orchestrator/
│   │   │   └── ui/
│   │   │
│   │   ├── models/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── screens/
│   │
│   ├── benchmarks/
│   │   ├── runner/
│   │   ├── models/
│   │   └── reports/
│   │
│   └── test/
│       ├── unit/
│       ├── integration/
│       ├── benchmarks/
│       ├── parser_regressions/
│       ├── property_providers/
│       └── fixtures/
│
├── docs/
│   ├── architecture/
│   ├── evaluation/
│   ├── research/
│   └── images/
│
├── LICENSE
├── CHANGELOG.md
└── README.md
```

The repository is organized around architectural responsibilities rather than implementation details, mirroring the layered reasoning pipeline implemented by ChipLens.

---

# Engineering Principles

ChipLens is developed according to a consistent set of software engineering principles that guide every architectural decision.

## Layered Reasoning

Verification is decomposed into independent reasoning frameworks.

Each framework performs one semantic transformation before producing immutable outputs consumed by downstream stages.

---

## Deterministic Execution

Given identical RTL input, ChipLens produces identical reasoning results.

This property enables reproducible experimentation, regression testing, and benchmark comparison.

---

## Immutability

Frameworks communicate exclusively through immutable value objects.

No framework mutates outputs produced by previous stages.

---

## Explainability

Verification decisions should be understandable.

Generated properties, diagnostics, repair recommendations, and verification plans are accompanied by structured reasoning wherever possible.

---

## Testability

Every framework is independently unit tested.

Regression testing currently exceeds **2723 automated tests**, helping ensure architectural stability while supporting continuous development.

---

## Modularity

Frameworks evolve independently.

Architectural improvements remain localized, minimizing coupling between reasoning stages.

---

## Extensibility

The platform is intentionally designed to support future research without requiring architectural redesign.

Examples include:

- Additional formal verification engines
- New property synthesis providers
- Alternative ranking strategies
- AI-assisted reasoning modules
- Verification visualization
- Cloud verification services

---

# Getting Started

## Prerequisites

Install the following tools:

### Required

- Flutter (latest stable release)
- Dart SDK
- Git

### Optional (Formal Verification)

ChipLens integrates with external verification tools for proof execution.

Supported backends include:

- SymbiYosys
- Yosys
- Verilator
- Icarus Verilog

The reasoning pipeline operates independently of these tools; they are only required when executing formal verification.

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

## Execute the Test Suite

```bash
flutter test
```

---

## Static Analysis

```bash
flutter analyze
```

---

## Run Benchmarks

```bash
flutter test test/benchmarks/benchmark_suite_test.dart
```

This executes the deterministic benchmark harness and regenerates evaluation artifacts under:

```
docs/evaluation/
```

---

## Development Workflow

Recommended workflow for contributors:

```text
Modify Code
      │
      ▼
flutter analyze
      │
      ▼
flutter test
      │
      ▼
Benchmark Suite
      │
      ▼
Update Documentation
      │
      ▼
Commit Changes
```

Maintaining deterministic behavior, regression coverage, and documentation consistency is considered part of every production change.

# Project Roadmap

ChipLens has completed the **Core Reasoning Platform (v1.5.0)**.

Development is now focused on transforming the platform into a mature research and engineering ecosystem while preserving its deterministic, compiler-inspired architecture.

---

## Phase 1 — Core Reasoning Platform ✅

The following architectural milestones have been completed:

- RTL Analysis
- Design Intelligence
- Semantic Evidence
- Candidate Property Synthesis
- Property Ranking
- Property Emitter
- Explainability
- Verification Planning
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

- Verification Workbench
- Project Explorer
- Property Explorer
- Explainability Viewer
- Coverage Dashboard
- Diagnostics Timeline
- Repair Planner
- Flutter Web support
- Cross-platform user experience
- Improved reporting
- Repository refinement

---

## Phase 3 — Research Expansion

Future research directions include:

- Large-scale open-source RTL evaluation
- Industrial benchmark evaluation
- Human-subject productivity studies
- Comparative verification studies
- Explainable verification metrics
- Property synthesis evaluation
- Verification planning effectiveness
- Research publication

---

## Phase 4 — Community & Ecosystem

Long-term objectives include:

- Open-source community contributions
- Multiple formal verification backends
- Plugin architecture
- Cloud verification services
- Python interoperability
- CI/CD integration
- Educational use
- Research collaboration

---

# Documentation

Project documentation is organized under the `docs/` directory.

| Directory | Description |
|-----------|-------------|
| `docs/architecture/` | Architectural overviews and framework documentation |
| `docs/evaluation/` | Benchmark reports and case studies |
| `docs/research/` | Research methodology and experimental results |
| `docs/images/` | Figures, diagrams, and screenshots |

Documentation evolves alongside the implementation and is treated as a first-class project artifact.

---

# Research Vision

ChipLens investigates how compiler-inspired software engineering principles can improve hardware verification workflows.

The long-term vision is to develop a verification platform where semantic reasoning, explainability, planning, diagnostics, and formal verification operate as components of a unified, deterministic architecture rather than isolated tool invocations.

Current research themes include:

- Compiler-inspired verification architectures
- Semantic RTL analysis
- Deterministic property synthesis
- Explainable verification
- Verification planning
- Coverage intelligence
- Diagnostics correlation
- Dependency-aware repair planning
- Empirical verification methodology

Future research may explore:

- AI-assisted verification reasoning
- Hybrid symbolic and semantic analysis
- Interactive verification workbenches
- Large-scale industrial evaluation
- Collaborative verification environments

ChipLens is intended to remain an open research platform that encourages experimentation, reproducibility, and collaboration.

---

# Contributing

Contributions are welcome.

Whether you are interested in RTL verification, formal methods, compiler design, software architecture, or Flutter development, contributions that improve the quality, correctness, or usability of ChipLens are appreciated.

Before contributing:

1. Fork the repository.
2. Create a feature branch.
3. Follow the existing architectural principles.
4. Add regression tests for all production changes.
5. Run:

```bash
flutter analyze
flutter test
```

6. Update relevant documentation.
7. Submit a Pull Request.

Architectural consistency, deterministic behavior, and comprehensive testing are considered essential project requirements.

---

# Citation

If ChipLens contributes to your research, please cite the project.

```text
@software{chiplens,
  title   = {ChipLens: Compiler-Inspired Semantic RTL Verification Research Platform},
  author  = {Anumeha},
  year    = {2026},
  url     = {https://github.com/Anumeha600/ChipLens},
  license = {MIT}
}
```

A formal publication citation will be added once a peer-reviewed paper becomes available.

---

# Acknowledgements

ChipLens builds upon the open-source hardware verification ecosystem.

The project gratefully acknowledges the work of the communities behind:

- Yosys
- SymbiYosys
- Verilator
- Icarus Verilog
- Flutter
- Dart

Their tools and ecosystems make open, reproducible hardware verification research possible.

---

# License

ChipLens is released under the **MIT License**.

See the [LICENSE](LICENSE) file for details.

---

# Closing Remarks

ChipLens began as an exploration into whether compiler-inspired semantic reasoning could improve the organization and explainability of RTL verification workflows.

It has since evolved into a modular research platform comprising fourteen reasoning frameworks, deterministic property synthesis, empirical evaluation methodology, and a growing body of experimental evidence.

The project continues to evolve through careful architectural design, rigorous regression testing, and evidence-driven refinement.

Contributions, discussions, and research collaborations are welcome as ChipLens continues toward its long-term vision of making hardware verification more transparent, reproducible, and understandable.
