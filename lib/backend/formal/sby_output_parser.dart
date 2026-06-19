import 'dart:io';

import 'formal_result.dart';

// ─── SbyOutputParser ──────────────────────────────────────────────────────────

/// Converts raw SymbiYosys process output into a [FormalResult].
///
/// All sby-specific regex patterns and property-extraction logic live here.
/// [SymbiYosysEngine] is responsible only for invoking the tool and then
/// delegating to [interpret] — no parsing happens in the engine itself.
abstract class SbyOutputParser {
  SbyOutputParser._();

  // ── SymbiYosys output patterns (tested across versions 0.9–0.40) ──────────
  //
  //   DONE (PASS)  — overall pass summary
  //   DONE (FAIL)  — overall fail summary
  //   Property ASSERT in module <m> at <f>:<l> [<f>:<l>]: passed.
  //   Property ASSERT in module <m> at <f>:<l> [<f>:<l>] FAILED!
  //   Assert failed in <m>: <f>:<l> $formal$<f>:<l>$<n>
  //   Property <name> ... UNKNOWN

  static final _propNameRe   = RegExp(r'Property\s+(\S+)\s+in\s+',              caseSensitive: false);
  static final _propPassRe   = RegExp(r'Property\s+\S+\s+in\s+\S+.*?\bpass(?:ed)?\b', caseSensitive: false);
  static final _propFailRe   = RegExp(r'Property\s+\S+\s+in\s+\S+.*?\bFAIL(?:ED)?\b', caseSensitive: false);
  static final _assertFailRe = RegExp(r'Assert failed in\s+\S+:\s*(\S+)',        caseSensitive: false);
  static final _unknownRe    = RegExp(r'Property\s+(\S+).*?\bUNKNOWN\b',        caseSensitive: false);
  static final _donePassRe   = RegExp(r'DONE\s*\(PASS\)',                        caseSensitive: false);
  static final _doneFailRe   = RegExp(r'DONE\s*\(FAIL\)',                        caseSensitive: false);

  // ── Public factory ─────────────────────────────────────────────────────────

  /// Converts a completed SymbiYosys [proc] and its [elapsed] time into a
  /// fully-populated [FormalResult].
  static FormalResult interpret(ProcessResult proc, Duration elapsed) {
    final stdout = proc.stdout.toString();
    final stderr = proc.stderr.toString();

    final proven  = _extractProven(stdout, stderr);
    final failed  = _extractFailed(stdout, stderr);
    final unknown = _extractUnknown(stdout, stderr);

    return FormalResult(
      success:           proc.exitCode == 0 && failed.isEmpty,
      exitCode:          proc.exitCode,
      stdout:            stdout,
      stderr:            stderr,
      executionTime:     elapsed,
      provenProperties:  proven,
      failedProperties:  failed,
      unknownProperties: unknown,
    );
  }

  // ── Extraction helpers ────────────────────────────────────────────────────

  static List<String> _extractProven(String stdout, String stderr) {
    final combined = '$stderr\n$stdout';
    final proven   = <String>{};

    for (final m in _propPassRe.allMatches(combined)) {
      final nm = _propNameRe.firstMatch(m.group(0)!);
      if (nm != null) proven.add(nm.group(1)!);
    }

    // Generic overall PASS with no individually named properties
    if (proven.isEmpty &&
        _donePassRe.hasMatch(combined) &&
        !_doneFailRe.hasMatch(combined)) {
      proven.add('all_assertions');
    }

    return proven.toList();
  }

  static List<String> _extractFailed(String stdout, String stderr) {
    final combined = '$stderr\n$stdout';
    final failed   = <String>{};

    // Named property failures
    for (final m in _propFailRe.allMatches(combined)) {
      final nm = _propNameRe.firstMatch(m.group(0)!);
      if (nm != null) failed.add(nm.group(1)!);
    }

    // Assert-failed references (file:line or $formal$ identifiers)
    for (final m in _assertFailRe.allMatches(combined)) {
      failed.add(m.group(1)!);
    }

    // Generic overall FAIL with no individually named properties
    if (failed.isEmpty && _doneFailRe.hasMatch(combined)) {
      failed.add('unknown_assertion');
    }

    return failed.toList();
  }

  static List<String> _extractUnknown(String stdout, String stderr) {
    final combined = '$stderr\n$stdout';
    final unknown  = <String>{};

    for (final m in _unknownRe.allMatches(combined)) {
      unknown.add(m.group(1)!);
    }

    return unknown.toList();
  }
}
