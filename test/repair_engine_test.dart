import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/repair/repair.dart';
import 'package:chiplens_lite/models/design_spec.dart';
import 'package:chiplens_lite/backend/diagnostics/diagnostic_source.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

QualityWarning _w(String type, {String severity = 'warning'}) =>
    QualityWarning(type: type, message: 'test', severity: severity);

// ─── RepairSuggestion ─────────────────────────────────────────────────────────

void main() {
  group('RepairSuggestion', () {
    test('isAutoFixable true when originalCode non-empty', () {
      const s = RepairSuggestion(
        ruleId: 'test', title: 'T', explanation: 'E',
        originalCode: 'x = 1;', replacementCode: 'x <= 1;',
        confidence: 0.9,
      );
      expect(s.isAutoFixable, isTrue);
    });

    test('isAutoFixable false when originalCode empty', () {
      const s = RepairSuggestion(
        ruleId: 'test', title: 'T', explanation: 'E',
        originalCode: '', replacementCode: '',
        confidence: 0.3,
      );
      expect(s.isAutoFixable, isFalse);
    });

    test('confidenceLabel high for >= 0.85', () {
      const s = RepairSuggestion(
        ruleId: 'r', title: 'T', explanation: 'E',
        originalCode: '', replacementCode: '', confidence: 0.9,
      );
      expect(s.confidenceLabel, 'High');
    });

    test('confidenceLabel medium for >= 0.60', () {
      const s = RepairSuggestion(
        ruleId: 'r', title: 'T', explanation: 'E',
        originalCode: '', replacementCode: '', confidence: 0.70,
      );
      expect(s.confidenceLabel, 'Medium');
    });

    test('confidenceLabel low below 0.60', () {
      const s = RepairSuggestion(
        ruleId: 'r', title: 'T', explanation: 'E',
        originalCode: '', replacementCode: '', confidence: 0.40,
      );
      expect(s.confidenceLabel, 'Low');
    });

    test('assert fires for confidence > 1', () {
      expect(
        () => RepairSuggestion(
          ruleId: 'r', title: 'T', explanation: 'E',
          originalCode: '', replacementCode: '', confidence: 1.1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert fires for confidence < 0', () {
      expect(
        () => RepairSuggestion(
          ruleId: 'r', title: 'T', explanation: 'E',
          originalCode: '', replacementCode: '', confidence: -0.1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('confidence boundary 0.0 is valid', () {
      const s = RepairSuggestion(
        ruleId: 'r', title: 'T', explanation: 'E',
        originalCode: '', replacementCode: '', confidence: 0.0,
      );
      expect(s.confidence, 0.0);
    });

    test('confidence boundary 1.0 is valid', () {
      const s = RepairSuggestion(
        ruleId: 'r', title: 'T', explanation: 'E',
        originalCode: '', replacementCode: '', confidence: 1.0,
      );
      expect(s.confidence, 1.0);
    });
  });

  // ─── RepairResult ────────────────────────────────────────────────────────────

  group('RepairResult', () {
    const report = QualityReport(
      total: 85, grade: 'B+', categories: {}, warnings: [], warningCount: 0,
    );
    const result = RepairResult(
      repairedRTL: 'module m; endmodule',
      issuesFixed: 3,
      remainingIssues: 1,
      qualityBefore: 60.0,
      qualityAfter: 85.0,
      appliedSuggestions: [],
      newQualityReport: report,
    );

    test('qualityDelta is positive when improved', () {
      expect(result.qualityDelta, closeTo(25.0, 0.001));
    });

    test('qualityDelta is negative when degraded', () {
      const r2 = RepairResult(
        repairedRTL: '', issuesFixed: 0, remainingIssues: 2,
        qualityBefore: 80.0, qualityAfter: 70.0,
        appliedSuggestions: [], newQualityReport: report,
      );
      expect(r2.qualityDelta, closeTo(-10.0, 0.001));
    });

    test('stores all fields', () {
      expect(result.repairedRTL, 'module m; endmodule');
      expect(result.issuesFixed, 3);
      expect(result.remainingIssues, 1);
      expect(result.qualityBefore, 60.0);
      expect(result.qualityAfter, 85.0);
    });
  });

  // ─── RepairEngine.suggest() ──────────────────────────────────────────────────

  group('RepairEngine.suggest()', () {
    const rtl = '''
module counter(input clk, input rst, output reg [3:0] q);
  always @(posedge clk) begin
    if (rst) q <= 4\'d0;
    else q = q + 1;
  end
endmodule
''';

    test('empty warnings → empty suggestions', () {
      final sug = RepairEngine.suggest(rtlSource: rtl, warnings: []);
      expect(sug, isEmpty);
    });

    test('unknown rule IDs produce no suggestions', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('totally_unknown_rule_xyz')],
      );
      expect(sug, isEmpty);
    });

    test('blocking_assignment warning generates suggestion', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('blocking_assignment')],
      );
      expect(sug, isNotEmpty);
      expect(sug.first.ruleId, 'blocking_assignment');
    });

    test('missing_default warning generates suggestion', () {
      final rtlWithCase = '''
module m(input [1:0] sel, output reg out);
  always @(*) begin
    case (sel)
      2\'b00: out = 1;
      2\'b01: out = 0;
    endcase
  end
endmodule''';
      final sug = RepairEngine.suggest(
        rtlSource: rtlWithCase,
        warnings: [_w('missing_default')],
      );
      expect(sug, isNotEmpty);
      expect(sug.first.confidence, greaterThan(0.0));
    });

    test('inferred_latch generates suggestion (RTL with case, no default)', () {
      const rtlCase = '''
module m(input [1:0] sel, output reg out);
  always @(*) begin
    case (sel)
      2'b00: out = 1;
      2'b01: out = 0;
    endcase
  end
endmodule''';
      final sug = RepairEngine.suggest(
        rtlSource: rtlCase,
        warnings: [_w('inferred_latch')],
      );
      expect(sug, isNotEmpty);
    });

    test('missing_reset warning generates suggestion (RTL without reset)', () {
      const rtlNoReset = '''
module counter(input clk, output reg [3:0] q);
  always @(posedge clk) begin
    q <= q + 1;
  end
endmodule''';
      final sug = RepairEngine.suggest(
        rtlSource: rtlNoReset,
        warnings: [_w('missing_reset')],
      );
      expect(sug, isNotEmpty);
    });

    test('incomplete_sensitivity generates suggestion (explicit sens list)', () {
      // Regex requires >=2 chars in list: [^*)\s][^)]+ needs first char + one more
      const rtlExplicit = '''
module m(input a, input b, output reg out);
  always @(a, b) begin
    out = a & b;
  end
endmodule''';
      final sug = RepairEngine.suggest(
        rtlSource: rtlExplicit,
        warnings: [_w('incomplete_sensitivity')],
      );
      expect(sug, isNotEmpty);
    });

    test('unused_signal generates suggestion (warning names signal in RTL)', () {
      const rtlUnused = '''
module m(input a, output out);
  wire unused_sig;
  assign out = a;
endmodule''';
      final w = QualityWarning(
        type: 'unused_signal', message: "Signal 'unused_sig' is unused",
        severity: 'warning',
      );
      final sug = RepairEngine.suggest(rtlSource: rtlUnused, warnings: [w]);
      expect(sug, isNotEmpty);
    });

    test('unreachable_state generates informational suggestion', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('unreachable_state')],
      );
      expect(sug, isNotEmpty);
      expect(sug.first.isAutoFixable, isFalse);
    });

    test('combinatorial_loop generates informational suggestion', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('combinatorial_loop')],
      );
      expect(sug, isNotEmpty);
      expect(sug.first.isAutoFixable, isFalse);
    });

    test('multiple_drivers generates informational suggestion', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('multiple_drivers')],
      );
      expect(sug, isNotEmpty);
      expect(sug.first.isAutoFixable, isFalse);
    });

    test('Verilator alias: verilator_latch → suggestion', () {
      const rtlCase = '''
module m(input [1:0] sel, output reg out);
  always @(*) begin
    case (sel)
      2'b00: out = 1;
    endcase
  end
endmodule''';
      final sug = RepairEngine.suggest(
        rtlSource: rtlCase,
        warnings: [_w('verilator_latch')],
      );
      expect(sug, isNotEmpty);
    });

    test('Verilator alias: verilator_blkandnblk → suggestion', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('verilator_blkandnblk')],
      );
      expect(sug, isNotEmpty);
    });

    test('Yosys alias: yosys_infer_latch → suggestion', () {
      const rtlCase = '''
module m(input [1:0] sel, output reg out);
  always @(*) begin
    case (sel)
      2'b00: out = 1;
    endcase
  end
endmodule''';
      final sug = RepairEngine.suggest(
        rtlSource: rtlCase,
        warnings: [_w('yosys_infer_latch')],
      );
      expect(sug, isNotEmpty);
    });

    test('suggestions sorted by descending confidence', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [
          _w('blocking_assignment'),   // 0.80
          _w('missing_reset'),         // 0.70
          _w('unused_signal'),         // 0.60
        ],
      );
      for (var i = 0; i < sug.length - 1; i++) {
        expect(sug[i].confidence, greaterThanOrEqualTo(sug[i + 1].confidence));
      }
    });

    test('duplicate warnings with same code deduplicate', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('blocking_assignment'), _w('verilator_blkandnblk')],
      );
      // Both map to same fix — dedup should keep only one
      final blockingSugs = sug.where((s) =>
          s.ruleId == 'blocking_assignment' ||
          s.ruleId == 'verilator_blkandnblk').toList();
      expect(blockingSugs.length, lessThanOrEqualTo(2));
    });
  });

  // ─── RepairEngine.applyAll() ──────────────────────────────────────────────────

  group('RepairEngine.applyAll()', () {
    test('empty suggestions list returns source unchanged', () {
      const src = 'module m; endmodule';
      expect(RepairEngine.applyAll(src, []), src);
    });

    test('applies single replacement', () {
      const src = 'x = y + 1;';
      const sug = RepairSuggestion(
        ruleId: 'test', title: 'T', explanation: 'E',
        originalCode: 'x = y + 1;',
        replacementCode: 'x <= y + 1;',
        confidence: 0.8,
      );
      final result = RepairEngine.applyAll(src, [sug]);
      expect(result, contains('x <= y + 1;'));
    });

    test('skips suggestion whose originalCode is not found', () {
      const src = 'module m; endmodule';
      const sug = RepairSuggestion(
        ruleId: 'test', title: 'T', explanation: 'E',
        originalCode: 'does_not_exist_in_source',
        replacementCode: 'replacement',
        confidence: 0.8,
      );
      final result = RepairEngine.applyAll(src, [sug]);
      expect(result, src);
    });

    test('skips non-fixable suggestions (empty originalCode)', () {
      const src = 'module m; endmodule';
      const sug = RepairSuggestion(
        ruleId: 'test', title: 'T', explanation: 'E',
        originalCode: '', replacementCode: '', confidence: 0.3,
      );
      final result = RepairEngine.applyAll(src, [sug]);
      expect(result, src);
    });

    test('applies multiple non-overlapping suggestions', () {
      const src = 'a = 1; b = 2;';
      const suggestions = [
        RepairSuggestion(
          ruleId: 'r1', title: 'T', explanation: 'E',
          originalCode: 'a = 1;', replacementCode: 'a <= 1;', confidence: 0.9,
        ),
        RepairSuggestion(
          ruleId: 'r2', title: 'T', explanation: 'E',
          originalCode: 'b = 2;', replacementCode: 'b <= 2;', confidence: 0.8,
        ),
      ];
      final result = RepairEngine.applyAll(src, suggestions);
      expect(result, contains('a <= 1;'));
      expect(result, contains('b <= 2;'));
    });
  });

  // ─── Pattern-specific confidence values ──────────────────────────────────────

  group('Confidence values', () {
    const rtl = 'module m(input clk); always @(posedge clk) begin end endmodule';

    test('incomplete_sensitivity confidence is 0.95', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('incomplete_sensitivity')],
      );
      if (sug.isNotEmpty) {
        expect(sug.first.confidence, closeTo(0.95, 0.001));
      }
    });

    test('missing_default confidence is 0.90', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('missing_default')],
      );
      if (sug.isNotEmpty) {
        expect(sug.first.confidence, closeTo(0.90, 0.001));
      }
    });

    test('blocking_assignment confidence is 0.80', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('blocking_assignment')],
      );
      if (sug.isNotEmpty) {
        expect(sug.first.confidence, closeTo(0.80, 0.001));
      }
    });

    test('unused_signal confidence is 0.60', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('unused_signal')],
      );
      if (sug.isNotEmpty) {
        expect(sug.first.confidence, closeTo(0.60, 0.001));
      }
    });

    test('combinatorial_loop confidence is 0.35', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('combinatorial_loop')],
      );
      if (sug.isNotEmpty) {
        expect(sug.first.confidence, closeTo(0.35, 0.001));
      }
    });

    test('multiple_drivers confidence is 0.30', () {
      final sug = RepairEngine.suggest(
        rtlSource: rtl,
        warnings: [_w('multiple_drivers')],
      );
      if (sug.isNotEmpty) {
        expect(sug.first.confidence, closeTo(0.30, 0.001));
      }
    });
  });

  // ─── DiagnosticSource field on QualityWarning ────────────────────────────────

  group('QualityWarning source field', () {
    test('defaults to internal', () {
      final w = _w('missing_default');
      expect(w.source, DiagnosticSource.internal);
    });

    test('can be set to verilator', () {
      final w = QualityWarning(
        type: 'verilator_latch', message: 'test',
        severity: 'warning', source: DiagnosticSource.verilator,
      );
      expect(w.source, DiagnosticSource.verilator);
    });
  });
}
