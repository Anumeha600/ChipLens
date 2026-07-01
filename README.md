# ChipLens Lite

> **Compiler-Inspired Semantic RTL Engineering and Verification Platform**

**Build • Understand • Analyze • Verify RTL Designs**

<p align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Desktop-Windows%20|%20Linux%20|%20macOS-blue)
![Tests](https://img.shields.io/badge/Tests-6404%20Passing-success)
![Analyzer](https://img.shields.io/badge/flutter%20analyze-0%20Errors-success)
![License](https://img.shields.io/badge/License-MIT-green)

</p>

---

## Overview

ChipLens Lite is a **compiler-inspired RTL engineering and verification platform** that unifies parsing, semantic analysis, property inference, formal verification, explainability, and reproducible evaluation into a single workflow.

Rather than treating RTL as plain text, ChipLens constructs a reusable semantic representation of hardware designs. That semantic model is shared across navigation, dependency analysis, property inference, verification, diagnostics, and evaluation instead of repeatedly analyzing the same design in multiple independent stages.

ChipLens is being developed with two complementary goals:

- **Engineering Platform** — an integrated desktop workbench for RTL design analysis and verification.
- **Research Platform** — a reproducible framework for investigating compiler-inspired verification methodologies.

---

# Motivation

RTL verification today is typically performed using multiple disconnected tools.

A common workflow requires engineers to repeatedly switch between:

- RTL parsers
- lint tools
- simulators
- formal verification tools
- waveform viewers
- manually written SystemVerilog Assertions
- external scripts for collecting experimental results

Each tool performs its own analysis of the design, resulting in duplicated work and fragmented engineering workflows.

ChipLens investigates whether a **shared semantic representation**, inspired by modern compiler architectures, can provide a better foundation for RTL engineering and verification.

---

# Design Philosophy

ChipLens follows five core principles.

### Compiler-Inspired

RTL is treated as a structured programming language rather than plain text.

### Semantic-First

Semantic information is extracted once and reused throughout the platform.

### Deterministic

The same RTL and configuration always produce identical analysis and verification results.

### Modular

Each stage performs one well-defined task while communicating through immutable data models.

### Reproducible

Evaluation automatically generates structured research artifacts suitable for experimental studies.

---

# System Architecture

```
                     SystemVerilog RTL
                             │
                             ▼
                    Lexical Analysis
                             │
                             ▼
                          Parser
                             │
                             ▼
                 Abstract Syntax Tree (AST)
                             │
                             ▼
                     Symbol Resolution
                             │
                             ▼
                    Semantic Analysis
                             │
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
       ▼                     ▼                     ▼
 Dependency Analysis   Design Intelligence   Navigation
       │                     │                     │
       └──────────────┬──────┴──────────────┬──────┘
                      ▼                     ▼
              Property Inference     Explainability
                      │
                      ▼
            Formal Verification Engine
                      │
                      ▼
             Evaluation Framework
                      │
                      ▼
         Reproducible Research Artifacts
```

Unlike traditional RTL workflows, every stage operates on a shared semantic representation instead of independently re-analyzing the original source code.

---

# Research Direction

ChipLens is being developed around the following research question:

> **Can compiler-inspired semantic architectures improve RTL engineering workflows by enabling reusable semantic analysis across parsing, navigation, verification and property inference?**

The platform does **not** aim to replace existing EDA tools.

Instead, it investigates how semantic reasoning can complement established tools by providing a unified semantic foundation for engineering workflows and verification research.

---

# Core Capabilities

ChipLens is organized into modular subsystems that together form an end-to-end RTL engineering workflow.

Each subsystem has a single responsibility and produces structured outputs that are consumed by later stages of the pipeline.

---

## RTL Front-End

The front-end transforms SystemVerilog source into structured intermediate representations suitable for semantic reasoning.

### Features

- SystemVerilog parsing
- Abstract Syntax Tree (AST) construction
- Symbol table generation
- Source mapping
- Error recovery
- Multi-module project support

---

## Semantic Analysis

The semantic engine enriches parsed RTL with engineering knowledge required for downstream analyses.

Current analyses include:

- Signal dependency analysis
- Driver and reader identification
- Dataflow analysis
- Fan-in and fan-out computation
- Clock domain analysis
- Reset domain analysis
- FSM candidate identification
- Structural connectivity analysis

This semantic information becomes the shared foundation for navigation, diagnostics, verification and evaluation.

---

## Property Inference

ChipLens investigates semantic-driven generation of formal verification properties.

Current inference providers include:

| Provider | Purpose |
|-----------|---------|
| FSM | State transition safety |
| Handshake | Valid-ready protocol correctness |
| Counter | Counter progression and overflow |
| Register | Register stability |
| Reset | Reset correctness |
| Arithmetic | Arithmetic safety |
| Memory | Memory consistency |
| Generic Safety | Default structural properties |

Candidate properties are ranked before formal verification using engineering heuristics.

---

## Formal Verification

ChipLens integrates property generation with formal verification through a deterministic multi-stage pipeline.

Current pipeline stages include:

1. Design Intelligence
2. Evidence Extraction
3. Property Generation
4. Property Ranking
5. Property Emission
6. Verification Planning
7. Formal Verification
8. Coverage Analysis
9. Counterexample Analysis
10. Diagnostic Generation
11. Repair Planning

Each stage operates on structured semantic information rather than reparsing RTL.

---

## Navigation & Engineering Productivity

ChipLens provides semantic IDE capabilities inspired by modern software development environments.

Supported functionality includes:

- Go To Definition
- Find References
- Symbol Outline
- Project Explorer
- Workspace Search
- Diagnostics Panel
- Problems View
- Command Palette

Navigation is driven by semantic analysis rather than textual matching.

---

## Evaluation Framework

ChipLens includes an integrated evaluation framework for repeatable engineering experiments.

Current capabilities include:

- Automated benchmark execution
- Pipeline timing collection
- Verification summaries
- Benchmark reports
- Research artifact generation
- Structured CSV / JSON / Markdown export

The framework is designed to support reproducible experimentation and future statistical analysis.

---

# Technology Stack

| Layer | Technology |
|--------|------------|
| Desktop Application | Flutter 3.x |
| Core Platform | Dart |
| Backend Services | Node.js + Express |
| RTL Parsing | Tree-sitter |
| Formal Verification | SymbiYosys |
| Simulation | Icarus Verilog |
| Linting | Verilator |
| Logic Synthesis | Yosys |

---

# Current Implementation

| Component | Status |
|------------|--------|
| RTL Parsing | ✅ Complete |
| AST Construction | ✅ Complete |
| Symbol Table | ✅ Complete |
| Semantic Analysis | ✅ Complete |
| Dependency Analysis | ✅ Complete |
| Property Inference | ✅ Complete |
| Navigation Services | ✅ Complete |
| Formal Verification Pipeline | ✅ Complete |
| Evaluation Framework | ✅ Complete |
| Benchmark Infrastructure | ✅ Complete |
| Research Artifact Generation | ✅ Complete |

---

# Research Platform

ChipLens is being developed not only as an RTL engineering platform but also as a research artifact for investigating compiler-inspired verification methodologies.

The long-term objective is to evaluate how semantic reasoning can support verification workflows through reproducible experimentation rather than anecdotal examples.

---

# Research Objectives

The current research focuses on four complementary directions.

| Area | Objective |
|-------|-----------|
| Compiler-Inspired RTL Analysis | Investigate reusable semantic representations for RTL engineering |
| Property Inference | Study semantic-driven generation of formal verification properties |
| Verification Workflows | Integrate semantic analysis with formal verification engines |
| Experimental Evaluation | Build reproducible methodologies for quantitative evaluation |

---

# Experimental Infrastructure

ChipLens includes an integrated evaluation framework designed to support repeatable experiments.

Current infrastructure includes:

- Benchmark management
- Benchmark corpus
- Automated evaluation
- Experiment execution
- Structured reporting
- Research artifact generation

The platform automatically exports machine-readable datasets for downstream statistical analysis.

```
research_output/

csv/
json/
markdown/
metadata/
```

Supported export formats include:

- CSV
- JSON
- Markdown

allowing experiments to be reproduced without manual post-processing.

---

# Benchmark Infrastructure

ChipLens currently maintains two complementary benchmark collections.

### Engineering Benchmark Suite

Used for regression testing and pipeline validation.

Current coverage includes:

- Flip-Flops
- Counters
- FSMs
- Hierarchical designs
- ALUs
- Shift Registers
- Handshake protocols

These benchmarks validate the correctness of the engineering pipeline.

---

### Research Benchmark Corpus

The research corpus organizes larger open-source RTL designs for future experimental evaluation.

Current benchmark categories include:

- Educational Designs
- Communication
- Memory
- Processors
- Bus Architectures
- Control Logic
- Miscellaneous Designs

The benchmark corpus is intended to support scalability studies, comparative evaluation and reproducible experiments.

---

# Evaluation Methodology

ChipLens measures multiple aspects of the verification pipeline rather than relying on a single performance metric.

Current evaluation includes:

| Category | Examples |
|----------|----------|
| Timing | Parsing, semantic analysis, verification |
| Structural | Modules, ports, signals, instances |
| Semantic | FSMs, clock domains, reset domains |
| Verification | Generated properties, diagnostics, verification outcomes |

These measurements are exported automatically after every evaluation run.

---

# Reproducible Research

A primary design goal of ChipLens is reproducibility.

Every experiment is intended to generate structured outputs that can be archived, regenerated and incorporated into future research publications.

Typical outputs include:

```
research_output/

csv/
performance.csv
semantic.csv
verification.csv

json/
performance.json
semantic.json
verification.json

markdown/
summary.md
benchmark_report.md

metadata/
experiment.json
```

This structure enables downstream statistical analysis and automated figure generation without requiring manual data collection.

---

# Current Research Status

The engineering platform has reached the point where systematic experimental evaluation becomes the primary development focus.

Current priorities include:

- Expanding the benchmark corpus
- Large-scale experimental evaluation
- Statistical analysis
- Comparative studies
- Scalability analysis
- Preparation of research publications

Future work will focus on validating the proposed architecture through quantitative evidence rather than adding isolated software features.

---

# Engineering Workbench

ChipLens provides a desktop-first RTL engineering environment inspired by modern software IDEs.

The workbench is designed around immutable MVVM architecture and integrates engineering tools into a single workspace.

## Major Components

| Component | Purpose |
|------------|---------|
| Activity Bar | Primary workspace navigation |
| Project Explorer | RTL project and file management |
| RTL Editor | Syntax-aware editing environment |
| Outline View | Structural overview of the current design |
| Symbol Explorer | Semantic navigation |
| Problems Panel | Diagnostics and verification issues |
| Output Panel | Analysis and verification logs |
| Command Palette | Command-driven workflow |
| Global Search | Workspace-wide search |
| Status Bar | Project and verification status |

---

## Keyboard Shortcuts

| Shortcut | Action |
|-----------|--------|
| `Ctrl + P` | Quick Open |
| `Ctrl + Shift + P` | Command Palette |
| `Ctrl + Shift + F` | Global Search |
| `Ctrl + Shift + O` | Go To Symbol |
| `F12` | Go To Definition |
| `Shift + F12` | Find References |
| `Ctrl + W` | Close Editor |
| `Ctrl + B` | Toggle Explorer |

---

# Current Project Status

| Metric | Value |
|--------|------:|
| Passing Tests | **6,404** |
| Test Files | **173** |
| Analyzer Errors | **0** |
| Parser | ✅ |
| AST | ✅ |
| Semantic Analysis | ✅ |
| Verification Pipeline | ✅ |
| Benchmark Infrastructure | ✅ |
| Research Platform | ✅ |

---

# Repository Structure

```
ChipLens/
│
├── backend/            Node.js REST services
│
├── frontend/
│   ├── lib/
│   │   ├── backend/    Compiler-inspired RTL pipeline
│   │   ├── services/   Verification & engineering services
│   │   └── ui/         Desktop workbench
│   │
│   └── test/           Automated test suite
│
├── benchmarks/         Benchmark corpus
│
├── docs/               Documentation
│
└── research_output/    Generated experiment artifacts
```

---

# Documentation

Additional documentation is available in the `docs/` directory.

| Document | Description |
|-----------|-------------|
| Architecture | System architecture and design |
| Benchmarks | Benchmark infrastructure |
| Evaluation | Experimental methodology |
| Verification | Verification pipeline |
| Research | Research planning and artifacts |

---

# Getting Started

## Requirements

| Dependency | Version |
|------------|---------|
| Flutter | 3.x |
| Dart | 3.x |
| Node.js | 20+ |
| Yosys | Latest |
| Verilator | Latest |
| Icarus Verilog | Latest |
| SymbiYosys | Latest |

---

## Backend

```bash
cd backend

npm install

node index.js
```

---

## Frontend

```bash
cd frontend

flutter pub get

flutter run
```

---

## Run Tests

```bash
flutter test
```

---

## Static Analysis

```bash
flutter analyze
```

---

## Generate Research Artifacts

```dart
final report =
    await EvaluationRunner().runSuite(
        EvaluationSuite.defaults(),
    );

await EvaluationExporter.exportResearchArtifacts(
    report,
    "research_output",
);
```

Running the evaluation framework automatically produces structured CSV, JSON and Markdown artifacts that can be used for experimental analysis.

# Roadmap

ChipLens is being developed as both an engineering platform and a research platform.

The engineering foundation is largely established. Current development is focused on experimental evaluation, evidence generation and research publication.

| Milestone | Status |
|------------|--------|
| RTL Front-End | ✅ Complete |
| Semantic Analysis | ✅ Complete |
| Symbol Resolution | ✅ Complete |
| Dependency Analysis | ✅ Complete |
| Property Inference | ✅ Complete |
| Navigation Services | ✅ Complete |
| Verification Pipeline | ✅ Complete |
| Evaluation Framework | ✅ Complete |
| Benchmark Infrastructure | ✅ Complete |
| Research Artifact Generation | ✅ Complete |
| Experimental Evaluation | 🚧 In Progress |
| Statistical Analysis | 🚧 Planned |
| Comparative Evaluation | 🚧 Planned |
| Scalability Studies | 🚧 Planned |
| Research Publication | 🚧 In Preparation |

---

# Research Vision

ChipLens is intended to evolve beyond a traditional RTL development environment into a reproducible research platform for compiler-inspired hardware engineering.

Current research efforts focus on:

- Semantic representations for RTL engineering
- Compiler-inspired verification architectures
- Semantic-driven property inference
- Explainable verification workflows
- Reproducible experimental methodologies

Future work will emphasize quantitative evaluation using benchmark-driven experimentation, statistical analysis and comparative studies.

The long-term objective is to produce a reusable research platform capable of supporting academic publications as well as practical RTL engineering workflows.

---

# Contributing

Contributions are welcome.

Areas of particular interest include:

- RTL parsing
- Semantic analysis
- Formal verification
- Property inference
- Benchmark development
- Experimental evaluation
- Documentation
- Testing

If you are interested in collaborating on compiler-inspired RTL engineering research, please open an issue or submit a pull request.

---

# Citation

If ChipLens contributes to your research, please consider citing it.

```bibtex
@software{paul2026chiplens,
  author = {Anumeha Paul},
  title = {ChipLens Lite: Compiler-Inspired Semantic RTL Engineering and Verification Platform},
  year = {2026},
  url = {https://github.com/Anumeha600/ChipLens},
  note = {Research platform for semantic RTL engineering, verification and reproducible evaluation}
}
```

---

# License

This project is released under the **MIT License**.

See the `LICENSE` file for additional details.

---

<p align="center">

**ChipLens Lite**

*Compiler-Inspired Semantic RTL Engineering and Verification Platform*

**Built for Engineering. Designed for Research.**

</p>
