// RTL Generator — produces synthesizable Verilog from a DesignSpecification.
// Every generated module is complete: timescale, ports, params, sequential &
// combinational always blocks, reset handling, and default case branches.

import '../../models/design_spec.dart';

class RtlGenerator {
  static String generate(DesignSpecification spec) {
    switch (spec.designType) {
      case 'vending_machine':
        return _vendingMachine(spec);
      case 'traffic_light':
        return _trafficLight(spec);
      case 'elevator':
        return _elevator(spec);
      case 'uart_transmitter':
        return _uart(spec);
      case 'sequence_detector':
        return _sequenceDetector(spec);
      case 'digital_lock':
        return _digitalLock(spec);
      case 'pwm_generator':
        return _pwm(spec);
      default:
        return _generic(spec);
    }
  }

  // ─── Vending Machine ─────────────────────────────────────────────────────────

  static String _vendingMachine(DesignSpecification spec) {
    final coins = List<int>.from(spec.params['coins'] as List)..sort();
    final price = spec.params['price'] as int;
    final hasChange = spec.outputs.any((o) => o.name.startsWith('change_'));
    final stateCount = spec.states.length;
    final stateBits = (stateCount - 1).bitLength.clamp(1, 8);

    // Build state localparam block
    final stateParams = StringBuffer();
    for (int i = 0; i < spec.states.length; i++) {
      stateParams.write(
          "    ${spec.states[i].name.padRight(12)} = ${stateBits}'d$i");
      stateParams.write(i < spec.states.length - 1 ? ',\n' : ';');
    }

    // Build next-state case branches
    final nsCases = StringBuffer();
    // We need to reconstruct reachable amounts
    final reachable = <int>{0};
    final queue = [0];
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      for (final coin in coins) {
        final next = curr + coin;
        if (next < price && !reachable.contains(next)) {
          reachable.add(next);
          queue.add(next);
        }
      }
    }
    final amounts = reachable.toList()..sort();
    final stateNames = <int, String>{
      for (final a in amounts) a: a == 0 ? 'IDLE' : 'S$a'
    };

    for (final amt in amounts) {
      final sName = stateNames[amt]!;
      nsCases.write('      $sName: begin\n');
      bool first = true;
      for (final coin in coins) {
        final next = amt + coin;
        String toState;
        if (next == price) {
          toState = 'DISPENSE';
        } else if (next > price) {
          toState = hasChange ? 'OVER' : 'IDLE';
        } else if (stateNames.containsKey(next)) {
          toState = stateNames[next]!;
        } else {
          continue;
        }
        if (first) {
          nsCases.write('        if      (coin_$coin) next_state = $toState;\n');
          first = false;
        } else {
          nsCases.write('        else if (coin_$coin) next_state = $toState;\n');
        }
      }
      nsCases.write('      end\n');
    }
    nsCases.write('      DISPENSE:   next_state = IDLE;\n');
    if (hasChange) nsCases.write('      OVER:       next_state = IDLE;\n');
    nsCases.write('      default:    next_state = IDLE;\n');

    final changeOutput = hasChange
        ? '    change_${coins.first} = (state == OVER);\n'
        : '';

    final coinPorts = coins.map((c) => '  input  wire       coin_$c,').join('\n');
    final changePorts = hasChange
        ? '\n  output reg        change_${coins.first}'
        : '';

    return '''`timescale 1ns / 1ps
// ============================================================
//  Vending Machine Controller
//  Coins : ${coins.map((c) => 'Rs.$c').join(' / ')}
//  Price : Rs.$price
//  Type  : Moore FSM, synchronous reset
// ============================================================

module ${spec.moduleName} (
  input  wire       clk,
  input  wire       rst_n,
$coinPorts
  output reg        dispense$changePorts
);

  // ── State encoding ──────────────────────────────────────
  localparam [$stateBits-1:0]
$stateParams

  reg [$stateBits-1:0] state, next_state;

  // ── State register ──────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) state <= IDLE;
    else        state <= next_state;
  end

  // ── Next-state logic (combinational) ───────────────────
  always @(*) begin
    next_state = state;   // default: hold
    case (state)
$nsCases    endcase
  end

  // ── Output logic (Moore) ────────────────────────────────
  always @(*) begin
    dispense     = (state == DISPENSE)${hasChange ? ' || (state == OVER)' : ''};
$changeOutput  end

endmodule
''';
  }

  // ─── Traffic Light ────────────────────────────────────────────────────────────

  static String _trafficLight(DesignSpecification spec) {
    final g = spec.params['green_time'] as int;
    final y = spec.params['yellow_time'] as int;
    final r = spec.params['red_time'] as int;
    final maxTime = [g, y, r].reduce((a, b) => a > b ? a : b);
    final timerBits = maxTime.bitLength.clamp(1, 16);

    return '''`timescale 1ns / 1ps
// ============================================================
//  Traffic Light Controller
//  Green : $g cycles  |  Yellow : $y cycles  |  Red : $r cycles
//  Type  : Moore FSM, parameterised timer, synchronous reset
// ============================================================

module ${spec.moduleName} #(
  parameter GREEN_TIME  = $g,
  parameter YELLOW_TIME = $y,
  parameter RED_TIME    = $r
) (
  input  wire       clk,
  input  wire       rst_n,
  output reg  [2:0] light    // [2]=red [1]=yellow [0]=green
);

  // ── State encoding ──────────────────────────────────────
  localparam [1:0]
    GREEN  = 2'd0,
    YELLOW = 2'd1,
    RED    = 2'd2;

  reg [1:0]             state, next_state;
  reg [$timerBits-1:0]  timer, next_timer;

  // ── State + timer register ──────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      state <= GREEN;
      timer <= 0;
    end else begin
      state <= next_state;
      timer <= next_timer;
    end
  end

  // ── Next-state + timer logic ────────────────────────────
  always @(*) begin
    next_state = state;
    next_timer = timer + 1'b1;
    case (state)
      GREEN:  if (timer >= GREEN_TIME  - 1) begin next_state = YELLOW; next_timer = 0; end
      YELLOW: if (timer >= YELLOW_TIME - 1) begin next_state = RED;    next_timer = 0; end
      RED:    if (timer >= RED_TIME    - 1) begin next_state = GREEN;  next_timer = 0; end
      default: begin next_state = GREEN; next_timer = 0; end
    endcase
  end

  // ── Output logic (Moore) ────────────────────────────────
  always @(*) begin
    case (state)
      GREEN:   light = 3'b001;
      YELLOW:  light = 3'b010;
      RED:     light = 3'b100;
      default: light = 3'b100;
    endcase
  end

endmodule
''';
  }

  // ─── Elevator ────────────────────────────────────────────────────────────────

  static String _elevator(DesignSpecification spec) {
    final floors = spec.params['floors'] as int;
    final floorBits = (floors - 1).bitLength.clamp(1, 4);

    return '''`timescale 1ns / 1ps
// ============================================================
//  $floors-Floor Elevator Controller
//  Algorithm : SCAN (service in current direction first)
//  Type      : Moore FSM, synchronous reset
// ============================================================

module ${spec.moduleName} #(
  parameter FLOORS = $floors
) (
  input  wire              clk,
  input  wire              rst_n,
  input  wire [FLOORS-1:0] req,       // floor request buttons
  output reg  [$floorBits-1:0] floor,     // current floor (0..FLOORS-1)
  output reg               door_open,  // doors are open
  output reg               moving_up,  // travelling upward
  output reg               moving_dn   // travelling downward
);

  // ── State encoding ──────────────────────────────────────
  localparam [2:0]
    IDLE       = 3'd0,
    DOOR_OPEN  = 3'd1,
    MOVE_UP    = 3'd2,
    MOVE_DOWN  = 3'd3,
    ARRIVED    = 3'd4;

  reg [2:0]        state, next_state;
  reg [$floorBits-1:0] next_floor;
  reg [FLOORS-1:0] requests;          // latched request register

  // ── Request latch ───────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n)
      requests <= 0;
    else if (state == DOOR_OPEN)
      // Clear current-floor bit; OR in any new requests
      requests <= (requests | req) & ~({{(FLOORS-1){{1'b0}}},1'b1} << floor);
    else
      requests <= requests | req;
  end

  // ── State + floor register ──────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      floor <= 0;
    end else begin
      state <= next_state;
      floor <= next_floor;
    end
  end

  // ── Next-state logic ────────────────────────────────────
  always @(*) begin
    next_state = state;
    next_floor = floor;
    case (state)
      IDLE: begin
        if (requests[floor])
          next_state = DOOR_OPEN;
        else if (|(requests >> (floor + 1)))
          next_state = MOVE_UP;
        else if (floor > 0 && |(requests & (({{(FLOORS){{1'b0}}}} | ((1'b1 << floor) - 1'b1)) [$floorBits:0])))
          next_state = MOVE_DOWN;
      end
      DOOR_OPEN: next_state = IDLE;
      MOVE_UP: begin
        if (floor < FLOORS - 1) begin
          next_floor = floor + 1'b1;
          if (requests[floor + 1'b1]) next_state = ARRIVED;
        end else
          next_state = IDLE;
      end
      MOVE_DOWN: begin
        if (floor > 0) begin
          next_floor = floor - 1'b1;
          if (requests[floor - 1'b1]) next_state = ARRIVED;
        end else
          next_state = IDLE;
      end
      ARRIVED:   next_state = DOOR_OPEN;
      default:   next_state = IDLE;
    endcase
  end

  // ── Output logic (Moore) ────────────────────────────────
  always @(*) begin
    door_open = (state == DOOR_OPEN) || (state == ARRIVED);
    moving_up = (state == MOVE_UP);
    moving_dn = (state == MOVE_DOWN);
  end

endmodule
''';
  }

  // ─── UART Transmitter ────────────────────────────────────────────────────────

  static String _uart(DesignSpecification spec) {
    final baud = spec.params['baud'] as int;
    final dataBits = spec.params['data_bits'] as int;
    final isRx = spec.params['is_rx'] as bool;

    if (isRx) return _uartRx(spec, baud, dataBits);
    return _uartTx(spec, baud, dataBits);
  }

  static String _uartTx(DesignSpecification spec, int baud, int dataBits) {
    return '''`timescale 1ns / 1ps
// ============================================================
//  UART Transmitter — ${dataBits}N1
//  Baud rate  : $baud (BAUD_RATE parameter)
//  Clock freq : 50 MHz (CLK_FREQ parameter)
//  Type       : Moore FSM with baud-rate counter
// ============================================================

module ${spec.moduleName} #(
  parameter CLK_FREQ  = 50_000_000,
  parameter BAUD_RATE = $baud
) (
  input  wire            clk,
  input  wire            rst_n,
  input  wire [${dataBits - 1}:0] tx_data,    // parallel byte to send
  input  wire            tx_valid,   // strobe: start TX
  output reg             tx_ready,   // HIGH when idle
  output reg             tx_out      // serial TX line (idles HIGH)
);

  // ── Baud divisor ────────────────────────────────────────
  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;  // ${50000000 ~/ baud}

  // ── State encoding ──────────────────────────────────────
  localparam [1:0]
    IDLE      = 2'd0,
    START_BIT = 2'd1,
    DATA_BITS = 2'd2,
    STOP_BIT  = 2'd3;

  reg [1:0]  state;
  reg [15:0] baud_cnt;   // baud-rate counter (16 bits covers up to 65535 clks/bit)
  reg [2:0]  bit_cnt;    // data bit counter (0..7)
  reg [${dataBits - 1}:0] shift_reg;  // TX shift register

  // ── Combined sequential FSM ─────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      state     <= IDLE;
      baud_cnt  <= 0;
      bit_cnt   <= 0;
      shift_reg <= 0;
      tx_out    <= 1'b1;
      tx_ready  <= 1'b1;
    end else begin
      case (state)
        IDLE: begin
          tx_out   <= 1'b1;
          tx_ready <= 1'b1;
          if (tx_valid) begin
            state     <= START_BIT;
            shift_reg <= tx_data;
            bit_cnt   <= 0;
            baud_cnt  <= 0;
            tx_ready  <= 1'b0;
          end
        end

        START_BIT: begin
          tx_out <= 1'b0;
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt <= 0;
            state    <= DATA_BITS;
          end else
            baud_cnt <= baud_cnt + 1'b1;
        end

        DATA_BITS: begin
          tx_out <= shift_reg[0];   // LSB first
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt  <= 0;
            shift_reg <= {1'b0, shift_reg[${dataBits - 1}:1]};  // logical right shift
            if (bit_cnt == ${dataBits - 1}) begin
              bit_cnt <= 0;
              state   <= STOP_BIT;
            end else
              bit_cnt <= bit_cnt + 1'b1;
          end else
            baud_cnt <= baud_cnt + 1'b1;
        end

        STOP_BIT: begin
          tx_out <= 1'b1;
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt <= 0;
            state    <= IDLE;
            tx_ready <= 1'b1;
          end else
            baud_cnt <= baud_cnt + 1'b1;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
''';
  }

  static String _uartRx(DesignSpecification spec, int baud, int dataBits) {
    return '''`timescale 1ns / 1ps
// ============================================================
//  UART Receiver — ${dataBits}N1
//  Baud rate  : $baud (BAUD_RATE parameter)
//  Clock freq : 50 MHz (CLK_FREQ parameter)
//  Sampling   : mid-bit point (CLKS_PER_BIT/2)
// ============================================================

module ${spec.moduleName} #(
  parameter CLK_FREQ  = 50_000_000,
  parameter BAUD_RATE = $baud
) (
  input  wire            clk,
  input  wire            rst_n,
  input  wire            rx_in,      // serial RX line (idles HIGH)
  output reg  [${dataBits - 1}:0] rx_data,    // received parallel byte
  output reg             rx_valid,   // 1-cycle pulse when byte ready
  output reg             frame_err   // framing error (stop bit != 1)
);

  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  localparam HALF_BIT     = CLKS_PER_BIT / 2;

  localparam [1:0]
    IDLE      = 2'd0,
    START_BIT = 2'd1,
    DATA_BITS = 2'd2,
    STOP_BIT  = 2'd3;

  reg [1:0]  state;
  reg [15:0] baud_cnt;
  reg [2:0]  bit_cnt;
  reg [${dataBits - 1}:0] shift_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      state     <= IDLE;
      baud_cnt  <= 0;
      bit_cnt   <= 0;
      shift_reg <= 0;
      rx_data   <= 0;
      rx_valid  <= 0;
      frame_err <= 0;
    end else begin
      rx_valid  <= 0;
      frame_err <= 0;

      case (state)
        IDLE: begin
          baud_cnt <= 0;
          if (!rx_in)          // falling edge = start bit
            state <= START_BIT;
        end

        START_BIT: begin
          if (baud_cnt == HALF_BIT - 1) begin
            if (!rx_in) begin  // still LOW at mid-point — valid start
              baud_cnt <= 0;
              bit_cnt  <= 0;
              state    <= DATA_BITS;
            end else
              state <= IDLE;   // false start
          end else
            baud_cnt <= baud_cnt + 1'b1;
        end

        DATA_BITS: begin
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt  <= 0;
            shift_reg <= {rx_in, shift_reg[${dataBits - 1}:1]};  // LSB first
            if (bit_cnt == ${dataBits - 1}) begin
              bit_cnt <= 0;
              state   <= STOP_BIT;
            end else
              bit_cnt <= bit_cnt + 1'b1;
          end else
            baud_cnt <= baud_cnt + 1'b1;
        end

        STOP_BIT: begin
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt  <= 0;
            rx_data   <= shift_reg;
            rx_valid  <= rx_in;        // valid only if stop bit HIGH
            frame_err <= !rx_in;
            state     <= IDLE;
          end else
            baud_cnt <= baud_cnt + 1'b1;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
''';
  }

  // ─── Sequence Detector ────────────────────────────────────────────────────────

  static String _sequenceDetector(DesignSpecification spec) {
    final seq = spec.params['sequence'] as String;
    final overlap = spec.params['overlap'] as bool;
    final n = seq.length;
    final stateBits = (n + 1).bitLength.clamp(1, 8);

    // Build state localparams
    final stateNames = List.generate(n + 1, (i) {
      if (i == 0) return 'S_INIT';
      if (i == n) return 'S_$seq';
      return 'S_${seq.substring(0, i)}';
    });

    final stateParamLines = StringBuffer();
    for (int i = 0; i <= n; i++) {
      stateParamLines.write(
          '    ${stateNames[i].padRight(14)} = ${stateBits}\'d$i');
      stateParamLines.write(i < n ? ',\n' : ';');
    }

    // KMP transitions
    final kmp = _kmpTable(seq);
    final caseLines = StringBuffer();
    for (int s = 0; s <= n; s++) {
      int ns0, ns1;
      if (s == n && !overlap) {
        ns0 = 0;
        ns1 = 0;
      } else {
        ns0 = kmp[s]![0];
        ns1 = kmp[s]![1];
      }
      caseLines.write('      ${stateNames[s]}: '
          'next_state = din ? ${stateNames[ns1]} : ${stateNames[ns0]};\n');
    }
    caseLines.write('      default: next_state = S_INIT;\n');

    return '''`timescale 1ns / 1ps
// ============================================================
//  Sequence Detector — pattern "$seq"
//  Length  : $n bits  |  States : ${n + 1}
//  Overlap : ${overlap ? "YES (KMP)" : "NO (resets after match)"}
//  Type    : Moore FSM, synchronous reset
// ============================================================

module ${spec.moduleName} (
  input  wire clk,
  input  wire rst_n,
  input  wire din,       // serial input bit
  output wire detected   // HIGH for 1 cycle when "$seq" matched
);

  // ── State encoding ──────────────────────────────────────
  localparam [$stateBits-1:0]
$stateParamLines

  reg [$stateBits-1:0] state, next_state;

  // ── State register ──────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) state <= S_INIT;
    else        state <= next_state;
  end

  // ── Next-state logic ────────────────────────────────────
  always @(*) begin
    case (state)
$caseLines    endcase
  end

  // ── Output (Moore) ──────────────────────────────────────
  assign detected = (state == S_$seq);

endmodule
''';
  }

  static Map<int, List<int>> _kmpTable(String seq) {
    final n = seq.length;
    final fail = List<int>.filled(n + 1, 0);
    if (n >= 1) fail[0] = -1;
    for (int i = 2; i <= n; i++) {
      int j = fail[i - 1];
      while (j >= 0 && seq[j] != seq[i - 1]) {
        j = j > 0 ? fail[j] : -1;
      }
      fail[i] = j + 1;
    }
    final trans = <int, List<int>>{};
    for (int s = 0; s <= n; s++) {
      trans[s] = [0, 0];
      for (int bit = 0; bit <= 1; bit++) {
        final ch = bit.toString();
        if (s < n && seq[s] == ch) {
          trans[s]![bit] = s + 1;
        } else {
          int k = s > 0 ? fail[s] : -1;
          while (k >= 0 && (k >= n || seq[k] != ch)) {
            k = k > 0 ? fail[k] : -1;
          }
          trans[s]![bit] = k >= 0 ? k + 1 : 0;
        }
      }
    }
    return trans;
  }

  // ─── Digital Lock ─────────────────────────────────────────────────────────────

  static String _digitalLock(DesignSpecification spec) {
    final combo = spec.params['combination'] as String;
    final maxAttempts = spec.params['max_attempts'] as int;
    final digits = combo.split('').map(int.parse).toList();
    final n = digits.length;
    final totalStates = n + 1; // IDLE + GOT_1..GOT_(n-1) + UNLOCKED + LOCKOUT = n+2
    final stateBits = (totalStates + 1).bitLength.clamp(1, 8);
    final attBits = maxAttempts.bitLength.clamp(1, 4);

    // State names: IDLE, GOT_<prefix>, ..., UNLOCKED, LOCKOUT
    final stateNames = <String>[
      'IDLE',
      for (int i = 1; i < n; i++) 'GOT_${combo.substring(0, i)}',
      'UNLOCKED',
      'LOCKOUT',
    ];
    final totalStateCount = stateNames.length;

    final stateParamLines = StringBuffer();
    for (int i = 0; i < totalStateCount; i++) {
      stateParamLines.write(
          '    ${stateNames[i].padRight(14)} = ${stateBits}\'d$i');
      stateParamLines.write(i < totalStateCount - 1 ? ',\n' : ';');
    }

    // Build case transitions
    final caseLines = StringBuffer();
    for (int i = 0; i < n; i++) {
      final fromState = stateNames[i];
      final toCorrect = stateNames[i + 1]; // GOT_1, GOT_12, ... UNLOCKED
      final nextDigit = digits[i];
      caseLines.write('      $fromState: begin\n');
      caseLines.write('        if (digit_valid) begin\n');
      caseLines.write('          if (digit == 4\'d$nextDigit) begin\n');
      caseLines.write('            next_state   = $toCorrect;\n');
      if (i == n - 1) {
        caseLines.write('            next_attempts = 0;\n');
      }
      caseLines.write('          end else begin\n');
      caseLines.write('            next_attempts = attempt_cnt + 1\'b1;\n');
      caseLines.write('            if (attempt_cnt >= ${maxAttempts - 1})\n');
      caseLines.write('              next_state = LOCKOUT;\n');
      caseLines.write('            else\n');
      caseLines.write('              next_state = IDLE;\n');
      caseLines.write('          end\n');
      caseLines.write('        end\n');
      caseLines.write('      end\n');
    }
    caseLines.write('      UNLOCKED: next_state = UNLOCKED;   // hold until reset\n');
    caseLines.write('      LOCKOUT:  next_state = LOCKOUT;    // hold until reset\n');
    caseLines.write('      default:  next_state = IDLE;\n');

    return '''`timescale 1ns / 1ps
// ============================================================
//  Digital Lock FSM
//  Combination  : $combo ($n digits BCD)
//  Max attempts : $maxAttempts (then LOCKOUT)
//  Type         : Moore FSM, synchronous reset
// ============================================================

module ${spec.moduleName} (
  input  wire       clk,
  input  wire       rst_n,
  input  wire [3:0] digit,        // BCD digit input (0-9)
  input  wire       digit_valid,  // single-cycle strobe
  output reg        unlocked,     // HIGH when combination correct
  output reg        locked_out    // HIGH after $maxAttempts failures
);

  // ── State encoding ──────────────────────────────────────
  localparam [$stateBits-1:0]
$stateParamLines

  reg [$stateBits-1:0] state, next_state;
  reg [$attBits-1:0]   attempt_cnt, next_attempts;

  // ── State + attempt register ────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      state       <= IDLE;
      attempt_cnt <= 0;
    end else begin
      state       <= next_state;
      attempt_cnt <= next_attempts;
    end
  end

  // ── Next-state logic ────────────────────────────────────
  always @(*) begin
    next_state    = state;
    next_attempts = attempt_cnt;
    case (state)
$caseLines    endcase
  end

  // ── Output logic (Moore) ────────────────────────────────
  always @(*) begin
    unlocked   = (state == UNLOCKED);
    locked_out = (state == LOCKOUT);
  end

endmodule
''';
  }

  // ─── PWM Generator ────────────────────────────────────────────────────────────

  static String _pwm(DesignSpecification spec) {
    final bits = spec.params['bits'] as int;
    final duty = spec.params['duty'] as int;
    final defaultThreshold = ((duty / 100) * (1 << bits)).round();

    return '''`timescale 1ns / 1ps
// ============================================================
//  $bits-bit PWM Generator
//  Default duty : $duty% (threshold = $defaultThreshold / ${1 << bits})
//  Architecture : free-running counter compare
// ============================================================

module ${spec.moduleName} #(
  parameter BITS         = $bits,
  parameter DEFAULT_DUTY = $defaultThreshold
) (
  input  wire           clk,
  input  wire           rst_n,
  input  wire [BITS-1:0] duty,   // duty cycle threshold
  input  wire           enable,
  output reg            pwm_out
);

  reg [BITS-1:0] counter;

  // ── Counter + output ────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      counter <= 0;
      pwm_out <= 1'b0;
    end else if (!enable) begin
      counter <= 0;
      pwm_out <= 1'b0;
    end else begin
      counter <= counter + 1'b1;
      pwm_out <= (counter < duty) ? 1'b1 : 1'b0;
    end
  end

endmodule
''';
  }

  // ─── Generic ─────────────────────────────────────────────────────────────────

  static String _generic(DesignSpecification spec) {
    return '''`timescale 1ns / 1ps
// ============================================================
//  Generic FSM Controller — Template
//  States : IDLE → ACTIVE → DONE → IDLE
//  Type   : Moore FSM, synchronous reset
// ============================================================

module ${spec.moduleName} (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       start,
  input  wire [7:0] data_in,
  output reg        busy,
  output reg  [7:0] data_out,
  output reg        valid
);

  // ── State encoding ──────────────────────────────────────
  localparam [1:0]
    IDLE   = 2'd0,
    ACTIVE = 2'd1,
    DONE   = 2'd2;

  reg [1:0] state, next_state;
  reg [7:0] data_reg;

  // ── State register ──────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      state    <= IDLE;
      data_reg <= 0;
    end else begin
      state <= next_state;
      if (state == IDLE && start)
        data_reg <= data_in;
    end
  end

  // ── Next-state logic ────────────────────────────────────
  always @(*) begin
    next_state = state;
    case (state)
      IDLE:   if (start)   next_state = ACTIVE;
      ACTIVE:              next_state = DONE;    // single-cycle processing (extend as needed)
      DONE:                next_state = IDLE;
      default:             next_state = IDLE;
    endcase
  end

  // ── Output logic (Moore) ────────────────────────────────
  always @(*) begin
    busy     = (state == ACTIVE);
    valid    = (state == DONE);
    data_out = (state == DONE) ? data_reg : 8'h00;
  end

endmodule
''';
  }
}
