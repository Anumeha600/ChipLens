# ChipLens System Architecture

> Comprehensive architecture of the ChipLens verification platform.

---

# Overview

ChipLens is a layered RTL verification platform that combines compiler-inspired program analysis, semantic reasoning, automated property synthesis, formal verification, coverage analysis, diagnostics, and repair into a unified verification workflow.

Unlike conventional verification flows that invoke verification engines directly, ChipLens incrementally transforms RTL designs into progressively richer semantic representations before verification begins.

Each architectural layer performs a single well-defined transformation and communicates with downstream components through immutable data models. This layered design improves modularity, explainability, testability, and extensibility while enabling future research in intelligent Electronic Design Automation (EDA).

This document provides a high-level view of how the major architectural components interact.

---

# Layered Architecture

ChipLens follows a layered architecture in which each subsystem performs a single transformation before passing its output to the next stage.

Rather than allowing every subsystem to communicate directly with every other subsystem, information flows in one direction through well-defined intermediate representations. Each layer consumes the output of the previous layer, enriches it with additional knowledge, and produces a new immutable data model for downstream consumers.

This architecture is inspired by modern compiler pipelines, where source code is progressively transformed into richer internal representations before optimization and code generation.

The same philosophy is applied to RTL verification.

Instead of directly generating formal assertions from RTL source code, ChipLens first constructs semantic knowledge about the design, infers candidate verification properties, ranks them according to confidence and relevance, and finally prepares them for formal verification engines.

This separation of responsibilities provides several advantages:

- Each layer can be developed and tested independently.
- Intermediate representations are reusable by multiple downstream frameworks.
- New reasoning stages can be inserted without modifying existing components.
- Verification decisions become explainable because each transformation preserves its supporting evidence.
- The overall platform remains extensible for future research in intelligent Electronic Design Automation (EDA).

---

# Complete Verification Pipeline

The complete ChipLens verification workflow is organized as a sequence of independent architectural layers.

Each stage consumes the output of the previous stage, performs a well-defined transformation, and produces a richer intermediate representation for downstream components.

```text
RTL Source
     │
     ▼
RTL Parsing
     │
     ▼
Design Intelligence
     │
     ▼
Semantic Evidence Extraction
     │
     ▼
Candidate Property Synthesis
     │
     ▼
Property Ranking
     │
     ▼
Property Emission
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
Automated Repair
```

The pipeline intentionally separates reasoning into multiple stages instead of combining all verification logic into a single monolithic component.

Each layer introduces additional semantic information while preserving the outputs of previous stages. This incremental approach improves explainability, enables independent testing of each framework, and allows future reasoning modules to be inserted without disrupting the existing architecture.

---

# Architectural Layers

## 1. RTL Parsing

The verification process begins with RTL source files written in Verilog or SystemVerilog.

ChipLens invokes supported parsing backends to extract the structural representation of the hardware design, including modules, ports, signals, always blocks, assignments, and hierarchical relationships.

The parser produces a normalized internal representation that serves as the foundation for all subsequent reasoning stages.

---

## 2. Design Intelligence

The Design Intelligence Framework analyzes the parsed RTL structure to identify higher-level design concepts.

Rather than working with low-level syntax, this stage discovers architectural knowledge such as finite state machines (FSMs), counters, registers, clock domains, reset networks, handshakes, and module relationships.

The result is a structured Design Knowledge model that captures the behavioral characteristics of the design.

---

## 3. Semantic Evidence Extraction

The Semantic Evidence Framework transforms design knowledge into reusable semantic evidence.

Each evidence item represents a meaningful observation about the design, together with supporting metadata and a confidence score.

Examples include:

- Identified FSMs
- Counter behavior
- Reset semantics
- Register behavior
- Clock relationships
- Communication protocols

This semantic layer forms the reasoning foundation for downstream property inference.

---

## 4. Candidate Property Synthesis

The Property Synthesizer converts semantic evidence into candidate verification properties.

Instead of generating formal assertions directly, synthesis rules analyze semantic evidence and propose verification objectives that describe expected design behavior.

Each candidate property maintains traceability to the semantic evidence that produced it, allowing future reasoning stages to explain why a property was generated.

---

## 5. Property Ranking

The Property Ranking Framework prioritizes candidate properties before formal verification.

Ranking considers multiple factors including:

- confidence of supporting evidence,
- verification importance,
- metadata richness,
- quantity of supporting evidence,
- domain-specific priorities.

The output is an ordered list of verification objectives that allows verification engines to focus on the most valuable properties first.

---

## 6. Property Emission

The Property Emitter transforms ranked candidate properties into backend-specific formal assertions.

This layer translates high-level verification objectives into representations that can be consumed by downstream formal verification engines while preserving traceability to the original semantic evidence.

This component is currently under development.

---

## 7. Formal Verification

The generated formal properties are executed using supported verification backends.

ChipLens currently integrates with established open-source verification tools while maintaining backend independence through abstraction layers.

Verification results are normalized into a common internal representation for downstream processing.

---

## 8. Coverage Analysis

Coverage analysis evaluates the completeness of the verification process.

The Coverage Framework identifies uncovered behaviors, unreachable states, incomplete transitions, and other verification gaps that may require additional properties or design improvements.

---

## 9. Diagnostics

The Diagnostics Framework analyzes verification failures and coverage results to identify likely root causes.

Rather than reporting raw tool output, ChipLens produces structured diagnostic information designed to support automated reasoning and repair.

---

## 10. Automated Repair

The Repair Framework generates repair suggestions based on diagnostics and semantic knowledge.

Rather than modifying RTL automatically, the framework produces explainable repair recommendations that assist engineers in resolving verification issues while preserving human oversight.

---

# Design Principles

The ChipLens architecture is guided by a small set of engineering principles that influence every framework within the platform.

## Layered Responsibility

Each architectural layer performs exactly one primary transformation.

Rather than combining parsing, reasoning, verification, and diagnostics into a single subsystem, ChipLens separates these concerns into independent frameworks with clearly defined responsibilities.

This simplifies testing, improves maintainability, and makes the verification process easier to understand.

---

## Immutable Data Flow

Information flows through immutable intermediate representations.

Each framework consumes an existing data model and produces a new one without modifying previous stages.

This approach improves predictability, enables reproducible verification workflows, and simplifies debugging.

---

## Explainable Reasoning

Every verification decision should be traceable.

Candidate properties maintain references to semantic evidence, ranking decisions explain why properties were prioritized, and future verification results will remain linked to their originating design knowledge.

This traceability enables engineers to understand not only what was verified, but also why it was verified.

---

## Backend Independence

ChipLens is designed to remain independent of any single verification backend.

External tools such as Yosys, SymbiYosys, Verilator, and Icarus Verilog are accessed through abstraction layers that isolate backend-specific behavior from the rest of the platform.

This allows new verification engines to be integrated without modifying higher-level reasoning frameworks.

---

## Extensibility

New capabilities should be introduced by extending the architecture rather than modifying existing implementations.

The layered design enables future frameworks to be inserted into the verification pipeline while preserving compatibility with existing components.

This principle supports long-term research and experimentation in intelligent Electronic Design Automation (EDA).

---

# Data Flow Through the System

ChipLens processes RTL designs through a sequence of immutable intermediate representations.

Rather than sharing mutable state across frameworks, each architectural layer consumes the output of the previous stage and produces a new data model for downstream components.

The complete data flow is illustrated below.

```text
RTL Source
     │
     ▼
Parsed RTL Model
     │
     ▼
DesignKnowledge
     │
     ▼
SemanticEvidenceSet
     │
     ▼
CandidatePropertySet
     │
     ▼
RankedCandidatePropertySet
     │
     ▼
FormalPropertySet
     │
     ▼
VerificationResult
     │
     ▼
CoverageReport
     │
     ▼
DiagnosticReport
     │
     ▼
RepairSuggestionSet
```

Each representation captures a higher level of abstraction than the previous stage.

The architecture intentionally separates these representations so that each framework operates on a well-defined input and produces a clearly defined output.

This design provides several important benefits:

- predictable execution
- easier debugging
- framework independence
- reusable intermediate representations
- simplified testing
- improved extensibility

By avoiding shared mutable state, ChipLens ensures that every stage of the verification pipeline can be reasoned about independently while preserving complete traceability from RTL source code to verification results and repair suggestions.

---

# Architectural Benefits

The layered architecture adopted by ChipLens provides several engineering advantages over tightly coupled verification workflows.

## Improved Modularity

Each framework performs a single, well-defined responsibility.

This separation allows frameworks to evolve independently while minimizing the impact of changes on the remainder of the system.

---

## Independent Testing

Because each architectural layer communicates through immutable data models, every framework can be tested independently using deterministic inputs and outputs.

This significantly simplifies unit testing and improves long-term maintainability.

---

## Explainable Verification

ChipLens preserves traceability throughout the verification pipeline.

Semantic evidence is linked to candidate properties, candidate properties are linked to ranking decisions, and future formal properties will preserve references to their originating semantic knowledge.

This enables verification decisions to be explained rather than simply produced.

---

## Extensible Architecture

New reasoning frameworks can be introduced without modifying existing implementations.

Examples include:

- Timing Analysis
- CDC Analysis
- Security Verification
- AI-assisted Property Refinement
- Counterexample Analysis
- Intelligent Verification Planning

Each new capability can consume existing intermediate representations while producing new outputs for downstream frameworks.

---

## Backend Flexibility

Verification backends are isolated behind abstraction layers.

The reasoning pipeline remains independent of specific verification engines, allowing ChipLens to support multiple tools without changing higher-level reasoning components.

---

## Long-Term Maintainability

The architecture favors clear interfaces, immutable models, and explicit responsibilities over tightly coupled implementations.

As the project grows, this design reduces architectural complexity while making future extensions easier to integrate.

---

# Future Architecture

The current implementation establishes the foundational reasoning pipeline of ChipLens, beginning with RTL analysis and progressing through semantic reasoning toward formal verification.

Future development will extend this architecture without modifying the responsibilities of existing layers.

Planned architectural extensions include:

## Verification Planning

Introduce an intelligent planning layer capable of selecting, scheduling, and prioritizing verification activities based on available semantic knowledge, verification history, and design complexity.

---

## Counterexample Intelligence

Integrate formal verification counterexamples into the semantic reasoning pipeline.

Future frameworks will analyze counterexamples, identify likely design faults, and connect failures back to the semantic evidence that generated the corresponding verification property.

---

## Advanced Repair Intelligence

Extend the Repair Framework with semantic reasoning to generate more precise repair recommendations.

Future repair strategies may leverage formal verification results, semantic knowledge, and historical repair patterns while preserving human oversight.

---

## Explainable Verification

Expand the explanation framework so every generated property, verification result, diagnostic, and repair recommendation can be traced back through the complete reasoning pipeline.

This improves transparency and makes verification decisions easier to understand and validate.

---

## Multi-Backend Support

Continue extending backend independence by supporting additional verification engines and assertion languages without changing the reasoning pipeline.

Future backend integrations may include additional commercial and open-source verification tools.

---

## Research Platform

The long-term objective is for ChipLens to serve as a research platform for intelligent Electronic Design Automation (EDA).

The modular architecture enables experimentation with new reasoning techniques, verification strategies, and AI-assisted workflows while maintaining compatibility with existing verification infrastructure.

---

# Summary

ChipLens adopts a layered architecture that transforms RTL designs into progressively richer semantic representations before verification begins.

By separating parsing, semantic reasoning, property inference, verification, diagnostics, and repair into independent frameworks, the platform achieves modularity, explainability, extensibility, and long-term maintainability.

The architecture emphasizes immutable data models, well-defined interfaces, and reusable intermediate representations, enabling each framework to evolve independently while contributing to a unified verification workflow.

As the project continues to evolve, this architectural foundation will support additional research in intelligent verification, automated reasoning, explainable diagnostics, and AI-assisted Electronic Design Automation.


