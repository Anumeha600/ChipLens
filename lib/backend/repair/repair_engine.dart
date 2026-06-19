import '../../models/design_spec.dart';
import '../../backend/coverage/coverage_report.dart';
import '../../backend/coverage/coverage_model.dart';
import '../../backend/diagnostics/diagnostics.dart';
import '../../backend/verification/verification_runner.dart';
import '../../backend/tools/rtl_testbench_generator.dart';
import '../../services/nl_pipeline/quality_analyzer.dart';
import '../../services/nl_pipeline/testbench_generator.dart';
import 'repair_suggestion.dart';

// ─── RepairEngine ─────────────────────────────────────────────────────────────

class RepairEngine {
  // ── Public API ──────────────────────────────────────────────────────────────

  /// Analyse [rtlSource] against [warnings] and return repair suggestions.
  ///
  /// Results are ordered by descending confidence and deduplicated by
  /// [RepairSuggestion.originalCode] so that two warnings that target the
  /// same code fragment produce only one suggestion.
  static List<RepairSuggestion> suggest({
    required String rtlSource,
    required List<QualityWarning> warnings,
    CoverageReport? coverageReport,
  }) {
    final seen        = <String>{};
    final suggestions = <RepairSuggestion>[];

    for (final w in warnings) {
      final s = _suggestForWarning(rtlSource, w);
      if (s == null) continue;
      final key = s.isAutoFixable ? s.originalCode : '${s.ruleId}:info';
      if (seen.add(key)) suggestions.add(s);
    }

    // Add informational suggestions for coverage gaps so the engineer knows
    // which areas of the testbench need expansion.
    if (coverageReport != null) {
      for (final w in coverageReport.coverageWarnings) {
        final key = 'coverage:${w.category.name}:${w.target}';
        if (!seen.add(key)) continue;
        suggestions.add(RepairSuggestion(
          ruleId:          w.toQualityWarning().type,
          title:           _coverageTitle(w),
          explanation:     '${w.message}${w.suggestion != null ? " ${w.suggestion}" : ""}',
          originalCode:    '',
          replacementCode: '',
          confidence:      _coverageConfidence(w),
        ));
      }
    }

    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions;
  }

  static String _coverageTitle(CoverageWarning w) {
    switch (w.category) {
      case CoverageWarningCategory.state:      return 'Unvisited state: ${w.target}';
      case CoverageWarningCategory.transition: return 'Missing transition: ${w.target}';
      case CoverageWarningCategory.branch:     return 'Uncovered branch';
      case CoverageWarningCategory.toggle:     return 'Untoggled signal: ${w.target}';
      case CoverageWarningCategory.condition:  return 'Partial condition coverage';
      case CoverageWarningCategory.deadLogic:  return 'Potential dead logic detected';
    }
  }

  static double _coverageConfidence(CoverageWarning w) {
    switch (w.severity) {
      case 'critical': return 0.80;
      case 'warning':  return 0.65;
      default:         return 0.45;
    }
  }

  /// Apply [suggestions] sequentially to [rtlSource] and return the result.
  ///
  /// Non-auto-fixable suggestions (empty [originalCode]) are skipped.
  /// If a later suggestion's [originalCode] was already replaced by an earlier
  /// one, the replacement is skipped gracefully.
  static String applyAll(String rtlSource, List<RepairSuggestion> suggestions) {
    var result = rtlSource;
    for (final s in suggestions) {
      if (!s.isAutoFixable) continue;
      if (result.contains(s.originalCode)) {
        result = result.replaceFirst(s.originalCode, s.replacementCode);
      }
    }
    return result;
  }

  /// Apply [suggestions] to [originalRtl], then re-run the full analysis
  /// pipeline (internal quality + Verilator + Yosys + Icarus) and return a
  /// [RepairResult] comparing before/after metrics.
  static Future<RepairResult> repair({
    required String originalRtl,
    required List<RepairSuggestion> suggestions,
    required DesignSpecification spec,
    required QualityReport qualityBefore,
  }) async {
    // 1 — apply patches
    final repairedRtl = applyAll(originalRtl, suggestions);

    // 2 — generate testbench for Icarus (prefer RTL-inferred, fall back to template)
    final tbResult  = RtlTestbenchGenerator.generate(repairedRtl);
    final testbench = tbResult.success
        ? tbResult.source
        : TestbenchGenerator.generate(spec);

    // 3 — launch all external tools concurrently while the sync analyser runs
    final verilatorFuture = VerificationRunner.runVerilator(repairedRtl);
    final yosysFuture     = VerificationRunner.runYosys(repairedRtl);
    final icarusFuture    = VerificationRunner.runIcarus(repairedRtl, testbench)
        .then((r) => r.$1);

    // 4 — internal quality (synchronous) — acts as "re-run rule engine"
    final newInternal = QualityAnalyzer.analyze(repairedRtl, spec);

    // 5 — collect external results
    final verilatorDiags = await verilatorFuture;
    final yosysDiags     = await yosysFuture;
    final icarusDiags    = await icarusFuture;

    // 6 — merge
    QualityReport newQuality = newInternal;
    if (verilatorDiags.isNotEmpty ||
        yosysDiags.isNotEmpty     ||
        icarusDiags.isNotEmpty) {
      final engine = DiagnosticEngine()
        ..addAll(verilatorDiags)
        ..addAll(yosysDiags)
        ..addAll(icarusDiags);
      newQuality = engine.mergeIntoReport(newInternal);
    }

    // 7 — compute delta metrics
    final before = qualityBefore.warnings.length;
    final after  = newQuality.warnings.length;

    return RepairResult(
      repairedRTL:        repairedRtl,
      issuesFixed:        (before - after).clamp(0, before),
      remainingIssues:    after,
      qualityBefore:      qualityBefore.total.toDouble(),
      qualityAfter:       newQuality.total.toDouble(),
      appliedSuggestions: suggestions,
      newQualityReport:   newQuality,
    );
  }

  // ── Pattern matchers ────────────────────────────────────────────────────────

  static RepairSuggestion? _suggestForWarning(
      String rtl, QualityWarning w) {
    switch (w.type) {
      // ── Latch / missing default ───────────────────────────────────────────
      case 'missing_default':
      case 'inferred_latch':
      case 'latch_risk':
      case 'verilator_latch':
      case 'verilator_nolatch':
      case 'yosys_infer_latch':
        return _fixMissingDefault(rtl, w);

      // ── Blocking assignments ──────────────────────────────────────────────
      case 'blocking_seq':
      case 'no_nonblocking':
      case 'blocking_assignment':
      case 'verilator_blkloopinit':
      case 'verilator_combdly':
      case 'verilator_blkandnblk':
        return _fixBlockingAssignment(rtl, w);

      // ── Missing reset ─────────────────────────────────────────────────────
      case 'missing_reset':
      case 'no_reset':
      case 'verilator_resetall':
        return _fixMissingReset(rtl, w);

      // ── Incomplete sensitivity list ───────────────────────────────────────
      case 'incomplete_sensitivity':
        return _fixIncompleteSensitivity(rtl, w);

      // ── Unused signal ─────────────────────────────────────────────────────
      case 'unused_signal':
        return _fixUnusedSignal(rtl, w);

      // ── Unreachable state ─────────────────────────────────────────────────
      case 'unreachable_state':
      case 'dead_code':
        return _noteUnreachableState(w);

      // ── Combinatorial loop ────────────────────────────────────────────────
      case 'combinatorial_loop':
      case 'yosys_loop':
        return _noteCombinatorialLoop(w);

      // ── Multiple drivers ──────────────────────────────────────────────────
      case 'multiple_drivers':
      case 'yosys_multiple_drivers':
        return _noteMultipleDrivers(w);

      // ── Width mismatch (Verilator) ────────────────────────────────────────
      case 'verilator_width':
      case 'icarus_type_error':
        return _suggestWidthFix(rtl, w);

      // ── Undeclared / implicit wire ────────────────────────────────────────
      case 'icarus_implicit_wire':
      case 'icarus_undefined':
        return _fixImplicitWire(rtl, w);

      default:
        return null;
    }
  }

  // ── Fix: add default case ─────────────────────────────────────────────────

  static RepairSuggestion? _fixMissingDefault(String rtl, QualityWarning w) {
    final caseRe = RegExp(
      r'(case[xz]?\s*\([^)]+\))([\s\S]*?)(endcase)',
      multiLine: true,
    );

    for (final m in caseRe.allMatches(rtl)) {
      final header = m.group(1)!;
      final body   = m.group(2)!;
      final footer = m.group(3)!;
      final full   = m.group(0)!;

      if (body.contains('default')) continue; // already present

      // Infer indentation from the last non-empty line of body
      final indent = _lastLineIndent(body);

      final replacement = '$header$body${indent}default: ;\n$indent$footer';

      return RepairSuggestion(
        ruleId:          w.type,
        title:           'Add default case branch',
        explanation:     'A case statement without a default branch causes latch '
            'inference: the synthesiser "holds" current values for unlisted inputs. '
            'Adding `default: ;` makes all input combinations explicit.',
        originalCode:    full,
        replacementCode: replacement,
        confidence:      0.90,
      );
    }
    return null;
  }

  // ── Fix: blocking → non-blocking assignments ──────────────────────────────

  static RepairSuggestion? _fixBlockingAssignment(String rtl, QualityWarning w) {
    // Match: always @( ... posedge/negedge ... ) begin ... end
    final seqRe = RegExp(
      r'(always\s*@\s*\([^)]*(?:posedge|negedge)[^)]*\)\s*begin)'
      r'([\s\S]*?)'
      r'(\n[ \t]*end\b)',
      multiLine: true,
    );

    for (final m in seqRe.allMatches(rtl)) {
      final header = m.group(1)!;
      final body   = m.group(2)!;
      final footer = m.group(3)!;
      final full   = m.group(0)!;

      // Check if any blocking assignments exist (= but not ==, !=, <=, >=)
      if (!_hasBlockingAssignment(body)) continue;

      final fixedBody = _replaceBlockingWithNonBlocking(body);
      if (fixedBody == body) continue;

      return RepairSuggestion(
        ruleId:          w.type,
        title:           'Replace blocking with non-blocking assignments',
        explanation:     'Blocking assignments (=) in clocked always blocks cause '
            'simulation–synthesis mismatches because they execute in order like '
            'software. Non-blocking (<=) schedules all updates simultaneously at '
            'the clock edge, matching flip-flop behaviour.',
        originalCode:    full,
        replacementCode: header + fixedBody + footer,
        confidence:      0.80,
      );
    }
    return null;
  }

  static bool _hasBlockingAssignment(String body) =>
      RegExp(r'(?<![<>!=])=(?![>=])').hasMatch(body);

  static String _replaceBlockingWithNonBlocking(String body) {
    const keywords = {
      'if', 'else', 'for', 'while', 'repeat', 'forever',
      'case', 'casex', 'casez', 'begin', 'end',
    };
    return body.replaceAllMapped(
      // Match: (word)(whitespace)(=)(whitespace) but not ==, !=, <=, >=
      RegExp(r'(\b\w+\b)(\s*)(=)(\s*)(?![>=])', multiLine: true),
      (m) {
        final lhs = m.group(1)!;
        if (keywords.contains(lhs)) return m.group(0)!;
        return '$lhs${m.group(2)!}<=${m.group(4)!}';
      },
    );
  }

  // ── Fix: add synchronous reset ────────────────────────────────────────────

  static RepairSuggestion? _fixMissingReset(String rtl, QualityWarning w) {
    // Match: always @(posedge clk) begin ... end  (no negedge reset already)
    final seqRe = RegExp(
      r'(always\s*@\s*\(\s*posedge\s+(\w+)\s*\)\s*begin)'
      r'([\s\S]*?)'
      r'(\n[ \t]*end\b)',
      multiLine: true,
    );

    for (final m in seqRe.allMatches(rtl)) {
      final clk    = m.group(2)!;
      final body   = m.group(3)!;
      final footer = m.group(4)!;
      final full   = m.group(0)!;

      // Skip if reset is already handled
      if (RegExp(r'\b(?:rst|reset)\b', caseSensitive: false).hasMatch(body)) continue;

      final indent = _detectBodyIndent(body);

      // Wrap existing body in else clause; add reset block
      final newHeader = 'always @(posedge $clk or negedge rst_n) begin';
      final newBody   = '\n${indent}if (!rst_n) begin\n'
          '$indent  // TODO: reset registers to their initial values\n'
          '${indent}end else begin$body\n${indent}end';

      return RepairSuggestion(
        ruleId:          w.type,
        title:           'Add synchronous reset (rst_n)',
        explanation:     'Sequential logic without a reset cannot be initialised to '
            'a known state after power-on or simulation start. An active-low '
            'synchronous reset ensures predictable startup behaviour.',
        originalCode:    full,
        replacementCode: newHeader + newBody + footer,
        confidence:      0.70,
      );
    }
    return null;
  }

  // ── Fix: incomplete sensitivity list ─────────────────────────────────────

  static RepairSuggestion? _fixIncompleteSensitivity(String rtl, QualityWarning w) {
    // Match always @(explicit list) — no posedge/negedge, no *
    final combRe = RegExp(
      r'(always\s*@\s*\()([^*)\s][^)]+)(\))',
      multiLine: true,
    );

    for (final m in combRe.allMatches(rtl)) {
      final prefix = m.group(1)!;
      final list   = m.group(2)!;
      final suffix = m.group(3)!;

      if (list.contains('posedge') || list.contains('negedge')) continue;

      final original    = m.group(0)!;
      final replacement = '$prefix*$suffix';

      return RepairSuggestion(
        ruleId:          w.type,
        title:           'Replace explicit sensitivity list with @(*)',
        explanation:     'If any input signal is missing from the sensitivity list '
            'the always block will not re-evaluate when that signal changes, '
            'creating a simulation bug. `@(*)` automatically includes every '
            'signal read inside the block.',
        originalCode:    original,
        replacementCode: replacement,
        confidence:      0.95,
      );
    }
    return null;
  }

  // ── Fix: unused signal — comment out declaration ──────────────────────────

  static RepairSuggestion? _fixUnusedSignal(String rtl, QualityWarning w) {
    // Try to extract signal name from warning message
    final nameMatch = RegExp(r"'(\w+)'").firstMatch(w.message);
    if (nameMatch == null) return null;
    final signal = nameMatch.group(1)!;

    // Find a wire/reg declaration for this signal
    final declRe = RegExp(
      r'([ \t]*(?:wire|reg)\b[^\n]*\b' +
      RegExp.escape(signal) +
      r'\b[^\n]*\n)',
      multiLine: true,
    );
    final m = declRe.firstMatch(rtl);
    if (m == null) return null;

    final original    = m.group(1)!;
    final replacement = '${original.replaceAll('\n', '')} // unused\n';

    return RepairSuggestion(
      ruleId:          w.type,
      title:           "Comment out unused signal '$signal'",
      explanation:     "The signal '$signal' is declared but never driven or read. "
          'Synthesisers can optimise it away, but leaving it unchecked makes '
          'the intent ambiguous. Mark it with a comment or remove it.',
      originalCode:    original,
      replacementCode: replacement,
      confidence:      0.60,
    );
  }

  // ── Fix: implicit wire — add declaration ─────────────────────────────────

  static RepairSuggestion? _fixImplicitWire(String rtl, QualityWarning w) {
    final nameMatch = RegExp(r"'(\w+)'|wire\s+(\w+)").firstMatch(w.message);
    final signal = nameMatch?.group(1) ?? nameMatch?.group(2);
    if (signal == null) return null;

    // Insert wire declaration after the module port list (after first `;`)
    final semicolonIdx = rtl.indexOf(';');
    if (semicolonIdx < 0) return null;

    // Check if already declared
    if (RegExp(r'\b(?:wire|reg)\b[^\n]*\b' + RegExp.escape(signal) + r'\b')
        .hasMatch(rtl)) {
      return null;
    }

    final insertPoint = rtl.substring(0, semicolonIdx + 1);

    return RepairSuggestion(
      ruleId:          w.type,
      title:           "Add missing wire declaration for '$signal'",
      explanation:     'Iverilog found an implicit wire — a net used without an '
          'explicit declaration. Verilog 2001+ requires explicit declarations '
          'with `default_nettype none`. Adding `wire $signal;` removes the '
          'ambiguity.',
      originalCode:    insertPoint,
      replacementCode: '$insertPoint\nwire $signal;',
      confidence:      0.75,
    );
  }

  // ── Informational: width mismatch ────────────────────────────────────────

  static RepairSuggestion? _suggestWidthFix(String rtl, QualityWarning w) {
    return RepairSuggestion(
      ruleId:          w.type,
      title:           'Fix width mismatch',
      explanation:     'A signal is assigned to a bus of a different bit-width. '
          'Use explicit casting: `signal[N-1:0]` to truncate, or zero-extend '
          'with `{{padding{1\'b0}}, signal}`. Review assignments flagged by '
          'Verilator -Wall.',
      originalCode:    '',
      replacementCode: '',
      confidence:      0.40,
    );
  }

  // ── Informational: unreachable state ─────────────────────────────────────

  static RepairSuggestion _noteUnreachableState(QualityWarning w) {
    return RepairSuggestion(
      ruleId:          w.type,
      title:           'Remove or connect unreachable state',
      explanation:     'An FSM state exists but can never be entered from the '
          'initial state. Either add a transition leading to it or remove '
          'its case branch, outputs, and localparams to keep the code '
          'consistent with the actual reachability graph.',
      originalCode:    '',
      replacementCode: '',
      confidence:      0.45,
    );
  }

  // ── Informational: combinatorial loop ────────────────────────────────────

  static RepairSuggestion _noteCombinatorialLoop(QualityWarning w) {
    return RepairSuggestion(
      ruleId:          w.type,
      title:           'Break combinational loop with a register',
      explanation:     'A combinational feedback path exists where an output feeds '
          'back to an input without a register stage. Insert a flip-flop '
          '(`always @(posedge clk) reg_q <= comb_out;`) to break the cycle '
          'and create well-defined timing.',
      originalCode:    '',
      replacementCode: '',
      confidence:      0.35,
    );
  }

  // ── Informational: multiple drivers ──────────────────────────────────────

  static RepairSuggestion _noteMultipleDrivers(QualityWarning w) {
    return RepairSuggestion(
      ruleId:          w.type,
      title:           'Resolve multiple-driver conflict',
      explanation:     'Two or more always blocks or continuous assignments drive '
          'the same net, creating an X (unknown) in simulation and '
          'unpredictable hardware. Merge the drivers into one always block '
          'or use a priority mux (conditional assign).',
      originalCode:    '',
      replacementCode: '',
      confidence:      0.30,
    );
  }

  // ── Utility ─────────────────────────────────────────────────────────────────

  /// Return the indentation of the last non-empty line in [text].
  static String _lastLineIndent(String text) {
    final lines = text.split('\n');
    for (final line in lines.reversed) {
      if (line.trim().isNotEmpty) {
        final m = RegExp(r'^([ \t]*)').firstMatch(line);
        return m?.group(1) ?? '      ';
      }
    }
    return '      ';
  }

  /// Return the indentation used by the first non-empty line of the body.
  static String _detectBodyIndent(String body) {
    for (final line in body.split('\n')) {
      if (line.trim().isNotEmpty) {
        final m = RegExp(r'^([ \t]+)').firstMatch(line);
        return m?.group(1) ?? '  ';
      }
    }
    return '  ';
  }
}
