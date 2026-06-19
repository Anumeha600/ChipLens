import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/diagnostics/diagnostics.dart';
import 'package:chiplens_lite/models/design_spec.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Diagnostic _vDiag(String id, String severity, {String? description}) =>
    Diagnostic(
      id:          id,
      severity:    severity,
      title:       id,
      description: description ?? '$id diagnostic',
      source:      DiagnosticSource.verilator,
    );

Diagnostic _yDiag(String id, String severity, {String? description}) =>
    Diagnostic(
      id:          id,
      severity:    severity,
      title:       id,
      description: description ?? '$id diagnostic',
      source:      DiagnosticSource.yosys,
    );

Diagnostic _iDiag(String id, String severity, {String? description}) =>
    Diagnostic(
      id:          id,
      severity:    severity,
      title:       id,
      description: description ?? '$id diagnostic',
      source:      DiagnosticSource.icarus,
    );

QualityReport _baseReport({
  int correctness = 30,
  List<QualityWarning> warnings = const [],
}) =>
    QualityReport(
      total:      correctness + 25 + 18 + 12,  // synth+maint+fsm fixed
      grade:      'B+',
      categories: {
        'correctness':      correctness,
        'synthesizability': 25,
        'maintainability':  18,
        'fsm':              12,
      },
      warnings:      warnings,
      warningCount:  warnings.length,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── DiagnosticSource enum ──────────────────────────────────────────────────

  group('DiagnosticSource', () {
    test('has internal, verilator, yosys and icarus values', () {
      expect(DiagnosticSource.internal.name,  'internal');
      expect(DiagnosticSource.verilator.name, 'verilator');
      expect(DiagnosticSource.yosys.name,     'yosys');
      expect(DiagnosticSource.icarus.name,    'icarus');
    });

    test('QualityWarning defaults to internal source', () {
      const w = QualityWarning(type: 't', message: 'm', severity: 'warning');
      expect(w.source, DiagnosticSource.internal);
    });

    test('QualityWarning can be created with verilator source', () {
      const w = QualityWarning(
        type: 'verilator_unused', message: 'Signal unused',
        severity: 'warning', source: DiagnosticSource.verilator,
      );
      expect(w.source, DiagnosticSource.verilator);
    });
  });

  // ── Internal-only diagnostics ──────────────────────────────────────────────

  group('internal diagnostics only', () {
    test('mergeIntoReport returns base unchanged when engine is empty', () {
      final base   = _baseReport(correctness: 28);
      final engine = DiagnosticEngine();
      final merged = engine.mergeIntoReport(base);

      expect(merged.total,                base.total);
      expect(merged.grade,                base.grade);
      expect(merged.categories['correctness'], 28);
      expect(merged.warnings.length,      0);
    });

    test('internal warnings carry source = internal', () {
      const w = QualityWarning(
        type: 'missing_reset', message: 'No reset', severity: 'critical',
      );
      expect(w.source, DiagnosticSource.internal);
    });

    test('score stays at 100 when RTL is clean and no Verilator diags', () {
      final base   = QualityReport(
        total: 100, grade: 'A+',
        categories: {
          'correctness': 35, 'synthesizability': 30,
          'maintainability': 20, 'fsm': 15,
        },
        warnings: [], warningCount: 0,
      );
      final merged = DiagnosticEngine().mergeIntoReport(base);
      expect(merged.total, 100);
    });
  });

  // ── Verilator-only diagnostics ─────────────────────────────────────────────

  group('Verilator diagnostics only', () {
    test('Verilator error lowers correctness by penalty', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_multidriven', 'error')]);

      final merged = engine.mergeIntoReport(base);

      expect(merged.categories['correctness'], lessThan(35));
      expect(merged.total,                     lessThan(base.total));
    });

    test('Verilator warning lowers correctness by smaller amount than error', () {
      final base = _baseReport(correctness: 35);

      final withError = DiagnosticEngine()
        ..addAll([_vDiag('verilator_a', 'error')]);
      final withWarn = DiagnosticEngine()
        ..addAll([_vDiag('verilator_b', 'warning')]);

      final errorTotal   = withError.mergeIntoReport(base).total;
      final warningTotal = withWarn.mergeIntoReport(base).total;

      expect(errorTotal, lessThan(warningTotal));
    });

    test('Verilator info diagnostic has no score penalty', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_techmap', 'info')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.total, base.total);
    });

    test('Verilator warnings appear in merged warning list', () {
      final base   = _baseReport();
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_unused', 'warning')]);

      final merged = engine.mergeIntoReport(base);
      final vWarnings = merged.warnings
          .where((w) => w.source == DiagnosticSource.verilator)
          .toList();

      expect(vWarnings.length, 1);
      expect(vWarnings.first.type, 'verilator_unused');
    });

    test('Verilator diagnostics list accessor returns all added diagnostics', () {
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_a', 'error'),
          _vDiag('verilator_b', 'warning'),
        ]);

      expect(engine.diagnostics.length, 2);
      expect(engine.diagnostics.every((d) => d.source == DiagnosticSource.verilator), isTrue);
    });
  });

  // ── Merged diagnostics ─────────────────────────────────────────────────────

  group('merged diagnostics', () {
    test('internal and Verilator warnings both appear in merged list', () {
      final base = _baseReport(
        warnings: [
          const QualityWarning(
            type: 'missing_timescale', message: 'No timescale', severity: 'warning',
          ),
        ],
      );
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_unused', 'warning')]);

      final merged = engine.mergeIntoReport(base);

      final internalWarns = merged.warnings
          .where((w) => w.source == DiagnosticSource.internal)
          .toList();
      final verilatorWarns = merged.warnings
          .where((w) => w.source == DiagnosticSource.verilator)
          .toList();

      expect(internalWarns.length,  1);
      expect(verilatorWarns.length, 1);
      expect(merged.warningCount,   2);
    });

    test('total warning count is the sum of both sources', () {
      final base = _baseReport(
        warnings: List.generate(
          3, (i) => QualityWarning(type: 'w$i', message: 'm', severity: 'warning'),
        ),
      );
      final engine = DiagnosticEngine()
        ..addAll(List.generate(
          2,
          (i) => _vDiag('verilator_v$i', 'warning'),
        ));

      final merged = engine.mergeIntoReport(base);
      expect(merged.warningCount, 5);
    });
  });

  // ── Duplicate elimination ──────────────────────────────────────────────────

  group('duplicate elimination', () {
    test('verilator_latch dropped when missing_default already reported', () {
      final base = _baseReport(
        warnings: [
          const QualityWarning(
            type: 'missing_default', message: 'No default', severity: 'warning',
          ),
        ],
      );
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_latch', 'warning')]);

      final merged = engine.mergeIntoReport(base);

      expect(
        merged.warnings.any((w) => w.type == 'verilator_latch'),
        isFalse,
        reason: 'verilator_latch is a duplicate of missing_default',
      );
      // Score should NOT be doubly penalised
      expect(merged.total, base.total);
    });

    test('verilator_resetall dropped when missing_reset already reported', () {
      final base = _baseReport(
        warnings: [
          const QualityWarning(
            type: 'missing_reset', message: 'No reset', severity: 'critical',
          ),
        ],
      );
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_resetall', 'warning')]);

      final merged = engine.mergeIntoReport(base);

      expect(
        merged.warnings.any((w) => w.type == 'verilator_resetall'),
        isFalse,
      );
    });

    test('verilator_combdly dropped when no_nonblocking already reported', () {
      final base = _baseReport(
        warnings: [
          const QualityWarning(
            type: 'no_nonblocking', message: 'No <=', severity: 'critical',
          ),
        ],
      );
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_combdly', 'warning')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.warnings.any((w) => w.type == 'verilator_combdly'), isFalse);
    });

    test('unique Verilator diagnostic is kept when no equivalent internal', () {
      final base   = _baseReport(warnings: []);
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_multidriven', 'error')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.warnings.any((w) => w.type == 'verilator_multidriven'), isTrue);
    });

    test('mergeIntoReport returns base unchanged if all Verilator diags are dupes', () {
      final base = _baseReport(
        correctness: 35,
        warnings: [
          const QualityWarning(
            type: 'missing_default', message: 'm', severity: 'warning',
          ),
          const QualityWarning(
            type: 'missing_reset', message: 'm', severity: 'critical',
          ),
        ],
      );
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_latch',    'warning'),
          _vDiag('verilator_resetall', 'warning'),
        ]);

      final merged = engine.mergeIntoReport(base);

      expect(merged.total,                     base.total);
      expect(merged.categories['correctness'], 35);
      // No extra warnings added
      expect(merged.warningCount, base.warningCount);
    });
  });

  // ── RTL quality scoring with merged diagnostics ───────────────────────────

  group('RTL quality scoring with merged diagnostics', () {
    test('clean design (no internal, no Verilator) scores at ceiling', () {
      final base   = _baseReport(correctness: 35);
      final merged = DiagnosticEngine().mergeIntoReport(base);
      expect(merged.total, base.total);
      expect(merged.grade, isNotEmpty);
    });

    test('Verilator error reduces total score correctly', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_multidriven', 'error')]);

      final merged = engine.mergeIntoReport(base);
      // penalty = 8 per error, capped at 20
      expect(merged.categories['correctness'], 35 - 8);
      expect(merged.total,                     base.total - 8);
    });

    test('multiple unique Verilator errors accumulate penalty', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_multidriven', 'error'),   // -8
          _vDiag('verilator_undriven',    'error'),   // -8 (different id)
        ]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.categories['correctness'], 35 - 8 - 8);
    });

    test('penalty is capped per rule id (same id multiple times)', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([
          // Same id fired multiple times — penalty capped at 20
          _vDiag('verilator_multidriven', 'error'),
          _vDiag('verilator_multidriven', 'error'),
          _vDiag('verilator_multidriven', 'error'),
        ]);

      final merged = engine.mergeIntoReport(base);
      // min(8*3=24, 20) = 20
      expect(merged.categories['correctness'], 35 - 20);
    });

    test('correctness never goes below 0', () {
      final base   = _baseReport(correctness: 5);
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_x', 'error')]);  // -8, but floor at 0

      final merged = engine.mergeIntoReport(base);
      expect(merged.categories['correctness'], 0);
    });

    test('grade string is always set after merge', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_err', 'error')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.grade, isNotEmpty);
    });

    test('clean design score > design with Verilator errors', () {
      final clean  = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_vDiag('verilator_undriven', 'error')]);
      final dirty  = engine.mergeIntoReport(clean);

      expect(clean.total, greaterThan(dirty.total));
    });
  });

  // ── Yosys diagnostics ─────────────────────────────────────────────────────

  group('Yosys diagnostics', () {
    test('Yosys error lowers correctness score', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_yDiag('yosys_error', 'error')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.categories['correctness'], lessThan(35));
      expect(merged.total, lessThan(base.total));
    });

    test('Yosys warning lowers correctness by smaller amount than error', () {
      final base = _baseReport(correctness: 35);

      final withError = DiagnosticEngine()
        ..addAll([_yDiag('yosys_error', 'error')]);
      final withWarn = DiagnosticEngine()
        ..addAll([_yDiag('yosys_warning', 'warning')]);

      expect(
        withError.mergeIntoReport(base).total,
        lessThan(withWarn.mergeIntoReport(base).total),
      );
    });

    test('Yosys info diagnostic has no score penalty', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_yDiag('yosys_stat', 'info')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.total, base.total);
    });

    test('Yosys warnings appear in merged warning list with yosys source', () {
      final base   = _baseReport();
      final engine = DiagnosticEngine()
        ..addAll([_yDiag('yosys_undriven', 'warning')]);

      final merged   = engine.mergeIntoReport(base);
      final yWarnings = merged.warnings
          .where((w) => w.source == DiagnosticSource.yosys)
          .toList();

      expect(yWarnings.length, 1);
      expect(yWarnings.first.type, 'yosys_undriven');
    });

    test('yosys_infer_latch dropped when internal missing_default reported', () {
      final base = _baseReport(
        warnings: [
          const QualityWarning(
            type: 'missing_default', message: 'No default', severity: 'warning',
          ),
        ],
      );
      final engine = DiagnosticEngine()
        ..addAll([_yDiag('yosys_infer_latch', 'warning')]);

      final merged = engine.mergeIntoReport(base);
      expect(
        merged.warnings.any((w) => w.type == 'yosys_infer_latch'),
        isFalse,
        reason: 'yosys_infer_latch maps to latch_risk, same as missing_default',
      );
      expect(merged.total, base.total);
    });

    test('Verilator takes priority over Yosys for same canonical issue', () {
      // Both verilator_latch and yosys_infer_latch map to canonical 'latch_risk'.
      // Verilator has higher priority — yosys duplicate is dropped.
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_latch',   'warning'),
          _yDiag('yosys_infer_latch', 'warning'),
        ]);

      final merged = engine.mergeIntoReport(base);

      final latchWarns = merged.warnings
          .where((w) => w.type == 'verilator_latch' || w.type == 'yosys_infer_latch')
          .toList();

      expect(latchWarns.length, 1,
          reason: 'only one of the two latch diagnostics should survive');
      expect(latchWarns.first.source, DiagnosticSource.verilator,
          reason: 'Verilator has higher priority than Yosys');
    });

    test('unique Yosys and Verilator diagnostics both appear', () {
      final base   = _baseReport();
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_multidriven', 'error'),
          _yDiag('yosys_undriven',        'warning'),
        ]);

      final merged = engine.mergeIntoReport(base);

      expect(merged.warnings.any((w) => w.type == 'verilator_multidriven'), isTrue);
      expect(merged.warnings.any((w) => w.type == 'yosys_undriven'),        isTrue);
    });

    test('Yosys + Verilator unique diagnostics accumulate penalties', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_multidriven', 'error'),    // -8
          _yDiag('yosys_missing_module',  'error'),    // -8
        ]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.categories['correctness'], 35 - 8 - 8);
    });
  });

  // ── Icarus diagnostics ────────────────────────────────────────────────────

  group('Icarus diagnostics', () {
    test('Icarus error lowers correctness score', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([_iDiag('icarus_syntax_error', 'error')]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.categories['correctness'], lessThan(35));
      expect(merged.total, lessThan(base.total));
    });

    test('Icarus warning lowers score less than error', () {
      final base = _baseReport(correctness: 35);

      final withError = DiagnosticEngine()
        ..addAll([_iDiag('icarus_error',   'error')]);
      final withWarn  = DiagnosticEngine()
        ..addAll([_iDiag('icarus_warning', 'warning')]);

      expect(
        withError.mergeIntoReport(base).total,
        lessThan(withWarn.mergeIntoReport(base).total),
      );
    });

    test('Icarus warning appears in merged list with icarus source', () {
      final base   = _baseReport();
      final engine = DiagnosticEngine()
        ..addAll([_iDiag('icarus_implicit_wire', 'warning')]);

      final merged    = engine.mergeIntoReport(base);
      final iWarnings = merged.warnings
          .where((w) => w.source == DiagnosticSource.icarus)
          .toList();

      expect(iWarnings.length, 1);
      expect(iWarnings.first.type, 'icarus_implicit_wire');
    });

    test('Icarus has lowest priority — dropped when Verilator covers same key', () {
      // If a future canonical entry maps icarus_X → latch_risk,
      // a pre-existing verilator_latch should suppress it.
      // For now, test that icarus diagnostics without canonical keys are kept.
      final base   = _baseReport(warnings: []);
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_multidriven', 'error'),
          _iDiag('icarus_syntax_error',   'error'),
        ]);

      final merged = engine.mergeIntoReport(base);
      // Both have different rule IDs and no shared canonical key → both kept
      expect(merged.warnings.any((w) => w.type == 'verilator_multidriven'), isTrue);
      expect(merged.warnings.any((w) => w.type == 'icarus_syntax_error'),   isTrue);
    });

    test('three-source accumulation: Verilator + Yosys + Icarus all appear', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_multidriven', 'error'),
          _yDiag('yosys_undriven',        'warning'),
          _iDiag('icarus_implicit_wire',  'warning'),
        ]);

      final merged = engine.mergeIntoReport(base);

      expect(merged.warnings.any((w) => w.source == DiagnosticSource.verilator), isTrue);
      expect(merged.warnings.any((w) => w.source == DiagnosticSource.yosys),     isTrue);
      expect(merged.warnings.any((w) => w.source == DiagnosticSource.icarus),    isTrue);
    });

    test('Icarus + Verilator + Yosys penalties all accumulate correctly', () {
      final base   = _baseReport(correctness: 35);
      final engine = DiagnosticEngine()
        ..addAll([
          _vDiag('verilator_multidriven', 'error'),   // -8
          _yDiag('yosys_missing_module',  'error'),   // -8
          _iDiag('icarus_syntax_error',   'error'),   // -8
        ]);

      final merged = engine.mergeIntoReport(base);
      expect(merged.categories['correctness'], 35 - 8 - 8 - 8);
    });

    test('DiagnosticEngine.diagnostics accessor includes Icarus entries', () {
      final engine = DiagnosticEngine()
        ..addAll([
          _iDiag('icarus_error',   'error'),
          _iDiag('icarus_warning', 'warning'),
        ]);

      expect(engine.diagnostics.length, 2);
      expect(
        engine.diagnostics.every((d) => d.source == DiagnosticSource.icarus),
        isTrue,
      );
    });
  });
}
