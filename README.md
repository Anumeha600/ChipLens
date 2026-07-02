# ChipLens

> **Compiler-Inspired Semantic RTL Engineering and Verification Research Platform**

<p align="center">

**Build • Understand • Analyze • Verify • Evaluate • Research**

</p>

<p align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Desktop-Windows%20|%20Linux%20|%20macOS-blue)
![Tests](https://img.shields.io/badge/Tests-7801%2B-success)
![Analyzer](https://img.shields.io/badge/flutter%20analyze-0%20Errors-success)
![License](https://img.shields.io/badge/License-MIT-green)

</p>

---

# Compiler-Inspired RTL Engineering

ChipLens is a **compiler-inspired semantic RTL engineering and verification research platform** that investigates how reusable semantic representations can improve hardware engineering workflows.

Instead of repeatedly analyzing RTL source code for every engineering task, ChipLens constructs a shared semantic model that powers:

- RTL parsing
- Abstract syntax tree construction
- Symbol resolution
- Semantic analysis
- Design intelligence
- Property inference
- Formal verification orchestration
- Diagnostics
- Explainability
- Reproducible experimental evaluation

The project combines an engineering workbench with a research platform capable of generating publication-ready datasets, statistical analyses, figures, reports, and benchmark artifacts.

---

# Vision

Modern RTL engineering is often performed using a collection of disconnected tools.

A typical verification workflow repeatedly performs similar analyses while switching between parsers, simulators, formal verification tools, waveform viewers, scripting environments, and manually written assertions.

ChipLens investigates a different approach.

Inspired by modern compiler architectures, ChipLens computes semantic information once and reuses it throughout the engineering workflow.

The long-term research objective is to determine whether **compiler-inspired semantic reuse** can improve RTL engineering by reducing redundant analysis, enabling deterministic reasoning, and supporting reproducible verification methodologies.

---

# Research Question

ChipLens is built around a single central research question.

> **Can compiler-inspired semantic architectures improve RTL engineering workflows by enabling reusable semantic analysis across parsing, navigation, property inference, diagnostics, and verification?**

Every subsystem, benchmark, experiment, and evaluation framework in ChipLens contributes toward answering this question using measurable experimental evidence rather than anecdotal examples.

---

# Why ChipLens?

Unlike traditional RTL engineering environments, ChipLens is designed around a reusable semantic pipeline rather than independent analysis stages.

Instead of reparsing or reanalyzing designs for each engineering task, semantic information is generated once and shared across the entire platform.

This architecture enables:

- Deterministic semantic reasoning
- Reduced duplicate computation
- Consistent engineering analysis
- Modular verification workflows
- Reproducible experimentation
- Publication-oriented research evaluation

Rather than replacing established EDA tools, ChipLens investigates how semantic reasoning can complement existing verification workflows while providing a reusable research platform for compiler-inspired RTL engineering.

---

# Research Contributions

ChipLens currently investigates six complementary research directions.

| Research Area | Objective |
|--------------|-----------|
| Compiler-Inspired RTL Architecture | Reusable semantic representations for RTL engineering |
| Semantic Analysis | Deterministic extraction of structural and behavioral information |
| Property Inference | Automatic generation of candidate formal properties |
| Verification Methodology | Semantic-driven verification orchestration |
| Engineering Productivity | Investigation of semantic workflows for RTL development |
| Reproducible Research | Automated generation of datasets, reports, figures and statistical artifacts |

Together, these directions form a unified research program rather than a collection of independent software features.

---

# Current Research Status

ChipLens has evolved beyond a prototype into a reproducible research platform.

Current capabilities include:

| Component | Status |
|-----------|--------|
| Compiler-Inspired RTL Pipeline | ✅ Complete |
| Semantic Analysis Engine | ✅ Complete |
| Property Inference Engine | ✅ Complete |
| Formal Verification Orchestration | ✅ Complete |
| Benchmark Infrastructure | ✅ Complete |
| Experiment Framework | ✅ Complete |
| Research Analysis Engine | ✅ Complete |
| Semantic Reuse Evaluation | ✅ Complete |
| Duplicate Computation Evaluation | ✅ Complete |
| Large-Scale Benchmark Validation | ✅ Complete |
| Engineering Productivity Framework | ✅ Ready for Participant Studies |

The current development focus has shifted from feature implementation toward evidence generation, experimental validation, and research publication.

---

# Compiler-Inspired Architecture

ChipLens is designed around a compiler-inspired execution model.

Instead of treating RTL as plain text throughout the engineering workflow, ChipLens progressively transforms source code into increasingly richer semantic representations.

Each stage performs a single deterministic responsibility while exposing reusable semantic information to downstream consumers.

Unlike traditional workflows, semantic information is computed once and reused across multiple engineering tasks rather than repeatedly reconstructed.

---

## Semantic Engineering Pipeline

```text
                    RTL Source
                         │
                         ▼
                Lexical Analysis
                         │
                         ▼
                 RTL Parser
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
                         ▼
          Design Intelligence Engine
                         │
                         ▼
            Property Inference Engine
                         │
                         ▼
      Formal Verification Orchestration
                         │
                         ▼
            Diagnostics & Explainability
                         │
                         ▼
          Experiment & Research Pipeline
                         │
                         ▼
         Datasets • Statistics • Reports
```

---

# Semantic Reuse

The central architectural principle of ChipLens is **semantic reuse**.

Rather than allowing every subsystem to independently parse and analyze RTL source code, ChipLens constructs a shared semantic representation that becomes the foundation for the entire engineering workflow.

The same semantic information is reused by:

- Navigation
- Symbol lookup
- Dependency analysis
- Design intelligence
- Property inference
- Diagnostics
- Verification orchestration
- Research evaluation

This compiler-inspired architecture minimizes redundant analysis while ensuring deterministic behavior across engineering tasks.

---

# Architecture Philosophy

Each pipeline stage satisfies three architectural principles.

## 1. Single Responsibility

Every stage performs one clearly defined analysis.

Examples include:

- Parsing
- Symbol construction
- Semantic reasoning
- Property inference
- Verification orchestration

No stage performs unrelated work.

---

## 2. Immutable Semantic Objects

Intermediate representations are treated as immutable semantic artifacts.

Rather than modifying existing structures, downstream stages consume previously generated semantic information.

This improves:

- reproducibility
- deterministic execution
- debugging
- testing
- experiment repeatability

---

## 3. Semantic Reuse

Semantic information is intentionally shared across the pipeline.

Instead of repeatedly reconstructing engineering knowledge, later stages consume previously computed semantic objects.

This allows engineering analyses to remain modular while avoiding duplicated semantic computation.

---

# Pipeline Components

| Stage | Purpose | Output |
|--------|---------|--------|
| Parser | Parse SystemVerilog source | Abstract Syntax Tree |
| AST Builder | Construct syntax hierarchy | Immutable AST |
| Symbol Resolver | Build symbol tables | Symbol graph |
| Semantic Analyzer | Extract structural semantics | Semantic model |
| Design Intelligence | Analyze architecture | Engineering insights |
| Property Inference | Generate candidate assertions | Property set |
| Verification Engine | Coordinate verification workflow | Verification results |
| Diagnostics Engine | Explain engineering findings | Diagnostics |
| Research Engine | Produce reproducible artifacts | Datasets and reports |

---

# Information Flow

ChipLens separates syntax, semantics, verification, and experimentation into reusable stages.

```text
RTL
 │
 ▼
Parser
 │
 ▼
AST
 │
 ▼
Semantic Model
 ├──────────────┐
 ▼              ▼
Navigation   Design Intelligence
 │              │
 ├──────┐       │
 ▼      ▼       ▼
Diagnostics  Property Inference
        │       │
        └───┬───┘
            ▼
Formal Verification
            │
            ▼
Research Analysis
            │
            ▼
Datasets • Statistics • Reports
```

This separation enables engineering features and research experiments to operate on the same semantic foundation, ensuring that every analysis is reproducible and consistent across the platform.

---

# Architectural Characteristics

| Characteristic | Description |
|----------------|-------------|
| Compiler-inspired | Multi-stage deterministic semantic pipeline |
| Immutable | Intermediate semantic representations remain unchanged after construction |
| Modular | Independent analysis stages communicate through well-defined semantic objects |
| Reusable | Semantic information is shared rather than recomputed |
| Deterministic | Identical RTL produces identical semantic outputs |
| Testable | Every stage can be evaluated independently |
| Reproducible | Experiments generate identical research artifacts from identical inputs |

---

# Architectural Validation

The current implementation has been evaluated through automated architectural experiments.

Highlights include:

- **63.2% reduction in redundant pipeline computations** through semantic reuse compared with an experimental recomputation baseline.
- **100% parser success** across the evaluated benchmark corpus.
- Automated generation of reproducible datasets, reports, statistical summaries, and publication-ready artifacts.
- Semantic reuse verified across multiple downstream engineering components.

These results provide initial evidence supporting the compiler-inspired architectural model and establish a foundation for future large-scale evaluation.

---

# Experimental Validation

ChipLens is evaluated using a reproducible experimental methodology inspired by empirical software engineering and hardware verification research.

Rather than relying on anecdotal examples or manually collected observations, every experiment automatically generates structured datasets, statistical analyses, publication-ready tables, reproducible figures, and comprehensive research reports.

The objective is to evaluate the effectiveness of compiler-inspired semantic architectures using measurable evidence.

---

# Research Infrastructure

ChipLens includes a complete research infrastructure for automated experimentation.

| Component | Status |
|-----------|--------|
| Benchmark Registry | ✅ |
| Experiment Engine | ✅ |
| Statistical Analysis Engine | ✅ |
| Semantic Reuse Evaluation | ✅ |
| Duplicate Computation Evaluation | ✅ |
| Large-Scale Validation Framework | ✅ |
| Research Analysis Engine | ✅ |
| Productivity Evaluation Framework | ✅ |
| Automated Report Generation | ✅ |

---

# Experimental Pipeline

Every evaluation follows the same reproducible workflow.

```text
Benchmark Corpus
        │
        ▼
Experiment Engine
        │
        ▼
Semantic Pipeline
        │
        ▼
Metric Collection
        │
        ▼
Statistical Analysis
        │
        ▼
Research Findings
        │
        ▼
Publication Artifacts
```

Each execution automatically produces datasets, reports, figures, statistical summaries, and experiment metadata without manual post-processing.

---

# Research Datasets

The evaluation framework currently generates five primary datasets.

| Dataset | Description |
|----------|-------------|
| DS001 | Parser performance and robustness |
| DS002 | Semantic analysis and structural metrics |
| DS003 | RTL structural complexity characterization |
| DS004 | Property inference evaluation |
| DS005 | Verification execution metrics |

These datasets serve as the foundation for subsequent statistical analysis and experimental evaluation.

---

# Experimental Studies

ChipLens currently includes several complementary evaluation studies.

| Study | Objective | Status |
|--------|-----------|--------|
| Parser Validation | Evaluate parsing robustness across benchmark designs | ✅ |
| Semantic Analysis | Measure structural semantic extraction | ✅ |
| Property Inference | Evaluate automated assertion generation | ✅ |
| Semantic Reuse Study | Quantify reusable semantic computation | ✅ |
| Duplicate Computation Study | Compare semantic reuse against recomputation | ✅ |
| Large-Scale Validation | Validate pipeline across benchmark corpus | ✅ |
| Productivity Framework | Prepare controlled human studies | ✅ Ready |

---

# Current Research Statistics

| Metric | Current Value |
|---------|--------------:|
| Automated Tests | **7,801+** |
| Analyzer Errors | **0** |
| Benchmark Designs | **50** |
| Fully Evaluated Corpus | **15** |
| Research Datasets | **5** |
| Research Reports | **10+** |
| Generated Research Artifacts | **102+** |
| Pipeline Stages | **7** |

---

# Evidence Highlights

Current experiments provide the following evidence.

### Compiler-Inspired Semantic Reuse

- Eliminated **63.2%** of redundant semantic pipeline computations compared with an experimental recomputation baseline.
- Reduced repeated execution of parser, AST, symbol, semantic, and design analysis stages through reusable semantic representations.

---

### Parser Validation

- Successfully parsed **100%** of evaluated benchmark designs.
- Zero parser failures across the current benchmark corpus.

---

### Semantic Analysis

- Extracted deterministic semantic representations for all evaluated designs.
- Generated structural metrics including modules, ports, signals, registers, hierarchy, and symbol information.

---

### Property Inference

- Automatically generated more than **100 candidate formal properties** across the evaluated benchmark corpus.
- Produced reproducible property datasets suitable for further analysis.

---

### Automated Research Pipeline

Every experiment automatically generates:

- CSV datasets
- JSON datasets
- Markdown reports
- Statistical summaries
- Publication tables
- Publication figures
- Experiment metadata

No manual data collection is required.

---

# Research Artifacts

Every evaluation produces reproducible research outputs.

```text
research_output/

├── analysis/
├── datasets/
├── duplicate_computation/
├── experiments/
├── figures/
├── large_scale_validation/
├── reports/
├── semantic_reuse/
├── statistics/
└── tables/
```

These artifacts are intended to support transparent experimentation, reproducibility, and future research publications.

---

# Research Findings

Current evaluation has produced several evidence-backed observations.

- Semantic reuse substantially reduces redundant semantic computation.
- Parser robustness remained consistent across the evaluated benchmark corpus.
- Property generation scales with increasing structural complexity.
- Verification execution dominates total pipeline runtime, motivating future optimization and verification-focused studies.
- Structural complexity metrics correlate positively with several stages of the engineering pipeline.

These findings represent the current state of evaluation and will continue to evolve as the benchmark corpus expands.

---

# Reproducibility

ChipLens emphasizes reproducible experimentation.

Every experiment records:

- Benchmark configuration
- Execution metadata
- Statistical summaries
- Generated datasets
- Experiment reports
- Research findings

Identical inputs produce identical research artifacts, enabling repeatable evaluation and independent verification of experimental results.

---

# Engineering Workbench

ChipLens provides a desktop-first engineering environment for exploring, analyzing, and verifying RTL designs.

The workbench serves as the front-end for the semantic analysis pipeline and experimental framework, allowing engineering workflows and research experiments to operate within a unified environment.

## Current Components

| Component | Purpose |
|-----------|---------|
| Workspace Explorer | Project navigation |
| RTL Editor | SystemVerilog editing |
| Outline View | Structural overview |
| Symbol Explorer | Semantic navigation |
| Problems Panel | Diagnostics |
| Output Console | Pipeline execution logs |
| Command Palette | Quick actions |
| Global Search | Workspace search |
| Status Bar | Project status |
| Research Console | Experiment execution |

---

# Repository Structure

The repository is organized into independent engineering and research modules.

```text
ChipLens/

├── frontend/                 Flutter desktop application
├── backend/                  Analysis and experiment backend
├── benchmarks/               RTL benchmark corpus
├── docs/                     Documentation and evaluation protocols
├── research_output/          Generated datasets and reports
├── test/                     Automated test suite
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
└── web/
```

---

# Research Output Structure

All experimental results are generated automatically.

```text
research_output/

analysis/
datasets/
duplicate_computation/
experiments/
figures/
large_scale_validation/
reports/
semantic_reuse/
statistics/
tables/
```

Every directory is reproducible and generated directly from the experiment pipeline.

---

# Technology Stack

| Layer | Technology |
|--------|------------|
| Desktop Application | Flutter |
| Language | Dart |
| Backend Services | Node.js + Express |
| Parser | Tree-sitter |
| Formal Verification | SymbiYosys |
| Simulation | Icarus Verilog |
| Linting | Verilator |
| Synthesis | Yosys |

---

# Getting Started

## Clone

```bash
git clone https://github.com/Anumeha600/ChipLens.git
cd ChipLens
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Launch Desktop Application

```bash
flutter run
```

---

## Execute Tests

```bash
flutter test
```

---

## Static Analysis

```bash
flutter analyze
```

---

## Run Research Pipeline

```dart
await ResearchDatasetExporter.runAndExport(
  outputDir: "research_output",
);
```

This command automatically generates:

- Experimental datasets
- Statistical summaries
- Publication tables
- Publication figures
- Markdown reports

---

# Development Philosophy

ChipLens follows several engineering principles.

- Deterministic execution
- Immutable semantic representations
- Test-driven development
- Modular architecture
- Reproducible experimentation
- Evidence-driven evaluation

---

# Quality Assurance

Current project quality metrics.

| Metric | Status |
|---------|--------|
| Automated Tests | ✅ 7,801+ Passing |
| Test Failures | ✅ 0 |
| Analyzer Errors | ✅ 0 |
| Continuous Integration | ✅ Enabled |
| Deterministic Pipeline | ✅ Verified |
| Reproducible Outputs | ✅ Verified |

---

# Documentation

Comprehensive documentation is available throughout the repository.

| Documentation | Description |
|---------------|-------------|
| Architecture | Compiler-inspired pipeline |
| Evaluation | Experimental methodology |
| Benchmarks | RTL corpus documentation |
| Research | Generated findings and reports |
| Experiments | Experiment framework |
| Productivity Study | Human evaluation protocol |

---

# Research Roadmap

ChipLens is being developed as a long-term research platform rather than a single software release.

The roadmap is organized around research milestones instead of feature additions.

| Phase | Status |
|--------|--------|
| Phase I — Compiler-Inspired Engineering Platform | ✅ Complete |
| Phase II — Semantic Analysis Infrastructure | ✅ Complete |
| Phase III — Automated Research Platform | ✅ Complete |
| Phase IV — Experimental Validation | 🚧 In Progress |
| Phase V — Human Productivity Evaluation | 📋 Planned |
| Phase VI — Research Publications | 📋 Planned |

---

# Current Research Focus

Current development priorities include:

- Expanding the benchmark corpus using larger open-source RTL projects.
- Evaluating the quality and usefulness of automatically generated formal properties.
- Measuring verification effectiveness using controlled fault-injection benchmarks.
- Conducting controlled engineering productivity studies with human participants.
- Strengthening statistical analysis for future journal and conference publications.

---

# Planned Publications

ChipLens is intended to support multiple complementary research publications.

| Planned Paper | Current Status |
|---------------|----------------|
| Compiler-Inspired Semantic RTL Architecture | Evidence Collection Complete |
| Automated Property Inference for RTL Verification | Evaluation Ongoing |
| Semantic Diagnostics for RTL Verification | Planned |
| Engineering Productivity in RTL Workflows | Evaluation Framework Complete |

Publication plans may evolve as additional experimental evidence is collected.

---

# Contributing

Contributions that strengthen the engineering platform or the research methodology are welcome.

Examples include:

- RTL benchmark designs
- Parser improvements
- Semantic analysis enhancements
- Property inference techniques
- Experimental evaluation
- Documentation improvements
- Bug reports and reproducibility improvements

Please ensure that new contributions preserve deterministic behavior, maintain reproducibility, and include appropriate automated tests.

---

# Citation

If ChipLens contributes to your research, teaching, or engineering work, please cite it as:

```bibtex
@software{chiplens2026,
  title   = {ChipLens},
  author  = {Paul, Anumeha},
  year    = {2026},
  note    = {Compiler-Inspired Semantic RTL Engineering and Verification Research Platform},
  url     = {https://github.com/Anumeha600/ChipLens}
}
```

---

# License

ChipLens is released under the **MIT License**.

See the `LICENSE` file for additional details.

---

# Acknowledgements

ChipLens builds upon numerous open-source technologies and the broader hardware engineering community.

The project makes use of tools including:

- Flutter
- Dart
- Tree-sitter
- Yosys
- SymbiYosys
- Icarus Verilog
- Verilator

Their continued development has made this research platform possible.

---

# Project Philosophy

ChipLens was created with a simple idea:

> **Engineering decisions should be supported by reusable semantic information, and research claims should be supported by reproducible experimental evidence.**

The project combines compiler design principles, RTL engineering, formal verification, and empirical software engineering into a unified research platform.

As the benchmark corpus expands and additional experimental evidence is collected, ChipLens aims to contribute reproducible methodologies and open research artifacts that support future advances in RTL engineering and verification.

---

<p align="center">

**ChipLens**

*Compiler-Inspired Semantic RTL Engineering and Verification Research Platform*

**Build • Understand • Analyze • Verify • Evaluate • Research**

</p>

