import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/formal/formal.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FormalProperty _prop({
  String id              = 'p1',
  String name            = 'Safety check',
  String description     = 'Counter must not overflow',
  FormalPropertyType type = FormalPropertyType.assertion,
  String expression      = 'counter <= 255',
  bool enabled           = true,
  String severity        = 'error',
  FormalPropertyLocation? location,
  Map<String, dynamic> metadata = const {},
}) =>
    FormalProperty(
      id:             id,
      name:           name,
      description:    description,
      propertyType:   type,
      expression:     expression,
      enabled:        enabled,
      severity:       severity,
      sourceLocation: location,
      metadata:       metadata,
    );

FormalPropertySet _populatedSet() {
  final set = FormalPropertySet();
  set.add(_prop(id: 'p1', type: FormalPropertyType.assertion,  name: 'No overflow'));
  set.add(_prop(id: 'p2', type: FormalPropertyType.assumption, name: 'Valid input', enabled: false));
  set.add(_prop(id: 'p3', type: FormalPropertyType.cover,      name: 'Reachable state'));
  set.add(_prop(id: 'p4', type: FormalPropertyType.invariant,  name: 'Invariant holds'));
  return set;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {

  // ── FormalPropertyType ─────────────────────────────────────────────────────

  group('FormalPropertyType', () {
    test('all six variants exist', () {
      expect(FormalPropertyType.values.length, 6);
      expect(FormalPropertyType.values, containsAll([
        FormalPropertyType.assertion,
        FormalPropertyType.assumption,
        FormalPropertyType.cover,
        FormalPropertyType.invariant,
        FormalPropertyType.safety,
        FormalPropertyType.liveness,
      ]));
    });

    test('names are stable serialization keys', () {
      expect(FormalPropertyType.assertion.name,  'assertion');
      expect(FormalPropertyType.assumption.name, 'assumption');
      expect(FormalPropertyType.cover.name,      'cover');
      expect(FormalPropertyType.invariant.name,  'invariant');
      expect(FormalPropertyType.safety.name,     'safety');
      expect(FormalPropertyType.liveness.name,   'liveness');
    });

    test('byName round-trips all variants', () {
      for (final t in FormalPropertyType.values) {
        expect(FormalPropertyType.values.byName(t.name), t);
      }
    });
  });

  // ── FormalPropertyLocation ─────────────────────────────────────────────────

  group('FormalPropertyLocation', () {
    test('minimal construction requires only file', () {
      const loc = FormalPropertyLocation(file: 'top.v');
      expect(loc.file,   'top.v');
      expect(loc.line,   isNull);
      expect(loc.column, isNull);
      expect(loc.module, isNull);
    });

    test('full construction stores all fields', () {
      const loc = FormalPropertyLocation(
        file: 'counter.v', line: 42, column: 5, module: 'counter',
      );
      expect(loc.file,   'counter.v');
      expect(loc.line,   42);
      expect(loc.column, 5);
      expect(loc.module, 'counter');
    });

    test('toJson omits null fields', () {
      const loc = FormalPropertyLocation(file: 'top.v', line: 10);
      final j = loc.toJson();
      expect(j.containsKey('file'),   isTrue);
      expect(j.containsKey('line'),   isTrue);
      expect(j.containsKey('column'), isFalse);
      expect(j.containsKey('module'), isFalse);
    });

    test('toJson / fromJson round-trip with full data', () {
      const loc = FormalPropertyLocation(
        file: 'alu.v', line: 7, column: 3, module: 'alu',
      );
      final restored = FormalPropertyLocation.fromJson(loc.toJson());
      expect(restored, loc);
    });

    test('fromJson with only file field', () {
      final loc = FormalPropertyLocation.fromJson({'file': 'fsm.v'});
      expect(loc.file,   'fsm.v');
      expect(loc.line,   isNull);
      expect(loc.column, isNull);
      expect(loc.module, isNull);
    });

    test('toString includes file and line', () {
      const loc = FormalPropertyLocation(file: 'top.v', line: 15);
      expect(loc.toString(), 'top.v:15');
    });

    test('toString with file only', () {
      const loc = FormalPropertyLocation(file: 'top.v');
      expect(loc.toString(), 'top.v');
    });

    test('equality holds for identical fields', () {
      const a = FormalPropertyLocation(file: 'x.v', line: 1, module: 'm');
      const b = FormalPropertyLocation(file: 'x.v', line: 1, module: 'm');
      expect(a, b);
    });

    test('inequality when any field differs', () {
      const base = FormalPropertyLocation(file: 'x.v', line: 1);
      expect(base == const FormalPropertyLocation(file: 'y.v', line: 1), isFalse);
      expect(base == const FormalPropertyLocation(file: 'x.v', line: 2), isFalse);
    });
  });

  // ── FormalProperty ─────────────────────────────────────────────────────────

  group('FormalProperty', () {
    test('required fields are stored', () {
      final p = _prop();
      expect(p.id,           'p1');
      expect(p.name,         'Safety check');
      expect(p.expression,   'counter <= 255');
      expect(p.propertyType, FormalPropertyType.assertion);
    });

    test('defaults: enabled=true, severity=error, description empty, no location', () {
      const p = FormalProperty(
        id: 'x', name: 'x', propertyType: FormalPropertyType.cover,
        expression: 'true',
      );
      expect(p.enabled,        isTrue);
      expect(p.severity,       'error');
      expect(p.description,    isEmpty);
      expect(p.sourceLocation, isNull);
      expect(p.metadata,       isEmpty);
    });

    test('all fields round-trip through toJson/fromJson', () {
      final p = _prop(
        location: const FormalPropertyLocation(file: 'top.v', line: 5),
        metadata: {'ai': true, 'confidence': 0.9},
      );
      final restored = FormalProperty.fromJson(p.toJson());
      expect(restored.id,                p.id);
      expect(restored.name,              p.name);
      expect(restored.description,       p.description);
      expect(restored.propertyType,      p.propertyType);
      expect(restored.severity,          p.severity);
      expect(restored.enabled,           p.enabled);
      expect(restored.expression,        p.expression);
      expect(restored.sourceLocation,    p.sourceLocation);
      expect(restored.metadata['ai'],    true);
      expect(restored.metadata['confidence'], 0.9);
    });

    test('toJson omits sourceLocation when null', () {
      final j = _prop().toJson();
      expect(j.containsKey('sourceLocation'), isFalse);
    });

    test('toJson omits metadata when empty', () {
      final j = _prop().toJson();
      expect(j.containsKey('metadata'), isFalse);
    });

    test('toJson includes sourceLocation when present', () {
      final p = _prop(
          location: const FormalPropertyLocation(file: 'f.v', line: 1));
      final j = p.toJson();
      expect(j.containsKey('sourceLocation'), isTrue);
      expect((j['sourceLocation'] as Map)['file'], 'f.v');
    });

    test('copyWith(enabled: false) produces disabled copy', () {
      final original = _prop(enabled: true);
      final disabled = original.copyWith(enabled: false);
      expect(original.enabled, isTrue);
      expect(disabled.enabled, isFalse);
      expect(disabled.id,      original.id);
      expect(disabled.name,    original.name);
    });

    test('copyWith only changes specified fields', () {
      final p = _prop(severity: 'warning');
      final q = p.copyWith(name: 'Renamed');
      expect(q.name,     'Renamed');
      expect(q.severity, 'warning');
      expect(q.id,       p.id);
    });

    test('toString contains id and type', () {
      final s = _prop(id: 'chk1').toString();
      expect(s, contains('chk1'));
      expect(s, contains('assertion'));
    });
  });

  // ── FormalPropertySet ──────────────────────────────────────────────────────

  group('FormalPropertySet', () {
    test('empty set has length 0', () {
      final set = FormalPropertySet();
      expect(set.isEmpty,   isTrue);
      expect(set.length,    0);
      expect(set.isNotEmpty, isFalse);
    });

    test('add increases length', () {
      final set = FormalPropertySet();
      set.add(_prop(id: 'a'));
      set.add(_prop(id: 'b'));
      expect(set.length, 2);
      expect(set.isNotEmpty, isTrue);
    });

    test('add duplicate id throws ArgumentError', () {
      final set = FormalPropertySet();
      set.add(_prop(id: 'dup'));
      expect(() => set.add(_prop(id: 'dup')), throwsArgumentError);
    });

    test('remove decreases length', () {
      final set = FormalPropertySet();
      set.add(_prop(id: 'r1'));
      set.add(_prop(id: 'r2'));
      set.remove('r1');
      expect(set.length, 1);
      expect(set.findById('r1'), isNull);
    });

    test('remove nonexistent id is a no-op', () {
      final set = FormalPropertySet();
      set.add(_prop(id: 'x'));
      expect(() => set.remove('missing'), returnsNormally);
      expect(set.length, 1);
    });

    test('findById returns matching property', () {
      final set = _populatedSet();
      final p = set.findById('p2');
      expect(p, isNotNull);
      expect(p!.name, 'Valid input');
    });

    test('findById returns null for unknown id', () {
      expect(_populatedSet().findById('nope'), isNull);
    });

    test('disable sets enabled=false for targeted property', () {
      final set = _populatedSet();
      expect(set.findById('p1')!.enabled, isTrue);
      set.disable('p1');
      expect(set.findById('p1')!.enabled, isFalse);
      expect(set.findById('p3')!.enabled, isTrue);
    });

    test('enable sets enabled=true for targeted property', () {
      final set = _populatedSet();
      expect(set.findById('p2')!.enabled, isFalse);
      set.enable('p2');
      expect(set.findById('p2')!.enabled, isTrue);
    });

    test('enable/disable on unknown id is a no-op', () {
      final set = _populatedSet();
      final before = set.length;
      expect(() => set.enable('ghost'),  returnsNormally);
      expect(() => set.disable('ghost'), returnsNormally);
      expect(set.length, before);
    });

    test('filter returns new set matching predicate', () {
      final set    = _populatedSet();
      final errors = set.filter((p) => p.severity == 'error');
      expect(errors.length, set.length);
    });

    test('filter does not mutate the original set', () {
      final set = _populatedSet();
      set.filter((p) => p.enabled);
      expect(set.length, 4);
    });

    test('byType returns only matching type', () {
      final set         = _populatedSet();
      final assumptions = set.byType(FormalPropertyType.assumption);
      expect(assumptions.length, 1);
      expect(assumptions.properties.first.id, 'p2');
    });

    test('enabledOnly returns only enabled properties', () {
      final set     = _populatedSet();
      final enabled = set.enabledOnly();
      expect(enabled.length, 3);
      expect(enabled.properties.every((p) => p.enabled), isTrue);
    });

    test('properties getter returns unmodifiable list', () {
      final set = _populatedSet();
      expect(
        () => (set.properties as dynamic).add(_prop(id: 'extra')),
        throwsUnsupportedError,
      );
    });

    test('constructor accepts initial list', () {
      final init = [_prop(id: 'i1'), _prop(id: 'i2')];
      final set  = FormalPropertySet(init);
      expect(set.length, 2);
    });
  });

  // ── FormalPropertySet serialization ────────────────────────────────────────

  group('FormalPropertySet serialization', () {
    test('empty set toJson produces empty properties list', () {
      final j = FormalPropertySet().toJson();
      expect(j['properties'], isA<List>());
      expect((j['properties'] as List).isEmpty, isTrue);
    });

    test('empty set round-trip via toJson/fromJson', () {
      final original = FormalPropertySet();
      final restored = FormalPropertySet.fromJson(original.toJson());
      expect(restored.isEmpty, isTrue);
    });

    test('populated set round-trip preserves all fields', () {
      final original = _populatedSet();
      final restored = FormalPropertySet.fromJson(original.toJson());

      expect(restored.length, original.length);
      for (var i = 0; i < original.length; i++) {
        final o = original.properties[i];
        final r = restored.properties[i];
        expect(r.id,           o.id);
        expect(r.name,         o.name);
        expect(r.propertyType, o.propertyType);
        expect(r.enabled,      o.enabled);
        expect(r.expression,   o.expression);
      }
    });

    test('disabled property survives round-trip with enabled=false', () {
      final set = FormalPropertySet([_prop(id: 'off', enabled: false)]);
      final restored = FormalPropertySet.fromJson(set.toJson());
      expect(restored.findById('off')!.enabled, isFalse);
    });

    test('property with location survives round-trip', () {
      final set = FormalPropertySet([
        _prop(
          id: 'loc',
          location: const FormalPropertyLocation(
              file: 'ram.v', line: 30, module: 'ram'),
        ),
      ]);
      final restored = FormalPropertySet.fromJson(set.toJson());
      final loc = restored.findById('loc')!.sourceLocation!;
      expect(loc.file,   'ram.v');
      expect(loc.line,   30);
      expect(loc.module, 'ram');
    });
  });

  // ── PropertySerializer ─────────────────────────────────────────────────────

  group('PropertySerializer', () {
    test('toJsonString produces a non-empty string', () {
      final s = PropertySerializer.toJsonString(_populatedSet());
      expect(s, isNotEmpty);
    });

    test('toJsonString output is valid JSON', () {
      final s   = PropertySerializer.toJsonString(_populatedSet());
      expect(() => jsonDecode(s), returnsNormally);
    });

    test('fromJsonString parses back to a set', () {
      final set       = _populatedSet();
      final jsonStr   = PropertySerializer.toJsonString(set);
      final restored  = PropertySerializer.fromJsonString(jsonStr);
      expect(restored.length, set.length);
    });

    test('toJsonString / fromJsonString round-trip preserves ids', () {
      final set      = _populatedSet();
      final restored = PropertySerializer.fromJsonString(
          PropertySerializer.toJsonString(set));
      final ids      = restored.properties.map((p) => p.id).toSet();
      expect(ids, {'p1', 'p2', 'p3', 'p4'});
    });

    test('toJson and toJsonString are consistent', () {
      final set       = _populatedSet();
      final viaMap    = jsonEncode(PropertySerializer.toJson(set));
      final viaString = PropertySerializer.toJsonString(set);
      expect(viaMap, viaString);
    });

    test('fromJson and fromJsonString are consistent', () {
      final json = PropertySerializer.toJson(_populatedSet());
      final fromMap =
          PropertySerializer.fromJson(json).properties.map((p) => p.id).toSet();
      final fromStr =
          PropertySerializer.fromJsonString(jsonEncode(json))
              .properties
              .map((p) => p.id)
              .toSet();
      expect(fromMap, fromStr);
    });

    test('fromJsonString throws FormatException on malformed JSON', () {
      expect(
        () => PropertySerializer.fromJsonString('{not valid json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('empty set survives PropertySerializer round-trip', () {
      final empty     = FormalPropertySet();
      final restored  = PropertySerializer.fromJsonString(
          PropertySerializer.toJsonString(empty));
      expect(restored.isEmpty, isTrue);
    });
  });
}
