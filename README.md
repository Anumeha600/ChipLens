# ChipLens

### Compiler-Inspired RTL Engineering Platform

> **Build • Understand • Analyze • Verify RTL Designs**

<p align="center">
  <img src="docs/images/workbench.png" width="95%">
</p>

<p align="center">

![Platform](https://img.shields.io/badge/Desktop-Windows%20%7C%20Linux%20%7C%20macOS-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Tests](https://img.shields.io/badge/Tests-5289+-brightgreen)
![Architecture](https://img.shields.io/badge/Compiler--Inspired-success)
![License](https://img.shields.io/badge/License-MIT-blue)

</p>

---

ChipLens is an open-source RTL engineering platform that applies compiler-inspired architecture to hardware design.

Instead of treating RTL verification as a collection of independent tools, ChipLens builds a shared language infrastructure—Parser → AST → Symbol Table → Semantic Model—that powers navigation, diagnostics, verification, and engineering analysis from a single semantic understanding of the design.

---

## What is ChipLens?

ChipLens is an open-source RTL engineering platform that explores a compiler-inspired approach to hardware development.

Instead of treating RTL verification as a collection of disconnected tools, ChipLens builds a shared language infrastructure that transforms Verilog designs into structured semantic representations. These representations become the foundation for navigation, diagnostics, verification planning, property generation, and future engineering intelligence.

The desktop workbench is one interface to this platform. At its core, ChipLens is a language and verification architecture designed for extensibility, explainability, and experimentation.

---

# Why ChipLens?

Modern RTL development typically involves multiple independent tools.

```

RTL Source

↓

Editor

↓

Lint

↓

Simulation

↓

Waveforms

↓

Formal Verification

↓

Coverage

↓

Reports

```

Each tool performs its own analysis with limited understanding of the overall design.

ChipLens investigates a different architecture.

Rather than repeatedly interpreting the same source code, it constructs shared language representations that every subsystem can consume.

```

RTL Source

↓

Parser

↓

Abstract Syntax Tree

↓

Symbol Table

↓

Semantic Model

↓

Navigation

Diagnostics

Verification

Analysis

Engineering Workspace

```

This architecture enables multiple engineering capabilities to operate on the same structured understanding of the design rather than repeatedly processing raw source text.

---

# Design Philosophy

ChipLens is built around five engineering principles.

### Language First

RTL is treated as a programming language rather than plain text.

Compiler-inspired language infrastructure forms the foundation of every subsystem.

---

### Semantic Engineering

Every major capability should operate on structured semantic information instead of regular expressions or ad hoc parsing.

---

### Verification Intelligence

Verification should become an engineering workflow rather than a sequence of isolated tool invocations.

Property generation, planning, diagnostics, and analysis share a common semantic foundation.

---

### Explainability

Engineering tools should explain *why* results are produced.

Every diagnostic, property, or recommendation should be traceable back to the underlying RTL semantics.

---

### Modular Architecture

Each subsystem has a single responsibility.

Parser.

AST.

Symbol Table.

Semantic Analysis.

Verification.

Workspace.

Each layer is independently testable and replaceable.

---

# Current Project Status

ChipLens is under active development.

The project currently includes a functional engineering workbench together with a growing compiler-inspired language platform.

| Component | Status |
|-----------|--------|
| Desktop Engineering Workbench | ✅ Implemented |
| Multi-panel IDE Shell | ✅ Implemented |
| Workspace Explorer | ✅ Implemented |
| Verilog Parser | ✅ Implemented |
| Abstract Syntax Tree | ✅ Implemented |
| Symbol Table | ✅ Implemented |
| Semantic Model | ✅ Implemented |
| Navigation Services | 🚧 In Progress |
| Verification Pipeline | ✅ Implemented |
| Property Generation | ✅ Implemented |
| Evaluation Framework | 🚧 Planned |
| Benchmark Suite | 🚧 Planned |

---

# Why this architecture?

Many RTL tools perform their own parsing, indexing, and analysis independently.

ChipLens instead adopts a layered architecture similar to modern compiler platforms.

Every subsystem builds upon the same language foundation.

This reduces duplication, improves consistency, and enables new capabilities to be added without redesigning the entire system.

# Architecture

ChipLens is organized as a layered engineering platform.

Each subsystem has a clearly defined responsibility and communicates only through stable interfaces. Higher layers consume services from lower layers, while lower layers remain independent of user interface concerns.

```

                                    ChipLens

┌──────────────────────────────────────────────────────────────────────────────┐
│                      Desktop Engineering Workbench                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                     Navigation • Diagnostics • Verification                  │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            Semantic Model                                    │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              Symbol Table                                    │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Abstract Syntax Tree (AST)                            │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           Verilog Parser                                     │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              RTL Source                                      │
└──────────────────────────────────────────────────────────────────────────────┘

```

Every layer has a single responsibility.

No subsystem bypasses the language pipeline.

This architecture allows future capabilities to reuse the same semantic understanding instead of implementing their own parsing logic.

---

# Language Platform

The language platform is the foundation of ChipLens.

Rather than treating Verilog as plain text, ChipLens progressively transforms source code into increasingly rich representations.

```

RTL Source

↓

Lexical & Syntactic Analysis

↓

Parser

↓

Abstract Syntax Tree

↓

Symbol Table

↓

Semantic Model

↓

Language Services

↓

Engineering Features

```

Each stage exists to answer a different class of engineering questions.

| Layer | Responsibility |
|--------|----------------|
| Parser | Converts Verilog source into structured language constructs. |
| AST | Represents the hierarchical structure of the design. |
| Symbol Table | Resolves declarations, references, and scopes. |
| Semantic Model | Captures design meaning beyond syntax. |
| Language Services | Provides reusable capabilities such as navigation, diagnostics, and future analysis tools. |

---

# Compiler-Inspired Pipeline

ChipLens borrows architectural principles from modern compiler infrastructures.

Instead of allowing every subsystem to interpret RTL independently, all downstream components consume common language representations.

```

RTL

↓

Parser

↓

AST

↓

Symbol Table

↓

Semantic Model

↓

Language Services

├── Go To Definition

├── Find References

├── Rename Symbol

├── Hover Information

├── Diagnostics

├── Verification Planning

├── Property Generation

└── Engineering Analysis

```

This layered approach reduces duplication and provides a single source of truth for language understanding.

---

# Verification Architecture

ChipLens separates language understanding from verification.

Verification components consume semantic information rather than directly processing source text.

```

Semantic Model

↓

Verification Planner

↓

Property Providers

↓

Property Ranking

↓

Verification Pipeline

↓

Formal Engines

↓

Diagnostics

↓

Reports

```

This separation allows verification strategies to evolve independently from the parser or workspace.

---

# Engineering Workspace

The desktop workbench is the primary interface to the platform.

Unlike traditional file explorers, the workspace is organized around the engineering workflow rather than the filesystem.

```

ChipLens Workspace

├── RTL

├── Verification

├── Analysis

├── Evaluation

├── Reports

└── Settings

```

Each workspace section represents a stage of the verification process instead of a directory hierarchy.

---

# Backend Architecture

ChipLens separates frontend responsibilities from backend tooling.

```

Flutter Workbench

↓

Language Platform

↓

Verification Pipeline

↓

Backend Services

↓

Verilator

Yosys

SymbiYosys

Icarus Verilog

Tree-sitter

```

External tools remain replaceable.

The frontend communicates through stable service interfaces rather than tool-specific APIs.

---

# Design Principles

Every subsystem in ChipLens follows the same architectural rules.

### Layered Architecture

Each layer depends only on the layer directly below it.

---

### Immutable Models

Language objects remain immutable after construction.

This simplifies reasoning, testing, and concurrent analysis.

---

### Single Responsibility

Parser.

AST.

Symbol Table.

Semantic Model.

Workspace.

Verification.

Each subsystem has one clearly defined purpose.

---

### Explainable Engineering

Engineering results should be reproducible and understandable.

ChipLens emphasizes traceability from RTL source to diagnostics and verification results.

---

### Extensibility

The architecture is designed to accommodate additional language services and verification capabilities without restructuring the existing pipeline.

# Project Structure

The repository is organized around architectural responsibilities rather than implementation convenience.

```

frontend/

├── backend/

│ ├── parser/

│ ├── ast/

│ ├── symbol_table/

│ ├── semantic/

│ ├── verification/

│ ├── analysis/

│ └── services/

│

├── ui/

│ ├── workbench/

│ ├── navigation/

│ ├── explorer/

│ ├── panels/

│ └── shared/

│

├── core/

├── models/

├── utilities/

└── test/

```

The architecture deliberately separates language infrastructure, engineering intelligence, verification logic, and user interface components.

---

# Language Infrastructure

The language platform is implemented as a sequence of independent compiler-inspired stages.

```

RTL Source

↓

Parser

↓

AST Builder

↓

Abstract Syntax Tree

↓

Symbol Table Builder

↓

Symbol Table

↓

Semantic Model

↓

Language Services

```

Each stage consumes only the output of the previous stage.

This minimizes coupling and allows future improvements without redesigning the entire platform.

---

# Current Language Infrastructure

| Component | Purpose | Status |
|------------|---------|--------|
| Verilog Parser | Parses RTL source into structured representations | ✅ |
| AST Builder | Builds immutable syntax tree | ✅ |
| AST Model | Represents hardware syntax | ✅ |
| Symbol Table | Compiler-style name resolution | ✅ |
| Semantic Model | Captures design semantics | ✅ |
| Navigation Services | Language-aware navigation | 🚧 |
| Diagnostics Engine | Semantic diagnostics | 🚧 |

---

# Verification Pipeline

ChipLens separates language understanding from verification.

```

RTL

↓

Language Platform

↓

Semantic Model

↓

Verification Planning

↓

Property Providers

↓

Property Ranking

↓

Formal Verification

↓

Engineering Reports

```

Each verification stage operates on structured semantic information instead of repeatedly parsing source code.

---

# Testing Philosophy

Reliability is treated as a core architectural requirement.

Every subsystem is validated independently before becoming part of the larger platform.

Current automated validation includes:

- Unit tests
- Widget tests
- Integration tests
- Regression tests
- Immutable model validation
- Parser validation
- Symbol resolution tests
- Semantic model tests
- Workspace tests

Current status:

| Metric | Value |
|---------|-------|
| Automated Tests | **5,289+** |
| Failing Tests | **0** |
| Regression Coverage | Continuous |
| Static Analysis | Zero analyzer errors (excluding existing informational warnings) |

Testing accompanies architectural development rather than being added after implementation.

---

# Engineering Principles

ChipLens follows a small number of architectural principles consistently throughout the codebase.

## Layered Architecture

Every subsystem depends only on lower architectural layers.

```

Workspace

↓

Language Services

↓

Semantic Model

↓

Symbol Table

↓

AST

↓

Parser

```

---

## Immutable State

Core language structures remain immutable after construction.

Benefits include:

- deterministic behaviour
- simpler reasoning
- easier testing
- safer concurrent analysis
- predictable transformations

---

## Single Responsibility

Every major subsystem owns one responsibility.

| Component | Responsibility |
|-----------|----------------|
| Parser | Parse RTL source |
| AST | Represent syntax |
| Symbol Table | Resolve declarations and references |
| Semantic Model | Represent design meaning |
| Verification Pipeline | Coordinate verification |
| Workbench | Present engineering workflows |

---

## Explainable Engineering

Engineering results should be understandable.

Rather than producing opaque outputs, ChipLens aims to expose how language analysis and verification decisions are derived.

This principle guides future work on diagnostics, property generation, and verification planning.

---

# Development Roadmap

Development is organized according to architectural dependencies rather than isolated feature additions.

```

Language Platform

        │

        ▼

Semantic Analysis

        │

        ▼

Language Services

        │

        ▼

Verification Intelligence

        │

        ▼

Evaluation Framework

        │

        ▼

Public Release

```

Current focus:

- Expanding semantic analysis
- Language-aware navigation
- Verification intelligence
- Evaluation and benchmarking
- Engineering workspace refinement

---

# Current Progress

| Area | Status |
|------|--------|
| Engineering Workspace | ✅ Active |
| Compiler Infrastructure | ✅ Active |
| Parser | ✅ Implemented |
| AST | ✅ Implemented |
| Symbol Table | ✅ Implemented |
| Semantic Model | ✅ Implemented |
| Navigation | 🚧 In Progress |
| Verification Intelligence | 🚧 In Progress |
| Evaluation Framework | 📋 Planned |
| Benchmark Suite | 📋 Planned |

---

# Research Direction

ChipLens is also intended to serve as a platform for exploring compiler-inspired approaches to RTL engineering.

Current areas of investigation include:

- Semantic representations for RTL
- Language-aware verification workflows
- Explainable engineering diagnostics
- Property generation from semantic information
- Verification planning
- Engineering productivity through shared language infrastructure

The emphasis is on building reusable language infrastructure that can support future experimentation and evaluation.

# Getting Started

## Prerequisites

ChipLens currently targets desktop platforms.

Recommended environment:

| Requirement | Version |
|------------|---------|
| Flutter | 3.x |
| Dart | 3.x |
| Git | Latest |
| Node.js | LTS |
| Platform | Windows, Linux, macOS |

Optional backend integrations:

- Verilator
- Yosys
- SymbiYosys
- Icarus Verilog

---

## Clone

```bash
git clone https://github.com/<username>/ChipLens.git

cd ChipLens/frontend
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run

```bash
flutter run -d windows
```

---

## Analyze

```bash
flutter analyze
```

---

## Test

```bash
flutter test
```

The project maintains an extensive automated test suite to ensure architectural correctness and regression protection.

---

# Documentation

Detailed documentation is available in the `docs/` directory.

| Document | Description |
|-----------|-------------|
| ARCHITECTURE.md | Platform architecture |
| LANGUAGE_PLATFORM.md | Parser, AST, Symbol Table, Semantic Model |
| VERIFICATION.md | Verification pipeline |
| WORKBENCH.md | Desktop engineering workspace |
| BENCHMARKS.md | Evaluation methodology and results |
| CONTRIBUTING.md | Development guidelines |

---

# Current Development Priorities

The immediate focus is strengthening the language platform.

Current priorities include:

- Language services
- Semantic diagnostics
- Navigation
- Verification intelligence
- Evaluation framework
- Public benchmark suite

Future work will build on these foundations rather than introducing unrelated features.

---

# Contributing

Contributions are welcome.

Areas of particular interest include:

- RTL language infrastructure
- Parser improvements
- Semantic analysis
- Verification workflows
- Formal verification
- Engineering user experience
- Documentation
- Testing
- Performance optimization

Please open an issue before beginning significant architectural changes.

---

# Project Goals

ChipLens is designed around a small number of long-term objectives.

- Build reusable RTL language infrastructure.
- Improve engineering workflows through shared semantic analysis.
- Explore compiler-inspired approaches to verification.
- Provide explainable engineering tooling.
- Support reproducible experimentation and evaluation.

These goals guide architectural decisions throughout the project.

---

# Project Status

ChipLens is under active development.

Implemented:

- Desktop engineering workspace
- Compiler-inspired architecture
- Verilog parser
- Abstract Syntax Tree
- Symbol Table
- Semantic Model
- Verification pipeline
- Property generation
- Extensive automated testing

Currently in progress:

- Language services
- Navigation
- Semantic diagnostics
- Verification intelligence

Planned:

- Evaluation framework
- Public benchmark corpus
- Performance measurements
- Advanced engineering analysis

The roadmap intentionally prioritizes architectural depth over feature breadth.

---

# Acknowledgements

ChipLens builds upon the work of numerous open-source projects and communities.

Notable technologies include:

- Flutter
- Dart
- Tree-sitter
- Verilator
- Yosys
- SymbiYosys
- Icarus Verilog

Their contributions make modern hardware tooling and experimentation possible.

---

# License

This project is released under the MIT License.

See the LICENSE file for details.

---

# Citation

If ChipLens contributes to your research or engineering work, please cite the repository.

```text
ChipLens

Compiler-Inspired RTL Engineering Platform

GitHub:

https://github.com/<username>/ChipLens
```

---

<p align="center">

Built with a passion for language engineering, RTL verification, and open-source software.

</p>
