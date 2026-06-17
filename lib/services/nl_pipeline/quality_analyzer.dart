// RTL Quality Analyzer — scores generated Verilog across four rubrics:
// Correctness (35), Synthesizability (30), Maintainability (20), FSM Quality (15).
// Each category includes an explanation and targeted recommendations.

import '../../models/design_spec.dart';

class QualityAnalyzer {
  static QualityReport analyze(String rtl, DesignSpecification spec) {
    final warnings  = <QualityWarning>[];
    final catDetails = <QualityCategory>[];
    final cats      = <String, int>{};

    // ── Correctness (35 pts) ─────────────────────────────────────────────
    final corIssues = <String>[];
    final corRecs   = <String>[];
    int correctness = 0;

    // Timescale directive (+5)
    if (rtl.contains('`timescale')) {
      correctness += 5;
    } else {
      corIssues.add('No `timescale directive — simulation resolution undefined');
      corRecs.add('Add `timescale 1ns/1ps at the top of every synthesizable file');
      warnings.add(const QualityWarning(
        type: 'missing_timescale',
        message: 'No `timescale directive — simulation time resolution undefined.',
        severity: 'warning',
      ));
    }

    // Reset handling (+10)
    final hasReset = rtl.contains('rst_n') || rtl.contains('rst');
    if (hasReset) {
      correctness += 10;
    } else {
      corIssues.add('No reset signal detected — power-up state is indeterminate');
      corRecs.add('Add active-low synchronous rst_n to all sequential always blocks');
      warnings.add(const QualityWarning(
        type: 'missing_reset',
        message: 'No reset signal detected — registers may power up in unknown state.',
        severity: 'critical',
      ));
    }

    // Default case branch (+8)
    final hasDefault = RegExp(r'\bdefault\s*:').hasMatch(rtl);
    if (hasDefault) {
      correctness += 8;
    } else {
      corIssues.add('No default branch in case statement — synthesis may infer a latch');
      corRecs.add('Add default: next_state = next_state; in every case statement');
      warnings.add(const QualityWarning(
        type: 'missing_default',
        message: 'No default branch in case statement — may infer latch in synthesis.',
        severity: 'warning',
      ));
    }

    // Non-blocking assignments in sequential block (+8)
    if (rtl.contains('<=')) {
      correctness += 8;
    } else {
      corIssues.add('No non-blocking (<=) assignments — sequential logic modelling incorrect');
      corRecs.add('Use non-blocking assignments (<=) exclusively in always @(posedge clk) blocks');
      warnings.add(const QualityWarning(
        type: 'no_nonblocking',
        message: 'No non-blocking assignments — sequential logic may not synthesize correctly.',
        severity: 'critical',
      ));
    }

    // Sized literal constants (+4) — e.g. 4'd5, 2'b01
    if (RegExp(r"\d+\s*'\s*[bBdDhHoO]").hasMatch(rtl)) {
      correctness += 4;
    } else {
      corRecs.add("Use sized literals (e.g. 2'd0, 8'hFF) to prevent implicit width extension");
    }

    cats['correctness'] = correctness;

    final corExpl = correctness >= 30
        ? 'Sequential logic follows synthesizable RTL conventions. '
          'Reset is properly handled and non-blocking assignments are used throughout.'
        : correctness >= 20
            ? 'Core correctness patterns are present. Address the listed issues '
              'to ensure correct synthesis and simulation behaviour.'
            : 'Critical correctness issues detected. This RTL may not synthesize '
              'or simulate as intended.';

    catDetails.add(QualityCategory(
      name: 'Correctness',
      score: correctness,
      maxScore: 35,
      explanation: corExpl,
      issues: corIssues,
      recommendations: corRecs,
    ));

    // ── Synthesizability (30 pts) ────────────────────────────────────────
    final synIssues = <String>[];
    final synRecs   = <String>[];
    int synth = 0;

    // posedge clock always block (+7)
    if (rtl.contains('posedge clk')) {
      synth += 7;
    } else {
      synIssues.add('No posedge clk block — design may be purely combinational or async');
      synRecs.add('Add always @(posedge clk) block for all registered state updates');
      warnings.add(const QualityWarning(
        type: 'no_posedge',
        message: 'No posedge clk always block — design appears combinational-only.',
        severity: 'warning',
      ));
    }

    // Separate combinational always block (+7)
    final hasCombAlways = rtl.contains('always @(*)') ||
        RegExp(r'always\s*@\s*\(\s*\*\s*\)').hasMatch(rtl);
    if (hasCombAlways) {
      synth += 7;
    } else {
      synIssues.add('Output/next-state logic merged into clocked block — limits portability');
      synRecs.add('Separate combinational output logic into a dedicated always @(*) block');
      warnings.add(const QualityWarning(
        type: 'no_comb_block',
        message: 'No always @(*) block — consider separating combinational and sequential logic.',
        severity: 'info',
      ));
    }

    // localparam state encoding (+7)
    if (rtl.contains('localparam')) {
      synth += 7;
    } else {
      synIssues.add('Hard-coded state values — no localparams for state encoding');
      synRecs.add('Use localparam for all state constants to allow encoding optimisation');
      warnings.add(const QualityWarning(
        type: 'no_localparam',
        message: 'No localparams — hard-coded state values reduce synthesizability.',
        severity: 'info',
      ));
    }

    // Explicit state register bit width (+5)
    if (RegExp(r'reg\s*\[[\w\s\-+:]+\]\s*(state|next_state)').hasMatch(rtl)) {
      synth += 5;
    } else if (RegExp(r'reg\s*\[\d+:\d+\]').hasMatch(rtl)) {
      synth += 3;
    } else {
      synRecs.add('Declare state variables with explicit widths: reg [1:0] state, next_state');
    }

    // Module-level parameters for overridable constants (+4)
    if (RegExp(r'module\s+\w+\s*#\s*\(').hasMatch(rtl)) {
      synth += 4;
    } else {
      synRecs.add('Add #(parameter ...) declarations so timing constants can be overridden per-instance');
    }

    cats['synthesizability'] = synth;

    final synExpl = synth >= 26
        ? 'RTL is written in clean synthesizable style with proper clocking, '
          'separated combinational/sequential logic, and parameterised constants.'
        : synth >= 16
            ? 'Basic synthesizability is present. Separating combinational logic '
              'and adding module parameters would improve portability across tools.'
            : 'Significant synthesizability concerns. Review clocking strategy, '
              'sensitivity lists, and state encoding before targeting synthesis.';

    catDetails.add(QualityCategory(
      name: 'Synthesizability',
      score: synth,
      maxScore: 30,
      explanation: synExpl,
      issues: synIssues,
      recommendations: synRecs,
    ));

    // ── Maintainability (20 pts) ─────────────────────────────────────────
    final mntIssues = <String>[];
    final mntRecs   = <String>[];
    int maint = 0;

    // Module-level header comment block (+4)
    if (rtl.contains('// ====') || rtl.contains('// ----') || rtl.contains('// ****')) {
      maint += 4;
    } else {
      mntRecs.add('Add a header comment block: module name, description, author, revision');
    }

    // Section separator comments (+4)
    if (rtl.contains('// ──') || rtl.contains('// --') || rtl.contains('// ==')) {
      maint += 4;
    } else {
      mntRecs.add('Use section separators (// ──────) to delineate port list, parameters, always blocks');
    }

    // Inline port comments (+4) — require at least 2 ports with // annotations
    final portCommentCount =
        RegExp(r'(?:input|output)\s.*//').allMatches(rtl).length;
    if (portCommentCount >= 3) {
      maint += 4;
    } else if (portCommentCount >= 1) {
      maint += 2;
      mntRecs.add('Add inline // comments to every port (currently only $portCommentCount annotated)');
    } else {
      mntIssues.add('No inline port documentation — interface is not self-describing');
      mntRecs.add('Annotate each port: input wire [7:0] data_in, // 8-bit data bus');
      warnings.add(const QualityWarning(
        type: 'no_port_docs',
        message: 'No inline port comments — interface signals are undocumented.',
        severity: 'info',
      ));
    }

    // Readable ALL_CAPS state names (+4)
    final hasReadableStates = spec.states.any(
        (s) => s.name.length > 2 && RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(s.name));
    if (hasReadableStates) {
      maint += 4;
    } else {
      mntRecs.add('Use descriptive ALL_CAPS names for states: IDLE, WAIT_ACK, TRANSMIT');
    }

    // Module-level parameters (reusability) (+4)
    if (RegExp(r'module\s+\w+\s*#\s*\(').hasMatch(rtl)) {
      maint += 4;
    } else {
      mntRecs.add('Add #(parameter ...) for timing/width constants to improve reuse '
          'across different clock frequencies and bus widths');
    }

    cats['maintainability'] = maint;

    final mntExpl = maint >= 16
        ? 'Well-structured RTL with clear documentation, section separation, '
          'and port annotations.'
        : maint >= 10
            ? 'Basic structure is present. Adding port comments and module parameters '
              'would significantly improve readability for other engineers.'
            : 'Minimal documentation. Add header comments, port descriptions, '
              'and named parameters before sharing this design.';

    catDetails.add(QualityCategory(
      name: 'Maintainability',
      score: maint,
      maxScore: 20,
      explanation: mntExpl,
      issues: mntIssues,
      recommendations: mntRecs,
    ));

    // ── FSM Quality (15 pts) ─────────────────────────────────────────────
    final fsmIssues = <String>[];
    final fsmRecs   = <String>[];
    int fsmQuality  = 0;

    // Is an FSM design (+3)
    if (spec.states.length >= 2) {
      fsmQuality += 3;
    }

    // Explicit bit-width localparam encoding (+4 / +2)
    if (rtl.contains('localparam [')) {
      fsmQuality += 4;
    } else if (rtl.contains('localparam')) {
      fsmQuality += 2;
      fsmRecs.add('Specify bit width for state encoding: localparam [1:0] IDLE = 2\'d0');
    }

    // Complete state transition coverage (+4)
    final stateNames  = spec.states.map((s) => s.name).toSet();
    final coveredFrom = spec.transitions.map((t) => t.from).toSet();
    if (stateNames.every((s) => coveredFrom.contains(s))) {
      fsmQuality += 4;
    } else {
      final missing = stateNames.difference(coveredFrom);
      fsmIssues.add('States with no outgoing transitions: ${missing.join(", ")}');
      fsmRecs.add('Add explicit transitions from ${missing.join(", ")} '
          'or document them as absorbing states');
      warnings.add(QualityWarning(
        type: 'uncovered_states',
        message: 'States with no outgoing transitions: ${missing.join(", ")}. '
            'FSM may lock up.',
        severity: 'warning',
      ));
    }

    // State count and encoding recommendations
    final n = spec.states.length;
    if (n <= 4) {
      fsmQuality += 2; // Small FSM — binary encoding is optimal
    } else if (n <= 8) {
      fsmQuality += 1;
      fsmRecs.add('With $n states, one-hot encoding ($n FFs) may be faster on FPGA '
          'than binary encoding (${n.bitLength} FFs) — trade area for speed');
    } else {
      fsmRecs.add('With $n states, evaluate one-hot vs binary vs gray encoding: '
          'gray minimises switching activity; one-hot minimises logic depth');
    }

    // Reachability: flag if dead/unreachable states exist at spec level
    final hasOutgoing = spec.transitions.map((t) => t.from).toSet();
    final deadStates  = stateNames.where((s) => !hasOutgoing.contains(s)).toSet();
    if (deadStates.isEmpty && n >= 2) {
      fsmQuality += 2;
    } else if (deadStates.isNotEmpty) {
      fsmIssues.add('Terminal states with no exit path: ${deadStates.join(", ")}');
    }

    cats['fsm'] = fsmQuality;

    final fsmExpl = fsmQuality >= 12
        ? 'FSM is well-formed: proper encoding, complete transition coverage, '
          'and no unreachable states detected.'
        : fsmQuality >= 7
            ? 'FSM structure is sound. Refining state encoding and ensuring '
              'all states have defined exit paths will improve robustness.'
            : 'FSM coverage is incomplete. Review the transition table for '
              'missing paths and potential lockup conditions.';

    catDetails.add(QualityCategory(
      name: 'FSM Quality',
      score: fsmQuality,
      maxScore: 15,
      explanation: fsmExpl,
      issues: fsmIssues,
      recommendations: fsmRecs,
    ));

    // ── Total & Grade ─────────────────────────────────────────────────────
    final total = correctness + synth + maint + fsmQuality;
    final grade = _grade(total);

    return QualityReport(
      total: total,
      grade: grade,
      categories: cats,
      categoryDetails: catDetails,
      warnings: warnings,
      warningCount: warnings.length,
    );
  }

  static String _grade(int score) {
    if (score >= 94) return 'A+';
    if (score >= 88) return 'A';
    if (score >= 82) return 'A-';
    if (score >= 76) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 64) return 'B-';
    if (score >= 55) return 'C';
    if (score >= 45) return 'D';
    return 'F';
  }
}
