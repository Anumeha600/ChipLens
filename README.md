# ChipLens Lite

**AI-native RTL engineering workbench.** Write, analyze, and formally verify SystemVerilog in a
single desktop IDE. The tool infers what your design *should* satisfy, synthesizes ranked SVA
assertions automatically, dispatches them to a formal solver, and produces reproducible research
artifacts — without leaving the editor.

```
┌─────────────────────────────────────────────────────────────┐
│                    ChipLens IDE Shell                       │
│  ActivityBar │ Explorer │ RTL Editor (tabbed, split)        │
│              │          │ Outline  /  Symbols  /  Props     │
│              │          ├─────────────────────────────────  │
│              │          │ Problems │ Output │ Terminal       │
│─────────────────────────────────────────────────────────────│
│  Status Bar: project · branch · verification · cursor       │
└─────────────────────────────────────────────────────────────┘
          │                          │
   Node.js REST API           Dart Pipeline
   (Express + EDA tools)      (14 stages, pure, stateless)
          │                          │
   Yosys · Verilator ·        SymbiYosys
   Icarus · Tree-sitter        (BMC + k-induction)
```

| | |
|---|---|
| Tests | ✅ **5,926 passing**, 0 failures |
| Analyzer | ✅ **0 errors** (`flutter analyze`) |
| Test files | 159 |
| Benchmark designs | 8 (100% pass rate) |
| Pipeline stages | 14 |
| Property providers | 8 |

---

## Why ChipLens?

RTL verification is fragmented across disconnected tools. Engineers run Verilator for lint, write
SVA assertions by hand, invoke SymbiYosys separately, and interpret counterexamples without
tooling support.

ChipLens collapses the workflow into one loop:

| Step | What happens |
|---|---|
| **Parse → Understand** | Compiler-grade semantic analysis extracts FSMs, clock domains, signal graphs |
| **Understand → Assert** | 8 domain-aware providers synthesize and rank SVA assertions automatically |
| **Assert → Verify** | SymbiYosys runs BMC + k-induction; results are classified and explained |
| **Verify → Evidence** | Every run emits reproducible CSV/JSON/Markdown research artifacts |

No boilerplate SVA. No context switching. No manual artifact collection.

---

## Architecture

```
Source (SystemVerilog)
        │
        ▼
FallbackVerilogParser ──── tokens · SourceSpans · parse errors
        │
        ▼
AstBuilder ─────────────── AstModule (ports · signals · assignments · always blocks)
        │
        ▼
RtlSymbolTableBuilder ──── two-level scope (global + per-module)
        │
        ▼
SemanticAnalyzer ──────── SemanticModel
                           ├─ SignalGraph   (nodes: port/net/reg · edges: assign/port)
                           ├─ DriverInfo / ReaderInfo maps
                           ├─ FSM candidates
                           └─ ClockDomain / ResetDomain
        │
        ├──► SignalDependencyService
        │      dependency graph · dataflow graph · fan-in/out · topological sort
        │
        ▼
VerificationOrchestrator  (14 stages, pure async)
        ├─ DesignRunner    (8 knowledge providers)
        ├─ PropertyRunner  (synthesize → rank → emit SVA)
        └─ VerificationRunner (SymbiYosys · Verilator · Yosys)
        │
        ▼
EvaluationRunner ──── EvaluationReport ──── EvaluationExporter
                                            ├─ exportAll()               Markdown/JSON/CSV
                                            └─ exportResearchArtifacts() research_output/
```

**Stack:**

| Layer | Technology |
|---|---|
| IDE shell | Flutter 3.x (Dart), Material 3, desktop |
| Verification pipeline | Dart (pure, no FFI) |
| REST API | Node.js 20 + Express 4 |
| RTL parsing | Tree-sitter (SystemVerilog grammar) |
| Formal verification | SymbiYosys — BMC + k-induction |
| Simulation / lint | Icarus Verilog, Verilator |
| Synthesis | Yosys |
| Process management | PM2 |

**Repository layout:**

```
ChipLens-Lite/
├── backend/                Node.js REST API (Express + EDA subprocess management)
│   └── src/
│       ├── core/           Yosys / Verilator / Icarus runners + 9 lint rules
│       └── generators/     NL intent classifier + 8 RTL design templates
└── frontend/
    ├── lib/
    │   ├── backend/        Dart pipeline — parser · AST · semantic · analysis
    │   │                   property inference · formal · evaluation · navigation
    │   ├── services/       NL-to-RTL synthesis pipeline
    │   └── ui/workbench/   IDE shell — editor · explorer · panels · dialogs
    └── test/               159 test files · 5,926 tests
```


---

## Core Capabilities

### Verification Pipeline — 14 Stages

| Stage | Function |
|---|---|
| 1 Initialization | Validate input, prepare pipeline context |
| 2 Design Intelligence | Run 8 domain knowledge providers concurrently |
| 3 Evidence Extraction | Build structured evidence from design knowledge |
| 4 Property Synthesis | Generate candidate SVA per evidence type |
| 5 Property Ranking | Score by severity, coverage, engineering priority |
| 6 Property Emission | Serialize ranked properties to SVA text |
| 7 Explainability | Human-readable rationale per property (optional) |
| 8 Verification Planning | Sequence properties into a verification plan |
| 9 Formal Verification | Dispatch to SymbiYosys (BMC + k-induction) |
| 10 Coverage Intelligence | Assess structural/functional coverage (optional) |
| 11 Counterexample Analysis | Classify and contextualize failing traces |
| 12 Diagnostics Intelligence | Aggregate evidence into diagnostic issues |
| 13 Repair Planning | Map diagnostics to ordered fix steps (optional) |
| 14 Complete | Collect and return `VerificationResult` |


### Property Inference Providers

| Provider | Properties Inferred |
|---|---|
| `FSMPropertyProvider` | Legal-state safety, state reachability cover, one-hot candidate |
| `HandshakePropertyProvider` | Valid/ready integrity, no data loss, no spurious acceptance |
| `RegisterPropertyProvider` | Inter-clock stability, no glitch on registered outputs |
| `CounterPropertyProvider` | Monotonic increment, no overflow without enable, wrap-at-max |
| `ResetPropertyProvider` | Sync/async reset clears all registered state |
| `ArithmeticPropertyProvider` | Overflow/underflow safety, identity elements under carry |
| `MemoryPropertyProvider` | Write-before-read, address bounds, no simultaneous R/W conflict |
| `SafetyPropertyProvider` | Output-defined fallback for unclassified modules |

### Semantic Analysis Engine

| API | Returns |
|---|---|
| `buildDependencyGraph(module)` | `DependencyGraph` — typed nodes + edges |
| `buildDataflowGraph(module)` | `DataflowGraph` — per-signal driver/reader/fan-in/out |
| `analyzeFanIn(signal, module)` | `FaninAnalysis` — direct + transitive sources |
| `analyzeFanOut(signal, module)` | `FanoutAnalysis` — direct + transitive sinks |
| `topologicalSort(module)` | Signal order: sources before sinks |
| `multiDrivenSignals(module)` | Signals with more than one driver |
| `unreadSignals(module)` | Dead-signal candidates |
| `generateReport()` | `AnalysisReport` — Markdown / JSON / CSV |


### Navigation Services

| Service | Shortcut | Function |
|---|---|---|
| `GoToDefinitionService` | F12 | Jump to signal/port/module declaration |
| `FindReferencesService` | Shift+F12 | All use-sites across modules |

### Node.js REST API

| Route | Tool | Function |
|---|---|---|
| `POST /api/v1/analyze` | Yosys + Verilator + Icarus | Multi-pass lint and synthesizability |
| `POST /api/v1/fsm` | Tree-sitter | CST-based FSM extraction |
| `POST /api/v1/hierarchy` | Yosys | Module hierarchy extraction |
| `POST /api/v1/lint` | Custom rules | 9 structural lint rules |
| `POST /api/v1/generate` | Template + NL | Natural-language → synthesizable Verilog |
| `POST /api/v1/explain` | Rule engine | RTL construct explanation |
| `POST /api/v1/parse` | Tree-sitter | Full CST parse |

**Lint rules:** blocking assignment in always_ff · latch inference · multiple drivers ·
combinational loop · missing reset · missing default · unused signal · large combinational block ·
constant condition.

---

## Evaluation & Evidence

### Benchmark Suite

| Design | Modules | Signals | Status |
|---|---|---|---|
| `simple_flip_flop` | 1 | 0 | ✅ PASS |
| `counter_8bit` | 1 | 0 | ✅ PASS |
| `simple_fsm` | 1 | 2 | ✅ PASS |
| `module_hierarchy` | 2 | 0 | ✅ PASS |
| `simple_alu` | 1 | 1 | ✅ PASS |
| `shift_register` | 1 | 1 | ✅ PASS |
| `handshake_buf` | 1 | 2 | ✅ PASS |
| `empty_source` | 0 | 0 | ✅ PASS |

**8/8 pass (100%)**

### Test Statistics

| Scope | Value |
|---|---|
| Unit tests (engines, models) | included in 5,926 |
| Widget tests (UI components) | included in 5,926 |
| Integration tests (full workbench) | included in 5,926 |
| Total | **5,926 passing** |
| Test files | 159 |
| `flutter analyze` errors | **0** |
| `flutter analyze` info warnings | 30 (pre-existing, in unmodified files) |

### Evaluation Pipeline

```
EvaluationCase ─── name · rtlSource · expectations
      ▼
EvaluationRunner.runCase()
      ├─ Parse (ms)   ├─ AST (ms)    ├─ Symbol (ms)  ├─ Semantic (ms)
      ├─ Design (ms)  ├─ Property (ms)  └─ Verify (ms)
      ▼
EvaluationMetrics ─── timing + module/signal/FSM/property/diagnostic counts
      ▼
EvaluationReport  ─── toMarkdown() · toJson() · toCsv()
      ▼
EvaluationExporter.exportAll("docs/benchmark_results")
```


---

## Research Platform

`EvaluationExporter.exportResearchArtifacts(report, outputDir)` auto-generates a reproducible
research bundle on every evaluation run:

```
research_output/
  csv/
    performance.csv      ← per-stage timing (parse/ast/symbol/semantic/design/property/verify/total)
    semantic.csv         ← design counts (modules/ports/signals/registers/instances/FSMs/clocks)
    verification.csv     ← pass/fail · diagnostic counts · failure reasons
    benchmarks.csv       ← all columns combined (EvaluationReport.toCsv())
  json/
    performance.json
    semantic.json
    verification.json
    benchmarks.json
  markdown/
    summary.md           ← benchmark table + pipeline summary
    benchmark_report.md  ← EvaluationReport.toMarkdown() — timing breakdown + failures
  metadata/
    experiment.json      ← experimentId · timestamp · version · counts · status
```

**`metadata/experiment.json`:**

```json
{
  "experimentId":     "eval-20260701-120000",
  "timestamp":        "2026-07-01T12:00:00.000Z",
  "chiplensVersion":  "1.0.0",
  "benchmarkCount":   8,
  "testCount":        8,
  "evaluationStatus": "passed"
}
```

`evaluationStatus` → `"passed"` | `"partial"` | `"failed"`.

All 11 output files are written concurrently. Directories are created automatically.


---

## Engineering Workbench

VS Code-style desktop IDE built in Flutter with immutable MVVM state.

| Component | Description |
|---|---|
| `EngineeringWorkbench` | Root widget; owns all controllers; dispatches all keyboard shortcuts |
| `ActivityBar` | 48 px Cursor-style strip; 9 items; left-border selection indicator |
| `WorkbenchToolbar` | Title bar with global search pill, action groups, project context |
| `WorkspaceExplorer` | Tree navigator; expand/collapse; search filter; CollapseAll/ExpandAll |
| `RtlWorkspace` | Tabbed editor; breadcrumb; split H/V; word-wrap; `EditorToolbar` |
| `RightSidebarPanel` | Outline / Symbols / Properties tabs; live `OutlineController` |
| `ProblemsPanel` | Diagnostics with severity icons; file:line references |
| `OutputPanel` | Scrollable analysis log; monospace; selectable text |
| `CommandPaletteDialog` | Ctrl+Shift+P — 18 commands, fuzzy label match |
| `QuickOpenDialog` | Ctrl+P — open document by name |
| `GlobalSearchDialog` | Ctrl+Shift+F — full-text search; line-level match highlight |
| `GoToSymbolDialog` | Ctrl+Shift+O — jump to module/port/always-block |
| `WorkbenchStatusbar` | 22 px; project · branch · encoding · language · verification dot |

**Keyboard shortcuts:**

```
Ctrl+P            Quick open              Ctrl+Shift+P    Command palette
Ctrl+Shift+F      Global search           Ctrl+Shift+O    Go to symbol
Ctrl+W            Close tab               Ctrl+Shift+W    Close all tabs
Ctrl+Tab          Next tab                Ctrl+Shift+Tab  Previous tab
Ctrl+B            Toggle sidebar          Ctrl+1/2/3      Focus panel
Alt+Shift+1/2/3   Split editor layout     F11             Fullscreen
```

**Design system:** 8-point grid · Inter (11/12/14/16/24 px) · Cursor palette
(`#141414` bg · `#181818` activity bar · violet-500 primary) · zero gradients.


---

## Getting Started

**Prerequisites:**

| Requirement | Version |
|---|---|
| Flutter SDK | ≥ 3.19 |
| Node.js | ≥ 20 |
| MSYS2 (Windows) | with `sby`, `verilator`, `iverilog`, `yosys` on PATH |

```bash
# 1. Backend
cd backend
npm install
node index.js                     # or: pm2 start ecosystem.config.js

# 2. Frontend
cd frontend
flutter pub get
flutter run -d windows            # or: macos / linux

# 3. Tests
flutter test --no-pub             # expects: All 5926 tests passed

# 4. Lint
flutter analyze --no-pub          # expects: No issues found / 0 errors

# 5. Run benchmark suite and generate research artifacts
#    (from Dart, inside the app or a test harness)
#    EvaluationRunner().runSuite(EvaluationSuite.defaults())
#      .then((r) => EvaluationExporter.exportResearchArtifacts(r, 'research_output'))
```

**The IDE boots without a running backend.** The backend is required only for formal
verification (SymbiYosys), lint (Verilator/Yosys/Icarus), and NL-to-RTL synthesis. All
parsing, semantic analysis, and property inference run in-process in Dart.

---

## Roadmap

| Milestone | Status | Description |
|---|---|---|
| M1 — IDE Shell | ✅ Done | Flutter desktop workbench, activity bar, project system |
| M2 — Semantic Engine | ✅ Done | Parser, AST, symbol table, semantic analysis, navigation |
| M2.1 — Workbench Polish | ✅ Done | Professional IDE UX, command palette, global search |
| M2.2 — Analysis Engine | ✅ Done | Dependency/dataflow graph, fan-in/out, analysis reports |
| M3 — Evaluation | ✅ Done | Benchmark framework, 8 designs, evaluation pipeline |
| L4 — NL Synthesis | ✅ Done | Intent classifier, RTL generator (8 design templates) |
| L5/L6 — Navigation | ✅ Done | Go To Definition, Find References |
| R1 — Research Platform | ✅ Done | Reproducible research artifact bundle, experiment metadata |
| L3 Parser | Planned | Full identifier extraction from assignment RHS (removes L2 edge limitation) |
| M4 — Cloud Verify | Planned | Cloud-based formal verification, no local EDA toolchain required |
| M5 — LLM Integration | Planned | LLM-powered property suggestion, counterexample explanation |

---

## Citation

```bibtex
@software{chiplens2026,
  title   = {ChipLens Lite: An AI-Native RTL Engineering Workbench},
  author  = {Paul, Anumeha},
  year    = {2026},
  url     = {https://github.com/anumehapaul/ChipLens-Lite},
  note    = {5926 tests · 14-stage verification pipeline · 8 property inference providers}
}
```

---

*ChipLens Lite — RTL verification without the context switch.*
