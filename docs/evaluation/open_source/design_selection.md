# Open-Source RTL Design Selection

**Status:** Planning (no designs downloaded or integrated)  
**Date:** 2026-06-24  
**Purpose:** Document candidate external RTL designs for ChipLens evaluation

---

## Selection Criteria

Candidate designs are evaluated against the following criteria:

| Criterion | Rationale |
|-----------|-----------|
| Open-source license (MIT, Apache 2.0, ISC) | Allows use in academic and research contexts |
| Synthesizable Verilog or SystemVerilog | Required for DesignRunner.analyze() |
| No proprietary dependencies | Evaluation must be self-contained |
| Well-documented behavior | Enables comparison of ChipLens outputs against expected results |
| Varied structural complexity | Tests ChipLens across the full range of design patterns |
| Community recognition | Reduces risk of obscure corner cases dominating results |

Designs are grouped by complexity tier to support the phased evaluation roadmap.

---

## Tier 1 — Small Modules (< 200 lines)

These designs are closest in size to the existing benchmark fixtures (13–78 lines). They are appropriate for initial evaluation and for validating that ChipLens does not regress on real-world RTL.

---

### TinyTapeout Example Designs

| Field | Value |
|-------|-------|
| Repository | https://github.com/TinyTapeout/tt-verilog-template |
| License | Apache 2.0 |
| Language | Verilog |
| Estimated size | 20–150 lines per design |
| Complexity | Low |

**Description:** TinyTapeout is a community project that enables small ASIC designs to be fabricated on shared wafers. Contributors submit small Verilog modules that implement specific digital functions (counters, shift registers, simple communication interfaces, simple encoders). Each submitted design is self-contained and targets a tile of approximately 500 logic gates.

**Why selected:** TinyTapeout designs are the external RTL most similar in size and structure to the ChipLens benchmark fixtures. They include a variety of structural patterns (counters, FSMs, combinational logic) written by engineers with different styles and conventions. Evaluating on TinyTapeout designs tests whether ChipLens handles real-world coding conventions rather than purpose-built examples.

**Specific candidates:**
- `tt_um_7seg_fun` — Seven-segment display controller, combinational and registered logic
- `tt_um_wokwi_counter` — Small binary counter
- `tt_um_rgbmixer` — PWM-based RGB LED mixer with counters

**Anticipated ChipLens behavior:**
- DesignRunner should detect clock, reset, and counter patterns in counter designs
- FSM detection likely in display controller designs
- Small size suggests fast pipeline execution (2–5 ms estimated)

**Known challenges:**
- TinyTapeout designs use a shared top-level wrapper interface — extracting individual modules may require understanding the template structure

---

### wb2axip — Wishbone-to-AXI Bridge (individual modules)

| Field | Value |
|-------|-------|
| Repository | https://github.com/ZipCPU/wb2axip |
| License | LGPL-3.0 (with commercial exception) |
| Language | Verilog |
| Estimated size | 100–500 lines per module |
| Complexity | Medium-Low |

**Description:** A collection of Wishbone and AXI bus interface components by Dan Gisselquist (Zip CPU). The repository is notable because many modules ship with formal verification specifications written by the original author, using SymbiYosys `.sby` flow files. This makes it possible to compare ChipLens's heuristic diagnostics against the actual formal verification conclusions.

**Why selected:** The existence of author-provided formal verification specifications creates a ground truth against which ChipLens outputs can be compared. If ChipLens flags a coverage concern on a module that the author has formally verified to be correct, that is a measurable false positive. If ChipLens does not flag a concern on a module with known verification failures, that is a measurable false negative.

**Specific candidates:**
- `skidbuffer.v` — AXI skid buffer, ~200 lines, formally verified
- `axilite2wbsp.v` — AXI-Lite to Wishbone bridge

**License note:** LGPL-3.0 with commercial exception. Suitable for research use.

---

## Tier 2 — Medium Modules (200–2,000 lines)

These designs introduce real structural complexity: multi-clock domains, parameterized hierarchies, and non-trivial state machines. They represent the next step beyond purpose-built examples.

---

### SERV — Serial RISC-V Processor

| Field | Value |
|-------|-------|
| Repository | https://github.com/olofk/serv |
| License | ISC (permissive) |
| Language | Verilog |
| Estimated size | ~800 lines (core) |
| Complexity | Medium |

**Description:** SERV is the world's smallest RISC-V CPU by area, implementing the RV32I instruction set using a bit-serial architecture. Rather than processing 32 bits in parallel, SERV processes one bit per clock cycle, dramatically reducing area at the cost of throughput. The design won the RISC-V Softcore Contest (2018).

**Why selected:** SERV's bit-serial architecture differs fundamentally from the parallel designs in the existing benchmark corpus. The structural patterns that ChipLens's heuristics target (registers named `count`, FSM `case` statements, clock/reset patterns) may appear differently in a bit-serial implementation. This makes SERV a useful stress test for structural detection heuristics.

**Anticipated ChipLens behavior:**
- FSM detection likely (bit-serial control is FSM-driven)
- Multiple shift registers may be detected as register patterns
- The bit-serial counter logic may or may not match the counter name heuristic
- Unknown whether parametric widths (serial designs often use 1-bit paths) affect detection

**Known challenges:**
- SERV has multiple modules with interdependencies; evaluating individual modules in isolation may not represent the full design intent
- Bit-serial designs have unusual structural patterns that may not match ChipLens's heuristics

---

### PicoRV32

| Field | Value |
|-------|-------|
| Repository | https://github.com/YosysHQ/picorv32 |
| License | ISC (permissive) |
| Language | Verilog |
| Estimated size | ~3,000 lines (single file) |
| Complexity | Medium-High |

**Description:** PicoRV32 is a small, single-file RISC-V CPU (RV32I/E/M) implementation by Clifford Wolf, the creator of Yosys and SymbiYosys. The entire processor fits in a single Verilog file (`picorv32.v`). It is widely used as a reference design in RISC-V research, FPGA projects, and verification benchmarks.

**Why selected:** PicoRV32 is arguably the most widely known small RISC-V implementation. It includes: a complex instruction decode FSM, multiple counting registers (instruction count, cycle count, return value registers), optional IRQ handling, optional multiplier/divider, and configurable pipeline depth. It is also used by the RISC-V Formal verification framework, providing a ground truth for verification results.

**Anticipated ChipLens behavior:**
- Multiple FSMs detected (instruction decode, IRQ handling)
- Multiple counter registers detected (cycle count, instruction count)
- Higher complexity → higher coverage risk estimate
- Possible multiple diagnostics (coverage moderate or high depending on detected structures)
- Runtime likely 10–50 ms (larger parse tree)

**Known challenges:**
- At ~3,000 lines, PicoRV32 is the largest design currently planned for evaluation and will test DesignRunner's scalability
- The design uses `generate` blocks and conditional compilation (`ifdef`) which may not be fully handled by text-based heuristics
- Many counter registers have names like `pcpi_rd` or `mem_rdata` that may not match the counter heuristic

---

### OpenTitan UART Module

| Field | Value |
|-------|-------|
| Repository | https://github.com/lowRISC/opentitan |
| Sub-path | `hw/ip/uart/rtl/` |
| License | Apache 2.0 |
| Language | SystemVerilog |
| Estimated size | 400–800 lines (core module) |
| Complexity | Medium |

**Description:** The OpenTitan UART module is a production-quality UART implementation from Google's open-source silicon project. Unlike the benchmark UART fixture (which is a minimal teaching example), the OpenTitan UART implements the full UVM-style register interface, FIFO buffers, parity checking, and configurable baud rate. It ships with formal verification specifications.

**Why selected:** The OpenTitan UART provides a direct comparison point for the existing `uart.v` benchmark case study. Both implement UART, but OpenTitan's version is production-grade and already formally verified. This creates a natural experiment: does ChipLens produce different and more diagnostic outputs for the more complex version?

**Known challenges:**
- OpenTitan uses SystemVerilog, not Verilog. ChipLens's text-based heuristics may or may not handle SystemVerilog constructs correctly.
- The OpenTitan UART uses a parameterized register map that requires understanding the full OpenTitan TLUL interface to evaluate meaningfully.
- Module boundaries are more complex than standalone designs.

---

## Tier 3 — Processor-Scale Designs (2,000–20,000 lines)

These designs represent real-world processor complexity. Evaluation at this tier primarily tests scalability rather than structural detection quality, since the heuristic-based approach reaches its limits on large, complex designs.

---

### Ibex RISC-V Core

| Field | Value |
|-------|-------|
| Repository | https://github.com/lowRISC/ibex |
| License | Apache 2.0 |
| Language | SystemVerilog |
| Estimated size | ~10,000 lines |
| Complexity | High |

**Description:** Ibex (formerly Zero-riscy) is a 2-stage in-order 32-bit RISC-V CPU (RV32IMCB) developed by ETH Zurich and maintained by lowRISC. It is the CPU core used in OpenTitan. The design includes a full pipeline, branch prediction, memory interface, exception handling, and debug support.

**Why selected:** Ibex is the most verification-mature open-source RISC-V core available, with extensive formal verification work, RISC-V compliance tests, and integration testing. It represents the kind of design that a real verification engineer would use ChipLens on. The question is whether ChipLens's structural analysis can extract meaningful information at this scale.

**Anticipated ChipLens behavior:**
- Many FSMs detected (pipeline stages, exception handling)
- Many registers detected (register file, CSRs, pipeline registers)
- High structural complexity → coverage estimate likely in high or critical risk tier
- Multiple diagnostics expected
- Runtime unknown; may be 100+ ms

**Known challenges:**
- SystemVerilog features (interfaces, packages, structs, enums) are not supported by ChipLens's text-based heuristics
- Multi-file hierarchical design requires flattening or per-module analysis
- At this scale, the heuristic approach is expected to produce false positives

---

## Tier 4 — Industrial-Scale (> 20,000 lines)

This tier is documented for completeness but is not planned for near-term evaluation. Designs at this scale require tool infrastructure (elaboration, hierarchical analysis) that goes beyond ChipLens's current text-based approach.

---

### OpenTitan (Full Chip)

| Field | Value |
|-------|-------|
| Repository | https://github.com/lowRISC/opentitan |
| License | Apache 2.0 |
| Language | SystemVerilog |
| Estimated size | > 500,000 lines |
| Complexity | Very High |

**Why documented:** OpenTitan is one of the most comprehensively verified open-source hardware projects. Evaluating ChipLens against individual OpenTitan IP blocks (uart, hmac, aes, flash_ctrl) is tractable. Full-chip evaluation is aspirational and would require substantial tooling investment.

---

## Priority Order for Evaluation

| Priority | Design | Tier | Rationale |
|----------|--------|------|-----------|
| 1 | TinyTapeout examples | 1 | Closest to current benchmark; low risk |
| 2 | wb2axip skidbuffer | 1 | Formal ground truth available; enables FP/FN measurement |
| 3 | SERV core | 2 | Unusual architecture; stress-tests heuristics |
| 4 | PicoRV32 | 2 | Most widely known small RISC-V; broad comparability |
| 5 | OpenTitan UART | 2 | Direct comparison to existing uart.v case study |
| 6 | Ibex | 3 | Processor-scale scalability test |
| 7 | OpenTitan (full chip) | 4 | Long-term aspiration |

---

## Designs Intentionally Excluded

| Design | Reason for Exclusion |
|--------|----------------------|
| Proprietary RTL | License restrictions |
| VHDL-only designs | ChipLens is Verilog/SystemVerilog focused |
| Designs requiring proprietary simulation libraries | Cannot be evaluated in isolation |
| Generated RTL (LiteX) | Generated code has unusual structural patterns that may bias results; deferred |
| mor1kx (OpenRISC) | Lower community usage than RISC-V alternatives; superseded by RISC-V ecosystem |
