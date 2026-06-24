# ChipLens Open-Source Evaluation Results

> **Instructions:** Copy this file, rename it to `results_<design_name>.md`, and fill in every section. Do not omit sections — write "Not applicable" or "Not available" rather than leaving fields blank. Remove these instruction blocks before publishing.

---

## Metadata

| Field | Value |
|-------|-------|
| Design name | <!-- e.g., picorv32 --> |
| Module name | <!-- e.g., picorv32 --> |
| Repository | <!-- full URL --> |
| Repository commit | <!-- full git SHA --> |
| File evaluated | <!-- relative path within repo --> |
| License | <!-- e.g., ISC, Apache 2.0 --> |
| Evaluation date | <!-- YYYY-MM-DD --> |
| ChipLens version | <!-- v1.0.0 or git SHA --> |
| Evaluator | <!-- name or "automated" --> |
| Tier | <!-- 1 / 2 / 3 / 4 --> |

---

## 1. Design Overview

<!-- Describe the design in 2–4 sentences. What does it do? Who created it? Why is it relevant to ChipLens evaluation? -->

---

## 2. Design Statistics

| Property | Value |
|----------|-------|
| RTL lines | <!-- count --> |
| Module count (file) | <!-- modules declared in the evaluated file --> |
| Language | <!-- Verilog / SystemVerilog --> |
| Clock domains | <!-- number, if known --> |
| Reset style | <!-- sync / async / mixed --> |
| FSMs (expected) | <!-- count, if known from documentation --> |
| Registers (expected) | <!-- count, if known --> |

**Preprocessing applied:**

<!-- List any lines removed (includes, undefined macros, etc.). If none, write "None." -->

**Parameters used:**

<!-- List parameter name = value for any non-default parameters. If defaults, write "All defaults." -->

---

## 3. ChipLens Design Intelligence Output

> Source: `DesignRunner.analyze()` → `DesignKnowledge`

| Field | Value |
|-------|-------|
| `hasClock` | <!-- true / false --> |
| `hasReset` | <!-- true / false --> |
| `hasFSM` | <!-- true / false --> |
| `hasCounter` | <!-- true / false --> |
| `hasHandshake` | <!-- true / false --> |
| `primaryClocks.length` | <!-- integer --> |
| `syncResets.length` | <!-- integer --> |
| `asyncResets.length` | <!-- integer --> |
| `fsms.length` | <!-- integer --> |
| `counters.length` | <!-- integer --> |
| `registers.length` | <!-- integer --> |

**Assessment — structure detection accuracy:**

<!-- Compare ChipLens's output against the known design. For each detection result, note whether it is correct, a false positive, or a false negative. -->

| Feature | Expected | Detected | Accurate? | Notes |
|---------|----------|----------|-----------|-------|
| Clock | <!-- Yes/No --> | <!-- true/false --> | <!-- Yes/No/FP/FN --> | |
| Reset | <!-- Yes/No --> | <!-- true/false --> | <!-- Yes/No/FP/FN --> | |
| FSM | <!-- Yes/No --> | <!-- true/false --> | <!-- Yes/No/FP/FN --> | |
| Counter | <!-- Yes/No --> | <!-- true/false --> | <!-- Yes/No/FP/FN --> | |

---

## 4. Diagnostics

> Source: `DiagnosticsEngine.analyze()` → `DiagnosticReport`

| Field | Value |
|-------|-------|
| `overallSeverity` | <!-- informational / low / medium / high / critical --> |
| `summary.verificationHealth` | <!-- healthy / acceptable / reduced / degraded / failing --> |
| `issues.length` | <!-- integer --> |

**Issue list:**

| # | Title | Category | Severity | Description (abbreviated) |
|---|-------|----------|----------|--------------------------|
| 1 | <!-- title --> | <!-- category --> | <!-- severity --> | <!-- brief description --> |
| 2 | | | | |

<!-- Add rows as needed. If no issues, write a single row: "None" / "–" / "–" / "–" / "No issues produced." -->

**Note on coverage estimate:**

<!-- State the estimated coverage percentage and coverage risk tier from the heuristic. Remind the reader that this is a heuristic estimate, not a formal measurement. -->

---

## 5. Repair Suggestions

> Source: `RepairPlanner.plan()` → `RepairPlan`

| Field | Value |
|-------|-------|
| `overallPriority` | <!-- critical / high / medium / low --> |
| `overallComplexity` | <!-- high / medium / low --> |
| `steps.length` | <!-- integer --> |

**Repair step list:**

| # | Title | Category | Priority | Complexity |
|---|-------|----------|----------|------------|
| 1 | <!-- title --> | <!-- category --> | <!-- priority --> | <!-- complexity --> |
| 2 | | | | |

<!-- Add rows as needed. If no steps, write a single row with "None." -->

---

## 6. Runtime

| Metric | Value |
|--------|-------|
| Total pipeline runtime | <!-- ms --> |
| Pipeline success | <!-- Yes / No --> |
| Exception (if any) | <!-- message, or "None" --> |

---

## 7. Ground Truth Comparison

<!-- Complete this section only when a formal verification reference is available for this design (e.g., author-provided .sby result, published verification report). If not available, write: "No formal verification reference available for this design." -->

**Reference source:** <!-- URL or citation -->

**Formal verification outcome:** <!-- Pass / Fail / Unknown -->

| ChipLens Diagnostic | Corresponds to Real Issue? | Classification |
|---------------------|---------------------------|----------------|
| <!-- diagnostic title --> | <!-- Yes / No / Uncertain --> | <!-- True Positive / False Positive / Unknown --> |

**False positive count:** <!-- integer or "N/A" -->

**False negative count:** <!-- integer or "N/A — ground truth incomplete" -->

---

## 8. Observations

<!-- 3–6 bullet points summarizing what was learned from this evaluation. Be specific and honest. -->

**Accurate detections:**

-
-

**Missed detections or false positives:**

-
-

**Unexpected behaviors:**

-

---

## 9. Limitations

<!-- List limitations specific to this evaluation that affect the interpretation of results. Distinguish between general methodology limitations (documented in evaluation_methodology.md) and design-specific issues. -->

-
-
-

---

## 10. Future Improvements

<!-- Suggest specific ChipLens improvements motivated by this evaluation. If ChipLens already handles the design correctly, write "No improvements suggested by this evaluation." -->

| Improvement | Affected Component | Priority |
|-------------|-------------------|----------|
| <!-- description --> | <!-- DesignRunner / DiagnosticsEngine / RepairPlanner --> | <!-- High / Medium / Low --> |

---

## Raw Output

<!-- Paste the complete raw output here for reproducibility. Include all fields, not just those used in the sections above. -->

```
DesignKnowledge:
  hasClock:      
  hasReset:      
  hasFSM:        
  hasCounter:    
  hasHandshake:  
  primaryClocks:  []
  syncResets:     []
  asyncResets:    []
  fsms:           []
  counters:       []
  registers:      []

DiagnosticReport:
  overallSeverity:  
  verificationHealth:
  issues: [
    // {title, category, severity, description}
  ]

RepairPlan:
  overallPriority:  
  overallComplexity:
  steps: [
    // {title, category, priority, complexity}
  ]

Runtime: ms
Success: 
```
