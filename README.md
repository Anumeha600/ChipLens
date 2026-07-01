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

ChipLens Lite is a **compiler-inspired RTL engineering platform** that unifies parsing, semantic analysis, property inference, formal verification, explainability and reproducible research into a single engineering workflow.

Instead of treating RTL as plain text, ChipLens constructs a rich semantic representation of a hardware design and reuses that representation throughout the verification pipeline.

The project has two complementary goals:

- **Engineering Platform** — an integrated desktop workbench for RTL development and verification.
- **Research Platform** — a reproducible framework for investigating compiler-inspired verification methodologies.

---

# Why ChipLens?

Modern RTL verification is fragmented across multiple independent tools.

A typical workflow requires engineers to:

- Parse RTL
- Run lint
- Understand hierarchy
- Write SystemVerilog Assertions manually
- Execute formal verification
- Interpret counterexamples
- Collect experimental results

ChipLens brings these stages together through a deterministic semantic pipeline.

```

```
RTL Source
      │
      ▼
Parser
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
Formal Verification
      │
      ▼
Research Artifacts
```

```markdown
The same semantic representation powers

- navigation
- diagnostics
- dependency analysis
- property generation
- verification
- explainability
- evaluation

reducing duplicated analysis across the engineering workflow.

# Architecture

ChipLens follows a compiler-inspired architecture where each stage transforms RTL into progressively richer semantic information.

```

RTL Source

↓

Parser

↓

Abstract Syntax Tree

↓

Symbol Table

↓

Semantic Analysis

↓

Design Intelligence

↓

Property Inference

↓

Formal Verification

↓

Evaluation

↓

Research Artifacts

```

The architecture separates parsing, semantic reasoning, verification and evaluation into reusable, deterministic stages.

---

# Core Capabilities

| Capability | Status |
|------------|--------|
| RTL Parser | ✅ |
| Abstract Syntax Tree | ✅ |
| Symbol Table | ✅ |
| Semantic Analysis | ✅ |
| Dependency Analysis | ✅ |
| Design Intelligence | ✅ |
| Property Inference | ✅ |
| Formal Verification | ✅ |
| Navigation Services | ✅ |
| Evaluation Framework | ✅ |
| Benchmark Infrastructure | ✅ |
| Research Artifact Generation | ✅ |

---

## Technology Stack

| Layer | Technology |
|--------|------------|
| Desktop IDE | Flutter 3.x |
| Core Pipeline | Dart |
| Backend API | Node.js + Express |
| Parser | Tree-sitter |
| Formal Verification | SymbiYosys |
| Simulation | Icarus Verilog |
| Lint | Verilator |
| Synthesis | Yosys |

# Research Platform

ChipLens is designed as a research platform rather than only an engineering IDE.

The platform emphasizes

- deterministic analysis
- semantic reasoning
- reproducible evaluation
- automated experiment generation
- evidence collection

rather than simply integrating existing RTL tools.

---

## Research Infrastructure

| Component | Status |
|-----------|--------|
| Evaluation Framework | ✅ |
| Benchmark Management | ✅ |
| Benchmark Corpus | ✅ |
| Research Artifact Generation | ✅ |
| Experiment Metadata | ✅ |
| CSV Export | ✅ |
| JSON Export | ✅ |
| Markdown Export | ✅ |

---

## Benchmark Infrastructure

Current benchmark corpus

| Metric | Value |
|--------|------:|
| Benchmark Designs | 13 |
| Categories | 7 |
| Evaluation Suite | 8 |
| Research Suites | 4 |
| Estimated RTL LOC | 13,490 |

---

## Research Artifact Generation

Each evaluation automatically produces structured research outputs.

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

These artifacts are designed to support reproducible experiments and future statistical analysis.

# Engineering Workbench

ChipLens provides a desktop-first engineering environment inspired by modern IDE workflows.

Major components include

- Activity Bar
- Workspace Explorer
- RTL Editor
- Outline View
- Symbol Explorer
- Problems Panel
- Output Panel
- Command Palette
- Global Search
- Go To Symbol
- Status Bar

The workbench follows immutable MVVM architecture and is designed primarily for desktop platforms.

# Current Status

| Metric | Value |
|--------|------:|
| Passing Tests | **6,404** |
| Test Files | **173** |
| Analyzer Errors | **0** |
| Pipeline Stages | **14** |
| Property Providers | **8** |
| Benchmark Designs | **13** |
| Benchmark Categories | **7** |

---

## Repository Structure

```

backend/
Node.js REST API

frontend/
Flutter Desktop IDE

benchmarks/
Research benchmark corpus

docs/
Architecture and documentation

research_output/
Generated experiment artifacts

```

---

## Getting Started

### Backend

```bash
cd backend
npm install
node index.js
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### Tests

```bash
flutter test
```

### Analyzer

```bash
flutter analyze
```
# Research Roadmap

## Completed

- Compiler-inspired parsing pipeline
- Semantic analysis engine
- Property inference
- Formal verification orchestration
- Evaluation framework
- Benchmark infrastructure
- Research artifact generation

---

## In Progress

- Large-scale benchmark evaluation
- Experimental methodology
- Statistical analysis
- Comparative evaluation
- Reproducible figures
- Research paper preparation

---

## Planned

- Large benchmark corpus
- Scalability evaluation
- Automated figure generation
- Comparative studies
- IEEE publication

---

# Publications

**Under Preparation**

> *Compiler-Inspired Semantic RTL Engineering and Verification*

---

# Citation

```bibtex
@software{chiplens2026,
  title  = {ChipLens Lite},
  author = {Paul, Anumeha},
  year   = {2026},
  note   = {Compiler-Inspired Semantic RTL Engineering and Verification Platform}
}
```

---

# License

MIT License

