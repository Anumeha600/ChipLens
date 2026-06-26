# ChipLens

> **Compiler-Inspired Semantic RTL Verification Research Platform**

[![Version](https://img.shields.io/badge/version-v1.5.0-blue.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-Stable-02569B?logo=flutter)]()
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()
[![Tests](https://img.shields.io/badge/Tests-2818%2B-success.svg)]()

ChipLens is an open-source research platform that investigates **compiler-inspired approaches to Register Transfer Level (RTL) verification**.

Rather than treating hardware verification as a sequence of disconnected tools, ChipLens incrementally constructs semantic knowledge about an RTL design before generating verification artifacts, planning formal verification, interpreting results, and producing explainable diagnostics.

The platform models verification as a deterministic reasoning pipeline composed of independent frameworks. Each framework performs one well-defined transformation and communicates exclusively through immutable value objects, enabling reproducible analysis, modular evolution, and transparent reasoning.

ChipLens is **not** a replacement for existing formal verification engines.

Instead, it acts as an intelligent semantic reasoning layer that organizes knowledge before, during, and after formal verification while remaining architecturally independent of any particular backend.

---

# Highlights

- Compiler-inspired layered verification architecture
- Deterministic semantic RTL reasoning
- Immutable intermediate representations
- Design Intelligence framework
- Semantic Evidence extraction
- Deterministic Property Synthesis
- Property Ranking
- Property Emitter
- Explainability framework
- Verification Planning
- Formal Verification abstraction
- Coverage Analysis
- Coverage Intelligence
- Counterexample Analysis
- Diagnostics Intelligence
- Dependency-aware Repair Planning
- Verification Orchestration
- Cross-platform Flutter workbench (under active development)
- Optional AI-assisted natural-language interaction
- Benchmark harness with reproducible evaluation
- Open-source RTL evaluation methodology
- 2818+ automated tests
- Zero analyzer errors and warnings
- Active research and development

---

# Current Status

| Item | Status |
|------|--------|
| Current Release | v1.5.0 – Core Reasoning Platform |
| Development | Active |
| Language | Dart |
| UI Framework | Flutter |
| License | MIT |
| Automated Tests | 2818+ Passing |
| Test Failures | 0 |
| Analyzer Errors | 0 |
| Analyzer Warnings | 0 |
| Architecture | Layered & Modular |
| Core Reasoning Pipeline | Complete |
| Property Synthesis | Stable |
| Formal Backend | SymbiYosys |
| Flutter Workbench | In Progress |
| Research Evaluation | Ongoing |

---

# Current Implementation Status

| Component | Status |
|-----------|--------|
| RTL Parsing | ✅ Stable |
| Design Intelligence | ✅ Stable |
| Semantic Evidence | ✅ Stable |
| Property Synthesis | ✅ Stable |
| Property Ranking | ✅ Stable |
| Property Emitter | ✅ Stable |
| Explainability | ✅ Stable |
| Verification Planning | ✅ Stable |
| Formal Verification Abstraction | ✅ Stable |
| SymbiYosys Backend | ✅ Available |
| Coverage Analysis | ✅ Stable |
| Coverage Intelligence | ✅ Stable |
| Counterexample Analysis | ✅ Stable |
| Diagnostics Intelligence | ✅ Stable |
| Repair Planning | ✅ Stable |
| Verification Orchestrator | ✅ Stable |
| Flutter Workbench | 🚧 In Progress |
| Flutter Web Experience | 🚧 Planned |
| Portable Formal Backend Discovery | 🚧 Planned |

---

# Table of Contents

- Why ChipLens?
- Research Motivation
- Engineering Philosophy
- Why Flutter and Dart?
- System Architecture
- Verification Pipeline
- Core Frameworks
- Property Synthesis Architecture
- Evaluation
- Open-Source RTL Validation
- Technology Stack
- Repository Structure
- Engineering Principles
- Getting Started
- Current Limitations
- Roadmap
- Research Vision
- Contributing
- Citation
- License

# Why ChipLens?

Modern RTL verification relies on a rich ecosystem of simulators, linters, model checkers, and formal verification engines. While these tools are individually powerful, engineers are often responsible for connecting them into a complete verification workflow, interpreting results, identifying verification gaps, and deciding what should be verified next.

Much of this reasoning remains manual, fragmented, and difficult to reproduce.

ChipLens investigates a different approach.

Rather than viewing verification as a collection of independent tools, ChipLens models verification as a **structured reasoning pipeline** that incrementally builds semantic knowledge about a design before, during, and after verification.

Instead of producing isolated verification artifacts, each framework contributes structured information that becomes immutable input for subsequent reasoning stages.

The result is a verification workflow that emphasizes:

- Determinism
- Explainability
- Modularity
- Reproducibility
- Extensibility

ChipLens complements existing verification engines rather than replacing them.

Its primary objective is to organize the reasoning surrounding verification instead of reimplementing proof engines.

---

# Research Motivation

ChipLens was created to investigate a simple research question:

> **Can compiler-inspired semantic analysis improve the organization, transparency, and explainability of RTL verification workflows?**

Modern compiler infrastructures rarely perform all analysis in a single pass.

Instead, they progressively enrich programs through multiple intermediate representations, enabling each analysis to build upon previous knowledge.

ChipLens applies the same philosophy to hardware verification.

Rather than generating verification properties directly from syntax, the platform first constructs structured semantic knowledge describing the design.

This semantic information is then reused throughout property synthesis, verification planning, diagnostics, explainability, repair planning, and orchestration.

The project therefore investigates verification as an incremental reasoning problem rather than a collection of isolated execution steps.

---

# Engineering Philosophy

Every framework inside ChipLens follows the same architectural principles.

## Single Responsibility

Each framework performs one clearly defined transformation.

Frameworks communicate only through immutable value objects and never depend on hidden mutable state.

---

## Deterministic Execution

Given identical RTL inputs, ChipLens always produces identical outputs.

No framework depends on randomness, machine learning, or non-deterministic heuristics.

Deterministic execution enables reproducible verification experiments and simplifies regression testing.

---

## Explainability

Verification artifacts should never appear without supporting evidence.

Whenever possible, generated properties, diagnostics, and recommendations are accompanied by traceable reasoning describing why they were produced.

---

## Modularity

Every framework is independently testable.

New reasoning stages can be integrated without modifying unrelated components.

This architecture enables long-term evolution while minimizing coupling between frameworks.

---

## Extensibility

ChipLens is designed as a research platform.

Future frameworks can extend the reasoning pipeline without requiring architectural redesign.

Potential future research includes:

- Hierarchical RTL reasoning
- Multi-module dependency analysis
- Advanced temporal property synthesis
- Formal backend optimization
- Interactive verification assistants
- Additional verification backends

---

# Why Flutter and Dart?

ChipLens intentionally separates its **reasoning engine** from its **user interface**.

The reasoning pipeline is implemented in Dart using immutable data models and deterministic transformations.

Flutter provides a cross-platform engineering workbench capable of running on desktop, web, and mobile from a shared codebase.

This architecture allows the same reasoning engine to support multiple frontends without duplicating business logic.

Flutter is used because ChipLens is intended to become an interactive engineering environment rather than a command-line utility alone.

The workbench provides a foundation for:

- Verification dashboards
- Property exploration
- Explainability visualization
- Coverage inspection
- Diagnostics navigation
- Repair planning
- Interactive verification workflows

Computationally intensive formal verification remains delegated to established external tools such as SymbiYosys.

ChipLens focuses on semantic reasoning, orchestration, and explainability rather than replacing existing proof engines.

---

# Architectural Scope

ChipLens currently provides:

- Semantic RTL analysis
- Deterministic property synthesis
- Property ranking
- Formal property emission
- Verification planning
- Formal verification abstraction
- Coverage interpretation
- Counterexample analysis
- Diagnostics intelligence
- Repair planning
- End-to-end orchestration

ChipLens intentionally does **not** implement:

- SAT solving
- SMT solving
- Model checking algorithms
- RTL simulation engines
- Formal proof engines

Instead, these responsibilities remain delegated to specialized verification tools while ChipLens focuses on organizing the reasoning surrounding verification.

This separation keeps the platform modular, backend-independent at the architectural level, and suitable for future integration with additional verification engines.

# System Architecture

ChipLens follows a compiler-inspired layered architecture.

Rather than combining all verification functionality into a single monolithic engine, the platform decomposes verification into independent reasoning frameworks.

Each framework performs exactly one well-defined transformation before producing immutable outputs that become structured inputs for subsequent stages.

This architecture provides:

- Separation of concerns
- Deterministic execution
- Independent framework testing
- Explainable reasoning
- Modular evolution
- Backend abstraction
- Long-term maintainability

Every framework is:

- Deterministic
- Independently testable
- Side-effect free
- Built around immutable value objects
- Focused on a single responsibility

---

# Verification Pipeline

```
                   RTL Source
                        │
                        ▼
        ┌─────────────────────────────────┐
        │      Design Intelligence        │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │      Semantic Evidence          │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │    Candidate Property Synthesis │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │        Property Ranking         │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │        Property Emitter         │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │         Explainability          │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │      Verification Planner       │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │     Formal Verification         │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │      Coverage Analyzer          │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │    Coverage Intelligence        │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │  Counterexample Analysis        │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Diagnostics Intelligence        │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │       Repair Planning           │
        └─────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Verification Orchestrator       │
        └─────────────────────────────────┘
                        │
                        ▼
           Verification Session Result
```

Each framework enriches the semantic understanding of the design before passing immutable outputs to the next reasoning stage.

No framework directly modifies another framework's internal state.

---

# Core Frameworks

| Framework | Primary Responsibility |
|------------|------------------------|
| Design Intelligence | Extracts structural and behavioural knowledge from RTL designs. |
| Semantic Evidence | Builds structured semantic information describing signals, registers, state machines, memories, and control flow. |
| Candidate Property Synthesis | Generates deterministic candidate verification properties from semantic knowledge. |
| Property Ranking | Orders synthesized properties according to deterministic ranking policies. |
| Property Emitter | Converts ranked candidates into backend-ready formal properties. |
| Explainability | Produces traceable explanations linking properties to semantic evidence. |
| Verification Planner | Organizes verification activities into deterministic execution plans. |
| Formal Verification | Executes verification through backend implementations while exposing a common abstraction. |
| Coverage Analyzer | Collects structural coverage information and execution statistics. |
| Coverage Intelligence | Interprets coverage results and identifies verification gaps. |
| Counterexample Analysis | Summarizes failed verification traces into structured evidence. |
| Diagnostics Intelligence | Correlates multiple reasoning stages to identify probable verification issues. |
| Repair Planning | Produces dependency-aware repair recommendations without modifying RTL. |
| Verification Orchestrator | Coordinates the complete reasoning workflow and assembles an immutable verification session. |

---

# Property Synthesis Architecture

Property synthesis is intentionally modular.

Rather than implementing one large inference engine, ChipLens delegates property generation to independent providers.

Each provider is responsible for one verification domain and contributes candidate properties through a common interface.

Current providers:

| Provider | Responsibility |
|-----------|----------------|
| ResetPropertyProvider | Reset behaviour and initialization safety |
| FSMPropertyProvider | Finite-state machine safety properties |
| CounterPropertyProvider | Counter correctness and progression |
| HandshakePropertyProvider | Ready/valid handshake protocols |
| SafetyPropertyProvider | Generic structural safety assertions |
| MemoryPropertyProvider | Memory arrays, ports, interface safety and register-file properties |
| ArithmeticPropertyProvider | Arithmetic datapath safety |
| RegisterPropertyProvider | Sequential register definition and non-X safety |

The `PropertyRunner` coordinates provider execution while remaining independent of provider-specific behaviour.

Providers execute independently.

Failures inside one provider cannot prevent the remaining providers from executing.

Duplicate property identifiers are safely ignored during merging, preserving deterministic behaviour.

---

# Property Generation Flow

```
RTL Design
      │
      ▼
Design Intelligence
      │
      ▼
Semantic Evidence
      │
      ▼
Property Context
      │
      ▼
┌──────────────────────────────────────────┐
│ Reset Provider                           │
├──────────────────────────────────────────┤
│ FSM Provider                             │
├──────────────────────────────────────────┤
│ Counter Provider                         │
├──────────────────────────────────────────┤
│ Handshake Provider                       │
├──────────────────────────────────────────┤
│ Safety Provider                          │
├──────────────────────────────────────────┤
│ Memory Provider                          │
├──────────────────────────────────────────┤
│ Arithmetic Provider                      │
├──────────────────────────────────────────┤
│ Register Provider                        │
└──────────────────────────────────────────┘
      │
      ▼
Merged Property Set
      │
      ▼
Property Ranking
      │
      ▼
Property Emitter
```

This provider architecture allows new synthesis strategies to be introduced without modifying existing providers or changing the orchestration logic.

---

# Formal Verification Architecture

ChipLens separates reasoning from proof execution.

```
Flutter Workbench
        │
        ▼
ChipLens Reasoning Engine
        │
        ▼
FormalEngine (Abstraction)
        │
        ▼
SymbiYosys Backend
        │
        ▼
Yosys / SMT Solver
```

The current implementation includes a SymbiYosys backend.

The architecture intentionally isolates backend-specific behaviour behind the `FormalEngine` abstraction, enabling future support for additional verification engines without changing the reasoning pipeline.

Portable backend discovery and configuration are planned as future improvements.

# Evaluation

ChipLens is evaluated using a structured empirical methodology designed to measure the effectiveness of its reasoning pipeline rather than the capabilities of external formal verification engines.

Evaluation focuses on answering the following questions:

- Does semantic reasoning generalize beyond handcrafted examples?
- Can deterministic property synthesis generate useful verification properties?
- Do generated diagnostics remain stable across diverse RTL designs?
- How accurately do the reasoning frameworks model real hardware structures?
- Does the architecture remain reproducible across repeated executions?

Evaluation artifacts are version-controlled and generated from reproducible benchmark executions.

---

# Benchmark Harness

ChipLens includes an automated benchmark harness that executes the complete reasoning pipeline against representative RTL designs.

Current benchmark suite:

| Design | Description | Diagnostics | Repairs | Runtime (ms) |
|---------|-------------|------------:|---------:|-------------:|
| Counter | 4-bit synchronous counter | 1 | 1 | 3 |
| FSM | 3-state traffic light controller | 1 | 1 | 2 |
| ALU | 32-bit combinational ALU | 1 | 1 | 2 |
| FIFO | Parameterized synchronous FIFO | 1 | 1 | 3 |
| UART | UART transmitter (8N1) | 1 | 1 | 4 |

Average reasoning runtime:

**≈3 ms per design**

These benchmarks evaluate the semantic reasoning frameworks only.

They do **not** measure the runtime of external formal verification engines.

---

# Open-Source RTL Evaluation

Beyond synthetic benchmarks, ChipLens is evaluated against independently developed open-source RTL modules.

These evaluations measure how well the reasoning pipeline generalizes to real hardware designs that were not created specifically for ChipLens.

Current evaluation corpus:

| Project | Purpose | Status |
|----------|---------|--------|
| wb2axip Skid Buffer | Flow-control verification | ✅ Completed |
| PicoRV32 Register File | Memory and register reasoning | ✅ Completed |
| SERV ALU | Arithmetic reasoning | ✅ Completed |
| Ibex RTL Module | Large-scale validation | ✅ Completed |

These evaluations are intentionally preserved as permanent regression artifacts.

Whenever parser improvements or reasoning changes are introduced, the complete corpus is re-evaluated to ensure previous improvements remain valid.

---

# Property Generation Evaluation

Property synthesis is evaluated using quantitative coverage metrics.

Rather than counting generated properties alone, ChipLens measures whether generated properties meaningfully cover verification-relevant design elements.

Current property generation summary:

| Metric | Result |
|--------|-------:|
| Generated Properties | 32 |
| Weighted Element Coverage | 92% |
| Malformed Properties | 0 |
| Deterministic Generation | 100% |
| Duplicate Property IDs | 0 |

These measurements are derived from controlled evaluation of the open-source RTL corpus.

---

# Regression Philosophy

Every production bug identified during evaluation becomes a permanent regression test.

Examples include:

- Parser keyword-boundary fixes
- Memory-array detection
- Symbolic width handling
- Parameterized RTL parsing
- Memory interface extraction
- Property synthesis regressions
- Provider-specific edge cases

This approach ensures that improvements remain permanent and prevents future architectural regressions.

---

# Automated Testing

ChipLens currently contains:

- **2818+ automated tests**
- **0 failing tests**
- **0 analyzer errors**
- **0 analyzer warnings**

Testing spans multiple architectural layers.

Current coverage includes:

- Parser validation
- Semantic analysis
- Design Intelligence
- Property synthesis
- Property providers
- Property ranking
- Property emission
- Explainability
- Verification planning
- Coverage analysis
- Diagnostics
- Repair planning
- Orchestration
- Benchmark execution
- UI architecture
- Regression suites

Testing emphasizes deterministic behaviour rather than implementation details.

---

# Reproducibility

One of ChipLens' primary design goals is reproducibility.

Given identical RTL input, the reasoning pipeline produces identical outputs across repeated executions.

Determinism is maintained by:

- Immutable value objects
- Sorted provider outputs
- Stable identifier generation
- Provider isolation
- Explicit merge ordering
- Elimination of hidden mutable state

This deterministic behaviour simplifies debugging, benchmarking, and scientific evaluation.

---

# Current Evaluation Scope

The current evaluation focuses on:

- Structural RTL understanding
- Semantic extraction
- Property synthesis effectiveness
- Diagnostic quality
- Cross-project generalization
- Framework interoperability

The evaluation intentionally does **not** attempt to measure:

- SAT solver performance
- SMT solver performance
- Model checking efficiency
- Simulation performance
- Commercial EDA tool comparison

Those responsibilities remain delegated to specialized verification engines.

ChipLens instead evaluates the reasoning that surrounds formal verification.

---

# Evaluation Artifacts

The repository includes reproducible evaluation documents under:

```

docs/evaluation/

```

These include:

- Benchmark reports
- Evaluation summaries
- Open-source RTL studies
- Methodology documentation
- Coverage analysis
- Property generation analysis
- Case studies

All published metrics within this repository are derived from these evaluation artifacts.

---

# Threats to Validity

As an active research platform, ChipLens has several current limitations.

Current evaluation is limited to representative open-source RTL modules rather than complete SoC-scale designs.

Property synthesis intentionally generates conservative assertions and avoids speculative temporal reasoning.

The current formal verification implementation includes a SymbiYosys backend; additional backend implementations remain future work.

The Flutter workbench is under active development and therefore usability studies have not yet been conducted.

These limitations are acknowledged explicitly to ensure evaluation results are interpreted within the intended research scope.

# Technology Stack

ChipLens combines modern software engineering practices with established open-source hardware verification tools.

The reasoning engine, user interface, and engineering workbench are implemented using Flutter and Dart, while formal proof execution is delegated to external verification engines.

| Category | Technology |
|-----------|------------|
| Language | Dart 3 |
| UI Framework | Flutter |
| Desktop Support | Windows, Linux, macOS (Flutter Desktop) |
| Web Support | Flutter Web (in progress) |
| Formal Verification | SymbiYosys |
| Logic Synthesis | Yosys |
| Simulation | Verilator, Icarus Verilog |
| Testing | flutter_test |
| Static Analysis | flutter analyze |
| Version Control | Git, GitHub |

---

# Repository Structure

```
ChipLens/

├── frontend/
│
├── lib/
│   │
│   ├── backend/
│   │   ├── design_intelligence/
│   │   ├── semantic_evidence/
│   │   ├── property_inference/
│   │   ├── explainability/
│   │   ├── planning/
│   │   ├── formal/
│   │   ├── coverage/
│   │   ├── coverage_intelligence/
│   │   ├── counterexample/
│   │   ├── diagnostics/
│   │   ├── repair/
│   │   ├── orchestrator/
│   │   └── verification/
│   │
│   ├── ui/
│   │   ├── navigation/
│   │   ├── responsive/
│   │   ├── workbench/
│   │   └── theme/
│   │
│   ├── models/
│   ├── services/
│   └── screens/
│
├── test/
│   ├── parser_regressions/
│   ├── property_providers/
│   ├── parameterized_rtl/
│   ├── benchmarks/
│   ├── integration/
│   └── fixtures/
│
├── docs/
│   ├── evaluation/
│   ├── research/
│   └── architecture/
│
├── README.md
├── CHANGELOG.md
└── LICENSE
```

The repository is organized around architectural responsibilities rather than implementation details.

Each framework evolves independently while communicating through immutable public models.

---

# Engineering Principles

Every subsystem inside ChipLens follows the same design principles.

## Layered Reasoning

Verification is decomposed into independent reasoning stages.

Each framework performs one transformation before passing immutable outputs to the next stage.

---

## Deterministic Execution

Given identical RTL input, ChipLens produces identical reasoning results.

No framework relies on randomness or hidden mutable state.

---

## Immutability

Frameworks exchange immutable value objects.

This eliminates hidden side effects while simplifying testing and reproducibility.

---

## Explainability

Generated properties and diagnostics are accompanied by traceable semantic evidence whenever possible.

ChipLens favors transparent reasoning over opaque automation.

---

## Single Responsibility

Each framework performs one clearly defined task.

Responsibilities remain isolated to improve maintainability and reduce coupling.

---

## Testability

Every major framework is independently unit tested.

Cross-framework integration tests verify complete pipeline behaviour.

Regression tests permanently capture previously identified defects.

---

## Extensibility

New reasoning stages can be integrated without redesigning the existing architecture.

This enables ChipLens to serve as an experimental research platform for future verification techniques.

---

# Getting Started

## Prerequisites

### Required

- Flutter (latest stable release)
- Dart SDK
- Git

---

### Optional (Formal Verification)

Install one or more supported verification tools to enable formal verification.

Currently supported:

- SymbiYosys
- Yosys
- Verilator
- Icarus Verilog

ChipLens' reasoning pipeline operates independently of these tools.

External engines are required only for proof execution.

---

# Clone the Repository

```bash
git clone https://github.com/Anumeha600/ChipLens.git
cd ChipLens/frontend
```

---

# Install Dependencies

```bash
flutter pub get
```

---

# Run ChipLens

Desktop:

```bash
flutter run
```

Run a specific platform:

```bash
flutter run -d windows
```

or

```bash
flutter run -d chrome
```

(Web support is under active development.)

---

# Run the Test Suite

```bash
flutter test
```

---

# Static Analysis

```bash
flutter analyze
```

Expected result:

- Zero analyzer errors
- Zero analyzer warnings

---

# Formal Verification Configuration

ChipLens currently includes a SymbiYosys backend implementation.

The backend communicates through the `FormalEngine` abstraction.

Current implementation uses explicit executable paths during development.

Portable executable discovery and configurable backend selection are planned future improvements.

This implementation detail does not affect the architecture of the reasoning pipeline.

---

# Current Limitations

ChipLens is an active research platform.

Current limitations include:

- SymbiYosys backend currently uses explicit executable configuration.
- Property synthesis intentionally generates conservative safety properties.
- Evaluation currently focuses on representative RTL modules rather than complete SoC designs.
- Flutter Web workbench is still under development.
- Additional formal verification backends remain future work.

These limitations are documented explicitly to ensure transparency and reproducibility.

---

# Project Status

ChipLens has completed its **Core Reasoning Platform (v1.5.0).**

Current development focuses on transforming the reasoning engine into a complete engineering workbench.

Completed:

- Design Intelligence
- Semantic Evidence
- Property Synthesis
- Property Ranking
- Property Emitter
- Explainability
- Verification Planning
- Formal Verification Abstraction
- Coverage Analysis
- Coverage Intelligence
- Counterexample Analysis
- Diagnostics Intelligence
- Repair Planning
- Verification Orchestrator

Current priorities:

- Flutter Workbench
- Verification Dashboard
- RTL Project Explorer
- Property Explorer
- Explainability Viewer
- Coverage Dashboard
- Diagnostics Timeline
- Repair Planner
- Flutter Web support

The architecture is considered stable.

Current development emphasizes usability, visualization, evaluation, and ecosystem integration rather than major architectural redesign.

# Roadmap

ChipLens has reached **v1.5.0 – Core Reasoning Platform**.

The core verification reasoning architecture is considered stable.

Future development focuses on transforming ChipLens into a complete engineering workbench while continuing empirical evaluation of the underlying research.

Development priorities are organized into incremental milestones rather than large architectural redesigns.

---

# Phase 1 — Core Reasoning Platform ✅

Completed:

- RTL parsing
- Design Intelligence
- Semantic Evidence
- Candidate Property Synthesis
- Property Ranking
- Property Emitter
- Explainability
- Verification Planning
- Formal Verification abstraction
- Coverage Analysis
- Coverage Intelligence
- Counterexample Analysis
- Diagnostics Intelligence
- Repair Planning
- Verification Orchestration
- Benchmark harness
- Open-source RTL evaluation
- Regression infrastructure
- Deterministic property synthesis
- 2800+ automated tests

The primary research architecture is now complete.

---

# Phase 2 — Verification Workbench 🚧

Current development focuses on building a modern engineering interface around the reasoning pipeline.

Planned components include:

- Verification Dashboard
- RTL Project Explorer
- Property Explorer
- Explainability Viewer
- Coverage Dashboard
- Diagnostics Timeline
- Repair Planner
- Verification Session Viewer
- Project Management
- Responsive Desktop Layout
- Flutter Web support

The workbench reuses the existing reasoning engine without duplicating verification logic.

---

# Phase 3 — Engineering Improvements

Planned engineering improvements include:

- Configurable formal backend discovery
- Backend selection UI
- Portable toolchain configuration
- Incremental project loading
- Project caching
- Improved diagnostic rendering
- Richer visualization components
- Performance profiling
- Larger benchmark corpus
- Continuous benchmark reporting

These improvements emphasize usability rather than architectural redesign.

---

# Phase 4 — Research Expansion

Potential future research directions include:

- Hierarchical RTL reasoning
- Multi-module semantic analysis
- Cross-module dependency reasoning
- Advanced temporal property synthesis
- Property quality ranking improvements
- Counterexample-guided refinement
- Interactive verification guidance
- Verification planning optimization
- Explainable repair recommendation
- Large-scale SoC evaluation

These directions remain research topics rather than committed implementation goals.

---

# Long-Term Vision

The long-term objective of ChipLens is to become an open research platform for semantic RTL verification.

Rather than competing with established verification engines, ChipLens aims to provide a reusable reasoning layer that can integrate with multiple formal verification backends.

The project emphasizes:

- Explainability
- Deterministic reasoning
- Modular architecture
- Scientific evaluation
- Reproducible experimentation

Future work will continue strengthening these principles rather than replacing them.

---

# Research Vision

ChipLens explores the intersection of:

- Electronic Design Automation (EDA)
- Formal Verification
- Compiler Design
- Software Architecture
- Program Analysis
- Explainable Systems
- Engineering Tooling

The project investigates how compiler-inspired semantic analysis can improve the organization, transparency, and reproducibility of RTL verification workflows.

While current development focuses on practical engineering infrastructure, the broader objective is to provide a foundation for future research into intelligent verification systems.

---

# Why Open Source?

ChipLens is released under the MIT License to encourage:

- Academic research
- Industrial experimentation
- Community contributions
- Independent evaluation
- Reproducible research

The project welcomes discussion, issue reports, architectural feedback, and experimental validation.

Open development helps ensure that research claims remain verifiable through publicly available implementations.

---

# Future Integration

ChipLens is intentionally designed around extensibility.

Potential future integrations include:

- Additional formal verification engines
- Simulation frameworks
- Linting tools
- Continuous Integration pipelines
- Hardware development workflows
- IDE extensions
- Python scripting interfaces
- Cloud-based verification services

The reasoning pipeline is designed to remain independent of any particular frontend or backend implementation.

---

# Current Priorities

Current engineering priorities are:

1. Complete the Flutter Verification Workbench.
2. Improve desktop and web usability.
3. Expand empirical evaluation on additional open-source RTL projects.
4. Improve backend configuration and portability.
5. Publish research artifacts.
6. Strengthen documentation and developer onboarding.

The emphasis is now on maturity, usability, and evaluation rather than adding new reasoning frameworks.

# Contributing

ChipLens is an active open-source research platform.

Contributions that improve correctness, reproducibility, documentation, engineering quality, or evaluation methodology are welcome.

Examples include:

- Bug reports
- Parser improvements
- Additional RTL evaluation cases
- Documentation improvements
- Performance profiling
- UI and workbench enhancements
- Verification backend integrations
- Regression tests
- Research discussions

Before opening a pull request, please ensure that:

- The project builds successfully.
- `flutter analyze` reports zero analyzer errors and warnings.
- All automated tests pass.
- New functionality includes appropriate regression tests.
- Public APIs remain backward compatible whenever practical.

Contributions should preserve ChipLens' core engineering principles:

- Deterministic execution
- Immutable data models
- Modular framework boundaries
- Explainable reasoning
- Reproducible evaluation

---

# Research Reproducibility

One objective of ChipLens is to encourage reproducible software engineering research.

All published evaluation results are derived from version-controlled source code and documented benchmark procedures.

Whenever practical, architectural changes should be accompanied by:

- Updated evaluation results
- Regression tests
- Documentation updates
- Benchmark comparisons

This ensures that published claims remain independently verifiable.

---

# Citation

If ChipLens contributes to academic research, publications, or engineering studies, please cite the repository.

A formal citation file (`CITATION.cff`) is planned for a future release.

Example citation:

```text
Anumeha.
ChipLens: Compiler-Inspired Semantic RTL Verification Research Platform.
GitHub Repository.
https://github.com/Anumeha600/ChipLens
```

---

# Acknowledgements

ChipLens builds upon decades of research in:

- Compiler design
- Electronic Design Automation (EDA)
- Formal verification
- Program analysis
- Software architecture
- Open-source hardware tooling

The project also benefits from the open-source hardware ecosystem, including verification tools that make reproducible experimentation possible.

Current formal verification support is implemented through the SymbiYosys ecosystem while maintaining an architectural abstraction for future backend expansion.

---

# License

ChipLens is released under the MIT License.

See the `LICENSE` file for details.

---

# Project Philosophy

ChipLens was created to investigate how modern software engineering principles can improve hardware verification workflows.

Rather than replacing established verification engines, the project explores how semantic reasoning, deterministic execution, immutable architectures, and explainable analysis can make verification workflows easier to understand, extend, and reproduce.

The project intentionally emphasizes engineering quality alongside research quality.

Architecture, testing, documentation, evaluation, and reproducibility are treated as equally important components of the system.

---

# Status

ChipLens is currently in active development.

The core reasoning architecture has reached stability.

Current development focuses on:

- Engineering workbench development
- User experience
- Cross-platform desktop and web support
- Expanded empirical evaluation
- Research publication
- Community adoption

Future releases will prioritize architectural maturity, usability, and scientific evaluation over rapid feature growth.

---

# About the Author

ChipLens is an independent research and engineering project created and actively maintained by **Anumeha**.

The project originated from an interest in applying compiler architecture and modern software engineering principles to Register Transfer Level (RTL) verification.

Development continues as an exploration of deterministic semantic reasoning, explainable verification workflows, and reusable engineering infrastructure for hardware verification research.

---

> **ChipLens is not intended to replace formal verification tools.**
>
> **Its goal is to improve the reasoning surrounding verification—making hardware verification more explainable, deterministic, reproducible, and architecturally modular.**

---

**If you find ChipLens interesting, consider:**

- ⭐ Starring the repository
- 🐛 Reporting issues
- 💡 Suggesting improvements
- 📖 Reading the evaluation documents
- 🤝 Contributing to the project
- 🎓 Using it for research or educational purposes

Thank you for your interest in ChipLens.
