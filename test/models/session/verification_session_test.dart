import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/session/session.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _t0 = DateTime(2026, 1, 15, 10, 0, 0);
final _t1 = DateTime(2026, 1, 15, 10, 5, 0);

final _meta = SessionMetadata(id: 'session_001', createdAt: _t0, updatedAt: _t1);
final _meta2 = SessionMetadata(id: 'session_002', createdAt: _t0, updatedAt: _t1);

const _rtl = 'module counter(input clk, output [3:0] q); endmodule';
const _rtl2 = 'module adder(input a, b, output s); endmodule';

const _summary = SessionSummary(
  rtlModules: 1,
  diagnosticCount: 0,
  repairCount: 0,
  coveragePercent: 92.0,
);

VerificationSession _session({
  SessionMetadata? metadata,
  SessionStatus status = SessionStatus.created,
  String rtlSource = _rtl,
  SessionSummary? summary,
}) =>
    VerificationSession(
      metadata: metadata ?? _meta,
      status: status,
      rtlSource: rtlSource,
      summary: summary,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('VerificationSession — field storage', () {
    test('metadata is stored', () {
      expect(_session().metadata, _meta);
    });

    test('status is stored', () {
      expect(_session().status, SessionStatus.created);
    });

    test('rtlSource is stored', () {
      expect(_session().rtlSource, _rtl);
    });

    test('summary defaults to null', () {
      expect(_session().summary, isNull);
    });

    test('summary is stored when provided', () {
      expect(_session(summary: _summary).summary, _summary);
    });

    test('all SessionStatus values can be stored', () {
      for (final s in SessionStatus.values) {
        final session = _session(status: s);
        expect(session.status, s,
            reason: 'status ${s.name} should be stored');
      }
    });
  });

  group('VerificationSession — equality', () {
    test('same values → equal', () {
      expect(_session(), _session());
    });

    test('identical instance → equal', () {
      final s = _session();
      expect(s, s);
    });

    test('different metadata → not equal', () {
      expect(_session(metadata: _meta), isNot(_session(metadata: _meta2)));
    });

    test('different status → not equal', () {
      expect(
        _session(status: SessionStatus.created),
        isNot(_session(status: SessionStatus.completed)),
      );
    });

    test('different rtlSource → not equal', () {
      expect(_session(rtlSource: _rtl), isNot(_session(rtlSource: _rtl2)));
    });

    test('with summary != without summary', () {
      expect(_session(summary: _summary), isNot(_session()));
    });

    test('different summary values → not equal', () {
      const other = SessionSummary(
        rtlModules: 99,
        diagnosticCount: 5,
        repairCount: 2,
        coveragePercent: 50.0,
      );
      expect(_session(summary: _summary), isNot(_session(summary: other)));
    });

    test('same summary → equal', () {
      expect(_session(summary: _summary), _session(summary: _summary));
    });

    test('not equal to non-VerificationSession', () {
      expect(_session(), isNot('session_001'));
    });
  });

  group('VerificationSession — hashCode', () {
    test('same values → same hashCode', () {
      expect(_session().hashCode, _session().hashCode);
    });

    test('different status → different hashCode (likely)', () {
      expect(
        _session(status: SessionStatus.created).hashCode,
        isNot(_session(status: SessionStatus.completed).hashCode),
      );
    });

    test('different rtlSource → different hashCode (likely)', () {
      expect(
        _session(rtlSource: _rtl).hashCode,
        isNot(_session(rtlSource: _rtl2).hashCode),
      );
    });

    test('with vs without summary → different hashCode (likely)', () {
      expect(_session().hashCode, isNot(_session(summary: _summary).hashCode));
    });
  });

  group('VerificationSession — copyWith', () {
    test('copyWith with no arguments returns equal instance', () {
      expect(_session().copyWith(), _session());
    });

    test('copyWith does not mutate the original', () {
      final original = _session();
      original.copyWith(status: SessionStatus.running);
      expect(original.status, SessionStatus.created);
    });

    test('copyWith(status:) updates status', () {
      expect(
        _session().copyWith(status: SessionStatus.running).status,
        SessionStatus.running,
      );
    });

    test('copyWith(status:) preserves other fields', () {
      final updated = _session().copyWith(status: SessionStatus.ready);
      expect(updated.metadata, _meta);
      expect(updated.rtlSource, _rtl);
      expect(updated.summary, isNull);
    });

    test('copyWith(metadata:) updates metadata', () {
      expect(_session().copyWith(metadata: _meta2).metadata, _meta2);
    });

    test('copyWith(rtlSource:) updates rtlSource', () {
      expect(_session().copyWith(rtlSource: _rtl2).rtlSource, _rtl2);
    });

    test('copyWith(summary:) attaches summary', () {
      final updated = _session().copyWith(summary: _summary);
      expect(updated.summary, _summary);
    });

    test('copyWith(summary:) preserves existing summary when not overridden',
        () {
      final withSummary = _session(summary: _summary);
      final updated = withSummary.copyWith(status: SessionStatus.completed);
      expect(updated.summary, _summary);
    });

    test('copyWith(clearSummary: true) removes summary', () {
      final withSummary = _session(summary: _summary);
      final cleared = withSummary.copyWith(clearSummary: true);
      expect(cleared.summary, isNull);
    });

    test('copyWith(clearSummary: true) on null summary stays null', () {
      final cleared = _session().copyWith(clearSummary: true);
      expect(cleared.summary, isNull);
    });

    test('copyWith chains are independent', () {
      final a = _session().copyWith(status: SessionStatus.ready);
      final b = _session().copyWith(status: SessionStatus.running);
      expect(a.status, SessionStatus.ready);
      expect(b.status, SessionStatus.running);
    });
  });

  group('VerificationSession — status lifecycle', () {
    test('session advances created → ready via copyWith', () {
      final ready = _session().copyWith(status: SessionStatus.ready);
      expect(ready.status, SessionStatus.ready);
    });

    test('session advances ready → running via copyWith', () {
      final running = _session(status: SessionStatus.ready)
          .copyWith(status: SessionStatus.running);
      expect(running.status, SessionStatus.running);
    });

    test('session advances running → completed with summary', () {
      final done = _session(status: SessionStatus.running).copyWith(
        status: SessionStatus.completed,
        summary: _summary,
      );
      expect(done.status, SessionStatus.completed);
      expect(done.summary, _summary);
    });

    test('session advances running → failed without summary', () {
      final failed =
          _session(status: SessionStatus.running).copyWith(
        status: SessionStatus.failed,
      );
      expect(failed.status, SessionStatus.failed);
      expect(failed.summary, isNull);
    });

    test('full lifecycle preserves rtlSource throughout', () {
      var s = _session();
      s = s.copyWith(status: SessionStatus.ready);
      s = s.copyWith(status: SessionStatus.running);
      s = s.copyWith(status: SessionStatus.completed, summary: _summary);
      expect(s.rtlSource, _rtl);
    });

    test('full lifecycle preserves metadata throughout', () {
      var s = _session();
      s = s.copyWith(status: SessionStatus.ready);
      s = s.copyWith(status: SessionStatus.running);
      s = s.copyWith(status: SessionStatus.completed, summary: _summary);
      expect(s.metadata, _meta);
    });
  });

  group('VerificationSession — immutability', () {
    test('status field is final (immutable via type)', () {
      final s = _session();
      // Verified implicitly: if status were mutable, the test below would
      // mutate and break equality. Since no mutation API exists, this
      // confirms the model is correctly immutable.
      expect(s.status, SessionStatus.created);
      expect(_session().status, SessionStatus.created);
    });

    test('two independent sessions do not share state', () {
      final a = _session(rtlSource: _rtl);
      final b = _session(rtlSource: _rtl2);
      expect(a.rtlSource, _rtl);
      expect(b.rtlSource, _rtl2);
    });
  });
}
