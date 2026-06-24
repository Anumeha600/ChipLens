import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/session/session.dart';
import 'package:chiplens_lite/models/workflow/workflow.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _t0 = DateTime(2026, 1, 15, 10, 0, 0);
final _t1 = DateTime(2026, 1, 15, 10, 5, 0);

final _meta =
    SessionMetadata(id: 'session_001', createdAt: _t0, updatedAt: _t1);

const _rtl = 'module counter(input clk, output [3:0] q); endmodule';

const _wfSummary = WorkflowSummary(
  totalSteps: 3,
  completedSteps: 0,
  failedSteps: 0,
  skippedSteps: 0,
);

const _workflow = VerificationWorkflow(
  sessionId: 'session_001',
  steps: [
    WorkflowStep(
      stage: WorkflowStage.verification,
      status: WorkflowStatus.pending,
    ),
    WorkflowStep(
      stage: WorkflowStage.coverage,
      status: WorkflowStatus.pending,
    ),
    WorkflowStep(
      stage: WorkflowStage.diagnostics,
      status: WorkflowStatus.pending,
    ),
  ],
  summary: _wfSummary,
);

VerificationSession _session({VerificationWorkflow? workflow}) =>
    VerificationSession(
      metadata: _meta,
      status: SessionStatus.created,
      rtlSource: _rtl,
      workflow: workflow,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Backward compatibility — existing session tests must be unaffected
  // ──────────────────────────────────────────────────────────────────────────

  group('VerificationSession — backward compatibility', () {
    test('workflow defaults to null', () {
      expect(_session().workflow, isNull);
    });

    test('session still constructs without workflow field', () {
      final s = VerificationSession(
        metadata: _meta,
        status: SessionStatus.created,
        rtlSource: _rtl,
      );
      expect(s.workflow, isNull);
      expect(s.status, SessionStatus.created);
    });

    test('equality unaffected when both sides have null workflow', () {
      expect(_session(), _session());
    });

    test('hashCode unaffected when both sides have null workflow', () {
      expect(_session().hashCode, _session().hashCode);
    });

    test('copyWith(status:) still works without touching workflow', () {
      final ready = _session().copyWith(status: SessionStatus.ready);
      expect(ready.status, SessionStatus.ready);
      expect(ready.workflow, isNull);
    });

    test('copyWith(clearSummary:) still works', () {
      final s = VerificationSession(
        metadata: _meta,
        status: SessionStatus.completed,
        rtlSource: _rtl,
        summary: const SessionSummary(
          rtlModules: 1,
          diagnosticCount: 0,
          repairCount: 0,
          coveragePercent: 100.0,
        ),
      );
      expect(s.copyWith(clearSummary: true).summary, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Workflow field operations
  // ──────────────────────────────────────────────────────────────────────────

  group('VerificationSession — workflow field', () {
    test('workflow is stored when provided', () {
      expect(_session(workflow: _workflow).workflow, _workflow);
    });

    test('copyWith(workflow:) attaches workflow', () {
      final updated = _session().copyWith(workflow: _workflow);
      expect(updated.workflow, _workflow);
    });

    test('copyWith(workflow:) preserves other fields', () {
      final updated = _session().copyWith(workflow: _workflow);
      expect(updated.metadata, _meta);
      expect(updated.status, SessionStatus.created);
      expect(updated.rtlSource, _rtl);
    });

    test('copyWith preserves existing workflow when not overridden', () {
      final withWf = _session(workflow: _workflow);
      final advanced = withWf.copyWith(status: SessionStatus.running);
      expect(advanced.workflow, _workflow);
    });

    test('copyWith(clearWorkflow: true) removes workflow', () {
      final withWf = _session(workflow: _workflow);
      expect(withWf.copyWith(clearWorkflow: true).workflow, isNull);
    });

    test('copyWith(clearWorkflow: true) on null workflow stays null', () {
      expect(_session().copyWith(clearWorkflow: true).workflow, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Equality with workflow
  // ──────────────────────────────────────────────────────────────────────────

  group('VerificationSession — equality with workflow', () {
    test('same workflow → equal', () {
      expect(_session(workflow: _workflow), _session(workflow: _workflow));
    });

    test('with workflow != without workflow', () {
      expect(_session(workflow: _workflow), isNot(_session()));
    });

    test('different workflow sessionId → not equal', () {
      const wfB = VerificationWorkflow(
        sessionId: 'session_002',
        steps: [],
        summary: _wfSummary,
      );
      expect(
        _session(workflow: _workflow),
        isNot(_session(workflow: wfB)),
      );
    });

    test('hashCode differs when workflow differs', () {
      expect(
        _session().hashCode,
        isNot(_session(workflow: _workflow).hashCode),
      );
    });

    test('hashCode consistent with workflow attached', () {
      expect(
        _session(workflow: _workflow).hashCode,
        _session(workflow: _workflow).hashCode,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Integration: session + workflow + sessionId consistency
  // ──────────────────────────────────────────────────────────────────────────

  group('VerificationSession + VerificationWorkflow — integration', () {
    test('workflow.sessionId can match session.metadata.id', () {
      final s = _session(workflow: _workflow);
      expect(s.workflow!.sessionId, s.metadata.id);
    });

    test('full lifecycle: session advances while workflow is preserved', () {
      var s = _session(workflow: _workflow);
      s = s.copyWith(status: SessionStatus.ready);
      s = s.copyWith(status: SessionStatus.running);
      s = s.copyWith(status: SessionStatus.completed);
      expect(s.workflow, _workflow);
      expect(s.status, SessionStatus.completed);
    });

    test('workflow steps are accessible through session', () {
      final s = _session(workflow: _workflow);
      expect(s.workflow!.steps.length, 3);
    });

    test('workflow summary is accessible through session', () {
      final s = _session(workflow: _workflow);
      expect(s.workflow!.summary.totalSteps, 3);
    });
  });
}
