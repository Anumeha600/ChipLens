# ADR-0001 — Unified Verification Framework

## Status

Accepted

---

## Context

ChipLens integrates multiple verification tools, including Verilator, Yosys, Icarus Verilog, and future verification engines.

Originally, each backend executed tools independently.

This resulted in duplicated process execution logic, inconsistent interfaces, and increased maintenance cost.

---

## Decision

Introduce a unified Verification Framework consisting of:

- VerificationRunner
- VerificationTool
- VerificationContext
- VerificationResult

Each verification backend implements the VerificationTool interface.

VerificationRunner becomes responsible for coordinating execution.

---

## Consequences

### Advantages

- Consistent execution flow.
- Easier addition of new verification tools.
- Shared process management.
- Reduced code duplication.
- Improved testability.

### Trade-offs

- Slight increase in abstraction.
- Additional framework layer.

---

## Alternatives Considered

Maintain independent services for each verification backend.

Rejected because it duplicated execution logic and prevented consistent orchestration.

---

## Outcome

Accepted.

This architecture forms the foundation for future verification backends, including formal verification and timing analysis.