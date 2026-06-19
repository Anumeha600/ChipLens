import '../../models/design_spec.dart';
import 'repair_models.dart';
import 'repair_suggestion.dart';
import 'repair_utils.dart';

/// The repair strategy repository.
///
/// For each [RepairFixGroup] key, [RepairCatalog] knows how to inspect the
/// RTL source, find the relevant code fragment, and produce a
/// [RepairSuggestion] (or `null` when the pattern is not present).
///
/// All strategy implementations live here so that:
/// - [RepairMatcher] stays a pure dispatch table (no regex logic).
/// - [RepairPipeline] stays a pure orchestrator (no pattern logic).
/// - Adding a new repair type requires only a new case in [RepairMatcher] and
///   a new private method here — zero changes elsewhere.
abstract class RepairCatalog {
  RepairCatalog._();

  /// Build a [RepairSuggestion] for the given [fixGroup] and [warning] by
  /// inspecting [rtlSource].  Returns `null` when the pattern is not found.
  static RepairSuggestion? build(
    String fixGroup,
    String rtlSource,
    QualityWarning warning,
  ) {
    switch (fixGroup) {
      case RepairFixGroup.missingDefault:
        return _fixMissingDefault(rtlSource, warning);
      case RepairFixGroup.blockingAssignment:
        return _fixBlockingAssignment(rtlSource, warning);
      case RepairFixGroup.missingReset:
        return _fixMissingReset(rtlSource, warning);
      case RepairFixGroup.incompleteSens:
        return _fixIncompleteSensitivity(rtlSource, warning);
      case RepairFixGroup.unusedSignal:
        return _fixUnusedSignal(rtlSource, warning);
      case RepairFixGroup.unreachableState:
        return _noteUnreachableState(warning);
      case RepairFixGroup.combinatorialLoop:
        return _noteCombinatorialLoop(warning);
      case RepairFixGroup.multipleDrivers:
        return _noteMultipleDrivers(warning);
      case RepairFixGroup.widthMismatch:
        return _suggestWidthFix(warning);
      case RepairFixGroup.implicitWire:
        return _fixImplicitWire(rtlSource, warning);
      default:
        return null;
    }
  }

  // ── Strategy: add default case ────────────────────────────────────────────

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

      if (body.contains('default')) continue;

      final indent      = RepairUtils.lastLineIndent(body);
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

  // ── Strategy: blocking → non-blocking ────────────────────────────────────

  static RepairSuggestion? _fixBlockingAssignment(String rtl, QualityWarning w) {
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

      if (!RepairUtils.hasBlockingAssignment(body)) continue;

      final fixedBody = RepairUtils.replaceBlockingWithNonBlocking(body);
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

  // ── Strategy: add synchronous reset ──────────────────────────────────────

  static RepairSuggestion? _fixMissingReset(String rtl, QualityWarning w) {
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

      if (RegExp(r'\b(?:rst|reset)\b', caseSensitive: false).hasMatch(body)) continue;

      final indent    = RepairUtils.detectBodyIndent(body);
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

  // ── Strategy: replace explicit sensitivity list with @(*) ─────────────────

  static RepairSuggestion? _fixIncompleteSensitivity(String rtl, QualityWarning w) {
    final combRe = RegExp(
      r'(always\s*@\s*\()([^*)\s][^)]+)(\))',
      multiLine: true,
    );

    for (final m in combRe.allMatches(rtl)) {
      final prefix = m.group(1)!;
      final list   = m.group(2)!;
      final suffix = m.group(3)!;

      if (list.contains('posedge') || list.contains('negedge')) continue;

      return RepairSuggestion(
        ruleId:          w.type,
        title:           'Replace explicit sensitivity list with @(*)',
        explanation:     'If any input signal is missing from the sensitivity list '
            'the always block will not re-evaluate when that signal changes, '
            'creating a simulation bug. `@(*)` automatically includes every '
            'signal read inside the block.',
        originalCode:    m.group(0)!,
        replacementCode: '$prefix*$suffix',
        confidence:      0.95,
      );
    }
    return null;
  }

  // ── Strategy: comment out unused signal declaration ───────────────────────

  static RepairSuggestion? _fixUnusedSignal(String rtl, QualityWarning w) {
    final nameMatch = RegExp(r"'(\w+)'").firstMatch(w.message);
    if (nameMatch == null) return null;
    final signal = nameMatch.group(1)!;

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

  // ── Strategy: add missing wire declaration ────────────────────────────────

  static RepairSuggestion? _fixImplicitWire(String rtl, QualityWarning w) {
    final nameMatch = RegExp(r"'(\w+)'|wire\s+(\w+)").firstMatch(w.message);
    final signal = nameMatch?.group(1) ?? nameMatch?.group(2);
    if (signal == null) return null;

    final semicolonIdx = rtl.indexOf(';');
    if (semicolonIdx < 0) return null;

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

  // ── Informational: width mismatch ─────────────────────────────────────────

  static RepairSuggestion _suggestWidthFix(QualityWarning w) =>
      RepairSuggestion(
        ruleId:          w.type,
        title:           'Fix width mismatch',
        explanation:     'A signal is assigned to a bus of a different bit-width. '
            'Use explicit casting: `signal[N-1:0]` to truncate, or zero-extend '
            "with `{{padding{1'b0}}, signal}`. Review assignments flagged by "
            'Verilator -Wall.',
        originalCode:    '',
        replacementCode: '',
        confidence:      0.40,
      );

  // ── Informational: unreachable state ──────────────────────────────────────

  static RepairSuggestion _noteUnreachableState(QualityWarning w) =>
      RepairSuggestion(
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

  // ── Informational: combinatorial loop ─────────────────────────────────────

  static RepairSuggestion _noteCombinatorialLoop(QualityWarning w) =>
      RepairSuggestion(
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

  // ── Informational: multiple drivers ───────────────────────────────────────

  static RepairSuggestion _noteMultipleDrivers(QualityWarning w) =>
      RepairSuggestion(
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
