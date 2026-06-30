<div align="center">

# ChipLens

### An Extensible RTL Engineering Workbench and Compiler-Inspired Verification Platform

<p>

A desktop-first engineering environment for **Register Transfer Level (RTL)** development, analysis, verification, and research.

Built with **Flutter** and **Dart**, ChipLens combines a modern IDE workspace with a modular compiler-inspired reasoning engine for digital hardware design.

</p>

---

![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Web-blue)

![Language](https://img.shields.io/badge/Language-Dart%203-blue)

![Framework](https://img.shields.io/badge/Framework-Flutter-02569B)

![License](https://img.shields.io/badge/License-MIT-success)

![Tests](https://img.shields.io/badge/Tests-4429%20Passing-success)

![Failures](https://img.shields.io/badge/Failures-0-success)

![Status](https://img.shields.io/badge/Status-Active%20Development-orange)

</div>

---

# Overview

ChipLens is an open-source engineering platform that explores a modern approach to **RTL development, verification, and design understanding**.

Rather than functioning as a traditional text editor or a single-purpose verification utility, ChipLens is designed as an integrated engineering workbench where RTL code, structural analysis, verification planning, diagnostics, and future AI-assisted engineering workflows coexist within a unified desktop environment.

The project combines two complementary directions:

- **A professional desktop RTL engineering workbench**
- **A compiler-inspired semantic reasoning framework for hardware verification**

These two layers are intentionally independent.

The workbench focuses on developer productivity and engineering workflows, while the reasoning engine focuses on deterministic semantic analysis, verification planning, explainability, diagnostics, and research into next-generation RTL verification methodologies.

---

# Vision

ChipLens aims to become a modern engineering platform for digital hardware development.

The long-term objective is **not** to replace established EDA tools such as Cadence, Synopsys, Siemens EDA, Vivado, Quartus, or SymbiYosys.

Instead, ChipLens investigates how modern software engineering principles—including modular architectures, compiler design, immutable data models, and AI-assisted workflows—can improve the overall RTL engineering experience.

In the same way that modern IDEs transformed software development, ChipLens explores how integrated tooling can improve hardware engineering.

---

# Why ChipLens?

Modern RTL development often spans multiple disconnected tools.

Engineers routinely switch between:

- Source code editors
- Simulation environments
- Formal verification tools
- Waveform viewers
- Linting tools
- Coverage reports
- Documentation
- Build systems
- Version control

While these tools are individually powerful, the engineering workflow surrounding them is often fragmented.

ChipLens explores a different approach.

Instead of treating RTL development as a sequence of unrelated applications, ChipLens provides a unified engineering environment where project navigation, source editing, semantic analysis, diagnostics, verification planning, and future AI-assisted workflows can coexist within a single workspace.

The long-term goal is to reduce engineering friction while improving understanding, reproducibility, and productivity.

---

# Current Project Status

ChipLens is under active development.

The project currently consists of two major subsystems.

## 1. Desktop Engineering Workbench

The workbench provides the user-facing engineering environment.

Current capabilities include:

- Desktop-first multi-panel workspace
- RTL project explorer
- Read-only RTL editor
- Multiple document tabs
- RTL tokenizer
- Syntax highlighting foundation
- Outline navigation
- Symbol extraction
- Command palette
- Global search
- Keyboard shortcuts
- Problems panel
- Output panel
- Status bar
- Workspace controller
- Responsive desktop/web layouts
- Immutable workspace state
- Extensive automated UI testing

---

## 2. Compiler-Inspired Verification Framework

The backend reasoning engine focuses on deterministic semantic reasoning rather than proof execution.

Implemented framework modules include:

- Design Intelligence
- Semantic Evidence
- Property Synthesis
- Property Ranking
- Property Emission
- Explainability
- Verification Planning
- Coverage Intelligence
- Counterexample Analysis
- Diagnostics Intelligence
- Repair Planning
- Verification Orchestrator

The reasoning engine is intentionally backend-independent and designed to integrate with external verification engines rather than replace them.

---

# Current Engineering Metrics

| Metric | Current |
|----------|---------|
| Automated Tests | **4,429 Passing** |
| Test Failures | **0** |
| Desktop Workbench | ✅ |
| RTL Workspace | ✅ |
| Project System | ✅ |
| Multi-Document Editor | ✅ |
| RTL Tokenizer | ✅ |
| Outline Navigation | ✅ |
| Command Palette | ✅ |
| Workspace Explorer | ✅ |
| Backend Frameworks | **14** |
| Property Providers | **8** |
| Open-Source RTL Validation | ✅ |
| Benchmark Framework | ✅ |
| License | MIT |

---

# Design Philosophy

ChipLens is guided by a small set of engineering principles that influence every architectural decision.

## Engineering Before Appearance

The workbench is designed to support long engineering sessions rather than showcase visual effects.

Functionality always takes precedence over decoration.

---

## Desktop First

ChipLens is designed primarily for desktop engineering workflows.

Keyboard navigation, information density, panel management, and workspace efficiency take priority over mobile-oriented interaction patterns.

---

## Modular Architecture

Every subsystem owns a clearly defined responsibility.

Examples include:

- Workspace Engine
- RTL Language Engine
- Verification Framework
- Project System
- Diagnostics
- Explainability
- Future AI Services

Each subsystem evolves independently through immutable interfaces.

---

## Deterministic Reasoning

The verification engine emphasizes deterministic execution.

Identical RTL inputs should always produce identical semantic outputs whenever possible.

This simplifies testing, reproducibility, benchmarking, and future research.

---

## Extensibility

ChipLens is designed as a long-term research platform.

Future capabilities—including language servers, verification engines, AI assistants, waveform analysis, and plugin systems—are intended to integrate without requiring architectural redesign.

---

# Architecture

ChipLens is organized into two largely independent layers:

```
                        ┌──────────────────────────────┐
                        │      ChipLens Platform       │
                        └──────────────┬───────────────┘
                                       │
          ┌────────────────────────────┴────────────────────────────┐
          │                                                         │
          ▼                                                         ▼
┌─────────────────────────────┐                  ┌─────────────────────────────┐
│   Desktop Engineering IDE   │                  │ Compiler-Inspired Backend   │
│                             │                  │                             │
│ • Workspace                 │                  │ • Semantic Analysis         │
│ • RTL Editor                │                  │ • Property Inference        │
│ • Explorer                  │                  │ • Explainability            │
│ • Outline                   │                  │ • Verification Planning     │
│ • Diagnostics               │                  │ • Coverage Intelligence     │
│ • Project System            │                  │ • Repair Planning           │
│ • Future AI Workspace       │                  │ • Verification Orchestrator │
└─────────────────────────────┘                  └─────────────────────────────┘
```

The two layers intentionally evolve independently.

The engineering workbench focuses on developer productivity.

The reasoning engine focuses on deterministic semantic reasoning.

This separation allows future command-line tools, web interfaces, plugins, and research prototypes to reuse the same reasoning infrastructure without depending on a specific user interface.

---

# Engineering Workbench

The Engineering Workbench is the primary user interface of ChipLens.

Unlike a traditional dashboard application, the workbench is designed to become the central environment where RTL engineers spend the majority of their development time.

Current architecture includes:

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Toolbar                                                                    │
├────────────────────────────────────────────────────────────────────────────┤
│ Sidebar │ Project Explorer │ RTL Editor │ Outline / Symbols / Properties   │
├─────────┴──────────────────┴────────────┴──────────────────────────────────┤
│ Problems │ Output │ Terminal │ Logs │ Analysis                             │
├────────────────────────────────────────────────────────────────────────────┤
│ Status Bar                                                                 │
└────────────────────────────────────────────────────────────────────────────┘
```

The workbench is built around immutable state models and independent panel controllers.

Current capabilities include:

- Multi-panel desktop workspace
- Project explorer
- RTL workspace
- Multiple document management
- Read-only RTL editor
- Line numbering
- RTL outline generation
- Symbol extraction
- Command palette
- Global search
- Keyboard shortcuts
- Responsive desktop layout
- Status bar
- Problems panel
- Output panel
- Workspace controller
- Modular panel architecture

The workbench continues to evolve toward a fully featured RTL engineering environment.

---

# Workspace Engine

The Workspace Engine is responsible for the behavior of the desktop environment.

Responsibilities include:

- Project navigation
- Document management
- Multi-document tabs
- Panel management
- Workspace state
- Layout management
- Keyboard navigation
- Command routing
- Responsive layouts

The Workspace Engine is intentionally separated from RTL analysis.

This allows future language engines, plugins, and verification tools to integrate without modifying the workspace infrastructure.

---

# RTL Language Layer

ChipLens treats RTL as a language rather than plain text.

Current language features include:

- RTL document model
- RTL line model
- RTL tokenizer
- Syntax highlighting foundation
- Symbol extraction
- Outline generation
- Structural block recognition
- Code folding foundation
- Search integration

The long-term goal is to evolve this layer into a complete language engine.

Planned future capabilities include:

- Verilog parser
- SystemVerilog parser
- Abstract Syntax Tree (AST)
- Symbol table
- Go To Definition
- Find References
- Rename Symbol
- Hover information
- Semantic highlighting
- Incremental parsing

---

# Compiler-Inspired Verification Framework

The backend reasoning engine is organized as a deterministic pipeline of independent frameworks.

Rather than performing verification as a monolithic process, ChipLens decomposes reasoning into a sequence of semantic transformations.

```
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
Diagnostics Intelligence
      │
      ▼
Repair Planning
      │
      ▼
Verification Orchestrator
```

Every framework performs one clearly defined responsibility.

Outputs are represented using immutable value objects.

This architecture improves:

- Testability
- Deterministic execution
- Reproducibility
- Explainability
- Long-term maintainability

---

# Current Backend Frameworks

ChipLens currently contains fourteen major reasoning frameworks.

| Framework | Responsibility |
|------------|----------------|
| Design Intelligence | Structural RTL analysis |
| Semantic Evidence | Immutable semantic facts |
| Property Synthesis | Candidate assertion generation |
| Property Ranking | Deterministic prioritization |
| Property Emission | Backend-independent property generation |
| Explainability | Human-readable reasoning |
| Verification Planning | Execution planning |
| Formal Integration | Backend abstraction |
| Coverage Intelligence | Coverage interpretation |
| Counterexample Analysis | Trace interpretation |
| Diagnostics Intelligence | Root-cause reasoning |
| Repair Planning | Suggested design improvements |
| Verification Orchestrator | Pipeline coordination |
| Benchmark Framework | Empirical evaluation |

---

# AI & Natural Language Services

ChipLens also contains an experimental natural language service layer.

Current research modules include:

- RTL generation from natural language
- Testbench generation
- Intent extraction
- RTL explanation
- FSM construction
- Quality analysis
- Pipeline orchestration

These components are currently experimental and are not yet integrated into the primary engineering workspace.

Future releases will expose these capabilities through the Engineering Workbench after the core RTL language infrastructure reaches production maturity.

---

# Architectural Principles

ChipLens follows several architectural principles consistently throughout the project.

## Single Responsibility

Every subsystem owns one well-defined responsibility.

Large monolithic managers are intentionally avoided.

---

## Immutable Models

Communication between frameworks occurs through immutable data structures.

This reduces unintended side effects and simplifies testing.

---

## Test-Driven Engineering

Every architectural improvement is expected to include automated regression tests.

The project currently maintains over **4,400 passing automated tests**, covering both backend reasoning and desktop workbench behavior.

---

## Backend Independence

The reasoning engine is intentionally separated from formal verification backends.

ChipLens is designed to integrate with multiple verification engines rather than depending on one implementation.

---

## Long-Term Extensibility

The architecture is designed for future expansion into:

- Language Server Protocol (LSP)
- Plugin SDK
- AI Engineering Assistant
- Waveform visualization
- Verification dashboards
- Hardware design analytics
- Distributed verification
- Cloud execution

# RTL Engineering Workbench

The ChipLens Engineering Workbench is a desktop-first environment designed specifically for RTL engineering workflows.

Unlike traditional text editors, the workbench is organized around engineering activities rather than files alone.

Current workbench capabilities include:

- Multi-panel desktop interface
- RTL project explorer
- Workspace controller
- Multi-document editor
- RTL document model
- RTL tokenizer
- Syntax highlighting foundation
- Outline generation
- Symbol extraction
- Command palette
- Global search
- Problems panel
- Output panel
- Status bar
- Responsive desktop layouts
- Immutable workspace state
- Keyboard-driven navigation

The workbench is designed to evolve into a complete RTL engineering environment supporting editing, navigation, verification, diagnostics, AI assistance, and visualization.

---

# RTL Editor

ChipLens treats RTL as a structured engineering language rather than plain text.

Current editor capabilities include:

## Editing

- Multi-document workspace
- Document tabs
- Pinning documents
- Recent documents
- Read-only mode
- Line numbering
- Cursor tracking
- Status reporting

---

## Navigation

- Outline generation
- Symbol extraction
- Keyboard shortcuts
- Global search
- Command palette
- Go To Symbol foundation
- Breadcrumb infrastructure

---

## Language Features

Current support includes:

- RTL tokenizer
- Structural block recognition
- Syntax highlighting foundation
- Code folding foundation
- Module extraction
- Port extraction
- Parameter extraction
- Always block recognition
- Assign statement recognition

Future milestones will introduce:

- Full Verilog parser
- SystemVerilog parser
- Incremental parsing
- Semantic highlighting
- Symbol indexing
- Rename Symbol
- Go To Definition
- Find References
- Hover documentation

---

# Project System

ChipLens includes an immutable project management system.

Projects currently maintain:

- Project metadata
- Workspace state
- Recent documents
- Project explorer
- Standard RTL folder structure
- Active project context
- Document management

Default project organization

```
Project

├── rtl/

├── testbench/

├── constraints/

├── reports/

└── docs/
```

Future releases will extend the project system with:

- Build configurations
- Simulation profiles
- Verification sessions
- Coverage history
- Git integration
- Workspace snapshots

---

# Technology Stack

## Frontend

| Technology | Purpose |
|------------|----------|
| Flutter | Desktop and Web UI |
| Dart | Application language |
| Material 3 | Base component system |
| Immutable Models | State management |
| Responsive Layouts | Multi-platform support |

---

## Backend

| Component | Purpose |
|------------|----------|
| Dart | Verification framework |
| Compiler-inspired architecture | Semantic reasoning |
| Immutable value objects | Deterministic execution |
| Property providers | Assertion synthesis |
| Verification orchestrator | Pipeline coordination |

---

## Development Practices

ChipLens follows several engineering practices throughout the project.

- Immutable architecture
- Separation of concerns
- Modular framework design
- Extensive automated testing
- Deterministic execution
- Continuous regression testing
- Desktop-first UX

---

# Repository Structure

```
lib/

├── core/
│   ├── models/
│   ├── services/
│   ├── workspace/
│   └── verification/
│
├── ui/
│   ├── workbench/
│   ├── editor/
│   ├── explorer/
│   ├── panels/
│   └── themes/
│
├── backend/
│   ├── design_intelligence/
│   ├── property_inference/
│   ├── explainability/
│   ├── planning/
│   ├── diagnostics/
│   ├── coverage/
│   ├── repair/
│   └── orchestrator/
│
├── benchmarks/
│
└── test/
```

The repository is intentionally organized around engineering subsystems rather than UI pages.

---

# Getting Started

## Prerequisites

- Flutter SDK
- Dart SDK
- Git

Verify installation

```bash
flutter doctor
```

---

## Clone

```bash
git clone https://github.com/<username>/ChipLens.git

cd ChipLens
```

---

## Install dependencies

```bash
flutter pub get
```

---

## Run

Desktop

```bash
flutter run -d windows
```

Web

```bash
flutter run -d chrome
```

---

# Running Tests

Execute the complete regression suite

```bash
flutter test
```

Static analysis

```bash
flutter analyze
```

The project currently maintains

- **4,429 passing automated tests**
- **0 failing tests**
- **3 intentionally skipped tests**

---

# Benchmark Framework

ChipLens includes a benchmark framework for evaluating the verification pipeline.

The benchmark runner coordinates:

- Design analysis
- Property generation
- Coverage reasoning
- Diagnostics
- Repair planning

This framework enables empirical evaluation of backend improvements while maintaining deterministic execution.

---

# Open-Source RTL Validation

ChipLens validates portions of its backend framework using publicly available RTL designs.

Current validation includes examples derived from projects such as:

- PicoRV32
- SERV

These designs are used exclusively for validation and regression testing.

ChipLens does **not** claim compatibility certification with any external RTL project.

---

# Automated Testing Philosophy

Automated testing is considered a core architectural requirement rather than an optional quality assurance step.

Tests currently cover:

## Frontend

- Workspace models
- Explorer
- RTL editor
- Toolbar
- Status bar
- Problems panel
- Outline generation
- Workspace state
- Navigation
- Project management

---

## Backend

- Property providers
- Verification orchestrator
- Semantic reasoning
- Explainability
- Diagnostics
- Repair planning
- Coverage intelligence
- Benchmark execution

Regression testing accompanies every architectural milestone to reduce the likelihood of unintended behavior changes.

---

# Documentation

Project documentation is organized into several categories.

- Architecture
- Backend frameworks
- Engineering workbench
- Verification pipeline
- Research notes
- Future roadmap

Additional documentation will continue to expand as the project matures.

# Implementation Status

The following table summarizes the current implementation status of major ChipLens subsystems.

| Component | Status |
|-----------|--------|
| Desktop Workbench | ✅ Stable |
| Project System | ✅ Stable |
| Workspace Engine | ✅ Stable |
| RTL Explorer | ✅ Stable |
| Multi-Document Workspace | ✅ Stable |
| Command Palette | ✅ Stable |
| Global Search | ✅ Stable |
| Problems Panel | ✅ Stable |
| Output Panel | ✅ Stable |
| Status Bar | ✅ Stable |
| RTL Tokenizer | ✅ Stable |
| Outline Generation | ✅ Stable |
| Symbol Extraction | ✅ Stable |
| Backend Verification Framework | ✅ Stable |
| Benchmark Framework | ✅ Stable |
| Explainability Framework | ✅ Stable |
| Diagnostics Framework | ✅ Stable |
| Repair Planning Framework | ✅ Stable |
| Coverage Intelligence | ✅ Stable |
| RTL Parser | 🚧 Planned |
| AST | 🚧 Planned |
| Symbol Index | 🚧 Planned |
| Go To Definition | 🚧 Planned |
| Find References | 🚧 Planned |
| Rename Symbol | 🚧 Planned |
| Waveform Viewer | 🚧 Planned |
| Module Hierarchy | 🚧 Planned |
| FSM Visualization | 🚧 Planned |
| Coverage Dashboard | 🚧 Planned |
| Verification Dashboard | 🚧 Planned |
| AI Workspace Integration | 🧪 Experimental |

---

# Roadmap

ChipLens is developed incrementally through architecture-driven milestones.

Rather than implementing isolated features, each milestone introduces a complete engineering subsystem.

---

## Phase I — Desktop Engineering Workbench

Status: **Largely Complete**

Focus:

- Project management
- Workspace engine
- Explorer
- Multi-document editor
- Search
- Command palette
- Problems panel
- Output panel
- Status bar
- Responsive desktop interface

---

## Phase II — RTL Language Engine

Status: **In Progress**

Focus:

- Verilog parser
- SystemVerilog parser
- AST generation
- Symbol indexing
- Incremental parsing
- Semantic highlighting
- Go To Definition
- Find References
- Rename Symbol

---

## Phase III — RTL Engineering

Status: **Planned**

Focus:

- Module hierarchy
- Signal graph
- Dependency graph
- Clock domain analysis
- Reset domain analysis
- FSM visualization
- Design metrics
- Cross-module navigation

---

## Phase IV — Verification

Status: **Planned**

Focus:

- Waveform viewer
- Coverage visualization
- Assertion management
- Regression sessions
- Verification reports
- Counterexample navigation

---

## Phase V — AI Engineering Assistant

Status: **Research**

Focus:

- RTL explanation
- Testbench generation
- RTL generation
- Intent extraction
- Engineering documentation
- Design review assistance

Experimental NLP modules already exist in the repository but are not yet integrated into the primary workbench.

---

# Research Directions

ChipLens is also intended to serve as a research platform.

Current research interests include:

- Compiler-inspired RTL reasoning
- Deterministic semantic analysis
- Automated assertion synthesis
- Explainable verification
- Verification planning
- RTL documentation generation
- AI-assisted hardware engineering
- Large-scale RTL understanding

The project is intentionally structured so these research areas can evolve independently without disrupting the desktop engineering environment.

---

# Contributing

Contributions are welcome.

Areas of interest include:

### Engineering Workbench

- Desktop UX
- Workspace Engine
- RTL Editor
- Performance
- Accessibility

### RTL Language Engine

- Verilog parsing
- SystemVerilog parsing
- Symbol indexing
- Navigation
- Incremental parsing

### Verification

- Property synthesis
- Diagnostics
- Coverage
- Repair planning

### AI

- RTL explanation
- Testbench generation
- Documentation
- Engineering assistants

Please accompany significant changes with automated tests whenever practical.

---

# Design Principles

Every architectural decision in ChipLens follows several long-term principles.

## Engineering First

The primary objective is improving engineering productivity.

Visual polish should support engineering workflows rather than replace them.

---

## Deterministic Behavior

Identical RTL inputs should produce identical semantic outputs whenever possible.

This improves reproducibility, benchmarking, and explainability.

---

## Modular Systems

Large monolithic managers are intentionally avoided.

Subsystems communicate through immutable interfaces.

---

## Extensibility

ChipLens is designed to accommodate future language engines, verification frameworks, plugins, AI services, and research prototypes without requiring architectural redesign.

---

## Testability

Regression testing is considered an architectural requirement.

Every major subsystem should remain independently testable.

---

# Citation

If you use ChipLens in academic research, teaching, or publications, please cite the repository.

```text
ChipLens

An Extensible RTL Engineering Workbench
and Compiler-Inspired Verification Platform

GitHub:
https://github.com/<username>/ChipLens
```

---

# License

ChipLens is released under the MIT License.

See the LICENSE file for details.

---

# Acknowledgements

ChipLens draws inspiration from many outstanding engineering tools and research communities, including:

- VS Code
- JetBrains IDEs
- LLVM
- OpenROAD
- Yosys
- SymbiYosys
- PicoRV32
- SERV
- Flutter
- Dart

ChipLens is an independent project and is not affiliated with or endorsed by any of the above.

---

# Final Thoughts

ChipLens began as an exploration into compiler-inspired verification.

It has since evolved into a broader engineering platform that combines desktop tooling, RTL language technology, verification research, and future AI-assisted workflows.

The long-term vision is not to replace existing Electronic Design Automation (EDA) tools, but to explore how modern software engineering techniques can make RTL development more understandable, productive, and extensible.

As the project continues to evolve, ChipLens aims to remain grounded in three core values:

- **Engineering rigor**
- **Architectural clarity**
- **Honest, incremental progress**

Every implemented feature is intended to be testable, maintainable, and extensible, providing a foundation for both practical engineering workflows and future research.
