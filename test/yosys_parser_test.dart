import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/diagnostics/yosys_parser.dart';
import 'package:chiplens_lite/backend/diagnostics/diagnostic_source.dart';

void main() {
  // ── plain ERROR / Warning lines ────────────────────────────────────────────

  group('plain error/warning lines', () {
    test('parses plain ERROR line', () {
      const output = 'ERROR: syntax error, unexpected TOK_ALWAYS';
      final diags  = YosysParser.parse(output);

      expect(diags.length, 1);
      expect(diags.first.severity, 'error');
      expect(diags.first.source,   DiagnosticSource.yosys);
    });

    test('parses plain Warning line', () {
      const output = 'Warning: Latch inferred for signal foo';
      final diags  = YosysParser.parse(output);

      expect(diags.length, 1);
      expect(diags.first.severity, 'warning');
      expect(diags.first.id,       'yosys_infer_latch');
    });

    test('returns empty list for clean output', () {
      const output = 'Successfully finished synthesis.\nStat: 42 cells.';
      final diags  = YosysParser.parse(output);

      expect(diags, isEmpty);
    });

    test('skips blank and non-diagnostic lines', () {
      const output = '\nSynthesis complete.\n\n';
      expect(YosysParser.parse(output), isEmpty);
    });
  });

  // ── located lines (file:line prefix) ──────────────────────────────────────

  group('located error/warning lines', () {
    test('parses file:line: ERROR: message', () {
      const output = 'design.v:12: ERROR: syntax error, unexpected token';
      final diags  = YosysParser.parse(output);

      expect(diags.length, 1);
      expect(diags.first.severity,          'error');
      expect(diags.first.location?.line,    12);
      expect(diags.first.location?.file,    'design.v');
      expect(diags.first.source,            DiagnosticSource.yosys);
    });

    test('parses file:line: Warning: message', () {
      const output = 'design.v:8: Warning: multiple drivers for net q';
      final diags  = YosysParser.parse(output);

      expect(diags.length, 1);
      expect(diags.first.severity,       'warning');
      expect(diags.first.id,             'yosys_multiple_drivers');
      expect(diags.first.location?.line, 8);
    });
  });

  // ── rule ID inference ──────────────────────────────────────────────────────

  group('rule ID inference', () {
    test('latch keyword → yosys_infer_latch', () {
      final diags = YosysParser.parse('Warning: Latch inferred for signal out');
      expect(diags.first.id, 'yosys_infer_latch');
    });

    test('multiple driver keyword → yosys_multiple_drivers', () {
      final diags = YosysParser.parse('Warning: multiple drivers for signal bus');
      expect(diags.first.id, 'yosys_multiple_drivers');
    });

    test('undriven keyword → yosys_undriven', () {
      final diags = YosysParser.parse('Warning: Signal foo is undriven');
      expect(diags.first.id, 'yosys_undriven');
    });

    test('module not found keyword → yosys_missing_module', () {
      final diags = YosysParser.parse("ERROR: Module not found: mymod");
      expect(diags.first.id, 'yosys_missing_module');
    });

    test('combinatorial loop keyword → yosys_loop', () {
      final diags = YosysParser.parse('ERROR: combinatorial loop detected');
      expect(diags.first.id, 'yosys_loop');
    });

    test('syntax error keyword → yosys_syntax_error', () {
      final diags = YosysParser.parse('ERROR: syntax error near always');
      expect(diags.first.id, 'yosys_syntax_error');
    });

    test('unknown error falls back to yosys_error', () {
      final diags = YosysParser.parse('ERROR: something unfamiliar happened');
      expect(diags.first.id, 'yosys_error');
    });

    test('unknown warning falls back to yosys_warning', () {
      final diags = YosysParser.parse('Warning: something minor happened');
      expect(diags.first.id, 'yosys_warning');
    });
  });

  // ── multi-line output ──────────────────────────────────────────────────────

  group('multi-line output', () {
    test('parses multiple diagnostics from combined output', () {
      const output = '''
Yosys 0.38 (git sha1 abc123)
-- Executing Verilog-2005 frontend --
WARNING: ...
design.v:3: ERROR: syntax error, unexpected token
Warning: Latch inferred for signal out
Successfully finished synthesis.
''';
      final diags = YosysParser.parse(output);
      expect(diags.length, 2,
          reason: 'WARNING: without space-colon pattern is not matched; '
              'only located ERROR and plain Warning are valid');
    });

    test('parses synthesis warnings mixed with stat lines', () {
      const output = '''
Warning: Latch inferred for signal q
Stat: 12 cells, 8 wires
Warning: undriven signal net1
''';
      final diags = YosysParser.parse(output);
      expect(diags.length, 2);
      expect(diags.map((d) => d.id), containsAll(['yosys_infer_latch', 'yosys_undriven']));
    });
  });
}
