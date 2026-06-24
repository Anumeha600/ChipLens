import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/workflow/workflow_stage.dart';

void main() {
  group('WorkflowStage —', () {
    // ── Value existence ──────────────────────────────────────────────────────

    test('designIntelligence exists',
        () => expect(WorkflowStage.designIntelligence, isNotNull));
    test('propertySynthesis exists',
        () => expect(WorkflowStage.propertySynthesis, isNotNull));
    test('propertyRanking exists',
        () => expect(WorkflowStage.propertyRanking, isNotNull));
    test('propertyEmission exists',
        () => expect(WorkflowStage.propertyEmission, isNotNull));
    test('verification exists',
        () => expect(WorkflowStage.verification, isNotNull));
    test('coverage exists',
        () => expect(WorkflowStage.coverage, isNotNull));
    test('diagnostics exists',
        () => expect(WorkflowStage.diagnostics, isNotNull));
    test('repair exists',
        () => expect(WorkflowStage.repair, isNotNull));

    // ── Count ────────────────────────────────────────────────────────────────

    test('has exactly 8 values', () {
      expect(WorkflowStage.values.length, 8);
    });

    // ── Names ────────────────────────────────────────────────────────────────

    test('name: designIntelligence',
        () => expect(WorkflowStage.designIntelligence.name, 'designIntelligence'));
    test('name: propertySynthesis',
        () => expect(WorkflowStage.propertySynthesis.name, 'propertySynthesis'));
    test('name: propertyRanking',
        () => expect(WorkflowStage.propertyRanking.name, 'propertyRanking'));
    test('name: propertyEmission',
        () => expect(WorkflowStage.propertyEmission.name, 'propertyEmission'));
    test('name: verification',
        () => expect(WorkflowStage.verification.name, 'verification'));
    test('name: coverage',
        () => expect(WorkflowStage.coverage.name, 'coverage'));
    test('name: diagnostics',
        () => expect(WorkflowStage.diagnostics.name, 'diagnostics'));
    test('name: repair',
        () => expect(WorkflowStage.repair.name, 'repair'));

    // ── Identity / equality ──────────────────────────────────────────────────

    test('each value equals itself', () {
      for (final v in WorkflowStage.values) {
        expect(v, v, reason: '${v.name} should equal itself');
      }
    });

    test('no two distinct values are equal', () {
      final values = WorkflowStage.values;
      for (var i = 0; i < values.length; i++) {
        for (var j = 0; j < values.length; j++) {
          if (i != j) {
            expect(values[i], isNot(values[j]),
                reason: '${values[i].name} should not equal ${values[j].name}');
          }
        }
      }
    });

    // ── Lifecycle ordering ───────────────────────────────────────────────────

    test('values are in declared lifecycle order', () {
      expect(WorkflowStage.values, [
        WorkflowStage.designIntelligence,
        WorkflowStage.propertySynthesis,
        WorkflowStage.propertyRanking,
        WorkflowStage.propertyEmission,
        WorkflowStage.verification,
        WorkflowStage.coverage,
        WorkflowStage.diagnostics,
        WorkflowStage.repair,
      ]);
    });

    test('can be looked up by name', () {
      expect(
        WorkflowStage.values.firstWhere((v) => v.name == 'verification'),
        WorkflowStage.verification,
      );
    });
  });
}
