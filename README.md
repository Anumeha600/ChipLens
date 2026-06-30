# ChipLens

> **An Extensible RTL Engineering Workbench and Compiler-Inspired Verification Platform**

[![Version](https://img.shields.io/badge/version-v2.1.0-blue.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-4429%20Passing-success.svg)]()
[![License](https://img.shields.io/badge/License-MIT-success.svg)]()

---

> **Build • Understand • Analyze • Verify RTL Designs**

ChipLens is an open-source **desktop engineering platform** for Register Transfer Level (RTL) development, semantic analysis, verification, and hardware engineering research.

Rather than functioning as a traditional RTL editor, ChipLens combines a modern desktop workbench with a compiler-inspired verification framework to provide an integrated environment for understanding, analyzing, navigating, and verifying RTL designs.

The project investigates how ideas from compiler construction, language tooling, immutable architectures, and modern software engineering can improve digital hardware development workflows.

---

# Screenshots

> *(Replace these placeholders with actual screenshots.)*

## Engineering Workbench

![Workbench](docs/images/workbench.png)

---

## RTL Editor

![RTL Editor](docs/images/rtl_editor.png)

---

## Property Explorer

![Property Explorer](docs/images/property_explorer.png)

---

## Verification Workspace

![Verification](docs/images/verification.png)

---

# Why ChipLens?

Modern RTL engineering typically spans multiple independent tools.

A hardware engineer may need to switch between:

- Source code editors
- Simulators
- Formal verification tools
- Coverage reports
- Diagnostics
- Waveform viewers
- Documentation
- Version control
- Project management utilities

While each tool solves an individual problem well, the overall engineering workflow often becomes fragmented.

ChipLens explores a different approach.

Instead of treating editing, navigation, verification, diagnostics, explainability, and future AI assistance as isolated applications, ChipLens integrates them into a single engineering workbench designed specifically for RTL development.

---

# Vision

ChipLens is built around three complementary objectives.

## Modern RTL Engineering

Provide a professional desktop engineering environment specifically designed for RTL development.

Rather than adapting a generic text editor, ChipLens investigates workflows tailored to hardware engineers.

---

## Compiler-Inspired Verification

Explore verification as a deterministic semantic pipeline composed of modular analysis stages.

Compiler design principles—including parsing, semantic analysis, intermediate representations, and structured reasoning—are applied to RTL verification.

---

## Research Platform

ChipLens is intentionally designed as an extensible research platform for experimentation in:

- RTL language tooling
- Verification automation
- Property inference
- Explainable diagnostics
- AI-assisted engineering
- Engineering productivity

Experimental research components remain isolated from production infrastructure, allowing innovation without destabilizing the workbench.

---

# Highlights

## Desktop Engineering Workbench

Current workbench capabilities include:

- Desktop-first multi-panel interface
- Project Explorer
- Custom RTL editor
- Workspace controller
- Command Palette
- Quick Open
- Global Search
- Outline panel
- Module information
- Design metrics
- Problems panel
- Output panel
- Logs panel
- Integrated terminal
- Status bar
- Responsive layouts

---

## RTL Language Infrastructure

Current capabilities include:

- RTL tokenizer
- Syntax highlighting
- Structural outline extraction
- Symbol extraction
- Go To Symbol
- Code folding foundation
- RTL document model
- RTL line model
- Workspace controller
- Navigation services

These components establish the foundation for future semantic tooling such as incremental parsing, symbol indexing, and cross-reference navigation.

---

## Verification Framework

ChipLens contains a modular compiler-inspired verification framework supporting:

- Design intelligence
- Semantic analysis
- Property inference
- Property ranking
- Explainability
- Verification planning
- Coverage intelligence
- Diagnostics intelligence
- Counterexample analysis
- Repair planning
- Verification orchestration

Each subsystem operates independently while participating in a larger deterministic verification pipeline.

---

## Experimental AI Research

ChipLens also includes an experimental natural-language pipeline investigating AI-assisted RTL engineering.

Current research components include:

- RTL generation
- Testbench generation
- RTL explanation
- FSM construction
- Intent extraction
- Quality analysis

These components are experimental and are currently separated from the primary engineering workbench.

---

# At a Glance

| Category | Value |
|-----------|-------|
| Project Type | Desktop RTL Engineering Platform |
| Primary Language | Dart 3 |
| Framework | Flutter |
| Desktop Platforms | Windows • Linux • macOS |
| Web Support | Yes |
| Backend Subsystems | 28+ |
| Source Files | 400+ |
| Automated Tests | 4,429 Passing |
| Test Failures | 0 |
| License | MIT |

---

# Design Philosophy

Every architectural decision in ChipLens follows a consistent set of engineering principles.

## Engineering First

Engineering productivity takes precedence over visual decoration.

Features should improve how engineers understand, navigate, verify, and maintain RTL designs.

---

## Modular Systems

ChipLens is intentionally divided into independent engineering subsystems.

Each subsystem owns one responsibility and communicates through stable interfaces.

---

## Immutable Models

Shared state is represented using immutable value objects wherever practical.

This improves reproducibility, testing, and maintainability.

---

## Deterministic Behaviour

Identical RTL inputs should produce identical semantic outputs whenever possible.

Deterministic execution simplifies benchmarking, testing, and explainability.

---

## Extensible Architecture

Future language engines, AI assistants, verification backends, plugins, and visualization tools should integrate without requiring architectural redesign.

---

> **ChipLens does not seek to replace existing Electronic Design Automation (EDA) tools. Instead, it explores how modern software engineering techniques can complement traditional RTL workflows through better language tooling, integrated engineering environments, and explainable verification.**

# Architecture

ChipLens is organized as a collection of independent engineering subsystems rather than a monolithic application.

Each subsystem owns a well-defined responsibility and communicates through stable interfaces and immutable data models wherever practical.

This architecture allows the desktop workbench, language tooling, verification framework, and future research components to evolve independently while maintaining a consistent engineering foundation.

---

# High-Level Architecture

```text
                          ChipLens Platform
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
        ▼                        ▼                        ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Desktop        │      │ RTL Language   │      │ Verification   │
│ Workbench      │      │ Infrastructure │      │ Framework      │
└────────────────┘      └────────────────┘      └────────────────┘
        │                        │                        │
        └───────────────┬────────┴────────┬───────────────┘
                        ▼                 ▼
               Project Infrastructure    AI Research
```

The platform consists of four primary layers:

- Desktop Engineering Workbench
- RTL Language Infrastructure
- Compiler-Inspired Verification Framework
- Experimental AI Research Services

Each layer is largely independent and designed for long-term extensibility.

---

# Desktop Engineering Workbench

The Desktop Engineering Workbench is the primary user-facing environment.

Rather than presenting RTL as plain text, the workbench organizes engineering activities into dedicated panels that support navigation, structural understanding, diagnostics, and verification.

Current workbench architecture includes:

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ Activity Bar │ Toolbar                                                  │
├──────────────┬──────────────────────────────────────────┬────────────────┤
│              │                                          │                │
│ Explorer     │           RTL Editor                     │ Outline        │
│              │                                          │ Module Info    │
│              │                                          │ Design Metrics │
├──────────────┴──────────────────────────────────────────┴────────────────┤
│ Problems │ Output │ Terminal │ Logs                                   │
├──────────────────────────────────────────────────────────────────────────┤
│ Status Bar                                                       Ready │
└──────────────────────────────────────────────────────────────────────────┘
```

Current workbench components include:

- Engineering Workbench
- Activity Bar
- Workspace Controller
- Project Explorer
- RTL Editor
- Outline Panel
- Module Information
- Design Metrics
- Command Palette
- Quick Open
- Global Search
- Problems Panel
- Output Panel
- Integrated Terminal
- Logs Panel
- Status Bar

---

# Workspace Engine

The Workspace Engine coordinates the behaviour of the desktop environment.

Responsibilities include:

- Project lifecycle
- Document management
- Tab management
- Panel coordination
- Workspace layout
- Keyboard navigation
- Command routing
- Session state

The workspace engine is intentionally separated from RTL analysis, allowing new engineering capabilities to integrate without modifying the desktop infrastructure.

Future milestones will extend the Workspace Engine with:

- Dockable panels
- Split editors
- Persistent workspace layouts
- Session restoration
- Workspace snapshots
- Multi-project support

---

# RTL Language Infrastructure

ChipLens treats RTL as a structured engineering language.

Instead of viewing source code as plain text, the platform builds increasingly rich representations of RTL throughout the analysis pipeline.

Current language infrastructure consists of:

```text
RTL Source

↓

Tokenizer

↓

Parser

↓

Abstract Syntax Tree

↓

Symbol Table

↓

Semantic Analysis

↓

Navigation Services

↓

Engineering Workbench
```

This layered architecture allows each stage to focus on one engineering responsibility.

---

# Parser

ChipLens includes a dedicated Verilog parsing layer.

Current responsibilities include:

- RTL parsing
- Parse result generation
- Source span tracking
- Entity extraction
- Fallback parsing
- Remote parser integration

Parser output forms the basis for all later semantic analysis.

---

# Abstract Syntax Tree

The parser constructs an Abstract Syntax Tree (AST) representing RTL structure.

Current node types include:

- Modules
- Ports
- Parameters
- Signals
- Assignments
- Always blocks
- Expressions
- Identifiers
- Data types
- Instances
- Sensitivity lists

The AST provides a structured representation suitable for semantic analysis and future language tooling.

---

# Symbol Table

The Symbol Table manages scoped RTL symbols throughout a design.

Current responsibilities include:

- Symbol registration
- Scope tracking
- Symbol references
- Cross-reference information
- Symbol lookup

This subsystem forms the foundation for future capabilities such as:

- Go To Definition
- Find References
- Rename Symbol
- Semantic highlighting

---

# Semantic Analysis

Semantic Analysis transforms parsed RTL into engineering knowledge.

Current semantic models include:

- Signal graphs
- Module hierarchy
- Clock domains
- Sequential elements
- Combinational elements
- Driver information
- FSM candidates

Rather than focusing only on syntax, semantic analysis attempts to understand the behaviour and structure of the design.

---

# Navigation Services

Navigation services provide engineering-oriented movement throughout RTL projects.

Current infrastructure includes:

- Go To Definition services
- Find References services
- Symbol navigation
- Outline generation

Future milestones will extend navigation with:

- Cross-module navigation
- Hover documentation
- Workspace-wide symbol search
- Incremental indexing

---

# Compiler-Inspired Verification Framework

The backend verification framework applies compiler-inspired design principles to RTL reasoning.

Rather than performing verification inside one large engine, ChipLens decomposes reasoning into independent stages.

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

Every stage performs one clearly defined responsibility.

This architecture improves:

- Testability
- Explainability
- Deterministic execution
- Extensibility
- Long-term maintainability

---

# AI Research Layer

ChipLens also contains an experimental Natural Language Pipeline investigating AI-assisted RTL engineering.

Current experimental modules include:

- RTL Generator
- Testbench Generator
- Intent Extractor
- Explanation Engine
- FSM Builder
- Quality Analyzer
- Pipeline Orchestrator

These modules are intentionally isolated from the primary engineering workbench while research continues.

Future milestones will integrate selected AI capabilities into the desktop environment once the core language infrastructure reaches production maturity.

---

# Architectural Principles

Every subsystem within ChipLens follows five consistent engineering principles.

### Separation of Concerns

Each subsystem owns a single engineering responsibility.

---

### Immutable Data

Shared state is represented using immutable value objects wherever practical.

---

### Test-Driven Development

Architectural milestones are accompanied by automated regression tests.

---

### Backend Independence

Verification infrastructure is designed to integrate with multiple external tools rather than depending on a single backend.

---

### Extensibility

Future language tooling, plugins, verification engines, visualization systems, and AI assistants should integrate without requiring architectural redesign.

# RTL Engineering Workbench

The ChipLens Engineering Workbench is the primary environment for interacting with RTL projects.

Unlike conventional source code editors, the workbench is organized around engineering workflows rather than files alone.

Current development focuses on creating an extensible desktop environment where RTL editing, structural understanding, verification planning, diagnostics, and future AI-assisted workflows coexist naturally.

---

# Workbench Overview

The Engineering Workbench currently consists of multiple coordinated panels.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ Activity Bar │ Toolbar                                                     │
├──────────────┬───────────────────────────────────────────┬──────────────────┤
│              │                                           │                  │
│ Explorer     │               RTL Editor                  │ Outline          │
│              │                                           │ Symbols          │
│              │                                           │ Module Info      │
│              │                                           │ Design Metrics   │
├──────────────┴───────────────────────────────────────────┴──────────────────┤
│ Problems │ Output │ Terminal │ Logs │ Analysis                            │
├─────────────────────────────────────────────────────────────────────────────┤
│ Status Bar                                                    Ready        │
└─────────────────────────────────────────────────────────────────────────────┘
```

The workbench is intentionally modular.

Each panel owns one engineering responsibility while communicating through shared workspace services.

---

# Current Workbench Features

## Workspace

- Multi-panel engineering interface
- Desktop-first workflow
- Workspace controller
- Responsive layouts
- Recent projects
- Recent RTL files
- Keyboard shortcuts
- Status reporting

---

## Project Explorer

Current capabilities include:

- RTL project navigation
- Expand/collapse hierarchy
- Project switching
- File selection
- Workspace synchronization
- Keyboard navigation

Future milestones will introduce:

- Drag-and-drop support
- File operations
- Git integration
- Workspace bookmarks

---

## RTL Editor

Current editor capabilities include:

### Editing

- Multi-document tabs
- Read-only editor
- Line numbering
- Cursor tracking
- Selection handling
- Status reporting

---

### Language Features

Current implementation includes:

- RTL tokenizer
- Syntax highlighting
- Structural outline extraction
- Module detection
- Port detection
- Parameter detection
- Always block detection
- Assign statement detection
- Symbol extraction
- Code folding foundation

---

### Navigation

Current support includes:

- Go To Symbol
- Outline navigation
- Global search
- Quick Open
- Command Palette

Planned features include:

- Go To Definition
- Find References
- Rename Symbol
- Hover documentation
- Semantic highlighting

---

# Engineering Panels

Current engineering panels include:

| Panel | Purpose |
|---------|----------|
| Explorer | Project navigation |
| Outline | Structural navigation |
| Symbols | Symbol overview |
| Module Information | RTL metadata |
| Design Metrics | Structural metrics |
| Problems | Diagnostics |
| Output | Analysis output |
| Terminal | Command execution |
| Logs | Engineering logs |
| Status Bar | Workspace status |

Each panel is developed as an independent subsystem.

---

# Project System

ChipLens includes an immutable project management infrastructure.

Current project capabilities include:

- Project metadata
- Workspace state
- Active project context
- Recent projects
- Recent RTL files
- Explorer synchronization

Recommended project layout:

```text
Project

├── rtl/

├── testbench/

├── constraints/

├── scripts/

├── reports/

└── docs/
```

Future milestones will extend the project system with:

- Build profiles
- Simulation configurations
- Workspace persistence
- Verification sessions
- Git integration

---

# Technology Stack

## Frontend

| Technology | Purpose |
|------------|----------|
| Flutter | Desktop UI |
| Dart | Application language |
| Material 3 | Base component system |
| Immutable Models | State management |
| Responsive Layouts | Multi-platform support |

---

## Backend

| Technology | Purpose |
|------------|----------|
| Dart | Verification framework |
| Compiler-inspired architecture | Semantic reasoning |
| Immutable value objects | Deterministic execution |
| Modular frameworks | Verification pipeline |

---

## Engineering Practices

ChipLens follows several engineering practices throughout the project.

- Modular architecture
- Immutable state
- Separation of concerns
- Test-driven development
- Continuous regression testing
- Deterministic execution
- Desktop-first UX

---

# Repository Structure

```text
ChipLens

├── assets/
│
├── benchmarks/
│
├── docs/
│
├── lib/
│   ├── backend/
│   ├── core/
│   ├── parser/
│   ├── services/
│   ├── ui/
│   ├── workbench/
│   ├── widgets/
│   └── themes/
│
├── test/
│
└── tool/
```

The repository is organized around engineering subsystems rather than user interface pages.

This structure improves modularity, maintainability, and long-term scalability.

---

# Getting Started

## Prerequisites

Install:

- Flutter SDK 3.x
- Dart SDK 3.x
- Git

Verify your environment:

```bash
flutter doctor
```

---

## Clone

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

## Run

### Windows

```bash
flutter run -d windows
```

### Linux

```bash
flutter run -d linux
```

### macOS

```bash
flutter run -d macos
```

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

Run static analysis:

```bash
flutter analyze
```

Current project metrics:

| Metric | Value |
|---------|------:|
| Passing Tests | **4,429** |
| Test Failures | **0** |
| Skipped Tests | **3** |

Regression testing accompanies every major architectural milestone.

---

# Benchmark Framework

ChipLens includes a benchmark framework for evaluating backend reasoning and verification performance.

Current benchmark stages include:

- RTL loading
- Parsing
- Semantic analysis
- Property generation
- Coverage reasoning
- Diagnostics
- Repair planning

The benchmark framework enables empirical evaluation while maintaining deterministic execution.

---

# Open-Source RTL Validation

ChipLens validates portions of its backend using publicly available RTL designs.

Current validation includes examples derived from:

- PicoRV32
- SERV

These designs are used exclusively for regression testing and architectural validation.

ChipLens is an independent project and is not affiliated with these repositories.

---

# Development Workflow

Every major feature follows a common engineering workflow.

```text
Feature Proposal
        │
        ▼
Architecture Design
        │
        ▼
Implementation
        │
        ▼
Automated Tests
        │
        ▼
Benchmark Validation
        │
        ▼
Documentation
        │
        ▼
Merge
```

Every subsystem should remain independently testable and maintainable.

---

# Documentation

Project documentation is organized into the following categories:

- Architecture
- Workspace
- RTL Language Infrastructure
- Verification Framework
- Backend Frameworks
- Research Notes
- Development Guides
- Future Roadmap

Additional documentation will continue to evolve alongside the platform.

# Compiler-Inspired Verification Framework

ChipLens investigates an alternative approach to RTL verification inspired by modern compiler architecture.

Instead of treating verification as a single execution step, ChipLens decomposes reasoning into a sequence of deterministic semantic transformations.

Each stage performs one well-defined engineering responsibility before passing immutable intermediate representations to the next stage.

This architecture emphasizes:

- Separation of concerns
- Explainability
- Deterministic execution
- Extensibility
- Testability
- Long-term maintainability

---

# Verification Pipeline

The current verification architecture follows a staged pipeline.

```text
                   RTL Source
                        │
                        ▼
               Lexical Analysis
                        │
                        ▼
                    Parsing
                        │
                        ▼
             Abstract Syntax Tree
                        │
                        ▼
                 Semantic Analysis
                        │
                        ▼
               Design Intelligence
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

Rather than concentrating all verification logic into a single component, each stage contributes specialized knowledge to the overall reasoning process.

---

# Backend Frameworks

ChipLens currently contains a collection of modular backend frameworks.

| Framework | Responsibility |
|-----------|----------------|
| Design Intelligence | Structural RTL understanding |
| Semantic Analysis | Semantic reasoning |
| Property Inference | Candidate assertion generation |
| Property Ranking | Prioritization of inferred properties |
| Property Emission | Backend-independent property generation |
| Explainability | Human-readable reasoning |
| Verification Planning | Strategy generation |
| Coverage Intelligence | Coverage interpretation |
| Diagnostics Intelligence | Root-cause analysis |
| Counterexample Analysis | Trace interpretation |
| Repair Planning | Engineering recommendations |
| Verification Orchestrator | Pipeline coordination |
| Benchmark Framework | Performance evaluation |
| Formal Backend Layer | External verification integration |

Each framework owns one clearly defined engineering responsibility and communicates through structured models rather than shared mutable state.

---

# Property Inference

Property inference is one of the primary research directions within ChipLens.

Rather than relying on manually written assertions alone, the platform investigates techniques for generating candidate verification properties directly from RTL structure and semantics.

Current property providers include:

| Provider | Domain |
|----------|--------|
| Arithmetic | Arithmetic logic |
| Counter | Counter behaviour |
| FSM | Finite State Machines |
| Handshake | Communication protocols |
| Memory | Memory correctness |
| Register | Register semantics |
| Reset | Reset sequencing |
| Safety | Generic safety properties |

Additional providers can be integrated without modifying the existing verification pipeline.

---

# Semantic Analysis

Semantic analysis transforms parsed RTL into engineering knowledge.

Current semantic models include:

- Module hierarchy
- Signal connectivity
- Driver relationships
- Sequential elements
- Combinational logic
- Clock domains
- Reset domains
- FSM candidates
- Structural dependencies

This semantic representation provides the foundation for diagnostics, property inference, explainability, and future language tooling.

---

# Explainability

ChipLens treats explainability as a first-class architectural concern.

Instead of producing assertions or diagnostics alone, backend frameworks preserve semantic evidence describing *why* engineering conclusions were reached.

This supports:

- Human-readable verification reports
- Engineering documentation
- Design review
- AI-assisted explanations
- Research reproducibility

Explainability improves trust in automated reasoning while making verification outputs easier to understand.

---

# Diagnostics Intelligence

Diagnostics are generated through semantic reasoning rather than isolated syntax checks.

Current investigations include:

- Structural inconsistencies
- Property generation issues
- Coverage interpretation
- Verification planning
- Semantic evidence analysis
- Potential repair opportunities

Future work will extend diagnostics to include:

- Clock-domain analysis
- Reset-domain analysis
- Incremental semantic diagnostics
- Cross-module reasoning
- Interactive engineering reports

---

# Repair Planning

Repair Planning investigates potential engineering improvements after diagnostics complete.

Current research focuses on:

- Candidate repair generation
- Verification refinement
- Engineering recommendations
- Explainable design improvements

The repair planner is advisory.

ChipLens intentionally avoids automatic RTL modification.

The engineer remains responsible for design decisions.

---

# Benchmark Framework

ChipLens includes a benchmark framework for evaluating backend behaviour under consistent conditions.

Current benchmark stages include:

- RTL loading
- Parsing
- Semantic analysis
- Property inference
- Coverage reasoning
- Diagnostics
- Repair planning

The benchmark framework enables objective evaluation of architectural improvements and research experiments.

---

# AI & Natural Language Research

ChipLens also contains an experimental Natural Language Pipeline.

Current experimental services include:

- RTL Generator
- Testbench Generator
- Explanation Engine
- Intent Extractor
- FSM Builder
- Quality Analyzer
- Pipeline Orchestrator

These services investigate AI-assisted RTL engineering but remain intentionally separated from the production workbench while research continues.

This separation ensures that experimental work can evolve independently without affecting deterministic engineering workflows.

---

# Validation Strategy

ChipLens validates its architecture through multiple complementary approaches.

## Automated Regression Testing

Every major subsystem is accompanied by regression tests whenever practical.

Current project metrics:

| Metric | Value |
|---------|------:|
| Automated Tests | **4,429 Passing** |
| Test Failures | **0** |
| Skipped Tests | **3** |

---

## Open-Source RTL Validation

The verification framework is evaluated using publicly available RTL designs.

Current validation includes examples derived from:

- PicoRV32
- SERV

These designs are used solely for architectural validation and regression testing.

ChipLens is an independent project and is not affiliated with these repositories.

---

## Deterministic Execution

Whenever practical, identical RTL inputs should produce identical semantic outputs.

Deterministic execution improves:

- Reproducibility
- Testing
- Benchmarking
- Explainability

---

# Research Contributions

ChipLens currently explores several complementary research directions.

### RTL Language Infrastructure

- Parsing
- Semantic analysis
- Symbol management
- Navigation services
- Structural understanding

---

### Verification

- Compiler-inspired verification pipelines
- Property inference
- Verification planning
- Explainable verification

---

### Engineering Productivity

- Unified desktop workbench
- Workspace architecture
- Integrated diagnostics
- Engineering navigation
- Project organization

---

### AI-Assisted Hardware Engineering

Experimental investigations include:

- RTL generation
- Testbench generation
- Design explanation
- Natural-language interfaces
- Engineering assistants

These research directions are intentionally modular so that future work can evolve without disrupting the production platform.

# Implementation Status

ChipLens is under active development.

The project combines a production-quality desktop engineering foundation with several advanced research-oriented subsystems. The table below summarizes the current implementation status of major components.

| Component | Status |
|-----------|--------|
| Desktop Engineering Workbench | ✅ Stable Foundation |
| Workspace Engine | ✅ Stable Foundation |
| Project Explorer | ✅ Stable |
| RTL Editor | 🟡 Active Development |
| RTL Tokenizer | ✅ Stable |
| Syntax Highlighting | 🟡 Initial Implementation |
| Outline Engine | ✅ Stable |
| Symbol Navigation | 🟡 Active Development |
| Global Search | ✅ Stable |
| Command Palette | ✅ Stable |
| Project System | 🟡 Active Development |
| Verification Framework | ✅ Stable Foundation |
| Property Inference | ✅ Stable Foundation |
| Diagnostics Framework | ✅ Stable Foundation |
| Explainability Framework | ✅ Stable Foundation |
| Coverage Intelligence | ✅ Stable Foundation |
| Repair Planning | ✅ Stable Foundation |
| Benchmark Framework | ✅ Stable |
| Natural Language Pipeline | 🧪 Experimental |
| Verilog Parser | 🚧 Planned Expansion |
| SystemVerilog Support | 🚧 Planned |
| Waveform Visualization | 🚧 Planned |
| Verification Dashboard | 🚧 Planned |
| Plugin System | 🚧 Planned |

---

# Roadmap

Development follows architecture-driven milestones rather than feature-driven releases.

---

## Phase I — Desktop Engineering Foundation

**Status:** ✅ Largely Complete

Delivered capabilities include:

- Desktop workbench
- Project explorer
- Multi-panel workspace
- RTL editor foundation
- Outline engine
- Command palette
- Search infrastructure
- Problems panel
- Output panel
- Workspace controller
- Responsive layouts

---

## Phase II — RTL Language Infrastructure

**Status:** 🟡 Active Development

Current focus:

- Parser improvements
- Symbol indexing
- Navigation
- Semantic highlighting
- Incremental language services
- Cross-reference infrastructure

Goal:

Transform ChipLens into a language-aware RTL engineering environment.

---

## Phase III — Engineering Intelligence

**Status:** 🚧 Planned

Focus areas:

- Module hierarchy visualization
- Signal dependency graphs
- Clock-domain analysis
- Reset-domain analysis
- Structural metrics
- FSM visualization
- Engineering insights

---

## Phase IV — Verification Workspace

**Status:** 🚧 Planned

Focus areas:

- Verification sessions
- Coverage visualization
- Assertion explorer
- Counterexample inspection
- Waveform integration
- Verification dashboards

---

## Phase V — AI-Assisted Engineering

**Status:** 🧪 Research

Research topics include:

- RTL generation
- Testbench generation
- Engineering documentation
- RTL explanation
- Design review assistance
- Natural-language engineering workflows

Experimental AI modules already exist within the repository and will be integrated into the workbench as the language infrastructure matures.

---

# Performance Goals

ChipLens aims to remain responsive even for large RTL projects.

Long-term engineering targets include:

| Area | Target |
|------|--------|
| Project Opening | < 2 s |
| Workspace Restore | < 1 s |
| Global Search | < 100 ms |
| Symbol Navigation | Near Instant |
| Editor Response | < 16 ms |
| Large Projects | 5,000+ RTL files |

These goals serve as architectural targets rather than release guarantees.

---

# Engineering Principles

ChipLens follows a small set of principles that influence every architectural decision.

## Engineering Before Features

Features are introduced only when they contribute meaningfully to RTL engineering workflows.

---

## Modularity

Subsystems should own one responsibility and evolve independently.

---

## Determinism

Whenever practical, identical RTL inputs should produce identical engineering outputs.

---

## Testability

New architectural milestones should include automated regression tests.

---

## Extensibility

Future language services, verification engines, visualization tools, and AI components should integrate without major architectural redesign.

---

# Contributing

Contributions are welcome.

Areas where contributors can have immediate impact include:

### Desktop Engineering

- Workspace Engine
- RTL Editor
- Navigation
- Desktop UX
- Performance

---

### RTL Language Infrastructure

- Parsing
- Symbol indexing
- Language services
- Semantic analysis
- Navigation

---

### Verification

- Property providers
- Diagnostics
- Coverage reasoning
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

## Development Workflow

Every major contribution should follow the same engineering workflow.

```text
Architecture Design
        │
        ▼
Implementation
        │
        ▼
Automated Tests
        │
        ▼
Benchmark Validation
        │
        ▼
Documentation
        │
        ▼
Review
        │
        ▼
Merge
```

Maintaining architectural clarity is prioritized over rapid feature addition.

---

# Citation

If ChipLens contributes to your research, teaching, or publications, please cite the repository.

```text
ChipLens

An Extensible RTL Engineering Platform

GitHub Repository

https://github.com/<YOUR_USERNAME>/ChipLens
```

A formal academic citation (BibTeX / DOI) may be introduced in future releases.

---

# License

ChipLens is released under the MIT License.

See the LICENSE file for additional information.

---

# Acknowledgements

ChipLens has been influenced by many outstanding engineering tools and research communities, including:

- LLVM
- Visual Studio Code
- JetBrains IDEs
- OpenROAD
- Yosys
- SymbiYosys
- Flutter
- Dart
- PicoRV32
- SERV

ChipLens is an independent open-source project and is not affiliated with or endorsed by any of the above.

---

# Project Philosophy

ChipLens began as an investigation into compiler-inspired RTL verification.

As development progressed, the project expanded into a broader vision: an extensible engineering platform that combines desktop tooling, RTL language infrastructure, verification research, and future AI-assisted workflows.

Rather than replacing existing EDA tools, ChipLens explores how modern software engineering principles—including language tooling, compiler architecture, modular design, immutable models, and explainable automation—can complement traditional hardware engineering workflows.

The project continues to evolve incrementally, with every milestone guided by three core values:

- **Engineering Rigor**
- **Architectural Clarity**
- **Honest, Incremental Progress**

By combining practical engineering with long-term research, ChipLens aims to provide a foundation for exploring the next generation of RTL development tools.

---

<div align="center">

### Built with Flutter • Dart • Engineering Curiosity

If you find ChipLens interesting, consider starring the repository and following its development.

</div>
