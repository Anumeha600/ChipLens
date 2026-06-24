import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/session/session_status.dart';

void main() {
  group('SessionStatus —', () {
    // ── Value existence ──────────────────────────────────────────────────────

    test('created value exists', () {
      expect(SessionStatus.created, isNotNull);
    });

    test('ready value exists', () {
      expect(SessionStatus.ready, isNotNull);
    });

    test('running value exists', () {
      expect(SessionStatus.running, isNotNull);
    });

    test('completed value exists', () {
      expect(SessionStatus.completed, isNotNull);
    });

    test('failed value exists', () {
      expect(SessionStatus.failed, isNotNull);
    });

    // ── Enum metadata ────────────────────────────────────────────────────────

    test('has exactly 5 values', () {
      expect(SessionStatus.values.length, 5);
    });

    test('values are in lifecycle order', () {
      expect(SessionStatus.values, [
        SessionStatus.created,
        SessionStatus.ready,
        SessionStatus.running,
        SessionStatus.completed,
        SessionStatus.failed,
      ]);
    });

    test('name: created', () => expect(SessionStatus.created.name, 'created'));
    test('name: ready',   () => expect(SessionStatus.ready.name,   'ready'));
    test('name: running', () => expect(SessionStatus.running.name, 'running'));
    test('name: completed', () =>
        expect(SessionStatus.completed.name, 'completed'));
    test('name: failed', () => expect(SessionStatus.failed.name, 'failed'));

    // ── Identity / equality ──────────────────────────────────────────────────

    test('each value equals itself', () {
      for (final v in SessionStatus.values) {
        expect(v, v, reason: '${v.name} should equal itself');
      }
    });

    test('created != ready', () {
      expect(SessionStatus.created, isNot(SessionStatus.ready));
    });

    test('running != completed', () {
      expect(SessionStatus.running, isNot(SessionStatus.completed));
    });

    test('completed != failed', () {
      expect(SessionStatus.completed, isNot(SessionStatus.failed));
    });

    test('no two distinct values are equal', () {
      final values = SessionStatus.values;
      for (var i = 0; i < values.length; i++) {
        for (var j = 0; j < values.length; j++) {
          if (i != j) {
            expect(values[i], isNot(values[j]),
                reason:
                    '${values[i].name} should not equal ${values[j].name}');
          }
        }
      }
    });

    // ── Parse ────────────────────────────────────────────────────────────────

    test('can be looked up by name from values list', () {
      expect(
        SessionStatus.values.firstWhere((v) => v.name == 'running'),
        SessionStatus.running,
      );
    });
  });
}
