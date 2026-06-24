import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/models/session/session_metadata.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _t0 = DateTime(2026, 1, 15, 10, 0, 0);
final _t1 = DateTime(2026, 1, 15, 10, 5, 0);
final _t2 = DateTime(2026, 1, 15, 11, 0, 0);

SessionMetadata _meta({
  String id = 'session_001',
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    SessionMetadata(
      id: id,
      createdAt: createdAt ?? _t0,
      updatedAt: updatedAt ?? _t1,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('SessionMetadata — field storage', () {
    test('id is stored', () {
      expect(_meta().id, 'session_001');
    });

    test('createdAt is stored', () {
      expect(_meta().createdAt, _t0);
    });

    test('updatedAt is stored', () {
      expect(_meta().updatedAt, _t1);
    });

    test('all fields survive round-trip construction', () {
      final m = SessionMetadata(id: 'abc', createdAt: _t0, updatedAt: _t2);
      expect(m.id, 'abc');
      expect(m.createdAt, _t0);
      expect(m.updatedAt, _t2);
    });
  });

  group('SessionMetadata — equality', () {
    test('same values → equal', () {
      final a = _meta();
      final b = _meta();
      expect(a, b);
    });

    test('identical instance → equal', () {
      final m = _meta();
      expect(m, m);
    });

    test('different id → not equal', () {
      expect(_meta(id: 'a'), isNot(_meta(id: 'b')));
    });

    test('different createdAt → not equal', () {
      expect(_meta(createdAt: _t0), isNot(_meta(createdAt: _t2)));
    });

    test('different updatedAt → not equal', () {
      expect(_meta(updatedAt: _t1), isNot(_meta(updatedAt: _t2)));
    });

    test('not equal to non-SessionMetadata', () {
      expect(_meta(), isNot('session_001'));
    });
  });

  group('SessionMetadata — hashCode', () {
    test('same values → same hashCode', () {
      expect(_meta().hashCode, _meta().hashCode);
    });

    test('different id → different hashCode (likely)', () {
      expect(_meta(id: 'a').hashCode, isNot(_meta(id: 'b').hashCode));
    });

    test('different createdAt → different hashCode (likely)', () {
      expect(
        _meta(createdAt: _t0).hashCode,
        isNot(_meta(createdAt: _t2).hashCode),
      );
    });
  });

  group('SessionMetadata — copyWith', () {
    test('copyWith with no arguments returns equal instance', () {
      final original = _meta();
      expect(original.copyWith(), original);
    });

    test('copyWith does not mutate the original', () {
      final original = _meta();
      original.copyWith(id: 'changed');
      expect(original.id, 'session_001');
    });

    test('copyWith(id:) updates id', () {
      expect(_meta().copyWith(id: 'new_id').id, 'new_id');
    });

    test('copyWith(id:) preserves other fields', () {
      final updated = _meta().copyWith(id: 'new_id');
      expect(updated.createdAt, _t0);
      expect(updated.updatedAt, _t1);
    });

    test('copyWith(createdAt:) updates createdAt', () {
      expect(_meta().copyWith(createdAt: _t2).createdAt, _t2);
    });

    test('copyWith(updatedAt:) updates updatedAt', () {
      expect(_meta().copyWith(updatedAt: _t2).updatedAt, _t2);
    });

    test('copyWith chains are independent', () {
      final a = _meta().copyWith(id: 'a');
      final b = _meta().copyWith(id: 'b');
      expect(a.id, 'a');
      expect(b.id, 'b');
    });
  });
}
