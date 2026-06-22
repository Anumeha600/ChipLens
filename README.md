# ChipLens

> **An AI-assisted RTL verification platform for intelligent hardware design analysis and formal verification.**

ChipLens is a research-oriented RTL verification platform that combines compiler-inspired program analysis, semantic reasoning, automated property synthesis, property ranking, formal verification, coverage analysis, diagnostics, and repair assistance into a unified verification workflow for digital hardware designs.

Unlike conventional verification flows that invoke verification tools directly, ChipLens incrementally builds an internal semantic model of the RTL design. The platform extracts structural and behavioral knowledge, synthesizes candidate verification properties, prioritizes them using an explainable ranking engine, and prepares them for downstream formal verification.

The project is designed as a modular reasoning pipeline that explores how semantic analysis, compiler techniques, and formal verification can be integrated into an explainable verification assistant for hardware engineers and researchers.

---

# Why ChipLens?

Modern RTL verification often requires engineers to combine multiple independent tools for parsing, simulation, formal verification, coverage analysis, debugging, and repair. Although these tools are individually powerful, interpreting their results and deciding the next verification step remains largely a manual process.

ChipLens investigates a different approach.

Instead of immediately generating assertions or invoking formal engines, ChipLens first develops an internal understanding of the hardware design through a sequence of reasoning stages. Each stage enriches the available information before passing it to the next stage, enabling explainable verification decisions and a modular architecture that is easy to extend.

The long-term vision is to build an intelligent verification assistant capable of helping engineers throughout the complete verification lifecycle—from design understanding to automated verification planning, diagnostics, and repair.

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
Property Emitter (Planned)
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

* RTL Parsing and Structural Analysis
* Design Intelligence Framework
* Semantic Evidence Extraction
* Candidate Property Synthesis
* Property Ranking Engine
* Formal Verification Integration
* Coverage Analysis
* Diagnostics Engine
* Automated Repair Suggestions
* Explainable Verification Pipeline
* Modular and Extensible Architecture

---

# Current Progress

## Completed

* RTL Parsing Infrastructure
* Design Intelligence Framework
* Property Inference Framework
* Semantic Evidence Framework
* Candidate Property Synthesizer
* Property Ranking Engine
* Coverage Analysis
* Diagnostics Framework
* Repair Framework
* Flutter Desktop Interface
* 500+ automated tests

## In Progress

* Property Emitter

## Planned

* Verification Planning
* Explainable Property Generation
* Intelligent Verification Scheduling
* Advanced Repair Intelligence

---

# Repository Structure

```text
lib/
├── backend/
│   ├── design_intelligence/
│   ├── property_inference/
│   │   ├── semantic/
│   │   ├── synthesizer/
│   │   └── ranking/
│   ├── coverage/
│   ├── diagnostics/
│   ├── repair/
│   └── formal/
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

### Frontend

* Flutter
* Dart

### Verification

* SymbiYosys
* Yosys
* Verilator
* Icarus Verilog

### Development

* Git
* GitHub

---

# Design Philosophy

ChipLens follows a layered architecture inspired by modern compiler design.

Instead of combining all verification logic into a single engine, each reasoning stage performs one well-defined transformation before passing immutable results to the next stage.

This separation of concerns improves maintainability, explainability, extensibility, and testing while allowing future reasoning modules to be integrated without modifying existing components.

---

# Project Goals

* Improve automation in RTL verification.
* Provide explainable verification decisions.
* Reduce manual effort in property generation.
* Combine semantic reasoning with formal verification.
* Build a modular research platform for intelligent EDA systems.

---

# Current Status

ChipLens is under active development.

The current implementation includes the complete reasoning pipeline up to **Property Ranking**. Future milestones focus on property emission, explainable verification, intelligent verification planning, and deeper integration with formal verification engines.

---

# Roadmap

### ✅ Completed

* Design Intelligence Framework
* Property Inference Framework
* Semantic Evidence Framework
* Property Synthesizer
* Property Ranking Engine

### 🚧 In Progress

* Property Emitter

### 📌 Planned

* Explainable Verification
* Verification Planner
* Advanced Coverage Intelligence
* Counterexample Analysis
* Intelligent Repair Planning

---

# Vision

ChipLens aims to bridge compiler technology, semantic reasoning, and formal verification to create an intelligent verification assistant capable of understanding, reasoning about, and verifying complex RTL designs.

The long-term objective is to contribute toward next-generation Electronic Design Automation (EDA) systems that combine explainable AI techniques with rigorous hardware verification.

---

# License

This project is released under the MIT License.
