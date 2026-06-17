// Explanation Engine — generates a structured Markdown engineering explanation
// covering design purpose, I/O, state machine, verification, and synthesis notes.

import '../../models/design_spec.dart';

class ExplanationEngine {
  static String explain(DesignSpecification spec, QualityReport quality) {
    final buf = StringBuffer();

    // ── Header ────────────────────────────────────────────
    buf.writeln('## ${spec.title}');
    buf.writeln();
    buf.writeln('> **Design type:** `${_typeName(spec.designType)}`  '
        '**Module:** `${spec.moduleName}`  '
        '**Grade:** ${quality.grade} (${quality.total}/100)');
    buf.writeln();

    // ── Design Description ────────────────────────────────
    buf.writeln('### What This Design Does');
    buf.writeln();
    buf.writeln(spec.description);
    buf.writeln();

    // ── I/O ───────────────────────────────────────────────
    buf.writeln('### Input / Output Interface');
    buf.writeln();
    buf.writeln('| Direction | Signal | Width | Description |');
    buf.writeln('|-----------|--------|-------|-------------|');
    for (final p in [...spec.inputs, ...spec.outputs]) {
      final dir  = p.direction == 'input' ? '**IN**' : '**OUT**';
      final bits = p.width == 1 ? '1-bit' : '${p.width}-bit';
      buf.writeln('| $dir | `${p.name}` | $bits | ${p.description} |');
    }
    buf.writeln();

    // ── State Machine ────────────────────────────────────
    if (spec.states.length >= 2) {
      buf.writeln('### State Machine');
      buf.writeln();
      buf.writeln('The FSM has **${spec.states.length} states** '
          'and **${spec.transitions.length} transitions**. '
          'Entry state: `${spec.entryState}`.');
      buf.writeln();
      buf.writeln('| State | Description | Role |');
      buf.writeln('|-------|-------------|------|');
      for (final s in spec.states) {
        final role = s.isEntry
            ? '🟢 Entry'
            : s.isExit
                ? '🔴 Exit'
                : '⬤ Normal';
        buf.writeln('| `${s.name}` | ${s.description} | $role |');
      }
      buf.writeln();

      // Key transitions
      buf.writeln('**Key transitions:**');
      buf.writeln();
      final shown = <String>{};
      for (final t in spec.transitions) {
        final key = '${t.from}→${t.to}';
        if (shown.contains(key)) continue;
        shown.add(key);
        final action = t.action != null ? ' → `${t.action}`' : '';
        buf.writeln('- `${t.from}` → `${t.to}` when `${t.condition}`$action');
        if (shown.length >= 10) {
          buf.writeln('- *(${spec.transitions.length - shown.length} more transitions — see FSM diagram)*');
          break;
        }
      }
      buf.writeln();
    }

    // ── Design-specific deep dive ─────────────────────────
    buf.write(_deepDive(spec));

    // ── Design Assumptions ───────────────────────────────
    if (spec.assumptions.isNotEmpty) {
      buf.writeln('### Design Assumptions & Constraints');
      buf.writeln();
      for (final a in spec.assumptions) {
        buf.writeln('- $a');
      }
      buf.writeln();
    }

    // ── Verification Strategy ─────────────────────────────
    buf.writeln('### Verification Strategy');
    buf.writeln();
    buf.write(_verificationNote(spec));
    buf.writeln();

    // ── RTL Quality ──────────────────────────────────────
    buf.writeln('### RTL Quality Analysis');
    buf.writeln();
    buf.writeln('| Category | Score | Max |');
    buf.writeln('|----------|-------|-----|');
    final meta = <String, (String, int)>{
      'correctness':      ('Correctness',      35),
      'synthesizability': ('Synthesizability', 30),
      'maintainability':  ('Maintainability',  20),
      'fsm':              ('FSM Quality',      15),
    };
    for (final e in meta.entries) {
      final score = quality.categories[e.key] ?? 0;
      final (label, max) = e.value;
      final bar = _bar(score, max);
      buf.writeln('| $label | $score / $max | $bar |');
    }
    buf.writeln();

    if (quality.warnings.isEmpty) {
      buf.writeln('✅ **No warnings** — design follows synthesizable RTL best practices.');
    } else {
      buf.writeln('**Warnings & notes:**');
      buf.writeln();
      for (final w in quality.warnings) {
        final icon = w.severity == 'critical'
            ? '🔴'
            : w.severity == 'warning'
                ? '🟡'
                : 'ℹ️';
        buf.writeln('$icon `${w.type}` — ${w.message}');
      }
    }
    buf.writeln();

    // ── Synthesis Notes ───────────────────────────────────
    buf.writeln('### Synthesis Notes');
    buf.writeln();
    buf.writeln('This module targets **standard-cell ASIC / FPGA** synthesis with:');
    buf.writeln();
    buf.writeln('- **Reset:** Active-low synchronous `rst_n` — compatible with most PDKs');
    buf.writeln('- **Clocking:** Single-clock domain — no CDC issues');
    buf.writeln('- **State encoding:** Binary-weighted `localparam` — '
        'synthesizer will choose optimal encoding (One-Hot on FPGA, Binary on ASIC)');
    buf.writeln('- **Output type:** Moore machine — outputs stable between transitions, '
        'reducing glitch risk');
    buf.writeln('- **Estimated resources:** ~${spec.states.length} flip-flops for state, '
        '+ datapath registers + combinational logic');

    return buf.toString();
  }

  // ─── Design-specific deep dives ──────────────────────────────────────────────

  static String _deepDive(DesignSpecification spec) {
    switch (spec.designType) {
      case 'vending_machine':
        final coins = List<int>.from(spec.params['coins'] as List)..sort();
        final price = spec.params['price'] as int;
        return '''### How the Vending Machine Works

The FSM accumulates inserted coin values in its state, replacing a numeric counter
with explicit states for each reachable partial sum. This makes it glitch-free and
fully synthesizable without an adder.

**Credit accumulation:**
${coins.map((c) => '- Insert Rs.$c → advance one credit state').join('\n')}

When accumulated credit reaches **Rs.$price**, the `DISPENSE` output pulses HIGH for
one clock cycle. The machine immediately returns to `IDLE`, allowing the next customer.

**Moore vs Mealy:** `dispense` is a **Moore** output — it is solely a function of
the current state, not the current coin input. This prevents spurious glitches.

''';

      case 'traffic_light':
        final g = spec.params['green_time'] as int;
        final y = spec.params['yellow_time'] as int;
        final r = spec.params['red_time'] as int;
        return '''### How the Traffic Light Works

The controller uses a **free-running down-counter (timer)** shared across all three
phases. When the timer expires, the FSM transitions and the timer resets to zero.

**Phase durations:**
| Phase | Duration | light[2:0] |
|-------|----------|------------|
| GREEN | $g cycles | `001` |
| YELLOW | $y cycles | `010` |
| RED | $r cycles | `100` |

Total cycle time: **${g + y + r} clock cycles**.

**One-hot light encoding:** exactly one bit is HIGH at a time, making the physical
output safe — no intermediate states where two lights appear simultaneously.

''';

      case 'elevator':
        final floors = spec.params['floors'] as int;
        return '''### How the Elevator Controller Works

The SCAN algorithm minimises average wait time by servicing all requests in the
current direction before reversing — like a disk scheduling algorithm.

**Request register:** A $floors-bit register `requests` latches floor call buttons.
The bit for the current floor is cleared when doors open (in `DOOR_OPEN` state).

**Direction decision (in IDLE):**
1. If `req[floor]` — serve immediately (open doors)
2. If any request above current floor — go `MOVE_UP`
3. If any request below current floor — go `MOVE_DOWN`

**Floor movement:** The `floor` register increments/decrements by 1 each cycle
in MOVE states. In a real implementation, add a delay counter per floor (~2s travel).

''';

      case 'uart_transmitter':
        final baud = spec.params['baud'] as int;
        final isRx = spec.params['is_rx'] as bool;
        return '''### How the UART ${isRx ? "Receiver" : "Transmitter"} Works

**Baud rate generation:** A 16-bit `baud_cnt` counter divides the system clock
down to the bit period. At 50 MHz / $baud baud = ${50000000 ~/ baud} clocks per bit.

**${isRx ? "Reception" : "Transmission"} sequence (8N1):**
${isRx ? """1. IDLE — monitor rx_in, detect falling edge (start bit)
2. START_BIT — validate at mid-bit point (CLKS_PER_BIT/2 cycles in)
3. DATA_BITS — sample 8 bits at each baud boundary, LSB first
4. STOP_BIT — verify stop bit = '1'; pulse rx_valid""" : """1. IDLE — assert tx_out=1 (mark state), wait for tx_valid
2. START_BIT — drive tx_out=0 for one baud period
3. DATA_BITS — shift out 8 bits LSB-first, one per baud period
4. STOP_BIT — drive tx_out=1 for one baud period, then return to IDLE"""}

**LSB-first:** UART standard transmits least-significant bit first. The shift register
${isRx ? "right-shifts captured bits into the MSB, so the final register holds the byte correctly." : "right-shifts so that shift_reg[0] always holds the next bit to transmit."}

''';

      case 'sequence_detector':
        final seq = spec.params['sequence'] as String;
        final overlap = spec.params['overlap'] as bool;
        return '''### How the Sequence Detector Works

The FSM implements the **Knuth-Morris-Pratt (KMP)** string matching algorithm in
hardware. Each state represents how many leading characters of "$seq" have been
matched so far.

**State meaning:**
- `S_INIT` — no prefix matched (0 bits)
${List.generate(seq.length, (i) => '- `S_${seq.substring(0, i + 1)}` — matched "${seq.substring(0, i + 1)}" (${ i + 1} bit${i > 0 ? "s" : ""})', ).join('\n')}

**${overlap ? "Overlapping" : "Non-overlapping"} detection:**
${overlap ? """After a full match in `S_$seq`, the FSM does **not** return to `S_INIT`.
Instead it follows the KMP failure function to the longest proper prefix of "$seq"
that is also a suffix, enabling detection of overlapping occurrences.""" : """After detection the FSM resets to `S_INIT`, missing any overlap.
To enable overlapping detection, set the `overlap` parameter in the prompt."""}

''';

      case 'digital_lock':
        final combo = spec.params['combination'] as String;
        final maxAttempts = spec.params['max_attempts'] as int;
        return '''### How the Digital Lock Works

The FSM tracks progress through the ${'${combo.length}'}-digit combination "$combo"
digit by digit. A separate **attempt counter** counts failed complete-entry attempts.

**Security model:**
- Any **wrong digit at any step** resets progress to `IDLE` and increments the counter
- After **$maxAttempts failures**, the FSM enters `LOCKOUT` and ignores all inputs
- `LOCKOUT` can only be cleared by asserting `rst_n` (hardware reset)
- The attempt counter has ${maxAttempts.bitLength} bits → max $maxAttempts trackable attempts

**`digit_valid` strobe:** The input must be a single-cycle pulse. If held HIGH,
the same digit will be entered on every clock cycle — protect with edge detection
in the top-level integration.

''';

      case 'pwm_generator':
        final bits = spec.params['bits'] as int;
        final duty = spec.params['duty'] as int;
        final dutyPct = (duty * 100.0 / (1 << bits)).toStringAsFixed(1);
        return '''### How the PWM Generator Works

A $bits-bit free-running counter `counter` wraps from 0 to ${(1 << bits) - 1}
every **${1 << bits} clock cycles** (the PWM period). The output is HIGH when
`counter < duty_reg` and LOW otherwise — a simple digital comparator.

**Default duty cycle:** $duty / ${1 << bits} = **$dutyPct%**

**Duty cycle formula:** duty_cycle% = (duty_register / ${1 << bits}) × 100

**Resolution:** $bits bits → ${1 << bits} discrete duty levels (${(100 / (1 << bits)).toStringAsFixed(2)}% per LSB)

**Frequency:** PWM_freq = CLK_FREQ / ${1 << bits}
At 50 MHz → ${(50000000 / (1 << bits)).toStringAsFixed(0)} Hz PWM frequency

''';

      default:
        return '''### Template Design

This is a **3-state FSM template** generated for your description. Customise:
1. Add domain-specific inputs/outputs to the port list
2. Replace the single-cycle `ACTIVE` state with your datapath logic
3. Add a counter if your operation takes multiple cycles

''';
    }
  }

  // ─── Verification notes ───────────────────────────────────────────────────────

  static String _verificationNote(DesignSpecification spec) {
    switch (spec.designType) {
      case 'vending_machine':
        return '''The auto-generated testbench covers:
- All valid coin sequences that sum exactly to the product price
- Overpayment (if applicable) — dispense + change
- Idle state — no dispense without coins
- Reset mid-sequence — returns cleanly to IDLE
''';
      case 'traffic_light':
        return '''The testbench verifies:
- Correct initial state (GREEN after reset)
- Exact phase durations (GREEN_TIME, YELLOW_TIME, RED_TIME)
- Correct phase ordering: GREEN → YELLOW → RED → GREEN
- Reset from any phase returns to GREEN
''';
      case 'sequence_detector':
        return '''The testbench verifies:
- No false detection on all-zeros stream
- Detection occurs on the target pattern `${spec.params['sequence']}`
- ${spec.params['overlap'] == true ? "Overlapping detection — back-to-back patterns" : "Non-overlapping — resets after each detection"}
- Reset clears matched prefix
- Inspect the generated VCD waveform to confirm exact detection timing
''';
      case 'digital_lock':
        return '''The testbench verifies:
- Correct combination → UNLOCKED
- Reset after unlock → re-locks
- Wrong first digit → stays IDLE, increments attempt counter
- Exhausting max attempts → LOCKOUT
- LOCKOUT persists until reset
''';
      case 'uart_transmitter':
        return '''The testbench uses accelerated simulation parameters (CLK=1000, BAUD=100 = 10 clks/bit)
to complete in microseconds while maintaining identical logic coverage:
- Framing correctness (start=0, 8 data bits LSB-first, stop=1)
- Back-to-back byte transmission
- tx_ready de-asserts during TX, re-asserts on completion
''';
      default:
        return '''The auto-generated testbench covers the golden path (IDLE → ACTIVE → DONE)
and reset behaviour. Extend with your domain-specific corner cases.
''';
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static String _typeName(String type) {
    const names = <String, String>{
      'vending_machine':    'Vending Machine FSM',
      'traffic_light':      'Traffic Light Controller',
      'elevator':           'Elevator Controller FSM',
      'uart_transmitter':   'UART TX/RX FSM',
      'sequence_detector':  'KMP Sequence Detector FSM',
      'digital_lock':       'Digital Lock FSM',
      'pwm_generator':      'PWM Generator',
      'generic':            'Generic FSM Template',
    };
    return names[type] ?? type;
  }

  static String _bar(int score, int max) {
    final filled = max > 0 ? (score * 10 ~/ max) : 0;
    return '█' * filled + '░' * (10 - filled);
  }
}
