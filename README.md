# ChipLens

> **A compiler-inspired RTL verification platform for intelligent hardware design analysis and explainable formal verification.**

ChipLens is a research-oriented RTL verification platform that combines compiler-inspired program analysis, semantic reasoning, automated property synthesis, deterministic property ranking, property emission, formal verification, coverage analysis, diagnostics, and repair assistance into a unified verification workflow for digital hardware designs.

Unlike conventional verification flows that invoke verification tools directly, ChipLens incrementally constructs an internal semantic model of RTL designs before generating formal verification artifacts. The platform extracts structural and behavioral knowledge, synthesizes candidate verification properties, prioritizes them using an explainable ranking engine, emits engine-independent formal properties, and prepares them for downstream formal verification.

ChipLens is designed as a modular reasoning pipeline that investigates how compiler techniques, semantic analysis, and formal verification can be integrated into an explainable verification assistant for hardware engineers and researchers.

---

# Why ChipLens?

Modern RTL verification typically requires engineers to combine multiple independent tools for parsing, simulation, formal verification, coverage analysis, debugging, and repair. Although these tools are individually powerful, understanding their results and deciding the next verification step remains largely a manual process.

ChipLens explores a different approach.

Instead of immediately generating assertions or invoking formal engines, ChipLens first develops an internal understanding of the hardware design through a sequence of reasoning stages. Each stage enriches the available information before passing immutable results to the next stage, enabling explainable verification decisions while preserving a clean, extensible architecture.

The long-term vision is to build an intelligent verification assistant capable of supporting engineers throughout the complete RTL verification lifecycle—from design understanding to verification planning, diagnostics, coverage analysis, and repair.

---

# Verification Pipeline

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
Formal Verification
     │
     ▼
Coverage Analysis
     │
     ▼
Diagnostics
     │
     ▼
Repair Suggestions
```

---

# Key Features

- RTL Parsing and Structural Analysis
- Design Intelligence Framework
- Semantic Evidence Extraction
- Candidate Property Synthesis
- Deterministic Property Ranking
- Engine-Independent Property Emitter
- Formal Verification Framework
- Coverage Analysis
- Diagnostics Engine
- Automated Repair Suggestions
- Explainable Verification Pipeline
- Modular Layered Architecture
- 770+ Automated Tests

---

# Current Progress

## ✅ Completed

- RTL Parsing Infrastructure
- Design Intelligence Framework
- Property Inference Framework
- Semantic Evidence Framework
- Candidate Property Synthesizer
- Property Ranking Engine
- Property Emitter
- Formal Verification Framework
- Coverage Analysis
- Diagnostics Framework
- Repair Framework
- Flutter Desktop Interface
- 770+ Automated Tests

## 🚧 Planned

- Explainable Verification
- Verification Planner
- Advanced Coverage Intelligence
- Counterexample Analysis
- Intelligent Repair Planning

---

# Repository Structure

```text
lib/
├── backend/
│   ├── design_intelligence/
│   ├── property_inference/
│   │   ├── semantic/
│   │   ├── synthesizer/
│   │   ├── ranking/
│   │   └── emitter/
│   ├── formal/
│   ├── coverage/
│   ├── diagnostics/
│   └── repair/
│
├── models/
├── services/
├── widgets/
└── screens/

test/
docs/
```

---

# Technology Stack

## Frontend

- Flutter
- Dart

## Formal Verification

- SymbiYosys
- Yosys
- Verilator
- Icarus Verilog

## Development

- Git
- GitHub

---

# Design Philosophy

ChipLens follows a layered architecture inspired by modern compiler design.

Each reasoning stage performs a single well-defined transformation before passing immutable results to the next stage.

This separation of concerns improves maintainability, explainability, extensibility, reproducibility, and testing while allowing future reasoning modules to be integrated without modifying existing components.

The platform favors deterministic algorithms, immutable data models, engine-independent abstractions, and clearly defined architectural boundaries.

---

# Project Goals

- Improve automation in RTL verification.
- Provide explainable verification decisions.
- Reduce manual effort in property generation.
- Integrate semantic reasoning with formal verification.
- Build a modular research platform for next-generation Electronic Design Automation (EDA).

---

# Current Status

ChipLens is under active development.

The current implementation includes the complete reasoning pipeline from RTL parsing through **Property Emitter**, producing engine-independent formal properties ready for downstream formal verification.

Future milestones focus on explainable verification, verification planning, advanced coverage intelligence, counterexample analysis, and intelligent repair planning.

---

# Roadmap

## ✅ Completed

- Design Intelligence Framework
- Property Inference Framework
- Semantic Evidence Framework
- Candidate Property Synthesizer
- Property Ranking Engine
- Property Emitter
- Formal Verification Framework

## 📌 Planned

- Explainable Verification
- Verification Planner
- Advanced Coverage Intelligence
- Counterexample Analysis
- Intelligent Repair Planning

---

# Vision

ChipLens aims to bridge compiler technology, semantic reasoning, and formal verification to create an intelligent verification assistant capable of understanding, reasoning about, and verifying complex RTL designs.

The long-term objective is to contribute toward next-generation Electronic Design Automation (EDA) systems by combining explainable reasoning with rigorous hardware verification.

---

# License

This project is released under the MIT License.
