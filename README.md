# ChipLens

> **An Extensible RTL Engineering Workbench and Compiler-Inspired Verification Platform**

[![Version](https://img.shields.io/badge/version-v2.1.0-blue.svg)]()
[![Tests](https://img.shields.io/badge/tests-4429_passing-success.svg)]()
[![Failures](https://img.shields.io/badge/failures-0-success.svg)]()
[![Flutter](https://img.shields.io/badge/flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-3.x-0175C2.svg?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

---

## Overview

ChipLens is an open-source desktop engineering platform for **Register Transfer Level (RTL)** development, semantic analysis, verification, and hardware engineering research.

Rather than treating hardware verification as a collection of disconnected tools, ChipLens explores a unified engineering environment where editing, navigation, structural analysis, verification, diagnostics, explainability, and future AI-assisted workflows coexist inside a single desktop workbench.

Inspired by modern software engineering environments such as **Visual Studio Code**, **JetBrains IDEs**, and **compiler toolchains like LLVM**, ChipLens applies modular compiler-inspired principles to digital hardware engineering.

The long-term vision is to investigate how modern software architecture, language tooling, and intelligent automation can improve RTL productivity while remaining transparent, explainable, and extensible.

---

# Why ChipLens?

RTL engineers often work across multiple independent tools throughout the design lifecycle.

A typical workflow may involve:

- Writing RTL in a text editor
- Running simulation separately
- Launching formal verification tools
- Reviewing diagnostics
- Examining coverage reports
- Navigating large codebases manually
- Consulting documentation and specifications
- Switching between numerous utilities throughout development

Although each tool is powerful, constantly moving between them introduces unnecessary engineering overhead.

ChipLens explores a different approach.

Instead of treating editing, verification, diagnostics, and analysis as isolated activities, ChipLens investigates how they can be integrated into a cohesive engineering workspace that assists engineers throughout the complete RTL development process.

---

# Project Vision

ChipLens is designed around three long-term objectives.

## 1. Modern RTL Engineering

Provide a desktop-first engineering environment purpose-built for hardware development rather than adapting a general-purpose code editor.

---

## 2. Compiler-Inspired Verification

Investigate compiler-inspired semantic analysis techniques for verification planning, property inference, diagnostics, explainability, and design reasoning.

---

## 3. Research Platform

Provide an extensible architecture suitable for experimentation in:

- RTL language tooling
- Verification automation
- Explainable diagnostics
- Property synthesis
- AI-assisted hardware engineering
- Engineering productivity research

The project intentionally separates research components from production infrastructure so experimental ideas can evolve independently without destabilizing the core workbench.

---

# Current Highlights

## Desktop Engineering Workbench

- Multi-document workspace
- Project explorer
- Command palette
- Global search
- Problems panel
- Output panel
- Status bar
- Outline navigation
- Responsive desktop interface

---

## RTL Engineering

- RTL tokenizer
- Syntax highlighting
- Structural outline extraction
- Symbol navigation
- Module information
- Design metrics
- Multi-file editing foundation

---

## Verification Framework

- Modular verification orchestrator
- Property inference framework
- Diagnostics engine
- Explainability framework
- Coverage intelligence
- Repair planning
- Benchmark framework
- Open-source RTL validation suite

---

## AI & Natural Language Research

ChipLens also contains an experimental natural-language pipeline that investigates AI-assisted RTL engineering workflows.

Current research modules include:

- RTL generation
- Testbench generation
- FSM construction
- Intent extraction
- Quality analysis
- RTL explanation
- Pipeline orchestration

These modules currently exist as experimental services and are not yet integrated into the primary engineering workbench.

---

# Engineering Philosophy

ChipLens follows several architectural principles that guide every subsystem.

### Engineering First

Engineering productivity is prioritized over visual complexity.

Every feature should help engineers understand, navigate, verify, or improve RTL designs.

---

### Modular by Design

Rather than relying on monolithic controllers, ChipLens is organized into small, composable subsystems with clearly defined responsibilities.

This simplifies maintenance, testing, and future research.

---

### Deterministic Where Possible

Verification results, semantic analyses, and engineering diagnostics should remain reproducible and explainable.

Deterministic behavior is preferred whenever practical.

---

### Research-Friendly Architecture

Experimental components—including AI services and verification research—are intentionally isolated behind stable interfaces.

This enables rapid experimentation without disrupting the engineering workbench.

---

### Extensible Platform

ChipLens is intended to evolve over time.

Future language engines, verification frameworks, AI assistants, visualization tools, and research prototypes should integrate naturally without requiring large-scale architectural redesign.

---

# At a Glance

| Category | Details |
|----------|---------|
| Project Type | Desktop RTL Engineering Platform |
| Primary Language | Dart 3 |
| Framework | Flutter |
| Architecture | Modular, Compiler-Inspired |
| Desktop Platforms | Windows, Linux, macOS |
| Web Support | Available |
| Automated Tests | **4,429 Passing** |
| Test Failures | **0** |
| Verification Frameworks | 14 |
| Property Providers | 8 |
| License | MIT |

---

> **ChipLens is not intended to replace established Electronic Design Automation (EDA) tools. Instead, it explores how modern software engineering techniques, language tooling, and intelligent automation can improve RTL development workflows while remaining transparent, extensible, and research-friendly.**

# Architecture

ChipLens is organized into independent engineering subsystems rather than a single monolithic application.

Each subsystem owns a clearly defined responsibility and communicates through immutable models and well-defined interfaces.

This architecture improves maintainability, testability, extensibility, and enables future research without destabilizing existing functionality.

---

## High-Level Architecture

```text
                             ChipLens Platform
                                      │
        ┌─────────────────────────────┴─────────────────────────────┐
        │                                                           │
        ▼                                                           ▼
┌─────────────────────────────┐                      ┌────────────────────────────┐
│ Desktop Engineering         │                      │ Compiler-Inspired          │
│ Workbench                   │                      │ Verification Framework     │
│                             │                      │                            │
│ • Workspace                 │                      │ • Semantic Analysis        │
│ • RTL Editor                │                      │ • Property Inference       │
│ • Explorer                  │                      │ • Explainability           │
│ • Outline                   │                      │ • Verification Planning    │
│ • Search                    │                      │ • Coverage Intelligence    │
│ • Diagnostics               │                      │ • Diagnostics Engine       │
│ • Project Management        │                      │ • Repair Planning          │
│ • Future AI Integration     │                      │ • Verification Orchestrator│
└─────────────────────────────┘                      └────────────────────────────┘
```

The two layers evolve independently.

The desktop workbench focuses on engineering productivity.

The backend framework focuses on deterministic RTL reasoning.

---

# Desktop Engineering Workbench

The Engineering Workbench is the primary user interface of ChipLens.

Unlike traditional RTL editors, it is designed around engineering workflows rather than simple file editing.

Current capabilities include:

- Desktop-first workspace
- Project explorer
- Multi-document editor
- Workspace controller
- Outline panel
- Symbol navigation
- Global search
- Command palette
- Problems panel
- Output panel
- Status bar
- Keyboard-first navigation
- Responsive desktop layouts

The workbench is currently evolving toward a professional RTL engineering environment with future support for dockable layouts, split editors, advanced navigation, verification dashboards, and visualization tools.

---

# Workspace Engine

The Workspace Engine manages the behavior of the desktop environment.

Responsibilities include:

- Project lifecycle
- Workspace state
- Document management
- Tab management
- Navigation
- Panel coordination
- Command routing
- Layout management

Future milestones will extend the Workspace Engine with:

- Dockable panels
- Split editors
- Persistent workspace layouts
- Multi-project workspaces
- Workspace snapshots
- Session recovery

---

# RTL Language Layer

ChipLens treats RTL as a structured language rather than plain text.

Current language support includes:

## Language Infrastructure

- RTL document model
- RTL tokenizer
- Syntax highlighting foundation
- Outline generation
- Symbol extraction
- Structural block recognition
- Code folding foundation
- Module information
- Design metrics

These features provide the foundation for future semantic analysis.

---

## Planned Language Features

Future milestones include:

- Verilog parser
- SystemVerilog parser
- Abstract Syntax Tree (AST)
- Symbol table
- Incremental parsing
- Semantic highlighting
- Hover documentation
- Go To Definition
- Find References
- Rename Symbol
- Cross-module navigation

---

# Verification Framework

ChipLens approaches verification as a sequence of modular semantic transformations.

Instead of performing all reasoning inside one large engine, the verification pipeline is divided into independent frameworks.

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
Property Synthesis
      │
      ▼
Property Ranking
      │
      ▼
Property Emission
      │
      ▼
Explainability
      │
      ▼
Verification Planning
      │
      ▼
Coverage Intelligence
      │
      ▼
Diagnostics
      │
      ▼
Repair Planning
      │
      ▼
Verification Orchestrator
```

Each stage performs one clearly defined responsibility and communicates through immutable value objects.

This architecture improves:

- Deterministic execution
- Explainability
- Testability
- Maintainability
- Extensibility

---

# Backend Frameworks

ChipLens currently contains fourteen major backend frameworks.

| Framework | Responsibility |
|-----------|----------------|
| Design Intelligence | Structural RTL understanding |
| Semantic Evidence | Immutable semantic facts |
| Property Synthesis | Candidate assertion generation |
| Property Ranking | Prioritization of generated properties |
| Property Emission | Backend-independent property generation |
| Explainability | Human-readable reasoning |
| Verification Planning | Verification strategy generation |
| Formal Integration | Backend abstraction layer |
| Coverage Intelligence | Coverage interpretation |
| Counterexample Analysis | Trace reasoning |
| Diagnostics Intelligence | Root-cause analysis |
| Repair Planning | Suggested engineering improvements |
| Verification Orchestrator | Pipeline coordination |
| Benchmark Framework | Empirical evaluation |

---

# Property Providers

ChipLens currently includes eight modular property providers.

| Provider | Focus |
|----------|-------|
| Arithmetic | Arithmetic logic |
| Counter | Counter verification |
| FSM | Finite State Machines |
| Handshake | Protocol verification |
| Memory | Memory correctness |
| Register | Register behaviour |
| Reset | Reset sequencing |
| Safety | Generic safety properties |

Each provider contributes candidate verification properties independently before the ranking and orchestration stages.

---

# AI & Natural Language Research

ChipLens also contains an experimental Natural Language Pipeline.

These services are currently isolated from the primary engineering workspace while research continues.

Current modules include:

- RTL Generator
- Testbench Generator
- Intent Extractor
- Explanation Engine
- FSM Builder
- Quality Analyzer
- Pipeline Orchestrator

These modules investigate AI-assisted RTL engineering workflows but should currently be considered experimental.

---

# Architectural Principles

Every subsystem follows several common engineering principles.

## Immutable Models

Shared state is represented using immutable value objects whenever practical.

This simplifies testing and reduces unintended side effects.

---

## Single Responsibility

Large monolithic managers are intentionally avoided.

Each subsystem owns one clearly defined engineering responsibility.

---

## Test-Driven Engineering

Every architectural milestone is accompanied by automated regression tests.

The project currently maintains **4,429 passing automated tests** across frontend and backend components.

---

## Backend Independence

The verification framework is intentionally backend-independent.

ChipLens is designed to integrate with external verification engines rather than depend exclusively on one implementation.

---

## Long-Term Extensibility

The architecture is designed to support future capabilities including:

- Language Server Protocol (LSP)
- Plugin SDK
- Waveform visualization
- AI Engineering Assistant
- Verification dashboards
- Distributed verification
- Cloud execution
- Hardware design analytics

# RTL Engineering Workbench

The ChipLens Engineering Workbench is designed as a desktop-first environment for RTL engineering.

Unlike conventional source code editors, the workbench is organized around engineering workflows rather than files alone.

The objective is to provide a unified environment where RTL editing, navigation, structural understanding, diagnostics, verification planning, and future AI-assisted engineering workflows coexist.

---

## Current Workbench Features

### Workspace

- Multi-panel engineering layout
- Project explorer
- Workspace controller
- Responsive desktop interface
- Workspace state management
- Project switching
- Recent projects
- Recent RTL files

---

### RTL Editor

Current editor capabilities include:

- Multi-document tabs
- Read-only RTL editor
- RTL document model
- Line numbering
- Cursor tracking
- Status reporting
- Keyboard navigation

---

### RTL Language Features

Current language support includes:

- RTL tokenizer
- Syntax highlighting
- Structural outline extraction
- Module extraction
- Port extraction
- Parameter extraction
- Always block detection
- Assign statement detection
- Symbol extraction
- Code folding foundation
- Go To Symbol foundation

These components form the basis for future semantic tooling.

---

### Navigation

ChipLens currently provides:

- Project explorer
- Outline panel
- Global search
- Command palette
- Symbol navigation
- Keyboard shortcuts

Future milestones will expand navigation with:

- Go To Definition
- Find References
- Rename Symbol
- Hover documentation
- Cross-module navigation

---

### Diagnostics

Current workspace diagnostics include:

- Problems panel
- Output panel
- Design metrics
- Module information
- Status bar
- Analysis summary

Future diagnostics will include:

- Lint warnings
- Semantic diagnostics
- Clock domain analysis
- Reset domain analysis
- Verification reports

---

# Project System

ChipLens includes an immutable project management layer.

Current project capabilities include:

- Project metadata
- Workspace state
- Active project context
- Recent projects
- Recent documents
- Standard RTL directory structure
- Project explorer

Default project layout:

```
Project

├── rtl/

├── testbench/

├── constraints/

├── reports/

├── docs/

└── scripts/
```

Future releases will extend the project system with:

- Build profiles
- Simulation configurations
- Verification sessions
- Workspace snapshots
- Git integration

---

# Technology Stack

## Frontend

| Technology | Purpose |
|------------|----------|
| Flutter | Desktop UI |
| Dart | Application Language |
| Material 3 | Base UI Components |
| Immutable Models | State Management |
| Responsive Layout | Cross-platform Desktop Support |

---

## Backend

| Technology | Purpose |
|------------|----------|
| Dart | Backend Frameworks |
| Immutable Value Objects | Deterministic Execution |
| Compiler-Inspired Architecture | Semantic Analysis |
| Property Providers | Assertion Synthesis |
| Verification Orchestrator | Pipeline Coordination |

---

## Development Practices

ChipLens follows several engineering practices throughout the codebase.

- Immutable architecture
- Modular design
- Separation of concerns
- Test-driven development
- Continuous regression testing
- Deterministic execution
- Desktop-first engineering

---

# Repository Structure

```
ChipLens

├── lib/
│
│   ├── backend/
│   │
│   ├── core/
│   │
│   ├── services/
│   │
│   ├── ui/
│   │
│   ├── workbench/
│   │
│   ├── editor/
│   │
│   ├── explorer/
│   │
│   └── themes/
│
├── benchmarks/
│
├── docs/
│
├── test/
│
└── assets/
```

The repository is intentionally organized around engineering subsystems rather than UI pages.

This makes future expansion significantly easier while reducing coupling between independent modules.

---

# Getting Started

## Prerequisites

Before building ChipLens, install:

- Flutter SDK (3.x or later)
- Dart SDK (3.x or later)
- Git

Verify your Flutter installation:

```bash
flutter doctor
```

---

## Clone the Repository

```bash
git clone https://github.com/<YOUR_USERNAME>/ChipLens.git

cd ChipLens
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run ChipLens

### Windows

```bash
flutter run -d windows
```

---

### Linux

```bash
flutter run -d linux
```

---

### macOS

```bash
flutter run -d macos
```

---

### Web

```bash
flutter run -d chrome
```

---

# Automated Testing

Run the complete regression suite:

```bash
flutter test
```

Static analysis:

```bash
flutter analyze
```

Current project metrics:

| Metric | Value |
|---------|-------|
| Passing Tests | **4,429** |
| Test Failures | **0** |
| Skipped Tests | **3** |

The project follows a regression-first philosophy.

Every major architectural milestone introduces automated tests to ensure existing functionality remains stable.

---

# Benchmark Framework

ChipLens includes a modular benchmark framework for evaluating verification pipeline performance.

Current benchmark stages include:

- Design analysis
- Property synthesis
- Coverage reasoning
- Diagnostics
- Repair planning

The benchmark framework enables empirical comparison of backend improvements while maintaining deterministic execution.

---

# Open-Source RTL Validation

ChipLens validates portions of its verification framework using publicly available RTL designs.

Current validation includes examples derived from:

- PicoRV32
- SERV

These designs are used exclusively for regression testing and validation.

ChipLens is not affiliated with or endorsed by these projects.

---

# Development Workflow

The recommended development workflow is:

```
New Feature

↓

Immutable Model

↓

Controller

↓

UI Integration

↓

Automated Tests

↓

Benchmark Validation

↓

Documentation

↓

Merge
```

Every subsystem is expected to remain independently testable and maintainable.

---

# Documentation

Documentation is organized into several categories:

- Architecture
- Workspace
- RTL Language Layer
- Verification Framework
- Backend Frameworks
- Research Notes
- Development Guides
- Future Roadmap

Additional technical documentation will continue to expand alongside the project.

# Verification Framework

One of ChipLens' primary research directions is investigating **compiler-inspired approaches to RTL verification**.

Rather than treating verification as a single monolithic process, ChipLens decomposes reasoning into a sequence of independent semantic stages.

Each framework performs one clearly defined engineering responsibility before passing immutable intermediate representations to the next stage.

This architecture improves:

- Testability
- Explainability
- Extensibility
- Deterministic execution
- Long-term maintainability

---

# Verification Pipeline

The current backend architecture follows the pipeline below.

```text
RTL Design
     │
     ▼
Design Intelligence
     │
     ▼
Semantic Evidence
     │
     ▼
Property Inference
     │
     ▼
Property Ranking
     │
     ▼
Property Emission
     │
     ▼
Verification Planning
     │
     ▼
Coverage Intelligence
     │
     ▼
Diagnostics Intelligence
     │
     ▼
Repair Planning
     │
     ▼
Verification Orchestrator
```

Each stage performs exactly one responsibility.

No framework owns the complete verification process.

---

# Backend Frameworks

ChipLens currently contains fourteen independent backend frameworks.

| Framework | Responsibility | Status |
|------------|----------------|--------|
| Design Intelligence | Structural RTL understanding | ✅ Stable |
| Semantic Evidence | Immutable semantic facts | ✅ Stable |
| Property Synthesis | Candidate assertion generation | ✅ Stable |
| Property Ranking | Deterministic prioritization | ✅ Stable |
| Property Emission | Backend-independent property generation | ✅ Stable |
| Explainability | Human-readable reasoning | ✅ Stable |
| Verification Planning | Verification strategy generation | ✅ Stable |
| Coverage Intelligence | Coverage interpretation | ✅ Stable |
| Counterexample Analysis | Trace interpretation | ✅ Stable |
| Diagnostics Intelligence | Root-cause reasoning | ✅ Stable |
| Repair Planning | Suggested design improvements | ✅ Stable |
| Verification Orchestrator | Pipeline coordination | ✅ Stable |
| Benchmark Framework | Performance evaluation | ✅ Stable |
| Formal Backend Abstraction | Backend integration layer | ✅ Stable |

---

# Property Providers

Property providers generate candidate verification properties for different RTL structures.

Current providers include:

| Provider | Focus |
|-----------|-------|
| Arithmetic | Arithmetic operations |
| Counter | Counters |
| FSM | Finite State Machines |
| Handshake | Communication protocols |
| Memory | Memories |
| Register | Registers |
| Reset | Reset behaviour |
| Safety | Generic safety properties |

Each provider operates independently before property ranking and verification planning.

This modular architecture allows future providers to be added without modifying existing implementations.

---

# Explainability

A major design objective of ChipLens is **explainable verification**.

Rather than producing only assertions or diagnostics, backend frameworks attempt to retain semantic evidence describing *why* a conclusion was reached.

This information supports:

- Engineering documentation
- Diagnostics
- Repair planning
- Future AI-assisted explanations

Explainability is considered a first-class architectural concern rather than an afterthought.

---

# Diagnostics

Diagnostics are generated using semantic reasoning rather than isolated syntax checks.

Current diagnostic infrastructure investigates:

- Structural inconsistencies
- Verification planning
- Property generation
- Semantic evidence
- Coverage interpretation
- Repair opportunities

Future milestones will expand diagnostics to include:

- Clock-domain analysis
- Reset-domain analysis
- Lint diagnostics
- Incremental semantic analysis
- Cross-module reasoning

---

# Repair Planning

Repair Planning investigates potential engineering improvements after diagnostics complete.

Current research focuses on:

- Candidate repair generation
- Design improvement suggestions
- Verification planning refinement
- Explainable recommendations

The repair planner does **not** automatically modify RTL.

Its objective is to support engineering decision-making rather than replace it.

---

# Benchmark Framework

ChipLens includes an internal benchmark framework used to evaluate verification pipeline behaviour.

Current benchmark stages include:

- Design loading
- Semantic analysis
- Property generation
- Coverage reasoning
- Diagnostics
- Repair planning

This framework allows backend improvements to be evaluated under consistent conditions.

---

# Validation

The backend framework is validated through several complementary approaches.

## Automated Testing

Every framework includes regression tests whenever practical.

Current metrics:

| Metric | Value |
|---------|-------|
| Automated Tests | **4,429 Passing** |
| Test Failures | **0** |
| Skipped Tests | **3** |

---

## Open-Source RTL Validation

ChipLens validates portions of the verification framework using publicly available RTL projects.

Current validation includes examples derived from:

- PicoRV32
- SERV

These designs are used exclusively for regression testing and architectural validation.

ChipLens is not affiliated with these projects.

---

## Deterministic Execution

Whenever practical, identical RTL inputs should produce identical semantic outputs.

Deterministic execution simplifies:

- Testing
- Benchmarking
- Explainability
- Reproducibility

---

# Current Research Areas

ChipLens currently investigates several research directions.

### Verification

- Compiler-inspired verification pipelines
- Property inference
- Verification planning
- Explainable verification

---

### RTL Language Tooling

- Structural RTL understanding
- Semantic indexing
- Language tooling
- Incremental analysis

---

### Engineering Productivity

- Unified RTL workbench
- Desktop engineering workflows
- Integrated diagnostics
- Workspace architecture

---

### AI-Assisted Hardware Engineering

Experimental work currently explores:

- RTL generation
- Testbench generation
- RTL explanation
- Intent extraction
- FSM generation
- Quality analysis

These components remain experimental and are intentionally isolated from the production workbench while research continues.

---

# Implementation Status

The table below summarizes the current implementation state of major ChipLens subsystems.

| Component | Status |
|-----------|--------|
| Desktop Engineering Workbench | ✅ Stable |
| Workspace Engine | ✅ Stable |
| Project System | ✅ Stable |
| RTL Explorer | ✅ Stable |
| Multi-Document Workspace | ✅ Stable |
| RTL Tokenizer | ✅ Stable |
| Syntax Highlighting | ✅ Initial Implementation |
| Outline Engine | ✅ Stable |
| Symbol Extraction | ✅ Stable |
| Command Palette | ✅ Stable |
| Global Search | ✅ Stable |
| Problems Panel | ✅ Stable |
| Output Panel | ✅ Stable |
| Verification Framework | ✅ Stable |
| Benchmark Framework | ✅ Stable |
| Explainability Framework | ✅ Stable |
| Diagnostics Framework | ✅ Stable |
| Repair Planning | ✅ Stable |
| AI Research Services | 🧪 Experimental |
| RTL Parser | 🚧 Planned |
| AST | 🚧 Planned |
| Symbol Index | 🚧 Planned |
| Go To Definition | 🚧 Planned |
| Find References | 🚧 Planned |
| Rename Symbol | 🚧 Planned |
| Module Hierarchy | 🚧 Planned |
| FSM Visualization | 🚧 Planned |
| Waveform Viewer | 🚧 Planned |
| Coverage Dashboard | 🚧 Planned |
| Verification Dashboard | 🚧 Planned |

---

# Engineering Principles

Every subsystem developed within ChipLens follows five architectural principles.

1. **Engineering First** — prioritize useful engineering workflows over visual complexity.

2. **Immutable by Default** — reduce side effects through immutable data models.

3. **Single Responsibility** — each subsystem owns one clearly defined responsibility.

4. **Deterministic Behaviour** — identical inputs should produce identical outputs whenever practical.

5. **Extensible Architecture** — future language engines, verification frameworks, AI services, and plugins should integrate without architectural redesign.

# Roadmap

ChipLens is developed through architecture-driven milestones.

Rather than implementing isolated user interface pages, each milestone introduces a complete engineering subsystem that expands the platform's capabilities.

---

## Phase I — Engineering Workbench

**Status:** 🟢 Mostly Complete

Focus areas:

- Desktop-first workspace
- Project management
- Workspace controller
- Multi-document editor
- Explorer
- Command palette
- Global search
- Problems panel
- Output panel
- Status bar
- Responsive layouts
- Immutable workspace models

---

## Phase II — Workspace Engine

**Status:** 🟡 Active Development

Current focus:

- Dockable panels
- Split editor
- Workspace persistence
- Advanced tab management
- Keyboard-first navigation
- Layout serialization
- Panel management
- Session restoration

Objective:

Provide a professional desktop engineering environment comparable to modern IDEs.

---

## Phase III — RTL Language Engine

**Status:** 🚧 Planned

Focus areas:

- Verilog parser
- SystemVerilog parser
- Abstract Syntax Tree
- Symbol index
- Incremental parsing
- Semantic highlighting
- Hover documentation
- Go To Definition
- Find References
- Rename Symbol

Objective:

Transform ChipLens from an RTL editor into a language-aware engineering environment.

---

## Phase IV — Engineering Intelligence

**Status:** 🚧 Planned

Focus areas:

- Module hierarchy
- Signal graph
- Dependency graph
- Clock-domain analysis
- Reset-domain analysis
- FSM visualization
- Design metrics
- Cross-module navigation

Objective:

Provide engineers with a structural understanding of large RTL designs.

---

## Phase V — Verification Workspace

**Status:** 🚧 Planned

Focus areas:

- Waveform viewer
- Coverage visualization
- Assertion explorer
- Regression manager
- Verification reports
- Counterexample navigation

Objective:

Create an integrated verification environment within the ChipLens workbench.

---

## Phase VI — AI Engineering Assistant

**Status:** 🧪 Research

Focus areas:

- RTL explanation
- RTL generation
- Testbench generation
- Intent extraction
- Documentation generation
- Design review
- Engineering recommendations

Objective:

Investigate practical AI-assisted workflows for RTL engineering while maintaining deterministic and explainable tooling.

---

# Long-Term Vision

ChipLens is designed as a long-term engineering and research platform.

The project's objective is **not** to replace established Electronic Design Automation (EDA) ecosystems.

Instead, ChipLens explores how modern software engineering principles—including compiler design, language tooling, immutable architectures, and intelligent automation—can complement existing RTL workflows and improve engineering productivity.

---

# Performance Goals

Future development will prioritize both capability and responsiveness.

Target engineering goals include:

| Area | Target |
|------|--------|
| Project Opening | < 2 seconds |
| Global Search | < 100 ms |
| Symbol Navigation | Instant |
| Workspace Restore | < 1 second |
| Panel Switching | < 16 ms |
| Large RTL Projects | 5,000+ source files |

These goals are intended to guide architectural decisions as the platform evolves.

---

# Contributing

Contributions are welcome.

Areas where contributors can have immediate impact include:

### Engineering Workbench

- Workspace Engine
- Desktop UX
- Panel management
- Keyboard navigation
- Accessibility

---

### RTL Language Engine

- Verilog parser
- SystemVerilog parser
- Symbol indexing
- Semantic analysis
- Language tooling

---

### Verification

- Property providers
- Diagnostics
- Coverage
- Repair planning
- Benchmarking

---

### AI Research

- RTL explanation
- Testbench generation
- Engineering assistants
- Documentation generation
- Natural-language interfaces

---

## Development Guidelines

ChipLens follows a small set of engineering principles.

- Keep components modular.
- Prefer immutable data models.
- Minimize coupling between subsystems.
- Add automated tests for new functionality whenever practical.
- Preserve deterministic behavior wherever possible.
- Document architectural decisions.

---

## Reporting Issues

Bug reports and feature requests are welcome.

When reporting an issue, please include:

- Operating system
- Flutter version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs or screenshots

---

# Citation

If ChipLens contributes to your research, teaching, or publications, please cite the project.

```text
ChipLens

An Extensible RTL Engineering Workbench
and Compiler-Inspired Verification Platform

GitHub Repository:
https://github.com/<YOUR_USERNAME>/ChipLens
```

A formal citation (e.g., BibTeX or DOI) may be added in future releases if appropriate.

---

# License

ChipLens is released under the MIT License.

See the LICENSE file for the complete license text.

---

# Acknowledgements

ChipLens draws inspiration from many outstanding open-source projects and engineering communities, including:

- LLVM
- Visual Studio Code
- JetBrains IDEs
- OpenROAD
- Yosys
- SymbiYosys
- PicoRV32
- SERV
- Flutter
- Dart

ChipLens is an independent project and is not affiliated with or endorsed by any of the above organizations or projects.

---

# Final Thoughts

ChipLens began as an exploration into compiler-inspired RTL verification.

As the project evolved, it expanded into a broader vision: a modern engineering platform that combines desktop tooling, language technology, verification research, and future AI-assisted workflows within a single extensible architecture.

The project remains guided by three core principles:

- **Engineering rigor**
- **Architectural clarity**
- **Honest, incremental progress**

Every implemented capability is expected to be testable, maintainable, and extensible.

As ChipLens continues to mature, the goal is to build a platform that not only supports practical RTL engineering but also serves as a foundation for research into the next generation of hardware development tools.

---

<div align="center">

**Built with Flutter • Dart • Curiosity • Engineering Discipline**

⭐ If you find ChipLens interesting, consider starring the repository and following its progress.

</div>
