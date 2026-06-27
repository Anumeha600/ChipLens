# ChipLens

# Compiler-Inspired Semantic RTL Verification Research Platform

<p align="center">

[![Version](https://img.shields.io/badge/version-v2.0.0--dev-blue.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-3196%2B-success.svg)]()

</p>

ChipLens is an open-source research platform that applies **compiler-inspired software engineering principles** to **Register Transfer Level (RTL) verification**.

Rather than viewing RTL verification as a sequence of disconnected tool invocations, ChipLens models verification as a structured reasoning pipeline. Each stage incrementally constructs semantic knowledge about an RTL design before producing verification artifacts, diagnostics, coverage intelligence, and explainable verification results.

The project separates **reasoning** from **verification execution**. ChipLens performs semantic analysis, property synthesis, verification planning, diagnostics, explainability, repair planning, and orchestration while remaining independent of any single formal verification engine.

The result is a deterministic, modular, and explainable verification workflow designed for research into next-generation hardware verification methodologies.

---

# Highlights

- Compiler-inspired layered verification architecture
- Semantic RTL analysis and evidence extraction
- Deterministic property synthesis
- Explainable verification decisions
- Verification planning
- Coverage intelligence
- Counterexample analysis
- Diagnostics intelligence
- Dependency-aware repair planning
- Verification orchestration
- Desktop-first Engineering Workbench
- Immutable intermediate representations
- Deterministic execution pipeline
- Empirical evaluation against open-source RTL designs
- Benchmark harness with reproducible results
- 3196+ automated tests
- Zero failing tests
- Active research and development

---

# Current Status

| Item | Status |
|------|--------|
| Current Version | **v2.0.0-dev** |
| Development Status | Active |
| Platform | Flutter + Dart |
| License | MIT |
| Core Reasoning Frameworks | 14 |
| Property Providers | 8 |
| Engineering Workbench | Desktop-first |
| Workspace Explorer | Complete |
| Verification Workspace | In Progress |
| Automated Tests | **3196+ Passing** |
| Test Failures | **0** |
| Analyzer Errors | **0** |
| Research Evaluation | Complete |
| Open-source RTL Validation | Complete |

---

# Table of Contents

- [Why ChipLens?](#why-chiplens)
- [Research Motivation](#research-motivation)
- [Engineering Philosophy](#engineering-philosophy)
- [Why Flutter and Dart?](#why-flutter-and-dart)
- [Architectural Scope](#architectural-scope)
- [System Architecture](#system-architecture)
- [Verification Pipeline](#verification-pipeline)
- [Core Frameworks](#core-frameworks)
- [Property Synthesis Architecture](#property-synthesis-architecture)
- [Engineering Workbench](#engineering-workbench)
- [Evaluation](#evaluation)
- [Open-Source RTL Validation](#open-source-rtl-validation)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Current Limitations](#current-limitations)
- [Roadmap](#roadmap)
- [Research Vision](#research-vision)
- [Contributing](#contributing)
- [Citation](#citation)
- [License](#license)

# Why ChipLens?

Modern RTL verification relies on a rich ecosystem of simulation, linting, static analysis, and formal verification tools. While these tools are individually powerful, the reasoning that connects them often remains fragmented, manual, and difficult to reproduce.

Verification engineers are frequently responsible for answering questions such as:

- Which properties should be verified?
- Why were those properties selected?
- What evidence supports a generated assertion?
- Which portions of the design remain under-verified?
- How should verification failures be prioritized?
- What repair activities should be performed next?

Traditional verification flows provide excellent execution engines but comparatively little structured reasoning before or after verification.

ChipLens investigates a different approach.

Rather than treating verification as a collection of independent tools, ChipLens models verification as a deterministic reasoning pipeline inspired by modern compiler infrastructures.

Every framework performs a single semantic transformation, incrementally enriching the understanding of an RTL design before producing verification artifacts, diagnostics, explainability information, coverage intelligence, repair recommendations, and verification reports.

The objective is not to replace established formal verification engines, but to organize the reasoning surrounding them.

---

# Research Motivation

ChipLens originated from a simple research question:

> **Can compiler-inspired semantic reasoning improve the transparency, reproducibility, and organization of RTL verification workflows?**

Modern compiler infrastructures have demonstrated that complex software analysis becomes significantly easier when computation is decomposed into independent semantic passes operating over immutable intermediate representations.

Hardware verification rarely adopts this architectural philosophy.

Instead, many verification flows consist of loosely connected scripts, isolated tools, manually maintained property sets, and independently interpreted results.

ChipLens investigates whether these software engineering principles can improve RTL verification by introducing:

- Layered semantic analysis
- Immutable intermediate representations
- Deterministic transformations
- Structured evidence propagation
- Explainable reasoning
- Modular verification stages
- Reproducible verification workflows

Rather than focusing exclusively on proving properties, ChipLens focuses on understanding the verification process itself.

---

# Engineering Philosophy

Every architectural decision within ChipLens follows a small set of engineering principles that remain consistent throughout the entire platform.

## Layered Reasoning

Verification is decomposed into independent reasoning stages.

Each framework performs one semantic transformation before passing immutable outputs to the next framework.

No framework performs multiple unrelated responsibilities.

---

## Single Responsibility

Every framework owns one clearly defined task.

Examples include:

- Semantic Evidence extraction
- Property Synthesis
- Property Ranking
- Explainability
- Coverage Intelligence
- Diagnostics Intelligence
- Repair Planning

This separation reduces coupling while allowing individual frameworks to evolve independently.

---

## Deterministic Execution

Identical RTL inputs always produce identical reasoning outputs.

ChipLens intentionally avoids hidden mutable state and non-deterministic execution whenever possible.

Deterministic execution enables:

- reproducible experiments
- stable benchmark results
- predictable verification artifacts
- reliable regression testing

---

## Immutability

Communication between frameworks occurs exclusively through immutable value objects.

This approach:

- eliminates unintended side effects
- simplifies testing
- improves reasoning reproducibility
- reduces architectural complexity

---

## Explainability

Verification artifacts should never appear without supporting evidence.

Whenever ChipLens generates a verification property, diagnostic, or recommendation, supporting semantic evidence accompanies that decision whenever possible.

The objective is to make verification understandable rather than opaque.

---

## Modularity

Every framework can evolve independently.

New reasoning stages can be introduced without modifying unrelated components.

Likewise, individual frameworks may be replaced or experimentally evaluated while preserving the surrounding architecture.

---

## Extensibility

ChipLens is designed as a long-term research platform rather than a fixed verification tool.

Future research directions include:

- semantic analysis
- verification planning
- explainable verification
- AI-assisted verification
- verification optimization
- automated repair planning
- engineering workbench extensions

without requiring fundamental architectural redesign.

---

# Why Flutter and Dart?

ChipLens intentionally adopts an unconventional technology stack.

Electronic Design Automation tools have historically been implemented using languages such as C++, Python, Tcl, Java, and OCaml.

ChipLens instead explores whether modern application engineering practices can simplify the development of research-grade verification software.

Flutter provides:

- cross-platform desktop support
- web deployment
- responsive engineering interfaces
- modern rendering
- rapid user interface development

Dart provides:

- strong static typing
- immutable programming patterns
- asynchronous execution
- expressive value-oriented APIs
- excellent testability

These characteristics closely align with the architectural goals of ChipLens.

The project deliberately separates semantic reasoning from graphical presentation.

Verification frameworks remain independent of the user interface, allowing future command-line interfaces, web deployments, and alternative frontends without modifying the reasoning engine.

Although unusual within Electronic Design Automation, this architecture enables a unified implementation across desktop and web environments while maintaining deterministic verification behavior.

---

# Architectural Scope

ChipLens is **not** a replacement for formal verification engines.

Instead, it operates as an intelligent reasoning layer surrounding existing verification backends.

Responsibilities currently implemented include:

- RTL semantic analysis
- evidence extraction
- candidate property synthesis
- deterministic property ranking
- property emission
- explainability
- verification planning
- coverage interpretation
- counterexample analysis
- diagnostics intelligence
- repair planning
- verification orchestration

Execution of formal verification remains delegated to external engines such as SymbiYosys.

This separation allows ChipLens to remain backend-independent while focusing on reasoning rather than proof execution.

# System Architecture

ChipLens follows a **compiler-inspired layered architecture** in which verification is decomposed into independent reasoning frameworks.

Rather than combining parsing, property generation, diagnostics, planning, and reporting into a monolithic verification engine, ChipLens performs verification as a sequence of deterministic semantic transformations.

Each framework receives immutable inputs, performs one well-defined responsibility, and produces immutable outputs consumed by subsequent frameworks.

This architecture improves:

- Modularity
- Testability
- Deterministic execution
- Explainability
- Reproducibility
- Long-term extensibility

Every framework is:

- Independently testable
- Deterministic
- Side-effect free
- Backend independent
- Built around immutable value objects

---

# Verification Pipeline

The complete reasoning pipeline currently consists of fourteen major frameworks.

```text
RTL Source
     │
     ▼
┌──────────────────────────────┐
│ Design Intelligence          │
└──────────────────────────────┘
     │
     ▼
┌──────────────────────────────┐
│ Semantic Evidence            │
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
Verification Session
```

Every framework contributes structured semantic knowledge to the overall verification process.

Rather than duplicating information across stages, ChipLens progressively enriches the understanding of the RTL design until a complete verification session is produced.

---

# Core Frameworks

| Framework | Primary Responsibility |
|------------|------------------------|
| **Design Intelligence** | Extracts structural and behavioural information from RTL designs, including modules, signals, registers, clocks, resets, counters, memories, and finite state machines. |
| **Semantic Evidence** | Converts structural information into immutable semantic evidence used throughout the reasoning pipeline. |
| **Candidate Property Synthesis** | Generates deterministic candidate verification properties from semantic evidence using independent synthesis providers. |
| **Property Ranking** | Prioritises candidate properties according to deterministic ranking policies before formal emission. |
| **Property Emitter** | Converts ranked properties into backend-independent formal verification artifacts suitable for downstream verification engines. |
| **Explainability** | Produces structured explanations describing why each property was generated and which semantic evidence contributed to that decision. |
| **Verification Planner** | Organises generated properties into deterministic verification plans prior to execution. |
| **Formal Verification** | Interfaces with external formal verification engines while remaining independent of any particular backend implementation. |
| **Coverage Analyzer** | Collects structural verification coverage and execution statistics. |
| **Coverage Intelligence** | Interprets coverage information, identifies verification gaps, and generates structured recommendations. |
| **Counterexample Analysis** | Reconstructs structured summaries from failed verification traces for downstream reasoning. |
| **Diagnostics Intelligence** | Correlates outputs from multiple reasoning frameworks to identify verification issues and likely root causes. |
| **Repair Planning** | Converts diagnostics into dependency-aware repair recommendations without modifying RTL source code. |
| **Verification Orchestrator** | Coordinates the complete verification workflow and assembles an immutable verification session representing the entire reasoning process. |

---

# Property Synthesis Architecture

Property synthesis is implemented as a modular provider pipeline.

Rather than embedding all synthesis logic inside a single framework, ChipLens delegates candidate generation to independent providers, each responsible for a specific verification domain.

Current providers include:

| Provider | Responsibility |
|-----------|----------------|
| **Reset Property Provider** | Generates reset-related safety properties. |
| **FSM Property Provider** | Produces properties describing finite-state machine behaviour. |
| **Counter Property Provider** | Generates deterministic counter verification properties. |
| **Handshake Property Provider** | Detects ready/valid style interfaces and synthesises communication safety properties. |
| **Safety Property Provider** | Generates generic safety assertions from semantic evidence. |
| **Memory Property Provider** | Produces conservative properties for memory arrays and memory interface signals. |
| **Arithmetic Property Provider** | Synthesises safety properties for arithmetic datapaths, carry chains, comparators, and result signals. |
| **Register Property Provider** | Generates safety properties for sequential registers not already covered by specialised providers. |

Every provider:

- operates independently,
- receives immutable semantic inputs,
- produces immutable property collections,
- remains deterministic,
- can be tested in isolation,
- integrates without modifying the synthesis pipeline.

This provider-based architecture enables new synthesis strategies to be introduced through composition rather than architectural modification.

---

# Engineering Workbench

ChipLens includes a **desktop-first Engineering Workbench** that exposes the reasoning pipeline through an IDE-inspired interface.

Unlike traditional EDA tools that present verification results as disconnected reports, the Engineering Workbench organises the complete verification workflow into reusable panels.

Current implementation includes:

- Desktop-first multi-panel architecture
- Engineering Workbench framework
- Immutable workbench state
- Panel registry
- Workspace Explorer
- Responsive desktop/web layout
- Toolbar
- Status bar

The Workspace Explorer organises projects by verification workflow rather than filesystem structure, providing logical access to:

- RTL sources
- Verification artifacts
- Coverage analysis
- Diagnostics
- Explainability
- Repair planning
- Evaluation results
- Reports

The workbench is intentionally modular.

Future engineering tools—including the RTL editor, Property Explorer, Explainability Viewer, Coverage Dashboard, Diagnostics Explorer, and Repair Planner—will integrate through the existing panel architecture without modifying the workbench framework itself.

# Evaluation

ChipLens includes a reproducible evaluation framework that measures the complete reasoning pipeline on representative RTL designs.

The evaluation focuses on the reasoning frameworks implemented by ChipLens rather than the performance of external formal verification engines.

Current evaluation areas include:

- End-to-end reasoning pipeline execution
- Property generation effectiveness
- Open-source RTL validation
- Parser calibration
- Property synthesis calibration
- Cross-project generalization
- Benchmark execution
- Structural diagnostics
- Coverage intelligence

Every evaluation is reproducible and documented within the repository.

---

# Benchmark Suite

ChipLens contains a deterministic benchmark harness that executes the complete reasoning pipeline against representative RTL designs.

Current benchmark corpus:

| Design | Description | Diagnostics | Repairs | Runtime |
|----------|-------------|------------:|---------:|--------:|
| Counter | 4-bit synchronous counter | 1 | 1 | ~3 ms |
| FSM | Traffic-light controller | 1 | 1 | ~2 ms |
| ALU | 32-bit combinational ALU | 1 | 1 | ~2 ms |
| FIFO | Parameterized synchronous FIFO | 1 | 1 | ~3 ms |
| UART | UART transmitter (8N1) | 1 | 1 | ~4 ms |

Average reasoning pipeline runtime:

**≈ 3 ms per benchmark design**

> **Note**
>
> Current benchmarks evaluate the ChipLens reasoning pipeline.
> They intentionally exclude the runtime of external formal verification engines.

---

# Property Generation Evaluation

ChipLens includes a dedicated evaluation methodology for measuring property synthesis effectiveness.

Rather than counting generated assertions alone, evaluation measures whether generated properties meaningfully cover verification-relevant RTL elements.

Current evaluation metrics include:

- Generated properties
- Useful properties
- Weighted element coverage
- Provider contribution
- Malformed properties
- Coverage gaps
- Cross-project generalization

Following Sprint J calibration:

| Metric | Result |
|---------|-------:|
| Total Property Providers | 8 |
| Generated Properties | 32 |
| Weighted Element Coverage | **92%** |
| Malformed Properties | **0** |
| Deterministic Generation | ✅ |
| Provider Isolation | ✅ |

The evaluation framework documents both successful synthesis and remaining limitations, allowing future improvements to be measured quantitatively rather than anecdotally.

---

# Open-Source RTL Validation

ChipLens is evaluated against RTL designs originating from independent open-source hardware projects.

These evaluations measure how well the reasoning pipeline generalizes beyond designs created specifically for ChipLens.

Current evaluation corpus:

| Project | Domain | Result |
|---------|--------|--------|
| wb2axip Skid Buffer | AXI Flow Control | Parser calibrated successfully |
| PicoRV32 Register File | RISC-V CPU | Parser robustness improved |
| SERV ALU | Bit-Serial RISC-V | Parameterized RTL support validated |
| Ibex RTL Module | Industrial RISC-V Core | Property synthesis evaluation completed |

These evaluations have directly influenced several architectural improvements, including:

- Keyword-boundary parser corrections
- Memory-array detection
- Width inference improvements
- Parameterized RTL support
- Memory interface extraction
- Property synthesis calibration
- Register property generation
- Memory property generation

Unlike synthetic examples, these evaluations represent independent codebases with differing design styles, improving confidence in the generality of the reasoning pipeline.

---

# Empirical Contributions

ChipLens emphasizes empirical software engineering.

Every architectural improvement is expected to be supported by:

- Regression tests
- Benchmark results
- Calibration studies
- Before/after comparisons
- Open-source validation
- Documented limitations

The repository intentionally records unsuccessful experiments, parser limitations, calibration decisions, and remaining research challenges.

The objective is to produce reproducible engineering evidence rather than isolated implementation claims.

---

# Automated Testing

ChipLens places a strong emphasis on deterministic regression testing.

Current statistics:

| Metric | Value |
|---------|-------|
| Automated Tests | **3196+** |
| Test Failures | **0** |
| Analyzer Issues | **0** |

The test suite covers:

- Parser correctness
- Semantic analysis
- Knowledge providers
- Property providers
- Ranking
- Explainability
- Planning
- Coverage
- Diagnostics
- Repair planning
- Formal integration
- Engineering Workbench
- Workspace Explorer
- UI architecture
- Regression scenarios
- Open-source RTL calibrations

The testing philosophy prioritizes deterministic behavior and architectural stability over implementation-specific testing.

---

# Technology Stack

| Category | Technologies |
|-----------|--------------|
| Language | Dart 3 |
| Framework | Flutter |
| Target Platforms | Windows, Linux, macOS, Web |
| UI Architecture | Desktop-first Engineering Workbench |
| Formal Verification | SymbiYosys, Yosys, Verilator, Icarus Verilog |
| Testing | flutter_test |
| Static Analysis | flutter analyze |
| Version Control | Git + GitHub |
| Documentation | Markdown |
| License | MIT |

ChipLens deliberately separates the reasoning engine from verification backends, enabling future integration with additional formal verification tools without modifying the reasoning architecture.

---

# Repository Structure

```text
ChipLens/
│
├── frontend/
│   ├── lib/
│   │   ├── backend/
│   │   │   ├── design_intelligence/
│   │   │   ├── semantic_evidence/
│   │   │   ├── property_inference/
│   │   │   ├── explainability/
│   │   │   ├── planning/
│   │   │   ├── formal/
│   │   │   ├── coverage/
│   │   │   ├── coverage_intelligence/
│   │   │   ├── counterexample/
│   │   │   ├── diagnostics/
│   │   │   ├── repair_planning/
│   │   │   └── orchestrator/
│   │   │
│   │   ├── ui/
│   │   │   ├── workbench/
│   │   │   ├── navigation/
│   │   │   ├── responsive/
│   │   │   └── theme/
│   │   │
│   │   └── models/
│   │
│   ├── benchmarks/
│   └── test/
│
├── docs/
│   ├── evaluation/
│   ├── research/
│   └── architecture/
│
├── LICENSE
├── CHANGELOG.md
└── README.md
```

The repository is organized around architectural responsibilities rather than implementation layers, reflecting the same modular philosophy adopted throughout the reasoning pipeline.

# Getting Started

## Requirements

- Flutter 3.x
- Dart SDK 3.x
- Git

Optional (for formal verification):

- SymbiYosys
- Yosys
- Verilator
- Icarus Verilog

---

## Clone the Repository

```bash
git clone https://github.com/<your-username>/ChipLens.git
cd ChipLens/frontend
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run the Application

```bash
flutter run
```

Desktop platforms are currently the primary development target.

---

## Run Static Analysis

```bash
flutter analyze
```

Expected result:

```
No issues found.
```

---

## Run the Test Suite

```bash
flutter test
```

Current status:

```
3196+ Passing Tests

0 Failures

0 Analyzer Issues
```

---

# Current Limitations

ChipLens is an active research platform and continues to evolve.

Current limitations include:

## Verification Backends

Formal execution currently targets SymbiYosys.

Portable backend discovery and configurable toolchain management are under active development.

---

## Property Synthesis

Current property synthesis emphasizes deterministic safety properties.

Future work includes:

- Temporal property inference
- Protocol-aware synthesis
- Cross-module reasoning
- Multi-clock verification
- Advanced memory consistency properties

---

## RTL Support

The parser currently focuses on synthesizable Verilog.

Future work includes:

- Additional SystemVerilog constructs
- Generate block enhancements
- Interface support
- Package-aware parsing

---

## Engineering Workbench

Current implementation includes:

- Engineering Workbench
- Workspace Explorer
- Responsive desktop layout
- Panel framework

Future engineering tools include:

- RTL Workspace
- Property Explorer
- Explainability Viewer
- Coverage Dashboard
- Diagnostics Explorer
- Repair Planner
- Verification Session Viewer

---

## AI Integration

ChipLens intentionally separates deterministic reasoning from AI-assisted workflows.

Future research may investigate:

- Property recommendation
- Natural-language verification queries
- Automated explanation refinement
- Intelligent repair suggestions

while preserving deterministic verification behavior.

---

# Roadmap

## Phase I

### Compiler-Inspired Reasoning Platform

- ✅ Design Intelligence
- ✅ Semantic Evidence
- ✅ Candidate Property Synthesis
- ✅ Property Ranking
- ✅ Property Emitter
- ✅ Explainability
- ✅ Verification Planning
- ✅ Formal Verification
- ✅ Coverage Intelligence
- ✅ Diagnostics Intelligence
- ✅ Repair Planning
- ✅ Verification Orchestration

Completed.

---

## Phase II

### Research Validation

- ✅ Open-source RTL evaluation
- ✅ Benchmark suite
- ✅ Property generation evaluation
- ✅ Calibration studies
- ✅ Coverage analysis
- ✅ Empirical documentation

Completed.

---

## Phase III

### Engineering Workbench

- ✅ Desktop-first architecture
- ✅ Responsive workbench
- ✅ Panel registry
- ✅ Immutable workbench state
- ✅ Workspace Explorer

In Progress:

- RTL Workspace
- Property Explorer
- Explainability Viewer
- Coverage Dashboard
- Diagnostics Explorer
- Repair Planner
- Verification Session Viewer

---

## Phase IV

### Platform Integration

Planned:

- Portable formal backend discovery
- Toolchain configuration
- Project persistence
- Workspace management
- Command-line interface
- Improved web deployment

---

## Phase V

### Research & Publication

Planned:

- Compiler-inspired RTL verification paper
- Property synthesis evaluation paper
- Explainable verification paper
- Engineering workbench paper
- Expanded benchmark suite

---

# Research Vision

ChipLens explores a broader research direction:

> **Applying compiler-inspired software engineering principles to hardware verification.**

Rather than replacing existing verification engines, ChipLens investigates how deterministic semantic reasoning can improve:

- Explainability
- Reproducibility
- Automation
- Verification planning
- Coverage interpretation
- Diagnostics
- Repair planning

The long-term objective is to establish a reusable semantic reasoning layer capable of supporting both academic research and practical engineering workflows.

---

# Contributing

Contributions are welcome.

Areas of interest include:

- RTL parsing
- Semantic analysis
- Property synthesis
- Verification planning
- Formal verification integration
- Coverage intelligence
- Diagnostics
- Engineering Workbench
- Documentation
- Benchmark development
- Testing

Please ensure that all contributions:

- preserve deterministic behavior
- include regression tests
- maintain architectural modularity
- avoid framework-specific coupling
- pass `flutter analyze`
- pass the complete automated test suite

---

# Citation

If ChipLens contributes to your research, please cite the project.

A formal citation will be provided following the first research publication.

---

# License

ChipLens is released under the MIT License.

See the LICENSE file for details.

---

# About the Author

ChipLens is an independent open-source research project exploring the intersection of:

- Electronic Design Automation (EDA)
- Formal Verification
- Compiler Design
- Software Architecture
- Verification Engineering
- Explainable Systems

The project is developed as both an engineering platform and a long-term research initiative investigating compiler-inspired approaches to RTL verification.

---

# Project Status

ChipLens has evolved from an experimental prototype into a research-oriented engineering platform.

Current implementation includes:

- 14 reasoning frameworks
- 8 property providers
- Desktop-first Engineering Workbench
- Workspace Explorer
- Open-source RTL evaluation
- Deterministic reasoning pipeline
- Empirical benchmark suite
- 3196+ automated tests
- Zero analyzer issues
- Zero failing tests

Development continues toward a complete verification engineering environment integrating deterministic reasoning, explainability, and modern engineering workflows.

---

**ChipLens**
*Compiler-Inspired Semantic RTL Verification Research Platform*
