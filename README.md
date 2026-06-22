# ChipLens

> **An AI-assisted RTL verification platform for intelligent hardware design analysis and formal verification.**

ChipLens is a research-oriented RTL verification platform that combines compiler-inspired program analysis, semantic reasoning, automated property synthesis, property ranking, formal verification, coverage analysis, diagnostics, and repair assistance into a unified verification workflow for digital hardware designs.

Unlike conventional verification flows that invoke verification tools directly, ChipLens incrementally builds an internal semantic model of the design. The platform extracts structural and behavioral knowledge from RTL, synthesizes candidate verification properties, prioritizes them using an explainable ranking engine, and prepares them for downstream formal verification.

Its modular architecture is designed to support explainable verification, extensibility, and future research in intelligent Electronic Design Automation (EDA) systems.

---

# Why ChipLens?

Modern RTL verification often relies on multiple independent tools for parsing, simulation, formal verification, coverage analysis, and debugging. While these tools are individually powerful, engineers must still manually interpret results, prioritize verification goals, and determine the next verification step.

ChipLens investigates a different approach by introducing a reasoning pipeline that understands a hardware design before verification begins. Rather than immediately generating assertions, the system progressively transforms RTL into semantic knowledge, candidate verification properties, and prioritized verification objectives.

This layered architecture explores how compiler techniques, semantic reasoning, and formal verification can be integrated into an explainable verification assistant for digital hardware engineers.

---

# Key Features

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

# Current Architecture

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

# Technology Stack

* Flutter
* Dart
* Yosys
* SymbiYosys
* Verilator
* Icarus Verilog

---

# Current Status

Completed frameworks include:

* Design Intelligence Framework
* Property Inference Framework
* Semantic Evidence Framework
* Candidate Property Synthesizer
* Property Ranking Engine

The next milestone is the **Property Emitter**, which will translate ranked candidate properties into formal assertions for downstream formal verification.

---

# Vision

ChipLens aims to bridge compiler technology, semantic reasoning, and formal verification to create an intelligent verification assistant capable of understanding, reasoning about, and verifying complex RTL designs.

The long-term vision is to develop an explainable verification platform that assists engineers throughout the complete verification lifecycle—from design understanding to automated verification planning, diagnostics, and repair.
