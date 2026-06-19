import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/diagnostics/icarus_parser.dart';
import 'package:chiplens_lite/backend/diagnostics/diagnostic_source.dart';

void main() {
  // ── plain error/warning lines ──────────────────────────────────────────────

  group('plain error/warning lines', () {
    test('parses plain error line', () {
      final diags = IcarusParser.parse('error: Unknown module type: foo');
      expect(diags.length, 1);
      expect(diags.first.severity, 'error');
      expect(diags.first.source,   DiagnosticSource.icarus);
    });

    test('parses plain warning line', () {
      final diags = IcarusParser.parse('warning: implicit declaration of wire foo');
      expect(diags.length, 1);
      expect(diags.first.severity, 'warning');
      expect(diags.first.id,       'icarus_implicit_wire');
    });

    test('returns empty list for clean output', () {
      const output = 'Simulation complete.\nVCD dumpfile opened.';
      expect(IcarusParser.parse(output), isEmpty);
    });

    test('skips blank and non-diagnostic lines', () {
      expect(IcarusParser.parse('\nVCD info: dumpfile opened.\n'), isEmpty);
    });

    test('skips elaboration summary line', () {
      expect(
        IcarusParser.parse('2 error(s) during elaboration.'),
        isEmpty,
      );
    });
  });

  // ── located lines (file:line prefix) ──────────────────────────────────────

  group('located error/warning lines', () {
    test('parses file:line: error: message', () {
      final diags = IcarusParser.parse('design.v:10: error: syntax error');
      expect(diags.length, 1);
      expect(diags.first.severity,       'error');
      expect(diags.first.location?.line, 10);
      expect(diags.first.location?.file, 'design.v');
      expect(diags.first.source,         DiagnosticSource.icarus);
    });

    test('parses file:line: warning: message', () {
      final diags = IcarusParser.parse(
        'testbench.v:5: warning: implicit declaration of wire q',
      );
      expect(diags.first.severity,       'warning');
      expect(diags.first.id,             'icarus_implicit_wire');
      expect(diags.first.location?.line, 5);
    });
  });

  // ── vvp runtime \$stop ─────────────────────────────────────────────────────

  group('vvp runtime \$stop', () {
    test('parses \$stop called line', () {
      final diags = IcarusParser.parse(
        'testbench.v:15: \$stop called at 15 (SystemVerilog)',
      );
      expect(diags.length, 1);
      expect(diags.first.id,             'icarus_simulation_stop');
      expect(diags.first.severity,       'error');
      expect(diags.first.location?.line, 15);
    });
  });

  // ── rule ID inference ──────────────────────────────────────────────────────

  group('rule ID inference', () {
    test('syntax error → icarus_syntax_error', () {
      final diags = IcarusParser.parse(
        'design.v:3: error: syntax error, unexpected TOK_ALWAYS',
      );
      expect(diags.first.id, 'icarus_syntax_error');
    });

    test('implicit declaration → icarus_implicit_wire', () {
      final diags = IcarusParser.parse(
        'design.v:7: warning: implicit declaration of wire net1',
      );
      expect(diags.first.id, 'icarus_implicit_wire');
    });

    test('unknown module → icarus_undefined_module', () {
      final diags = IcarusParser.parse(
        "error: Unknown module type: mymod",
      );
      expect(diags.first.id, 'icarus_undefined_module');
    });

    test('type mismatch → icarus_type_error', () {
      final diags = IcarusParser.parse(
        'design.v:9: error: type mismatch in assignment',
      );
      expect(diags.first.id, 'icarus_type_error');
    });

    test('unknown error falls back to icarus_error', () {
      final diags = IcarusParser.parse('error: something unexpected');
      expect(diags.first.id, 'icarus_error');
    });

    test('unknown warning falls back to icarus_warning', () {
      final diags = IcarusParser.parse('warning: something minor');
      expect(diags.first.id, 'icarus_warning');
    });
  });

  // ── multi-line output ──────────────────────────────────────────────────────

  group('multi-line output', () {
    test('parses compile + simulation output combined', () {
      const output = '''
design.v:3: error: syntax error, unexpected token
2 error(s) during elaboration.
testbench.v:15: \$stop called at 15 (SystemVerilog)
VCD info: dumpfile sim.vcd opened for output.
''';
      final diags = IcarusParser.parse(output);
      expect(diags.length, 2); // syntax error + $stop; summary skipped
      expect(diags.map((d) => d.id),
          containsAll(['icarus_syntax_error', 'icarus_simulation_stop']));
    });

    test('parses mixed errors and warnings', () {
      const output = '''
design.v:5: error: Unknown module type: foo
testbench.v:8: warning: implicit declaration of wire x
''';
      final diags = IcarusParser.parse(output);
      expect(diags.length, 2);
      expect(diags.map((d) => d.id),
          containsAll(['icarus_undefined_module', 'icarus_implicit_wire']));
    });

    test('returns empty list for pure VCD/stat output', () {
      const output = '''
VCD info: dumpfile sim.vcd opened for output.
Simulation complete.
      ''';
      expect(IcarusParser.parse(output), isEmpty);
    });
  });
}
