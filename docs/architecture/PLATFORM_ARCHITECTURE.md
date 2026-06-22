# ChipLens Architecture Overview

## Vision

ChipLens is a modular RTL analysis, verification, and repair platform.

Instead of acting as a frontend for individual EDA tools, ChipLens provides a unified framework that combines parsing, diagnostics, simulation, formal verification, coverage analysis, and automated repair behind consistent APIs.

The long-term objective is to make RTL verification easier to understand, automate, and extend.

---

# High-Level Architecture

```
                    +----------------------+
                    |     Flutter UI       |
                    +----------+-----------+
                               |
                               v
                  +---------------------------+
                  | Application Services      |
                  +------------+--------------+
                               |
                               v
+---------------------------------------------------------------+
|                        Backend Framework                       |
|                                                               |
|  Verification   Repair   Formal   Coverage   Diagnostics      |
|       |            |         |         |           |           |
+-------+------------+---------+---------+-----------+-----------+
                               |
                               v
                 +-----------------------------+
                 |     Core Data Models        |
                 +-----------------------------+
                               |
                               v
             +---------------------------------------+
             | External Verification / EDA Tools     |
             |                                       |
             | Verilator | Yosys | Icarus | SymbiYosys |
             +---------------------------------------+
```

---

# Core Principles

The architecture follows several principles.

## 1. Separation of Responsibilities

Each subsystem owns a single responsibility.

Examples:

- VerificationRunner coordinates execution.
- VerificationTool executes tools.
- OutputParser interprets tool output.
- DiagnosticEngine merges diagnostics.
- RepairPipeline coordinates repairs.

---

## 2. Backend Independence

Application code should never depend directly on a specific EDA tool.

Every backend is accessed through a common abstraction.

This allows new verification engines to be integrated with minimal changes.

---

## 3. Modular Framework Design

Each subsystem is independently testable.

Examples include:

- Verification Framework
- Repair Framework
- Formal Verification Framework
- Coverage Framework

Each framework exposes a stable public API.

---

## 4. Testability

Business logic should be isolated from process execution.

Parsers should be unit-tested using static inputs.

Integration tests verify interaction with external tools.

---

## 5. Extensibility

New capabilities should be introduced by extending existing interfaces rather than modifying existing implementations.

The architecture is intended to support future work in:

- Timing analysis
- Property inference
- Counterexample analysis
- Plugin systems
- AI-assisted verification

---

# Current Status

Completed

- RTL Parsing
- Verification Framework
- Diagnostics Framework
- Coverage Analysis
- Repair Framework
- Formal Verification Framework
- Formal Property System

In Progress

- Design Knowledge Framework
- Property Inference
- Counterexample Analysis

---

# Philosophy

ChipLens is designed as an engineering platform rather than a collection of integrations.

Architectural consistency, modularity, and long-term maintainability take priority over rapidly adding features.
