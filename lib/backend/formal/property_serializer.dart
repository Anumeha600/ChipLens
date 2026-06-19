import 'dart:convert';

import 'formal_property_set.dart';

// ─── PropertySerializer ───────────────────────────────────────────────────────

/// Converts [FormalPropertySet] to and from JSON.
///
/// Scope is deliberately narrow: **JSON only**.  SystemVerilog/VHDL emission
/// and `.sby` script generation are the responsibility of backend-specific
/// emitters introduced in future tasks.
abstract class PropertySerializer {
  PropertySerializer._();

  // ── Structured (Map) form ─────────────────────────────────────────────────

  /// Serializes [set] to a [Map] suitable for JSON encoding.
  static Map<String, dynamic> toJson(FormalPropertySet set) => set.toJson();

  /// Deserializes a [FormalPropertySet] from a previously serialized [Map].
  static FormalPropertySet fromJson(Map<String, dynamic> json) =>
      FormalPropertySet.fromJson(json);

  // ── String (encoded) form ─────────────────────────────────────────────────

  /// Encodes [set] as a JSON string.
  static String toJsonString(FormalPropertySet set) =>
      jsonEncode(toJson(set));

  /// Decodes a [FormalPropertySet] from the JSON string produced by
  /// [toJsonString].
  ///
  /// Throws [FormatException] when [jsonString] is not valid JSON, and
  /// [TypeError] when the root value is not a JSON object.
  static FormalPropertySet fromJsonString(String jsonString) =>
      fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
