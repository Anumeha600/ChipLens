// Intent extraction — parses a natural-language hardware description into a
// typed DesignIntent with extracted numeric parameters.

class DesignIntent {
  final String type;       // 'vending_machine' | 'traffic_light' | 'elevator' |
                           // 'uart_transmitter' | 'sequence_detector' |
                           // 'digital_lock' | 'pwm_generator' | 'generic'
  final String moduleName;
  final String title;
  final Map<String, dynamic> params;

  const DesignIntent({
    required this.type,
    required this.moduleName,
    required this.title,
    required this.params,
  });
}

class IntentExtractor {
  static DesignIntent extract(String description) {
    final lower = description.toLowerCase();

    if (_has(lower, ['vending', 'dispens', 'coin', 'rupee', '₹'])) {
      return _vendingMachine(lower);
    } else if (_has(lower, ['traffic', 'intersection']) ||
        (_has(lower, ['light', 'signal']) &&
            _has(lower, ['green', 'red', 'yellow']))) {
      return _trafficLight(lower);
    } else if (_has(lower, ['elevator', 'lift']) &&
        _has(lower, ['floor', 'storey', 'story'])) {
      return _elevator(lower);
    } else if (_has(lower, ['uart']) ||
        (_has(lower, ['baud']) && _has(lower, ['serial', 'transmit', 'receiv']))) {
      return _uart(lower);
    } else if (_has(lower, ['sequence detector', 'sequence detect']) ||
        (_has(lower, ['sequence', 'detect']) &&
            RegExp(r'\b[01]{3,8}\b').hasMatch(lower))) {
      return _sequenceDetector(lower, description);
    } else if ((_has(lower, ['lock', 'unlock']) &&
            _has(lower, ['combination', 'password', 'pin', 'digit', 'attempt'])) ||
        _has(lower, ['digital lock', 'combination lock'])) {
      return _digitalLock(lower, description);
    } else if (_has(lower, ['pwm', 'pulse width']) && _has(lower, ['duty'])) {
      return _pwm(lower);
    } else {
      return _generic(description);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static bool _has(String text, List<String> words) =>
      words.any((w) => text.contains(w));

  // ─── Vending Machine ─────────────────────────────────────────────────────────

  static DesignIntent _vendingMachine(String lower) {
    final amountRe =
        RegExp(r'(?:₹|rs\.?\s*|rupees?\s*)(\d+)|(\d+)\s*rupees?',
            caseSensitive: false);
    final amounts = amountRe.allMatches(lower).map((m) {
      final s = m.group(1) ?? m.group(2);
      return s != null ? int.tryParse(s) ?? 0 : 0;
    }).where((v) => v > 0).toSet();

    if (amounts.isEmpty) amounts.addAll([5, 10, 15]);

    final sorted = amounts.toList()..sort();
    final price = sorted.last;
    final coins = sorted.where((a) => a < price).toList();
    final finalCoins = coins.isEmpty ? [5, 10] : coins;

    return DesignIntent(
      type: 'vending_machine',
      moduleName: 'vending_machine',
      title: 'Vending Machine Controller',
      params: {'coins': finalCoins, 'price': price},
    );
  }

  // ─── Traffic Light ────────────────────────────────────────────────────────────

  static DesignIntent _trafficLight(String lower) {
    int greenTime = 30, yellowTime = 5, redTime = 25;

    final patterns = <(RegExp, String)>[
      (RegExp(r'(\d+)[- ]*cycles?[- ]*green', caseSensitive: false), 'green'),
      (RegExp(r'green[- ]*(?:for\s+)?:?\s*(\d+)', caseSensitive: false), 'green'),
      (RegExp(r'(\d+)[- ]*cycles?[- ]*yellow', caseSensitive: false), 'yellow'),
      (RegExp(r'yellow[- ]*(?:for\s+)?:?\s*(\d+)', caseSensitive: false), 'yellow'),
      (RegExp(r'(\d+)[- ]*cycles?[- ]*red', caseSensitive: false), 'red'),
      (RegExp(r'red[- ]*(?:for\s+)?:?\s*(\d+)', caseSensitive: false), 'red'),
    ];

    for (final (re, color) in patterns) {
      final m = re.firstMatch(lower);
      if (m != null) {
        final val = int.tryParse(m.group(1)!) ?? 0;
        if (val > 0) {
          if (color == 'green') greenTime = val;
          if (color == 'yellow') yellowTime = val;
          if (color == 'red') redTime = val;
        }
      }
    }

    return DesignIntent(
      type: 'traffic_light',
      moduleName: 'traffic_light',
      title: 'Traffic Light Controller',
      params: {
        'green_time': greenTime,
        'yellow_time': yellowTime,
        'red_time': redTime,
      },
    );
  }

  // ─── Elevator ────────────────────────────────────────────────────────────────

  static DesignIntent _elevator(String lower) {
    final re = RegExp(r'(\d+)[- ]*(?:floor|storey|story)', caseSensitive: false);
    final m = re.firstMatch(lower);
    final floors = (m != null ? int.tryParse(m.group(1)!) ?? 4 : 4).clamp(2, 8);

    return DesignIntent(
      type: 'elevator',
      moduleName: 'elevator_controller',
      title: '$floors-Floor Elevator Controller',
      params: {'floors': floors},
    );
  }

  // ─── UART ────────────────────────────────────────────────────────────────────

  static DesignIntent _uart(String lower) {
    final baudRe = RegExp(r'(\d[\d,_]*)\s*baud', caseSensitive: false);
    final baudM = baudRe.firstMatch(lower);
    final baudStr = baudM?.group(1)?.replaceAll(RegExp(r'[,_]'), '');
    final baud = (baudStr != null ? int.tryParse(baudStr) ?? 9600 : 9600);

    final bitsRe = RegExp(r'(\d+)\s*(?:data\s+)?bits?', caseSensitive: false);
    final bitsM = bitsRe.firstMatch(lower);
    final dataBits = (bitsM != null ? int.tryParse(bitsM.group(1)!) ?? 8 : 8)
        .clamp(5, 9);

    final isRx = lower.contains('receiv');

    return DesignIntent(
      type: 'uart_transmitter',
      moduleName: isRx ? 'uart_rx' : 'uart_tx',
      title: 'UART ${isRx ? "Receiver" : "Transmitter"} ($baud baud, ${dataBits}N1)',
      params: {'baud': baud, 'data_bits': dataBits, 'is_rx': isRx},
    );
  }

  // ─── Sequence Detector ────────────────────────────────────────────────────────

  static DesignIntent _sequenceDetector(String lower, String original) {
    final seqRe = RegExp(r'\b([01]{3,8})\b');
    final m = seqRe.firstMatch(original);
    final sequence = m?.group(1) ?? '1011';
    final overlap = lower.contains('overlap');

    return DesignIntent(
      type: 'sequence_detector',
      moduleName: 'seq_det',
      title: 'Sequence Detector ($sequence)',
      params: {'sequence': sequence, 'overlap': overlap},
    );
  }

  // ─── Digital Lock ─────────────────────────────────────────────────────────────

  static DesignIntent _digitalLock(String lower, String original) {
    final combRe = RegExp(r'\b(\d{4,8})\b');
    String combination = '1234';
    for (final m in combRe.allMatches(original)) {
      final s = m.group(1)!;
      if (s.length == 4) {
        combination = s;
        break;
      }
    }

    final attRe = RegExp(r'(\d+)\s*(?:max\s+)?attempts?', caseSensitive: false);
    final attM = attRe.firstMatch(lower);
    final maxAttempts =
        (attM != null ? int.tryParse(attM.group(1)!) ?? 3 : 3).clamp(1, 7);

    return DesignIntent(
      type: 'digital_lock',
      moduleName: 'digital_lock',
      title: 'Digital Lock FSM',
      params: {'combination': combination, 'max_attempts': maxAttempts},
    );
  }

  // ─── PWM Generator ────────────────────────────────────────────────────────────

  static DesignIntent _pwm(String lower) {
    final bitsRe = RegExp(r'(\d+)[- ]*bit', caseSensitive: false);
    final bitsM = bitsRe.firstMatch(lower);
    final bits = (bitsM != null ? int.tryParse(bitsM.group(1)!) ?? 8 : 8)
        .clamp(4, 16);

    final dutyRe = RegExp(r'(\d+)\s*%');
    final dutyM = dutyRe.firstMatch(lower);
    final duty = (dutyM != null ? int.tryParse(dutyM.group(1)!) ?? 50 : 50)
        .clamp(0, 100);

    return DesignIntent(
      type: 'pwm_generator',
      moduleName: 'pwm_gen',
      title: '$bits-bit PWM Generator ($duty% duty)',
      params: {'bits': bits, 'duty': duty},
    );
  }

  // ─── Generic ─────────────────────────────────────────────────────────────────

  static DesignIntent _generic(String original) {
    const skip = {
      'design', 'that', 'with', 'and', 'the', 'for', 'from',
      'into', 'using', 'which', 'this', 'will', 'can', 'has'
    };
    final words = original.split(RegExp(r'\s+'));
    final candidate = words
            .where((w) =>
                RegExp(r'^[A-Za-z]{3,}$').hasMatch(w) &&
                !skip.contains(w.toLowerCase()))
            .firstOrNull
            ?.toLowerCase() ??
        'controller';
    final moduleName = candidate.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final title = original.length > 60
        ? '${original.substring(0, 57)}…'
        : original;

    return DesignIntent(
      type: 'generic',
      moduleName: '${moduleName}_fsm',
      title: title,
      params: {},
    );
  }
}
