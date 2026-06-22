# ChipLens

> **An AI-assisted RTL verification platform for intelligent hardware design analysis and formal verification.**

ChipLens is a modular verification platform that combines compiler-inspired program analysis, semantic reasoning, automated property synthesis, property ranking, formal verification, coverage analysis, diagnostics, and repair assistance into a unified verification workflow for digital hardware designs.

Rather than acting as a wrapper around existing verification tools, ChipLens builds an internal semantic understanding of RTL designs before generating, prioritizing, and validating formal verification objectives. This layered architecture is designed to support explainable verification, extensibility, and future research in intelligent EDA systems.

---

## Key Features

* RTL Parsing and Analysis
* Design Intelligence Framework
* Semantic Evidence Extraction
* Candidate Property Synthesis
* Property Ranking Engine
* Formal Verification Integration
* Coverage Analysis
* Diagnostics Engine
* Automated Repair Suggestions
* Modular, Extensible Verification Pipeline

---

## Current Architecture

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
Property Emitter (In Progress)
     │
     ▼
Formal Verification
     │
     ▼
Coverage Analysis
     │
     ▼
Diagnostics & Repair
```

---

## Technology Stack

* Flutter
* Dart
* Yosys
* SymbiYosys
* Verilator
* Icarus Verilog

---

## Current Status

Completed frameworks include:

* Design Intelligence Framework
* Property Inference Framework
* Semantic Evidence Framework
* Candidate Property Synthesizer
* Property Ranking Engine

The next milestone is the **Property Emitter**, which will translate ranked candidate properties into formal assertions for downstream verification engines.

---

## Vision

ChipLens aims to bridge modern compiler techniques, semantic reasoning, and formal verification to create an intelligent verification assistant capable of understanding, reasoning about, and verifying digital hardware designs.
