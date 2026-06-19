// ─── Result ───────────────────────────────────────────────────────────────────

class TestbenchResult {
  final String source;
  final bool success;
  final String? error;

  const TestbenchResult({
    required this.source,
    required this.success,
    this.error,
  });
}

// ─── Internal port model ──────────────────────────────────────────────────────

class _Port {
  final String direction; // 'input' | 'output'
  final String name;
  final String? widthExpr; // raw text between [ ], null = 1-bit

  const _Port(this.direction, this.name, this.widthExpr);

  bool get isOneBit => widthExpr == null;

  String get declWidth => widthExpr != null ? '[$widthExpr] ' : '';

  String get monitorFmt => isOneBit ? '%b' : '%h';
}

// ─── Generator ───────────────────────────────────────────────────────────────

class RtlTestbenchGenerator {
  static const _clockNames = <String>{
    'clk', 'clock', 'clk_i', 'sys_clk', 'i_clk', 'clk_in', 'pclk', 'aclk',
  };

  static const _resetNames = <String>{
    'rst', 'reset', 'rst_n', 'rstn', 'aresetn', 'areset', 'areset_n',
    'rst_i', 'i_rst_n', 'nreset', 'nrst',
  };

  static TestbenchResult generate(String rtlSource) {
    try {
      final clean = _stripComments(rtlSource);
      final moduleName = _extractModuleName(clean);
      if (moduleName == null) {
        return const TestbenchResult(
          source: '',
          success: false,
          error: 'Could not find a module declaration in the source.',
        );
      }

      final ports = _extractPorts(clean);
      if (ports.isEmpty) {
        return const TestbenchResult(
          source: '',
          success: false,
          error: 'No input/output ports found in module.',
        );
      }

      final inputs  = ports.where((p) => p.direction == 'input').toList();
      final outputs = ports.where((p) => p.direction == 'output').toList();

      final clockPort = _findClock(inputs);
      final resetPort = _findReset(inputs);

      final src = _buildTestbench(
        moduleName: moduleName,
        ports:      ports,
        inputs:     inputs,
        outputs:    outputs,
        clockPort:  clockPort,
        resetPort:  resetPort,
      );

      return TestbenchResult(source: src, success: true);
    } catch (e) {
      return TestbenchResult(source: '', success: false, error: e.toString());
    }
  }

  // ── Source preprocessing ──────────────────────────────────────────────────

  static String _stripComments(String src) {
    src = src.replaceAll(RegExp(r'//[^\n]*'), '');
    src = src.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return src;
  }

  // ── Module name ───────────────────────────────────────────────────────────

  static String? _extractModuleName(String src) {
    final re = RegExp(r'\bmodule\s+(\w+)\s*(?:#[^(]*)?\s*[;(]', multiLine: true);
    return re.firstMatch(src)?.group(1);
  }

  // ── Port extraction ───────────────────────────────────────────────────────

  static final _portRe = RegExp(
    r'\b(input|output)\s+(?:wire\s+)?(?:reg\s+)?(?:\[([^\]]+)\]\s+)?(\w+)',
    multiLine: true,
  );

  static const _skipWords = <String>{
    'begin', 'end', 'always', 'initial', 'assign', 'wire', 'reg',
    'integer', 'parameter', 'localparam', 'posedge', 'negedge',
  };

  static List<_Port> _extractPorts(String src) {
    final ports = <_Port>[];
    final seen  = <String>{};
    for (final m in _portRe.allMatches(src)) {
      final dir   = m.group(1)!;
      final width = m.group(2);
      final name  = m.group(3)!;
      if (_skipWords.contains(name)) continue;
      if (!seen.add(name)) continue;
      ports.add(_Port(dir, name, width));
    }
    return ports;
  }

  // ── Clock / reset inference ───────────────────────────────────────────────

  static _Port? _findClock(List<_Port> inputs) =>
      inputs.where((p) => _clockNames.contains(p.name.toLowerCase())).firstOrNull;

  static _Port? _findReset(List<_Port> inputs) =>
      inputs.where((p) => _resetNames.contains(p.name.toLowerCase())).firstOrNull;

  static bool _isActiveLow(_Port p) {
    final n = p.name.toLowerCase();
    return n.endsWith('_n') || n == 'rstn' || n == 'aresetn' || n == 'nreset' || n == 'nrst';
  }

  // ── Testbench builder ─────────────────────────────────────────────────────

  static String _buildTestbench({
    required String    moduleName,
    required List<_Port> ports,
    required List<_Port> inputs,
    required List<_Port> outputs,
    required _Port?    clockPort,
    required _Port?    resetPort,
  }) {
    final tbName = 'tb_$moduleName';
    final b = StringBuffer();

    // Header
    b.writeln('`timescale 1ns / 1ps');
    b.writeln();
    b.writeln('module $tbName;');
    b.writeln();

    // Signal declarations
    b.writeln('  // ── DUT signals ──────────────────────────────────────────────────');
    for (final p in inputs) { b.writeln('  reg  ${p.declWidth}${p.name};'); }
    for (final p in outputs) { b.writeln('  wire ${p.declWidth}${p.name};'); }
    b.writeln();

    // Instantiation
    b.writeln('  // ── Instantiate DUT ──────────────────────────────────────────────');
    b.writeln('  $moduleName uut (');
    for (int i = 0; i < ports.length; i++) {
      final p     = ports[i];
      final comma = i < ports.length - 1 ? ',' : '';
      b.writeln('    .${p.name.padRight(12)}(${p.name})$comma');
    }
    b.writeln('  );');
    b.writeln();

    // Clock generation
    if (clockPort != null) {
      b.writeln('  // ── Clock generation ─────────────────────────────────────────────');
      b.writeln('  initial ${clockPort.name} = 0;');
      b.writeln('  always #5 ${clockPort.name} = ~${clockPort.name};');
      b.writeln();
    }

    // Waveform dump
    b.writeln('  // ── Waveform dump ────────────────────────────────────────────────');
    b.writeln('  initial begin');
    b.writeln('    \$dumpfile("$tbName.vcd");');
    b.writeln('    \$dumpvars(0, $tbName);');
    b.writeln('  end');
    b.writeln();

    // Stimulus
    b.writeln('  // ── Stimulus ─────────────────────────────────────────────────────');
    b.writeln('  initial begin');
    _writeStimulus(b, clockPort: clockPort, resetPort: resetPort, inputs: inputs);
    b.writeln('  end');
    b.writeln();

    // Monitor
    _writeMonitor(b, ports: ports);
    b.writeln();
    b.writeln('endmodule');

    return b.toString();
  }

  static void _writeStimulus(
    StringBuffer b, {
    required _Port? clockPort,
    required _Port? resetPort,
    required List<_Port> inputs,
  }) {
    final nonClock = inputs.where((p) => p != clockPort).toList();

    // Initialise all inputs to 0
    for (final p in nonClock) { b.writeln('    ${p.name} = 0;'); }
    b.writeln();

    if (clockPort != null) {
      // Reset sequence
      if (resetPort != null) {
        final lo = _isActiveLow(resetPort);
        b.writeln('    // Assert reset');
        b.writeln('    ${resetPort.name} = ${lo ? 0 : 1};');
        b.writeln('    repeat (4) @(posedge ${clockPort.name});');
        b.writeln('    ${resetPort.name} = ${lo ? 1 : 0};');
        b.writeln('    @(posedge ${clockPort.name});');
        b.writeln();
      } else {
        b.writeln('    repeat (4) @(posedge ${clockPort.name});');
        b.writeln();
      }

      // Stimulus for remaining inputs
      final stimInputs = nonClock.where((p) => p != resetPort).toList();
      if (stimInputs.isNotEmpty) {
        b.writeln('    // Apply stimulus');
        for (int v = 1; v <= 4; v++) {
          b.write('    @(posedge ${clockPort.name});');
          for (final p in stimInputs) {
            b.write(' ${p.name} = ${p.isOneBit ? (v % 2) : v};');
          }
          b.writeln();
        }
        b.writeln();
      }

      b.writeln('    repeat (4) @(posedge ${clockPort.name});');
    } else {
      // Combinational: use time delays
      final stimInputs = nonClock.where((p) => p != resetPort).toList();
      b.writeln('    #10;');
      for (final p in stimInputs) {
        b.writeln('    ${p.name} = 1; #10;');
        b.writeln('    ${p.name} = 0; #10;');
      }
      b.writeln('    #20;');
    }

    b.writeln('    \$finish;');
  }

  static void _writeMonitor(StringBuffer b, {required List<_Port> ports}) {
    b.writeln('  // ── Monitor ──────────────────────────────────────────────────────');
    final fmts = ports.map((p) => '${p.name}=${p.monitorFmt}').join(' ');
    final args = ['  \$time', ...ports.map((p) => '    ${p.name}')].join(',\n');
    b.writeln('  initial \$monitor("[%0t] $fmts",');
    b.writeln('$args);');
  }
}
