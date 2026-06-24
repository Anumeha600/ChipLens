# Case Study: Traffic Light FSM

**File:** `test/fixtures/rtl/fsm.v`  
**Pipeline run date:** 2026-06-24  
**Benchmark runtime:** 2 ms

---

## 1. Design Overview

A synchronous 3-state Mealy-style finite state machine modeling a traffic light controller. A sensor input influences the RED-to-GREEN transition, making output behavior input-dependent in that state.

| Property | Value |
|----------|-------|
| Module name | `traffic_light_fsm` |
| State register | `state [1:0]` |
| States | 3: RED (00), GREEN (01), YELLOW (10) |
| Clock edge | Positive (posedge clk) |
| Reset type | Synchronous, active-high (`rst`) |
| External input | `sensor` — controls RED→GREEN transition |
| RTL lines | 23 |

**Behavioral intent:** The FSM cycles RED → GREEN → YELLOW → RED. In the RED state, the next state is conditioned on `sensor`: if the sensor is asserted, the light turns green; otherwise it remains red. GREEN always transitions to YELLOW, and YELLOW always returns to RED.

---

## 2. RTL Input

```verilog
module traffic_light_fsm (
  input  wire       clk,
  input  wire       rst,
  input  wire       sensor,
  output reg  [1:0] state
);
  localparam RED    = 2'b00;
  localparam GREEN  = 2'b01;
  localparam YELLOW = 2'b10;

  always @(posedge clk) begin
    if (rst)
      state <= RED;
    else begin
      case (state)
        RED:     state <= sensor ? GREEN : RED;
        GREEN:   state <= YELLOW;
        YELLOW:  state <= RED;
        default: state <= RED;
      endcase
    end
  end
endmodule
```

Key structural features:
- Synchronous reset: `rst` appears inside the always block, not in the sensitivity list
- `case(state)` construct with three named states and a `default` branch
- Sensor-conditional transition in the RED state

---

## 3. Design Intelligence Output

`DesignRunner.analyze()` extracts structural knowledge about the design.

**Detected structural features:**

| Feature | Detected | Notes |
|---------|----------|-------|
| Clock signal | Yes | `clk` — positive edge trigger |
| Sync reset | Yes | `rst` — active-high, inside always block |
| Async reset | No | Not in sensitivity list |
| FSM | Yes | `case(state)` with state register |
| States | 3 | RED, GREEN, YELLOW (via localparam) |
| Counter pattern | No | `state` register does not match counter name heuristic |
| Register | Yes | `state` — clocked assignment target |

FSM detection relies on identifying `case` statements that switch on a register variable. The three `localparam` declarations provide the state encoding, though ChipLens extracts the structural pattern rather than symbolically evaluating the encoding.

---

## 4. Diagnostics Analysis

**Note:** The benchmark pipeline uses a heuristic coverage estimate rather than formal verification. The coverage figure reflects structural complexity, not measured state coverage.

**Heuristic:** `complexity = fsms.length + registers.length`. An FSM design with at least one register places coverage below the minimal threshold.

| Field | Value |
|-------|-------|
| Issue count | 1 |
| Issue title | Coverage low |
| Category | coverage |
| Severity | low |
| Estimated coverage | ~85–91% |
| Coverage risk | CoverageRisk.low |

**Issue description:** "Coverage is slightly below target."

**What this means:** FSM designs have non-trivial state spaces. Without formal verification or simulation, ChipLens flags a coverage concern because the RED-state sensor branch and the default state are not verified to be reachable or safe. The diagnostic is conservative: it does not claim that coverage is bad, only that it has not been confirmed to be sufficient.

---

## 5. Repair Planning

| Field | Value |
|-------|-------|
| Step count | 1 |
| Step title | Fix: Coverage low |
| Category | coverage |
| Priority | low |
| Complexity | medium |
| Dependencies | none |

**Reasoning:** The RepairPlanner maps the coverage diagnostic to a coverage repair suggestion. The medium complexity rating reflects that improving FSM state coverage typically requires writing cover properties for each state and transition, or augmenting the verification environment with constrained-random stimulus.

---

## 6. Verification Workflow

```text
traffic_light_fsm.v (23 lines, 3-state FSM)
     │
     ▼
Design Intelligence (DesignRunner.analyze)
     │  Detected: clock, sync reset, FSM (3 states), register
     ▼
Coverage Assessment (heuristic)
     │  FSM + register detected → complexity ≥ 1
     │  Estimated coverage below minimal threshold → CoverageRisk.low
     ▼
Diagnostics Intelligence (DiagnosticsEngine.analyze)
     │  1 issue: "Coverage low" (severity: low)
     │  Summary: "Minor verification concerns detected."
     ▼
Repair Planning (RepairPlanner.plan)
     │  1 step: "Fix: Coverage low" (priority: low, complexity: medium)
     ▼
BenchmarkResult
     designName: fsm
     diagnostics: 1   repairs: 1   runtime: 2 ms   success: true
```

---

## 7. Observations

**Strengths:**
- The FSM is correctly identified from the `case(state)` pattern. Design Intelligence does not require annotations or metadata: it extracts structural information directly from the RTL text.
- The synchronous reset (inside the always block) is correctly distinguished from an asynchronous reset (in the sensitivity list).
- Pipeline execution completes correctly and deterministically.

**Limitations:**
- The FSM detection identifies the presence of a state machine but does not extract the full transition relation. ChipLens does not verify properties like "the FSM eventually exits the RED state when sensor is asserted" or "the YELLOW state is always transient."
- The default branch in the case statement provides safe fallback behavior, but ChipLens does not verify that this branch is unreachable in normal operation.
- The coverage assessment is structural only. The actual reachable state space of this FSM (3 states, one conditional transition) is small and could be fully verified quickly with a formal tool.

**Future improvement:** Full property synthesis for this FSM would generate candidate properties for state reachability, transition correctness, and liveness (the sensor cannot prevent the traffic light from eventually cycling). These would be high-value properties to verify with a BMC or induction engine.
