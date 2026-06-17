// FSM Builder — converts a DesignIntent into a fully-described DesignSpecification
// containing states, transitions, I/O ports, and design assumptions.

import '../../models/design_spec.dart';
import 'intent_extractor.dart';

class FsmBuilder {
  static DesignSpecification build(DesignIntent intent) {
    switch (intent.type) {
      case 'vending_machine':
        return _vendingMachine(intent);
      case 'traffic_light':
        return _trafficLight(intent);
      case 'elevator':
        return _elevator(intent);
      case 'uart_transmitter':
        return _uart(intent);
      case 'sequence_detector':
        return _sequenceDetector(intent);
      case 'digital_lock':
        return _digitalLock(intent);
      case 'pwm_generator':
        return _pwm(intent);
      default:
        return _generic(intent);
    }
  }

  // ─── Vending Machine ─────────────────────────────────────────────────────────

  static DesignSpecification _vendingMachine(DesignIntent intent) {
    final coins = List<int>.from(intent.params['coins'] as List)..sort();
    final price = intent.params['price'] as int;

    // Compute all reachable intermediate amounts
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

    // Detect if any combination overpays
    bool needsOver = false;
    for (final amt in amounts) {
      for (final coin in coins) {
        if (amt + coin > price) needsOver = true;
      }
    }

    final stateNames = <int, String>{};
    for (final amt in amounts) {
      stateNames[amt] = amt == 0 ? 'IDLE' : 'S$amt';
    }

    final states = <StateNode>[
      const StateNode(
          name: 'IDLE', description: 'Waiting for first coin (0 accumulated)', isEntry: true),
      for (final amt in amounts.where((a) => a > 0))
        StateNode(name: 'S$amt', description: 'Rs.$amt accumulated'),
      const StateNode(
          name: 'DISPENSE',
          description: 'Dispense product — exact payment received',
          isExit: true,
          outputs: {'dispense': '1'}),
      if (needsOver)
        StateNode(
            name: 'OVER',
            description: 'Overpaid — dispense product + return Rs.${coins.first} change',
            isExit: true,
            outputs: {'dispense': '1', 'change_${coins.first}': '1'}),
    ];

    final transitions = <EdgeTransition>[];
    for (final amt in amounts) {
      final from = stateNames[amt]!;
      for (final coin in coins) {
        final next = amt + coin;
        if (next == price) {
          transitions.add(EdgeTransition(
              from: from, to: 'DISPENSE', condition: 'coin_$coin'));
        } else if (next > price && needsOver) {
          transitions.add(EdgeTransition(
              from: from, to: 'OVER', condition: 'coin_$coin'));
        } else if (stateNames.containsKey(next)) {
          transitions.add(EdgeTransition(
              from: from, to: stateNames[next]!, condition: 'coin_$coin'));
        }
      }
    }
    transitions.add(const EdgeTransition(
        from: 'DISPENSE', to: 'IDLE', condition: 'auto (next cycle)'));
    if (needsOver) {
      transitions.add(const EdgeTransition(
          from: 'OVER', to: 'IDLE', condition: 'auto (next cycle)'));
    }

    final coinLabel = coins.map((c) => 'Rs.$c').join(' / ');

    return DesignSpecification(
      title: intent.title,
      description:
          'Accept coins ($coinLabel) and dispense a product worth Rs.$price. '
          'Change is returned for overpayment.',
      moduleName: intent.moduleName,
      designType: intent.type,
      inputs: [
        const SignalPort(
            name: 'clk', width: 1, description: 'System clock', direction: 'input'),
        const SignalPort(
            name: 'rst_n',
            width: 1,
            description: 'Active-low synchronous reset',
            direction: 'input'),
        for (final coin in coins)
          SignalPort(
              name: 'coin_$coin',
              width: 1,
              description: 'Insert Rs.$coin coin (1-cycle pulse)',
              direction: 'input'),
      ],
      outputs: [
        const SignalPort(
            name: 'dispense',
            width: 1,
            description: 'Dispense product (1-cycle pulse)',
            direction: 'output'),
        if (needsOver)
          SignalPort(
              name: 'change_${coins.first}',
              width: 1,
              description: 'Return Rs.${coins.first} change (1-cycle pulse)',
              direction: 'output'),
      ],
      states: states,
      transitions: transitions,
      assumptions: [
        'Only one coin may be inserted per clock cycle',
        'Coins are single-cycle pulse inputs (not level)',
        'Reset clears accumulated credit and returns to IDLE',
        'dispense and change outputs are Moore (state-based) 1-cycle pulses',
        'Machine waits indefinitely for remaining coins',
      ],
      entryState: 'IDLE',
      exitStates: ['DISPENSE', if (needsOver) 'OVER'],
      params: intent.params,
    );
  }

  // ─── Traffic Light ────────────────────────────────────────────────────────────

  static DesignSpecification _trafficLight(DesignIntent intent) {
    final g = intent.params['green_time'] as int;
    final y = intent.params['yellow_time'] as int;
    final r = intent.params['red_time'] as int;

    return DesignSpecification(
      title: intent.title,
      description:
          'Cyclic 3-phase traffic light controller. '
          'Green: $g cycles → Yellow: $y cycles → Red: $r cycles → repeat.',
      moduleName: intent.moduleName,
      designType: intent.type,
      inputs: [
        const SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
        const SignalPort(
            name: 'rst_n', width: 1, description: 'Active-low synchronous reset', direction: 'input'),
      ],
      outputs: [
        const SignalPort(
            name: 'light',
            width: 3,
            description: '[2]=red, [1]=yellow, [0]=green',
            direction: 'output'),
      ],
      states: [
        StateNode(
            name: 'GREEN',
            description: 'Green light active — $g clock cycles',
            isEntry: true,
            outputs: {'light': "3'b001"}),
        StateNode(
            name: 'YELLOW',
            description: 'Yellow warning — $y clock cycles',
            outputs: {'light': "3'b010"}),
        StateNode(
            name: 'RED',
            description: 'Red light active — $r clock cycles',
            outputs: {'light': "3'b100"}),
      ],
      transitions: [
        EdgeTransition(from: 'GREEN', to: 'YELLOW', condition: 'timer == GREEN_TIME-1'),
        EdgeTransition(from: 'YELLOW', to: 'RED', condition: 'timer == YELLOW_TIME-1'),
        EdgeTransition(from: 'RED', to: 'GREEN', condition: 'timer == RED_TIME-1'),
        const EdgeTransition(from: 'GREEN', to: 'GREEN', condition: 'timer < GREEN_TIME-1'),
        const EdgeTransition(from: 'YELLOW', to: 'YELLOW', condition: 'timer < YELLOW_TIME-1'),
        const EdgeTransition(from: 'RED', to: 'RED', condition: 'timer < RED_TIME-1'),
      ],
      assumptions: [
        'Timer resets to 0 on every state transition',
        'One clock cycle = one timer increment',
        'Outputs are registered (one cycle output latency from state change)',
        'Parameters GREEN_TIME, YELLOW_TIME, RED_TIME are synthesizable localparam',
        'light[2:0] is one-hot encoded: only one bit high at a time',
      ],
      entryState: 'GREEN',
      params: intent.params,
    );
  }

  // ─── Elevator ────────────────────────────────────────────────────────────────

  static DesignSpecification _elevator(DesignIntent intent) {
    final floors = intent.params['floors'] as int;
    final floorBits = floors <= 2 ? 1 : floors <= 4 ? 2 : floors <= 8 ? 3 : 4;

    return DesignSpecification(
      title: intent.title,
      description:
          '$floors-floor elevator using a SCAN-like algorithm. '
          'Accepts floor requests and optimally routes the cabin up/down.',
      moduleName: intent.moduleName,
      designType: intent.type,
      inputs: [
        const SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
        const SignalPort(name: 'rst_n', width: 1, description: 'Active-low synchronous reset', direction: 'input'),
        SignalPort(
            name: 'req',
            width: floors,
            description: 'Floor request buttons [${floors - 1}:0]',
            direction: 'input'),
      ],
      outputs: [
        SignalPort(
            name: 'floor',
            width: floorBits,
            description: 'Current floor (0..${floors - 1})',
            direction: 'output'),
        const SignalPort(
            name: 'door_open', width: 1, description: 'Door open indicator', direction: 'output'),
        const SignalPort(
            name: 'moving_up', width: 1, description: 'Elevator moving upward', direction: 'output'),
        const SignalPort(
            name: 'moving_dn',
            width: 1,
            description: 'Elevator moving downward',
            direction: 'output'),
      ],
      states: [
        const StateNode(
            name: 'IDLE',
            description: 'No pending requests — doors closed, cabin stationary',
            isEntry: true),
        const StateNode(name: 'DOOR_OPEN', description: 'Serving current floor — doors open'),
        const StateNode(name: 'MOVE_UP', description: 'Traveling to a higher floor'),
        const StateNode(name: 'MOVE_DOWN', description: 'Traveling to a lower floor'),
        const StateNode(name: 'ARRIVED', description: 'Reached requested floor — prepare door open'),
      ],
      transitions: [
        const EdgeTransition(from: 'IDLE', to: 'DOOR_OPEN', condition: 'req[floor]'),
        const EdgeTransition(from: 'IDLE', to: 'MOVE_UP', condition: 'pending req above current floor'),
        const EdgeTransition(from: 'IDLE', to: 'MOVE_DOWN', condition: 'pending req below current floor'),
        const EdgeTransition(from: 'DOOR_OPEN', to: 'IDLE', condition: 'auto (next cycle)'),
        const EdgeTransition(from: 'MOVE_UP', to: 'ARRIVED', condition: 'req[floor+1]'),
        const EdgeTransition(from: 'MOVE_UP', to: 'MOVE_UP', condition: '!req[floor+1]'),
        const EdgeTransition(from: 'MOVE_DOWN', to: 'ARRIVED', condition: 'req[floor-1]'),
        const EdgeTransition(from: 'MOVE_DOWN', to: 'MOVE_DOWN', condition: '!req[floor-1]'),
        const EdgeTransition(from: 'ARRIVED', to: 'DOOR_OPEN', condition: 'auto (next cycle)'),
      ],
      assumptions: [
        'Request register latches all req bits; cleared when floor is served',
        'Door open state lasts exactly 1 clock cycle (use timer for realistic 3s delay)',
        'Floor moves one level per clock cycle in MOVE states (unrealistic but FSM-correct)',
        'SCAN: services floors in current direction before reversing',
        'Priority: serve current floor first, then nearest in motion direction',
      ],
      entryState: 'IDLE',
      params: intent.params,
    );
  }

  // ─── UART ────────────────────────────────────────────────────────────────────

  static DesignSpecification _uart(DesignIntent intent) {
    final baud = intent.params['baud'] as int;
    final dataBits = intent.params['data_bits'] as int;
    final isRx = intent.params['is_rx'] as bool;

    return DesignSpecification(
      title: intent.title,
      description:
          'UART ${isRx ? "receiver" : "transmitter"} implementing ${dataBits}N1 framing. '
          'Baud rate: $baud. Oversampling: ${isRx ? "16×" : "1×"} (TX: exact baud clock).',
      moduleName: intent.moduleName,
      designType: intent.type,
      inputs: isRx
          ? [
              const SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
              const SignalPort(name: 'rst_n', width: 1, description: 'Active-low reset', direction: 'input'),
              const SignalPort(name: 'rx_in', width: 1, description: 'Serial RX line (idles HIGH)', direction: 'input'),
            ]
          : [
              const SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
              const SignalPort(name: 'rst_n', width: 1, description: 'Active-low reset', direction: 'input'),
              SignalPort(
                  name: 'tx_data',
                  width: dataBits,
                  description: 'Parallel data byte to transmit',
                  direction: 'input'),
              const SignalPort(
                  name: 'tx_valid', width: 1, description: 'Assert to start TX', direction: 'input'),
            ],
      outputs: isRx
          ? [
              SignalPort(
                  name: 'rx_data',
                  width: dataBits,
                  description: 'Received parallel byte',
                  direction: 'output'),
              const SignalPort(
                  name: 'rx_valid',
                  width: 1,
                  description: 'Data valid (1-cycle pulse on stop bit)',
                  direction: 'output'),
              const SignalPort(
                  name: 'frame_err',
                  width: 1,
                  description: 'Framing error — stop bit not HIGH',
                  direction: 'output'),
            ]
          : [
              const SignalPort(
                  name: 'tx_ready',
                  width: 1,
                  description: 'Ready to accept new byte (HIGH in IDLE)',
                  direction: 'output'),
              const SignalPort(
                  name: 'tx_out', width: 1, description: 'Serial TX line (idles HIGH)', direction: 'output'),
            ],
      states: isRx
          ? const [
              StateNode(name: 'IDLE', description: 'Waiting for start bit (rx_in = 0)', isEntry: true),
              StateNode(name: 'START_BIT', description: 'Validating start bit at mid-period'),
              StateNode(name: 'DATA_BITS', description: 'Sampling 8 data bits LSB-first'),
              StateNode(name: 'STOP_BIT', description: 'Validating stop bit, output rx_valid'),
            ]
          : const [
              StateNode(name: 'IDLE', description: 'Idle — tx_out=1, tx_ready=1', isEntry: true),
              StateNode(name: 'START_BIT', description: 'Transmit start bit (tx_out=0)'),
              StateNode(name: 'DATA_BITS', description: 'Shift out 8 data bits LSB-first'),
              StateNode(name: 'STOP_BIT', description: 'Transmit stop bit (tx_out=1)'),
            ],
      transitions: isRx
          ? const [
              EdgeTransition(from: 'IDLE', to: 'START_BIT', condition: 'rx_in == 0'),
              EdgeTransition(from: 'START_BIT', to: 'DATA_BITS', condition: 'baud_tick (mid-period)'),
              EdgeTransition(from: 'START_BIT', to: 'IDLE', condition: 'false start (rx_in==1)'),
              EdgeTransition(from: 'DATA_BITS', to: 'STOP_BIT', condition: 'bit_cnt == 7 && baud_tick'),
              EdgeTransition(from: 'STOP_BIT', to: 'IDLE', condition: 'baud_tick'),
            ]
          : const [
              EdgeTransition(from: 'IDLE', to: 'START_BIT', condition: 'tx_valid'),
              EdgeTransition(from: 'START_BIT', to: 'DATA_BITS', condition: 'baud_tick'),
              EdgeTransition(from: 'DATA_BITS', to: 'STOP_BIT', condition: 'baud_tick && bit_cnt==7'),
              EdgeTransition(from: 'STOP_BIT', to: 'IDLE', condition: 'baud_tick'),
            ],
      assumptions: [
        'System clock: 50 MHz (CLK_FREQ parameter)',
        'Baud rate: $baud (BAUD_RATE parameter)',
        'Clocks per bit: ${50000000 ~/ baud}',
        '${dataBits}N1 framing: $dataBits data bits, no parity, 1 stop bit',
        'Data transmitted LSB-first (UART standard)',
        'TX output and RX input idle HIGH (UART mark state)',
      ],
      entryState: 'IDLE',
      params: intent.params,
    );
  }

  // ─── Sequence Detector ────────────────────────────────────────────────────────

  static DesignSpecification _sequenceDetector(DesignIntent intent) {
    final seq = intent.params['sequence'] as String;
    final overlap = intent.params['overlap'] as bool;
    final n = seq.length;

    final stateNames = List.generate(n + 1, (i) {
      if (i == 0) return 'S_INIT';
      if (i == n) return 'S_$seq';
      return 'S_${seq.substring(0, i)}';
    });

    final states = List.generate(n + 1, (i) {
      return StateNode(
        name: stateNames[i],
        description: i == 0
            ? 'No prefix matched'
            : i == n
                ? 'Full sequence "$seq" detected'
                : 'Matched "${seq.substring(0, i)}"',
        isEntry: i == 0,
        isExit: i == n,
        outputs: i == n ? const {'detected': '1'} : const {},
      );
    });

    final kmp = _kmpTable(seq);
    final transitions = <EdgeTransition>[];
    for (int s = 0; s <= n; s++) {
      for (int bit = 0; bit <= 1; bit++) {
        int ns;
        if (s == n && !overlap) {
          ns = 0;
        } else {
          ns = kmp[s]![bit];
        }
        transitions.add(EdgeTransition(
          from: stateNames[s],
          to: stateNames[ns],
          condition: 'din = $bit',
        ));
      }
    }

    return DesignSpecification(
      title: intent.title,
      description:
          'Detects binary sequence "$seq" on serial input. '
          '${overlap ? "Overlapping detection via KMP prefix function." : "Non-overlapping — resets after detection."}',
      moduleName: intent.moduleName,
      designType: intent.type,
      inputs: [
        const SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
        const SignalPort(name: 'rst_n', width: 1, description: 'Active-low reset', direction: 'input'),
        const SignalPort(name: 'din', width: 1, description: 'Serial input bit', direction: 'input'),
      ],
      outputs: [
        SignalPort(
            name: 'detected',
            width: 1,
            description: 'HIGH for 1 cycle when "$seq" is detected',
            direction: 'output'),
      ],
      states: states,
      transitions: transitions,
      assumptions: [
        'One input bit per clock cycle on din',
        'Sequence length: $n bits (${n + 1} FSM states)',
        overlap
            ? 'Overlapping detection: KMP algorithm allows reuse of matched prefix'
            : 'Non-overlapping: FSM resets to S_INIT after each detection',
        '"detected" is a 1-cycle Moore output pulse',
        'State bits required: ${(n + 1).bitLength} bits',
      ],
      entryState: 'S_INIT',
      exitStates: ['S_$seq'],
      params: intent.params,
    );
  }

  // KMP failure/transition table
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

  static DesignSpecification _digitalLock(DesignIntent intent) {
    final combo = intent.params['combination'] as String;
    final maxAttempts = intent.params['max_attempts'] as int;
    final digits = combo.split('').map(int.parse).toList();
    final n = digits.length;

    final stateNames = <String>[
      'IDLE',
      for (int i = 1; i < n; i++) 'GOT_${combo.substring(0, i)}',
      'UNLOCKED',
      'LOCKOUT',
    ];

    final states = <StateNode>[
      const StateNode(name: 'IDLE', description: 'Waiting for first correct digit', isEntry: true),
      for (int i = 1; i < n; i++)
        StateNode(
            name: 'GOT_${combo.substring(0, i)}',
            description: 'Received $i correct digit${i > 1 ? "s" : ""} ("${combo.substring(0, i)}")'),
      StateNode(
          name: 'UNLOCKED',
          description: 'Full combination "$combo" entered — unlocked',
          isExit: true,
          outputs: const {'unlocked': '1'}),
      StateNode(
          name: 'LOCKOUT',
          description: 'Max $maxAttempts failures — permanently locked out',
          isExit: true,
          outputs: const {'locked_out': '1'}),
    ];

    final transitions = <EdgeTransition>[];
    for (int i = 0; i < n; i++) {
      final from = stateNames[i]; // IDLE, GOT_1, GOT_12, ...
      final nextDigit = digits[i];
      final toCorrect = stateNames[i + 1]; // GOT_1, GOT_12, ..., UNLOCKED
      transitions
        ..add(EdgeTransition(
            from: from,
            to: toCorrect,
            condition: 'digit_valid && digit == $nextDigit'))
        ..add(EdgeTransition(
            from: from,
            to: 'IDLE',
            condition: 'digit_valid && digit ≠ $nextDigit && attempts < ${maxAttempts - 1}',
            action: 'attempt_cnt++'))
        ..add(EdgeTransition(
            from: from,
            to: 'LOCKOUT',
            condition: 'digit_valid && digit ≠ $nextDigit && attempts == ${maxAttempts - 1}'));
    }
    transitions
      ..add(const EdgeTransition(from: 'UNLOCKED', to: 'UNLOCKED', condition: 'stays until rst_n'))
      ..add(const EdgeTransition(from: 'LOCKOUT', to: 'LOCKOUT', condition: 'stays until rst_n'));

    return DesignSpecification(
      title: intent.title,
      description:
          'Sequential combination lock. Accepts $n BCD digits; unlocks on correct '
          'sequence "$combo". Locks out permanently after $maxAttempts wrong entries.',
      moduleName: intent.moduleName,
      designType: intent.type,
      inputs: [
        const SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
        const SignalPort(
            name: 'rst_n', width: 1, description: 'Active-low reset (also re-locks)', direction: 'input'),
        const SignalPort(
            name: 'digit', width: 4, description: 'BCD digit input (0–9)', direction: 'input'),
        const SignalPort(
            name: 'digit_valid', width: 1, description: 'Strobe — digit valid this cycle', direction: 'input'),
      ],
      outputs: [
        const SignalPort(
            name: 'unlocked', width: 1, description: 'HIGH when lock is open', direction: 'output'),
        SignalPort(
            name: 'locked_out',
            width: 1,
            description: 'HIGH after $maxAttempts failed attempts',
            direction: 'output'),
      ],
      states: states,
      transitions: transitions,
      assumptions: [
        'digit_valid is a single-cycle strobe, not a level signal',
        'BCD values 10–15 are treated as invalid (wrong digit)',
        'Any wrong digit at any step resets to IDLE and increments attempt counter',
        'LOCKOUT requires hardware reset (rst_n) to clear',
        'Combination: "$combo" ($n × 4-bit BCD digits)',
        'Attempt counter width: ${maxAttempts.bitLength} bits',
      ],
      entryState: 'IDLE',
      exitStates: const ['UNLOCKED', 'LOCKOUT'],
      params: intent.params,
    );
  }

  // ─── PWM Generator ────────────────────────────────────────────────────────────

  static DesignSpecification _pwm(DesignIntent intent) {
    final bits = intent.params['bits'] as int;
    final duty = intent.params['duty'] as int;
    final defaultThreshold = ((duty / 100) * (1 << bits)).round();

    return DesignSpecification(
      title: intent.title,
      description:
          '$bits-bit PWM generator with programmable duty cycle register. '
          'Default $duty% duty = threshold $defaultThreshold / ${1 << bits}.',
      moduleName: intent.moduleName,
      designType: intent.type,
      inputs: [
        const SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
        const SignalPort(name: 'rst_n', width: 1, description: 'Active-low reset', direction: 'input'),
        SignalPort(
            name: 'duty',
            width: bits,
            description: '$bits-bit duty cycle threshold (output HIGH when counter < duty)',
            direction: 'input'),
        const SignalPort(name: 'enable', width: 1, description: 'Enable PWM output', direction: 'input'),
      ],
      outputs: [
        const SignalPort(
            name: 'pwm_out', width: 1, description: 'PWM output signal', direction: 'output'),
      ],
      states: const [
        StateNode(name: 'IDLE', description: 'PWM disabled, output LOW', isEntry: true),
        StateNode(name: 'HIGH', description: 'Counter < duty — output HIGH'),
        StateNode(name: 'LOW', description: 'Counter ≥ duty — output LOW'),
      ],
      transitions: [
        const EdgeTransition(from: 'IDLE', to: 'HIGH', condition: 'enable'),
        const EdgeTransition(from: 'HIGH', to: 'LOW', condition: 'counter == duty-1'),
        const EdgeTransition(from: 'HIGH', to: 'HIGH', condition: 'counter < duty-1'),
        EdgeTransition(from: 'LOW', to: 'HIGH', condition: 'counter == ${(1 << bits) - 1} (period end)'),
        const EdgeTransition(from: 'LOW', to: 'LOW', condition: 'counter < period end'),
        const EdgeTransition(from: 'HIGH', to: 'IDLE', condition: '!enable'),
        const EdgeTransition(from: 'LOW', to: 'IDLE', condition: '!enable'),
      ],
      assumptions: [
        '$bits-bit free-running counter wraps at ${(1 << bits) - 1}',
        'pwm_out HIGH when counter < duty register value',
        'Default duty cycle: $duty% = threshold $defaultThreshold',
        'PWM period = ${1 << bits} clock cycles',
        'Duty cycle can change mid-period; takes effect at next period boundary',
      ],
      entryState: 'IDLE',
      params: intent.params,
    );
  }

  // ─── Generic ─────────────────────────────────────────────────────────────────

  static DesignSpecification _generic(DesignIntent intent) {
    return DesignSpecification(
      title: intent.title.isEmpty ? 'Generic FSM Controller' : intent.title,
      description:
          'Template FSM controller — 3-state sequential machine. '
          'Customize I/O ports and state logic for your specific design.',
      moduleName: intent.moduleName,
      designType: 'generic',
      inputs: const [
        SignalPort(name: 'clk', width: 1, description: 'System clock', direction: 'input'),
        SignalPort(name: 'rst_n', width: 1, description: 'Active-low reset', direction: 'input'),
        SignalPort(name: 'start', width: 1, description: 'Start operation', direction: 'input'),
        SignalPort(name: 'data_in', width: 8, description: '8-bit data input', direction: 'input'),
      ],
      outputs: const [
        SignalPort(name: 'busy', width: 1, description: 'Operation in progress', direction: 'output'),
        SignalPort(name: 'data_out', width: 8, description: '8-bit result output', direction: 'output'),
        SignalPort(name: 'valid', width: 1, description: 'Output data valid (1-cycle pulse)', direction: 'output'),
      ],
      states: const [
        StateNode(name: 'IDLE', description: 'Waiting for start', isEntry: true),
        StateNode(name: 'ACTIVE', description: 'Processing — customize with your logic'),
        StateNode(name: 'DONE', description: 'Output valid — auto-returns to IDLE', isExit: true),
      ],
      transitions: const [
        EdgeTransition(from: 'IDLE', to: 'ACTIVE', condition: 'start'),
        EdgeTransition(from: 'ACTIVE', to: 'DONE', condition: 'done_condition'),
        EdgeTransition(from: 'ACTIVE', to: 'ACTIVE', condition: '!done_condition'),
        EdgeTransition(from: 'DONE', to: 'IDLE', condition: 'auto (next cycle)'),
      ],
      assumptions: [
        'start is a single-cycle strobe',
        'ACTIVE state logic is a template — extend as needed',
        'valid asserted for 1 cycle when DONE state entered',
        'Customize data_in/data_out widths for your datapath',
      ],
      entryState: 'IDLE',
      params: const {},
    );
  }
}
