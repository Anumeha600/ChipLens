import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/session/session.dart';
import 'package:chiplens_lite/models/workflow/workflow.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

final _t0 = DateTime(2026, 6, 1, 10, 0, 0);
final _t1 = DateTime(2026, 6, 1, 10, 5, 0);
final _t2 = DateTime(2026, 6, 1, 10, 10, 0);

final _meta = SessionMetadata(
  id: 'session_integration_001',
  createdAt: _t0,
  updatedAt: _t1,
);

const _counterRtl = '''
module counter (
  input wire clk,
  input wire rst_n,
  input wire en,
  output reg [3:0] count
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) count <= 4'd0;
    else if (en) count <= count + 1;
endmodule
''';

const _wfSummaryInitial = WorkflowSummary(
  totalSteps: 3,
  completedSteps: 0,
  failedSteps: 0,
  skippedSteps: 0,
);

const _wfSummaryComplete = WorkflowSummary(
  totalSteps: 3,
  completedSteps: 3,
  failedSteps: 0,
  skippedSteps: 0,
);

VerificationWorkflow _initialWorkflow() => VerificationWorkflow(
      sessionId: 'session_integration_001',
      steps: const [
        WorkflowStep(stage: WorkflowStage.verification, status: WorkflowStatus.pending),
        WorkflowStep(stage: WorkflowStage.coverage,     status: WorkflowStatus.pending),
        WorkflowStep(stage: WorkflowStage.diagnostics,  status: WorkflowStatus.pending),
      ],
      summary: _wfSummaryInitial,
    );

VerificationSession _baseSession() => VerificationSession(
      metadata: _meta,
      status: SessionStatus.created,
      rtlSource: _counterRtl,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Session lifecycle ─────────────────────────────────────────────────────────

  group('Session lifecycle', () {
    test('session starts with created status', () {
      expect(_baseSession().status, SessionStatus.created);
    });

    test('session advances from created to ready', () {
      final ready = _baseSession().copyWith(status: SessionStatus.ready);
      expect(ready.status, SessionStatus.ready);
    });

    test('session advances from ready to running', () {
      var s = _baseSession();
      s = s.copyWith(status: SessionStatus.ready);
      s = s.copyWith(status: SessionStatus.running);
      expect(s.status, SessionStatus.running);
    });

    test('session advances from running to completed', () {
      var s = _baseSession();
      s = s.copyWith(status: SessionStatus.running);
      s = s.copyWith(status: SessionStatus.completed);
      expect(s.status, SessionStatus.completed);
    });

    test('session can transition to failed from any state', () {
      final failed = _baseSession().copyWith(status: SessionStatus.failed);
      expect(failed.status, SessionStatus.failed);
    });

    test('rtlSource is preserved through all status transitions', () {
      var s = _baseSession();
      s = s.copyWith(status: SessionStatus.ready);
      s = s.copyWith(status: SessionStatus.running);
      s = s.copyWith(status: SessionStatus.completed);
      expect(s.rtlSource, _counterRtl);
    });

    test('metadata is preserved through status transitions', () {
      var s = _baseSession();
      s = s.copyWith(status: SessionStatus.running);
      expect(s.metadata.id, 'session_integration_001');
    });
  });

  // ── Session + Workflow integration ───────────────────────────────────────────

  group('Session + Workflow integration', () {
    test('session accepts workflow attachment', () {
      final s = _baseSession().copyWith(workflow: _initialWorkflow());
      expect(s.workflow, isNotNull);
    });

    test('workflow.sessionId matches session.metadata.id', () {
      final s = _baseSession().copyWith(workflow: _initialWorkflow());
      expect(s.workflow!.sessionId, s.metadata.id);
    });

    test('session preserves workflow through all status transitions', () {
      var s = _baseSession().copyWith(workflow: _initialWorkflow());
      s = s.copyWith(status: SessionStatus.ready);
      s = s.copyWith(status: SessionStatus.running);
      s = s.copyWith(status: SessionStatus.completed);
      expect(s.workflow, isNotNull);
      expect(s.status, SessionStatus.completed);
    });

    test('workflow can be cleared with clearWorkflow flag', () {
      var s = _baseSession().copyWith(workflow: _initialWorkflow());
      s = s.copyWith(clearWorkflow: true);
      expect(s.workflow, isNull);
    });

    test('workflow steps are accessible through session', () {
      final s = _baseSession().copyWith(workflow: _initialWorkflow());
      expect(s.workflow!.steps.length, 3);
    });

    test('workflow summary is accessible through session', () {
      final s = _baseSession().copyWith(workflow: _initialWorkflow());
      expect(s.workflow!.summary.totalSteps, 3);
    });

    test('replacing workflow replaces the old one', () {
      var s = _baseSession().copyWith(workflow: _initialWorkflow());
      final newWorkflow = VerificationWorkflow(
        sessionId: 'session_integration_001',
        steps: const [
          WorkflowStep(stage: WorkflowStage.repair, status: WorkflowStatus.pending),
        ],
        summary: const WorkflowSummary(
          totalSteps: 1, completedSteps: 0, failedSteps: 0, skippedSteps: 0,
        ),
      );
      s = s.copyWith(workflow: newWorkflow);
      expect(s.workflow!.steps.length, 1);
      expect(s.workflow!.steps[0].stage, WorkflowStage.repair);
    });
  });

  // ── Workflow step progression ────────────────────────────────────────────────

  group('Workflow step progression', () {
    test('initial workflow has all steps pending', () {
      final wf = _initialWorkflow();
      expect(
        wf.steps.every((s) => s.status == WorkflowStatus.pending),
        isTrue,
      );
    });

    test('first step can be advanced to running', () {
      final wf = _initialWorkflow();
      final updated = wf.copyWith(steps: [
        wf.steps[0].copyWith(status: WorkflowStatus.running, startedAt: _t1),
        ...wf.steps.skip(1),
      ]);
      expect(updated.steps[0].status, WorkflowStatus.running);
      expect(updated.steps[0].startedAt, _t1);
    });

    test('completing first step preserves remaining steps as pending', () {
      final wf = _initialWorkflow();
      final updated = wf.copyWith(steps: [
        wf.steps[0].copyWith(
            status: WorkflowStatus.completed,
            startedAt: _t1,
            completedAt: _t2),
        ...wf.steps.skip(1),
      ]);
      expect(updated.steps[0].status, WorkflowStatus.completed);
      expect(updated.steps[1].status, WorkflowStatus.pending);
      expect(updated.steps[2].status, WorkflowStatus.pending);
    });

    test('all steps can be completed and summary updated', () {
      final wf = _initialWorkflow();
      final completedSteps = wf.steps
          .map((s) => s.copyWith(
                status: WorkflowStatus.completed,
                startedAt: _t1,
                completedAt: _t2,
              ))
          .toList();
      final completedWf =
          wf.copyWith(steps: completedSteps, summary: _wfSummaryComplete);
      expect(completedWf.summary.completedSteps, 3);
      expect(completedWf.summary.failedSteps, 0);
      expect(completedWf.steps.every((s) => s.status == WorkflowStatus.completed),
          isTrue);
    });

    test('step can be skipped', () {
      final wf = _initialWorkflow();
      final updated = wf.copyWith(steps: [
        wf.steps[0],
        wf.steps[1].copyWith(status: WorkflowStatus.skipped),
        wf.steps[2],
      ]);
      expect(updated.steps[1].status, WorkflowStatus.skipped);
    });
  });

  // ── Session summary integration ──────────────────────────────────────────────

  group('Session summary integration', () {
    test('session can have summary attached at completion', () {
      const summary = SessionSummary(
        rtlModules: 1,
        diagnosticCount: 2,
        repairCount: 1,
        coveragePercent: 87.5,
      );
      final s = _baseSession().copyWith(summary: summary);
      expect(s.summary, isNotNull);
      expect(s.summary!.rtlModules, 1);
      expect(s.summary!.coveragePercent, 87.5);
    });

    test('session summary and workflow can coexist', () {
      const summary = SessionSummary(
        rtlModules: 1,
        diagnosticCount: 0,
        repairCount: 0,
        coveragePercent: 97.0,
      );
      var s = _baseSession().copyWith(workflow: _initialWorkflow());
      s = s.copyWith(summary: summary);
      expect(s.summary, isNotNull);
      expect(s.workflow, isNotNull);
    });

    test('clearSummary removes summary while preserving workflow', () {
      const summary = SessionSummary(
        rtlModules: 1,
        diagnosticCount: 0,
        repairCount: 0,
        coveragePercent: 97.0,
      );
      var s = _baseSession()
          .copyWith(workflow: _initialWorkflow())
          .copyWith(summary: summary);
      s = s.copyWith(clearSummary: true);
      expect(s.summary, isNull);
      expect(s.workflow, isNotNull);
    });
  });

  // ── Equality and hashing ─────────────────────────────────────────────────────

  group('Session equality and hashing', () {
    test('two sessions with same data are equal', () {
      final s1 = VerificationSession(
        metadata: _meta,
        status: SessionStatus.created,
        rtlSource: _counterRtl,
        workflow: _initialWorkflow(),
      );
      final s2 = VerificationSession(
        metadata: _meta,
        status: SessionStatus.created,
        rtlSource: _counterRtl,
        workflow: _initialWorkflow(),
      );
      expect(s1, s2);
    });

    test('hashCode is consistent across identical sessions', () {
      final s1 = _baseSession().copyWith(workflow: _initialWorkflow());
      final s2 = _baseSession().copyWith(workflow: _initialWorkflow());
      expect(s1.hashCode, s2.hashCode);
    });

    test('sessions with different status are not equal', () {
      final s1 = _baseSession();
      final s2 = _baseSession().copyWith(status: SessionStatus.completed);
      expect(s1, isNot(s2));
    });

    test('session with workflow != session without workflow', () {
      final s1 = _baseSession();
      final s2 = _baseSession().copyWith(workflow: _initialWorkflow());
      expect(s1, isNot(s2));
    });
  });

  // ── Full lifecycle integration ───────────────────────────────────────────────

  group('Full lifecycle integration', () {
    test('counter session completes with workflow and summary', () {
      final sessionMeta = SessionMetadata(
        id: 'counter_session',
        createdAt: _t0,
        updatedAt: _t0,
      );

      var session = VerificationSession(
        metadata: sessionMeta,
        status: SessionStatus.created,
        rtlSource: _counterRtl,
      );

      // Attach workflow
      final workflow = VerificationWorkflow(
        sessionId: 'counter_session',
        steps: const [
          WorkflowStep(stage: WorkflowStage.verification, status: WorkflowStatus.pending),
          WorkflowStep(stage: WorkflowStage.diagnostics,  status: WorkflowStatus.pending),
        ],
        summary: const WorkflowSummary(
          totalSteps: 2, completedSteps: 0, failedSteps: 0, skippedSteps: 0,
        ),
      );
      session = session.copyWith(workflow: workflow);
      expect(session.status, SessionStatus.created);

      // Start session
      session = session.copyWith(status: SessionStatus.running);

      // Complete verification step
      session = session.copyWith(
        workflow: session.workflow!.copyWith(steps: [
          workflow.steps[0].copyWith(
            status: WorkflowStatus.completed,
            startedAt: _t1,
            completedAt: _t2,
          ),
          workflow.steps[1].copyWith(status: WorkflowStatus.running, startedAt: _t2),
        ]),
      );
      expect(session.workflow!.steps[0].status, WorkflowStatus.completed);

      // Complete session
      session = session.copyWith(
        status: SessionStatus.completed,
        summary: const SessionSummary(
          rtlModules: 1,
          diagnosticCount: 0,
          repairCount: 0,
          coveragePercent: 100.0,
        ),
      );

      expect(session.status, SessionStatus.completed);
      expect(session.workflow, isNotNull);
      expect(session.workflow!.steps[0].status, WorkflowStatus.completed);
      expect(session.summary!.coveragePercent, 100.0);
      expect(session.rtlSource, _counterRtl);
    });

    test('failed session retains rtlSource and workflow for post-mortem', () {
      var session = _baseSession().copyWith(workflow: _initialWorkflow());
      session = session.copyWith(status: SessionStatus.running);
      session = session.copyWith(status: SessionStatus.failed);

      expect(session.status, SessionStatus.failed);
      expect(session.rtlSource, _counterRtl);
      expect(session.workflow, isNotNull);
    });
  });
}
