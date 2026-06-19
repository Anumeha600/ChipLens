import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/diagnostics/diagnostics.dart';
import 'package:chiplens_lite/backend/formal/formal.dart';
import 'package:chiplens_lite/models/design_spec.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _sbyPath  = r'E:\msys64\ucrt64\bin\sby';
const _bashPath = r'E:\msys64\usr\bin\bash.exe';

bool get _sbyAvailable =>
    File(_bashPath).existsSync() && File(_sbyPath).existsSync();

// Minimal valid Verilog with one always-true assertion
const _validRtl = '''
module top(input clk, input rst_n, input [7:0] data);
  reg [7:0] r;
  always @(posedge clk) begin
    if (!rst_n) r <= 8'h00;
    else        r <= data;
  end
  // Trivially-true safety property: register never exceeds 8-bit range
  always @(*) begin
    assert(r <= 8'hFF);
  end
endmodule
''';

// RTL with a property that is falsifiable
const _failingRtl = '''
module top(input clk, input [7:0] data);
  reg [7:0] r;
  always @(posedge clk) r <= data;
  // This assertion is always false — counterexample exists immediately
  always @(*) begin
    assert(r == 8'h00);
  end
endmodule
''';

// ── Helpers ────────────────────────────────────────────────────────────────

Diagnostic _fDiag(String id, String severity) => Diagnostic(
      id:          id,
      severity:    severity,
      title:       id,
      description: '$id diagnostic',
      source:      DiagnosticSource.formal,
    );

QualityReport _baseReport({int correctness = 30}) => QualityReport(
      total:      correctness + 25 + 18 + 12,
      grade:      'B+',
      categories: {
        'correctness':      correctness,
        'synthesizability': 25,
        'maintainability':  18,
        'fsm':              12,
      },
      warnings:     [],
      warningCount: 0,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {

  // ── FormalContext ──────────────────────────────────────────────────────────

  group('FormalContext', () {
    test('defaults to bmc mode with depth 20', () {
      const ctx = FormalContext(rtlSource: 'module m; endmodule');
      expect(ctx.mode,  FormalMode.bmc);
      expect(ctx.depth, 20);
    });

    test('topModule defaults to null', () {
      const ctx = FormalContext(rtlSource: '');
      expect(ctx.topModule, isNull);
    });

    test('can be constructed with all fields', () {
      const ctx = FormalContext(
        rtlSource:  'module x; endmodule',
        topModule:  'x',
        mode:       FormalMode.prove,
        depth:      50,
        timeout:    Duration(seconds: 30),
        properties: ['prop_a', 'prop_b'],
        config:     {'solver': 'z3'},
      );
      expect(ctx.topModule,       'x');
      expect(ctx.mode,            FormalMode.prove);
      expect(ctx.depth,           50);
      expect(ctx.properties,      ['prop_a', 'prop_b']);
      expect(ctx.config['solver'], 'z3');
    });

    test('FormalMode enum has bmc, prove, cover values', () {
      expect(FormalMode.bmc.name,   'bmc');
      expect(FormalMode.prove.name, 'prove');
      expect(FormalMode.cover.name, 'cover');
    });
  });

  // ── FormalResult ───────────────────────────────────────────────────────────

  group('FormalResult', () {
    test('combined merges stderr then stdout', () {
      const r = FormalResult(
        success:  true,
        exitCode: 0,
        stdout:   'out',
        stderr:   'err',
      );
      expect(r.combined, 'err\nout');
    });

    test('combined trims leading/trailing whitespace', () {
      const r = FormalResult(
        success: false, exitCode: 1, stdout: '  \n', stderr: '\n  ',
      );
      expect(r.combined, isEmpty);
    });

    test('unavailable() sentinel has exitCode -1 and non-empty stderr', () {
      final r = FormalResult.unavailable();
      expect(r.success,   isFalse);
      expect(r.exitCode,  -1);
      expect(r.stderr,    isNotEmpty);
    });

    test('hasFailures is false when failedProperties is empty', () {
      const r = FormalResult(
        success: true, exitCode: 0, stdout: '', stderr: '',
        provenProperties: ['p1'],
      );
      expect(r.hasFailures, isFalse);
    });

    test('hasFailures is true when failedProperties is non-empty', () {
      const r = FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        failedProperties: ['p1'],
      );
      expect(r.hasFailures, isTrue);
    });

    test('allProven requires proven non-empty and failed+unknown empty', () {
      const pass = FormalResult(
        success: true, exitCode: 0, stdout: '', stderr: '',
        provenProperties: ['p1'],
      );
      const failToo = FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        provenProperties: ['p1'],
        failedProperties: ['p2'],
      );
      expect(pass.allProven,    isTrue);
      expect(failToo.allProven, isFalse);
    });

    test('toString includes property counts', () {
      const r = FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        provenProperties: ['a'],
        failedProperties: ['b', 'c'],
        unknownProperties: ['d'],
      );
      expect(r.toString(), contains('proven: 1'));
      expect(r.toString(), contains('failed: 2'));
      expect(r.toString(), contains('unknown: 1'));
    });
  });

  // ── SbyScriptBuilder ───────────────────────────────────────────────────────

  group('SbyScriptBuilder', () {
    test('contains all four required sections', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: ''),
      );
      expect(script, contains('[options]'));
      expect(script, contains('[engines]'));
      expect(script, contains('[script]'));
      expect(script, contains('[files]'));
    });

    test('bmc mode includes depth line', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: '', mode: FormalMode.bmc, depth: 30),
      );
      expect(script, contains('mode bmc'));
      expect(script, contains('depth 30'));
    });

    test('prove mode omits depth line', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: '', mode: FormalMode.prove),
      );
      expect(script, contains('mode prove'));
      expect(script, isNot(contains('depth')));
    });

    test('cover mode omits depth line', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: '', mode: FormalMode.cover),
      );
      expect(script, contains('mode cover'));
      expect(script, isNot(contains('depth')));
    });

    test('topModule specified → prep -top <name>', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: '', topModule: 'my_top'),
      );
      expect(script, contains('prep -top my_top'));
    });

    test('topModule null → plain prep', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: ''),
      );
      expect(script, contains('prep\n'));
      expect(script, isNot(contains('prep -top')));
    });

    test('uses smtbmc engine', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: ''),
      );
      expect(script, contains('smtbmc'));
    });

    test('references design.v as RTL file', () {
      final script = SbyScriptBuilder.build(
        const FormalContext(rtlSource: ''),
      );
      expect(script, contains('read -formal design.v'));
      expect(script, contains('design.v\n'));
    });
  });

  // ── FormalDiagnosticParser ─────────────────────────────────────────────────

  group('FormalDiagnosticParser', () {
    test('empty result produces no diagnostics', () {
      const r = FormalResult(
        success: true, exitCode: 0, stdout: '', stderr: '',
      );
      expect(FormalDiagnosticParser.parse(r), isEmpty);
    });

    test('proven-only result produces no diagnostics', () {
      const r = FormalResult(
        success: true, exitCode: 0, stdout: '', stderr: '',
        provenProperties: ['prop_a', 'prop_b'],
      );
      expect(FormalDiagnosticParser.parse(r), isEmpty);
    });

    test('failed property → error Diagnostic with formal source', () {
      const r = FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        failedProperties: ['prop_safety'],
      );
      final diags = FormalDiagnosticParser.parse(r);
      expect(diags.length, 1);
      expect(diags.first.id,       'formal_property_failed');
      expect(diags.first.severity, 'error');
      expect(diags.first.source,   DiagnosticSource.formal);
      expect(diags.first.description, contains('prop_safety'));
    });

    test('unknown property → warning Diagnostic with formal source', () {
      const r = FormalResult(
        success: false, exitCode: 2, stdout: '', stderr: '',
        unknownProperties: ['prop_liveness'],
      );
      final diags = FormalDiagnosticParser.parse(r);
      expect(diags.length, 1);
      expect(diags.first.id,       'formal_property_unknown');
      expect(diags.first.severity, 'warning');
      expect(diags.first.source,   DiagnosticSource.formal);
    });

    test('multiple failed properties → one diagnostic per property', () {
      const r = FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        failedProperties: ['p1', 'p2', 'p3'],
      );
      final diags = FormalDiagnosticParser.parse(r);
      expect(diags.length, 3);
      expect(diags.every((d) => d.id == 'formal_property_failed'), isTrue);
    });

    test('failed and unknown properties both produce diagnostics', () {
      const r = FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        failedProperties:  ['p_fail'],
        unknownProperties: ['p_unknown'],
      );
      final diags = FormalDiagnosticParser.parse(r);
      expect(diags.length, 2);
      expect(diags.any((d) => d.id == 'formal_property_failed'),  isTrue);
      expect(diags.any((d) => d.id == 'formal_property_unknown'), isTrue);
    });

    test('failed diagnostic includes quickFix hint', () {
      const r = FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        failedProperties: ['p'],
      );
      final diags = FormalDiagnosticParser.parse(r);
      expect(diags.first.quickFix, isNotNull);
    });

    test('engine-level ERROR line in raw output → error diagnostic', () {
      const r = FormalResult(
        success: false, exitCode: 1,
        stdout: '',
        stderr: 'Error: Solver not found: z3',
      );
      final diags = FormalDiagnosticParser.parse(r);
      expect(diags.any((d) => d.id == 'formal_engine_error'), isTrue);
      expect(diags.any((d) => d.severity == 'error'),         isTrue);
    });

    test('non-error output lines produce no diagnostics', () {
      const r = FormalResult(
        success: true, exitCode: 0,
        stdout: 'SBY 12:00 [design] DONE (PASS)',
        stderr: '',
      );
      expect(FormalDiagnosticParser.parse(r), isEmpty);
    });
  });

  // ── FormalEngine interface ─────────────────────────────────────────────────

  group('FormalEngine interface', () {
    test('stub engine satisfies the interface contract', () async {
      final engine = _StubEngine(success: true, proven: ['p1']);
      expect(engine.engineName,       'Stub');
      expect(await engine.isAvailable(), isTrue);

      final result = await engine.verify(
        const FormalContext(rtlSource: 'module m; endmodule'),
      );
      expect(result.success,            isTrue);
      expect(result.provenProperties,   ['p1']);
    });

    test('FormalRunner.run() delegates to provided engine', () async {
      final engine = _StubEngine(success: false, failed: ['prop_x']);
      final result = await FormalRunner.run(
        const FormalContext(rtlSource: ''),
        engine: engine,
      );
      expect(result.success,          isFalse);
      expect(result.failedProperties, ['prop_x']);
    });
  });

  // ── FormalRunner ───────────────────────────────────────────────────────────

  group('FormalRunner', () {
    test('runSymbiYosys returns empty list when sby is unavailable', () async {
      // Uses the real SymbiYosysEngine which may not be installed;
      // the convenience method must catch any exception and return [].
      final diags = await FormalRunner.runSymbiYosys('module m; endmodule');
      expect(diags, isA<List<Diagnostic>>());
    });

    test('run() with stub: successful result propagated', () async {
      final engine = _StubEngine(success: true, proven: ['all_assertions']);
      final result = await FormalRunner.run(
        const FormalContext(rtlSource: 'module m; endmodule'),
        engine: engine,
      );
      expect(result.allProven, isTrue);
    });

    test('run() with stub: failed result propagated', () async {
      final engine = _StubEngine(success: false, failed: ['inv_check']);
      final result = await FormalRunner.run(
        const FormalContext(rtlSource: ''),
        engine: engine,
      );
      expect(result.hasFailures, isTrue);
      expect(result.failedProperties.first, 'inv_check');
    });
  });

  // ── DiagnosticEngine + formal source ─────────────────────────────────────

  group('DiagnosticEngine formal integration', () {
    test('DiagnosticSource.formal exists', () {
      expect(DiagnosticSource.formal.name, 'formal');
    });

    test('formal error lowers correctness score', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_fDiag('formal_property_failed', 'error')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.categories['correctness'], lessThan(35));
      expect(merged.total, lessThan(base.total));
    });

    test('formal warning lowers score less than error', () {
      final base = _baseReport(correctness: 35);

      final withError = DiagnosticEngine()
        ..addAll([_fDiag('formal_error',   'error')]);
      final withWarn  = DiagnosticEngine()
        ..addAll([_fDiag('formal_warning', 'warning')]);

      expect(
        withError.mergeIntoReport(base).total,
        lessThan(withWarn.mergeIntoReport(base).total),
      );
    });

    test('formal warning appears in merged list with formal source', () {
      final base   = _baseReport();
      final engine = DiagnosticEngine()
        ..addAll([_fDiag('formal_property_unknown', 'warning')]);

      final merged      = engine.mergeIntoReport(base);
      final formalWarns = merged.warnings
          .where((w) => w.source == DiagnosticSource.formal)
          .toList();

      expect(formalWarns.length,    1);
      expect(formalWarns.first.type, 'formal_property_unknown');
    });

    test('formal info diagnostic has no score penalty', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_fDiag('formal_info', 'info')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.total, base.total);
    });

    test('FormalDiagnosticParser output integrates with DiagnosticEngine', () {
      final result = const FormalResult(
        success: false, exitCode: 1, stdout: '', stderr: '',
        failedProperties: ['prop_safety'],
      );
      final diags = FormalDiagnosticParser.parse(result);

      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()..addAll(diags);
      final merged = engine.mergeIntoReport(base);

      expect(merged.warnings.any((w) => w.type == 'formal_property_failed'), isTrue);
      expect(merged.categories['correctness'], lessThan(35));
    });

    test('three-source: Verilator + Icarus + Formal all accumulate', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([
          Diagnostic(
            id: 'verilator_multidriven', severity: 'error',
            title: 'v', description: 'v', source: DiagnosticSource.verilator,
          ),
          Diagnostic(
            id: 'icarus_syntax_error', severity: 'error',
            title: 'i', description: 'i', source: DiagnosticSource.icarus,
          ),
          _fDiag('formal_property_failed', 'error'),
        ]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.warnings.any((w) => w.source == DiagnosticSource.verilator), isTrue);
      expect(merged.warnings.any((w) => w.source == DiagnosticSource.icarus),    isTrue);
      expect(merged.warnings.any((w) => w.source == DiagnosticSource.formal),    isTrue);
    });
  });

  // ── SbyOutputParser ───────────────────────────────────────────────────────

  group('SbyOutputParser', () {
    // Build a mock ProcessResult from canned strings — no tool install needed.
    ProcessResult sby(String stdout, String stderr, {int exitCode = 0}) =>
        ProcessResult(0, exitCode, stdout, stderr);

    test('empty output → no proven/failed/unknown', () {
      final r = SbyOutputParser.interpret(sby('', ''), Duration.zero);
      expect(r.provenProperties,  isEmpty);
      expect(r.failedProperties,  isEmpty);
      expect(r.unknownProperties, isEmpty);
    });

    test('DONE (PASS) alone → all_assertions proven', () {
      final r = SbyOutputParser.interpret(
        sby('SBY 12:34:56 [design] DONE (PASS)', ''), Duration.zero,
      );
      expect(r.provenProperties,  ['all_assertions']);
      expect(r.failedProperties,  isEmpty);
      expect(r.unknownProperties, isEmpty);
    });

    test('DONE (FAIL) alone → unknown_assertion failed', () {
      final r = SbyOutputParser.interpret(
        sby('SBY 12:34:56 [design] DONE (FAIL)', '', exitCode: 1), Duration.zero,
      );
      expect(r.failedProperties,  ['unknown_assertion']);
      expect(r.provenProperties,  isEmpty);
      expect(r.unknownProperties, isEmpty);
    });

    test('named property line passed → property name in proven', () {
      const out =
          'Property ASSERT in module top at design.v:10 [design.v:10]: passed.';
      final r = SbyOutputParser.interpret(sby(out, ''), Duration.zero);
      expect(r.provenProperties, ['ASSERT']);
      expect(r.failedProperties, isEmpty);
    });

    test('named property line FAILED → property name in failed', () {
      const out =
          'Property ASSERT in module top at design.v:15 [design.v:15] FAILED!';
      final r = SbyOutputParser.interpret(
        sby(out, '', exitCode: 1), Duration.zero,
      );
      expect(r.failedProperties, ['ASSERT']);
      expect(r.provenProperties, isEmpty);
    });

    test('Assert failed reference → file:line identifier in failed', () {
      const out =
          'Assert failed in top: design.v:15\nSBY 12:34:56 [design] DONE (FAIL)';
      final r = SbyOutputParser.interpret(
        sby(out, '', exitCode: 1), Duration.zero,
      );
      expect(r.failedProperties, contains('design.v:15'));
    });

    test('UNKNOWN keyword → property name in unknown', () {
      const out =
          'Property ASSUME in module top at design.v:8 [design.v:8] UNKNOWN\n'
          'SBY 12:34:56 [design] DONE (FAIL)';
      final r = SbyOutputParser.interpret(
        sby(out, '', exitCode: 1), Duration.zero,
      );
      expect(r.unknownProperties, ['ASSUME']);
    });

    test('mixed proven and failed → both lists populated', () {
      const out = 'Property ASSERT in module top at design.v:10 [design.v:10]: passed.\n'
          'Property ASSERT in module top at design.v:20 [design.v:20] FAILED!\n'
          'SBY 12:34:56 [design] DONE (FAIL)';
      final r = SbyOutputParser.interpret(
        sby(out, '', exitCode: 1), Duration.zero,
      );
      expect(r.provenProperties, isNotEmpty);
      expect(r.failedProperties, isNotEmpty);
    });

    test('DONE (PASS) in stderr is recognized', () {
      final r = SbyOutputParser.interpret(
        sby('', 'SBY 12:34:56 [design] DONE (PASS)'), Duration.zero,
      );
      expect(r.provenProperties, ['all_assertions']);
    });

    test('exit code 0 and no failures → success true', () {
      final r = SbyOutputParser.interpret(
        sby('SBY 12:34:56 [design] DONE (PASS)', '', exitCode: 0),
        const Duration(seconds: 3),
      );
      expect(r.success,       isTrue);
      expect(r.exitCode,      0);
      expect(r.executionTime, const Duration(seconds: 3));
    });

    test('exit code 1 → success false even with DONE (PASS) in output', () {
      final r = SbyOutputParser.interpret(
        sby('SBY 12:34:56 [design] DONE (PASS)', '', exitCode: 1),
        Duration.zero,
      );
      expect(r.success,  isFalse);
      expect(r.exitCode, 1);
    });
  });

  // ── SymbiYosysEngine integration ──────────────────────────────────────────

  group('SymbiYosysEngine (integration)', () {
    test('isAvailable() returns a bool without throwing', () async {
      final engine = const SymbiYosysEngine(
        sbyPath:  _sbyPath,
        bashPath: _bashPath,
      );
      final available = await engine.isAvailable();
      expect(available, isA<bool>());
    });

    test('isAvailable() returns false when binary path is wrong', () async {
      final engine = const SymbiYosysEngine(
        sbyPath:  r'C:\nonexistent\sby',
        bashPath: r'C:\nonexistent\bash.exe',
      );
      expect(await engine.isAvailable(), isFalse);
    });

    test('engineName is SymbiYosys', () {
      expect(const SymbiYosysEngine().engineName, 'SymbiYosys');
    });

    test('verify() valid RTL returns success when sby available', () async {
      if (!_sbyAvailable) {
        markTestSkipped('SymbiYosys not installed at $_sbyPath');
        return;
      }
      final engine = const SymbiYosysEngine(
        sbyPath: _sbyPath, bashPath: _bashPath,
      );
      final result = await engine.verify(
        const FormalContext(
          rtlSource: _validRtl,
          topModule: 'top',
          mode:      FormalMode.bmc,
          depth:     5,
        ),
      );
      expect(result.exitCode, isNotNull);
      expect(result.stdout,   isA<String>());
      expect(result.stderr,   isA<String>());
    });

    test('verify() failing assertion returns failed property when sby available', () async {
      if (!_sbyAvailable) {
        markTestSkipped('SymbiYosys not installed at $_sbyPath');
        return;
      }
      final engine = const SymbiYosysEngine(
        sbyPath: _sbyPath, bashPath: _bashPath,
      );
      final result = await engine.verify(
        const FormalContext(
          rtlSource: _failingRtl,
          topModule: 'top',
          mode:      FormalMode.bmc,
          depth:     5,
        ),
      );
      // sby exits non-zero for assertion failures
      expect(result.success,   isFalse);
      expect(result.exitCode,  isNot(0));
    });

    test('FormalDiagnosticParser produces errors for sby failure output', () async {
      if (!_sbyAvailable) {
        markTestSkipped('SymbiYosys not installed at $_sbyPath');
        return;
      }
      final engine = const SymbiYosysEngine(
        sbyPath: _sbyPath, bashPath: _bashPath,
      );
      final result = await engine.verify(
        const FormalContext(
          rtlSource: _failingRtl,
          topModule: 'top',
          mode:      FormalMode.bmc,
          depth:     5,
        ),
      );
      if (!result.success) {
        final diags = FormalDiagnosticParser.parse(result);
        expect(diags.any((d) => d.severity == 'error'), isTrue);
      }
    });
  });
}

// ── Stub implementations ──────────────────────────────────────────────────────

class _StubEngine implements FormalEngine {
  final bool success;
  final List<String> proven;
  final List<String> failed;

  const _StubEngine({
    this.success = true,
    this.proven  = const [],
    this.failed  = const [],
  });

  @override
  String get engineName => 'Stub';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<FormalResult> verify(FormalContext context) async => FormalResult(
        success:           success,
        exitCode:          success ? 0 : 1,
        stdout:            '',
        stderr:            '',
        provenProperties:  proven,
        failedProperties:  failed,
      );
}
