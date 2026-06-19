import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/diagnostics/diagnostics.dart';

void main() {
  group('VerilatorDiagnosticParser', () {
    // ── Single-line parsing ─────────────────────────────────────────────────

    test('parses %Error line with file, line, and column', () {
      const out = "%Error: design.v:10:5: Unknown module name: 'foo'";
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags.length, 1);
      expect(diags[0].id,               'verilator_error');
      expect(diags[0].severity,         'error');
      expect(diags[0].source,           DiagnosticSource.verilator);
      expect(diags[0].location?.line,   10);
      expect(diags[0].location?.column, 5);
    });

    test('parses %Warning-UNUSED into diagnostic with correct id and title', () {
      const out = "%Warning-UNUSED: design.v:5:3: Signal 'x' is not used";
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags.length,      1);
      expect(diags[0].id,       'verilator_unused');
      expect(diags[0].severity, 'warning');
      expect(diags[0].title,    'Verilator: UNUSED');
    });

    test('parses %Warning without code as verilator_warning', () {
      const out = '%Warning: design.v:3: Something suspicious';
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags.length,      1);
      expect(diags[0].id,       'verilator_warning');
      expect(diags[0].severity, 'warning');
    });

    test('parses %Error without code as verilator_error', () {
      const out = '%Error: design.v:7:1: Syntax error';
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags.length,      1);
      expect(diags[0].id,       'verilator_error');
      expect(diags[0].severity, 'error');
    });

    test('parses %Warning-WIDTH diagnostic', () {
      const out = "%Warning-WIDTH: design.v:12: Operator '+' width mismatch";
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags.length,  1);
      expect(diags[0].id,   'verilator_width');
      expect(diags[0].title, 'Verilator: WIDTH');
    });

    test('description is set from the message part', () {
      const out = "%Error-MULTIDRIVEN: design.v:3:3: Signal 'b' driven multiple times";
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags[0].description, contains("Signal 'b'"));
    });

    test('location.file is the basename (not full path)', () {
      const out = "%Warning-UNUSED: /tmp/chiplens_abc123/design.v:5:1: Unused signal";
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags[0].location?.file, 'design.v');
    });

    test('all parsed diagnostics have source = verilator', () {
      const out = '''
%Error-MULTIDRIVEN: design.v:3:3: Signal 'b' is driven multiple times
%Warning-UNUSED: design.v:5:1: Signal 'x' is not used
''';
      final diags = VerilatorDiagnosticParser.parse(out);
      expect(diags.every((d) => d.source == DiagnosticSource.verilator), isTrue);
    });

    // ── Summary line filtering ──────────────────────────────────────────────

    test('skips %Error: Exiting summary line', () {
      const out = '%Error: Exiting due to 1 error(s)';
      expect(VerilatorDiagnosticParser.parse(out), isEmpty);
    });

    test('skips %Warning: Exiting summary line', () {
      const out = '%Warning: Exiting due to 3 warning(s)';
      expect(VerilatorDiagnosticParser.parse(out), isEmpty);
    });

    // ── Multi-line output ───────────────────────────────────────────────────

    test('parses multiple diagnostics and filters summary', () {
      const out = '''
%Error-MULTIDRIVEN: design.v:3:3: Signal 'b' is driven multiple times
%Warning-UNUSED: design.v:7:1: Signal 'sel' is not used
%Error: Exiting due to 1 error(s)
''';
      final diags = VerilatorDiagnosticParser.parse(out);

      expect(diags.length, 2);
      expect(diags[0].id, 'verilator_multidriven');
      expect(diags[1].id, 'verilator_unused');
    });

    test('returns empty list for empty string', () {
      expect(VerilatorDiagnosticParser.parse(''), isEmpty);
    });

    test('returns empty list for non-diagnostic output (report lines)', () {
      const out = '''
Verilator: Built from 0.030 MB sources in 1 files, 1 files changed
Verilator: Walltime 0.017 s, elapsed 0.017 s
''';
      expect(VerilatorDiagnosticParser.parse(out), isEmpty);
    });

    // ── Id normalisation ────────────────────────────────────────────────────

    test('code is lowercased in the rule id', () {
      const out = '%Warning-WIDTHTRUNC: design.v:4:3: Width truncation';
      final diags = VerilatorDiagnosticParser.parse(out);
      expect(diags[0].id, 'verilator_widthtrunc');
    });
  });
}
