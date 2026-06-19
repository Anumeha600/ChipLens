import 'dart:math' as math;

import '../../models/design_spec.dart';
import 'coverage_result.dart';
import 'coverage_model.dart';
import 'coverage_report.dart';

// ─── CoverageAnalyzer ─────────────────────────────────────────────────────────

/// Full 6-metric RTL coverage analyzer.
///
/// Metrics and weights:
/// | Metric     | Weight | Basis |
/// |------------|--------|-------|
/// | State      | 30 %   | FSM states visited vs spec total |
/// | Transition | 25 %   | Consecutive state pairs vs spec transitions |
/// | Branch     | 20 %   | if/case branches exercised |
/// | Toggle     | 10 %   | Output + internal regs that changed value |
/// | Condition  | 10 %   | Boolean guard expressions evaluated both ways |
/// | Line       | 5 %    | Executable statements in always blocks |
///
/// Call [analyze] to get a full [CoverageReport].
/// [CoverageEngine] is a backward-compatible thin wrapper that returns
/// just the inner [CoverageResult].
class CoverageAnalyzer {
  CoverageAnalyzer._();

  // ── Public API ──────────────────────────────────────────────────────────────

  static CoverageReport analyze({
    required String simulationOutput,
    required DesignSpecification spec,
    required String rtlSource,
  }) {
    // ── 1. Parse RTL structure ────────────────────────────────────────────────
    final encoding      = _parseStateEncoding(rtlSource, spec.states.map((s) => s.name).toList());
    final portNames     = _parsePortNames(rtlSource);
    final internalRegs  = _parseInternalRegs(rtlSource, portNames);
    final branches      = _parseBranches(rtlSource);
    final conditions    = _parseConditions(rtlSource);
    final alwaysLines   = _countAlwaysLines(rtlSource);

    // ── 2. Parse simulation monitor output ────────────────────────────────────
    final trace = _parseMonitorOutput(simulationOutput);

    // ── 3. Tracked signals: outputs + internal regs, minus clk/rst ───────────
    final allTrackedSignals = {
      ...portNames.outputs,
      ...internalRegs,
    }..removeWhere(_isClockOrReset);

    // ── 4. State signal detection ─────────────────────────────────────────────
    final stateSignal = _findStateSignal(trace.keys.toSet(), portNames);

    // ── 5. State coverage ─────────────────────────────────────────────────────
    final allStateNames   = spec.states.map((s) => s.name).toList();
    final stateSeq        = stateSignal != null
        ? _resolveStateSequence(trace[stateSignal] ?? [], encoding)
        : _inferStateSequence(trace, spec, portNames);

    final visitedSet      = stateSeq.where((s) => s != null).cast<String>().toSet();
    final visitedStates   = allStateNames.where(visitedSet.contains).toList();
    final unvisitedStates = allStateNames.where((s) => !visitedSet.contains(s)).toList();

    // Heat: fraction of timesteps in which each state was active
    final totalSteps = stateSeq.length;
    final stateHeat  = <String, double>{};
    for (final name in allStateNames) {
      final count = stateSeq.where((s) => s == name).length;
      stateHeat[name] = totalSteps > 0 ? count / totalSteps : 0.0;
    }

    final stateCov = allStateNames.isEmpty
        ? 1.0 : visitedStates.length / allStateNames.length;

    // ── 6. Transition coverage ────────────────────────────────────────────────
    final takenPairs = _extractTransitionPairs(stateSeq);
    final takenKeys  = takenPairs.map((p) => '${p.$1}→${p.$2}').toSet();

    final takenTransitions   = <String>[];
    final untakenTransitions = <String>[];
    for (final t in spec.transitions) {
      final key = '${t.from}→${t.to}';
      (takenKeys.contains(key) ? takenTransitions : untakenTransitions)
          .add('${t.from} → ${t.to}');
    }

    final transCov = spec.transitions.isEmpty
        ? 1.0 : takenTransitions.length / spec.transitions.length;

    // ── 7. Branch coverage ────────────────────────────────────────────────────
    final (coveredBranches, uncoveredBranches) = _analyzeBranchCoverage(
      branches:      branches,
      visitedStates: visitedSet,
      rtlSource:     rtlSource,
      trace:         trace,
    );

    final branchCov = branches.isEmpty
        ? 1.0 : coveredBranches.length / branches.length;

    // ── 8. Toggle coverage ────────────────────────────────────────────────────
    final toggledSignals   = <String>[];
    final untoggledSignals = <String>[];

    for (final sig in allTrackedSignals) {
      final vals = trace[sig];
      if (vals == null || vals.length < 2) {
        untoggledSignals.add(sig);
      } else {
        (vals.toSet().length >= 2 ? toggledSignals : untoggledSignals).add(sig);
      }
    }

    // Heat: 1.0 if toggled, 0.0 if not
    final signalHeat = <String, double>{
      for (final s in toggledSignals)    s: 1.0,
      for (final s in untoggledSignals)  s: 0.0,
    };

    final toggleCov = allTrackedSignals.isEmpty
        ? 1.0 : toggledSignals.length / allTrackedSignals.length;

    // ── 9. Condition coverage ─────────────────────────────────────────────────
    final (coveredConditions, uncoveredConditions) = _analyzeConditionCoverage(
      conditions: conditions,
      trace:      trace,
      hasSimOutput: trace.isNotEmpty,
    );

    final conditionCov = conditions.isEmpty
        ? 1.0 : coveredConditions.length / conditions.length;

    // ── 10. Line coverage ─────────────────────────────────────────────────────
    // Heuristic: lines inside always blocks are "executed" proportionally to
    // state + branch coverage (a simulation that visits more states and branches
    // executes more lines).
    final executableLines = alwaysLines;
    int executedLines;
    if (executableLines == 0 || trace.isEmpty) {
      executedLines = 0;
    } else {
      // Weight: 60 % from state coverage + 40 % from branch coverage
      final lineFraction = (stateCov * 0.60 + branchCov * 0.40).clamp(0.0, 1.0);
      executedLines = (executableLines * lineFraction).round();
    }

    final lineCov = executableLines == 0
        ? 1.0 : executedLines / executableLines;

    // ── 11. Overall ───────────────────────────────────────────────────────────
    final overall = CoverageResult.weighted(
        stateCov, transCov, branchCov, toggleCov, conditionCov, lineCov);

    // ── 12. Typed CoverageWarnings ────────────────────────────────────────────
    final typedWarnings = _buildCoverageWarnings(
      unvisitedStates:      unvisitedStates,
      untakenTransitions:   untakenTransitions,
      uncoveredBranches:    uncoveredBranches,
      untoggledSignals:     untoggledSignals,
      uncoveredConditions:  uncoveredConditions,
      stateCov:             stateCov,
    );

    // QualityWarnings derived from the typed list
    final qualityWarnings = typedWarnings
        .map((w) => w.toQualityWarning())
        .toList();

    // ── 13. Build CoverageResult ──────────────────────────────────────────────
    final result = CoverageResult(
      stateCoverage:       _clamp(stateCov),
      transitionCoverage:  _clamp(transCov),
      branchCoverage:      _clamp(branchCov),
      toggleCoverage:      _clamp(toggleCov),
      conditionCoverage:   _clamp(conditionCov),
      lineCoverage:        _clamp(lineCov),
      overallCoverage:     _clamp(overall),
      visitedStates:       visitedStates,
      unvisitedStates:     unvisitedStates,
      takenTransitions:    takenTransitions,
      untakenTransitions:  untakenTransitions,
      coveredBranches:     coveredBranches,
      uncoveredBranches:   uncoveredBranches,
      toggledSignals:      toggledSignals,
      untoggledSignals:    untoggledSignals,
      coveredConditions:   coveredConditions,
      uncoveredConditions: uncoveredConditions,
      warnings:            qualityWarnings,
    );

    // ── 14. Build CoverageMetrics ─────────────────────────────────────────────
    final metrics = CoverageMetrics(
      totalStates:               allStateNames.length,
      visitedStateCount:         visitedStates.length,
      totalTransitions:          spec.transitions.length,
      executedTransitionCount:   takenTransitions.length,
      totalBranches:             branches.length,
      coveredBranchCount:        coveredBranches.length,
      totalSignals:              allTrackedSignals.length,
      toggledSignalCount:        toggledSignals.length,
      totalConditions:           conditions.length,
      evaluatedConditionCount:   coveredConditions.length,
      totalLines:                executableLines,
      executedLineCount:         executedLines,
    );

    // ── 15. Build heatmap ─────────────────────────────────────────────────────
    final branchHeat = <String, double>{
      for (final b in coveredBranches)    b: 1.0,
      for (final b in uncoveredBranches)  b: 0.0,
    };

    final heatMap = CoverageHeatMapData(
      stateHeat:  stateHeat,
      signalHeat: signalHeat,
      branchHeat: branchHeat,
    );

    return CoverageReport(
      result:           result,
      metrics:          metrics,
      coverageWarnings: typedWarnings,
      heatMap:          heatMap,
    );
  }

  // ── RTL parsing ────────────────────────────────────────────────────────────

  /// Parse `localparam [W] NAME = VALUE;` for FSM state encoding.
  static Map<int, String> _parseStateEncoding(
      String rtl, List<String> stateNames) {
    final result = <int, String>{};
    final re = RegExp(
      r'\blocalparam\b\s*(?:\[[^\]]*\]\s*)?(\w+)\s*=\s*([^,;\n]+)',
      multiLine: true,
    );
    for (final m in re.allMatches(rtl)) {
      final name = m.group(1)!.trim();
      if (!stateNames.contains(name)) continue;
      final val = _parseVerilogLiteral(m.group(2)!.trim());
      if (val != null) result[val] = name;
    }
    return result;
  }

  /// Parse Verilog integer literals: `2'd5`, `3'h2`, `2'b01`, plain `5`.
  static int? _parseVerilogLiteral(String s) {
    s = s.trim().replaceAll('_', '');
    final sized = RegExp(r"\d+'([bBdDhHoO])([0-9a-fA-FxzXZ]+)").firstMatch(s);
    if (sized != null) {
      final base   = sized.group(1)!.toLowerCase();
      final digits = sized.group(2)!.replaceAll(RegExp(r'[xzXZ]'), '0');
      switch (base) {
        case 'b': return int.tryParse(digits, radix: 2);
        case 'd': return int.tryParse(digits);
        case 'h': return int.tryParse(digits, radix: 16);
        case 'o': return int.tryParse(digits, radix: 8);
      }
    }
    return int.tryParse(s);
  }

  static _PortNames _parsePortNames(String rtl) {
    final inputs  = <String>{};
    final outputs = <String>{};
    final re = RegExp(
      r'\b(input|output)\s+(?:wire\s+)?(?:reg\s+)?(?:\[[^\]]*\]\s*)?(\w+)',
      multiLine: true,
    );
    const skip = {'begin', 'end', 'always', 'initial', 'assign', 'wire', 'reg',
      'integer', 'parameter', 'localparam', 'posedge', 'negedge'};

    for (final m in re.allMatches(rtl)) {
      final dir  = m.group(1)!;
      final name = m.group(2)!;
      if (skip.contains(name)) continue;
      if (dir == 'input') { inputs.add(name); } else { outputs.add(name); }
    }
    return _PortNames(inputs: inputs, outputs: outputs);
  }

  static Set<String> _parseInternalRegs(String rtl, _PortNames ports) {
    final result = <String>{};
    final re = RegExp(r'\breg\s+(?:\[[^\]]*\]\s+)?(\w+)', multiLine: true);
    const skip = {'begin', 'end', 'always', 'initial', 'posedge', 'negedge',
      'wire', 'reg', 'integer', 'parameter', 'localparam'};

    for (final m in re.allMatches(rtl)) {
      final name = m.group(1)!;
      if (skip.contains(name)) continue;
      if (ports.inputs.contains(name) || ports.outputs.contains(name)) continue;
      result.add(name);
    }
    return result;
  }

  static bool _isClockOrReset(String name) {
    const clkNames = {'clk', 'clock', 'clk_i', 'sys_clk', 'i_clk', 'pclk', 'aclk'};
    const rstNames = {'rst', 'reset', 'rst_n', 'rstn', 'areset', 'areset_n',
      'rst_i', 'i_rst_n', 'nreset', 'nrst', 'aresetn'};
    final lower = name.toLowerCase();
    return clkNames.contains(lower) || rstNames.contains(lower);
  }

  /// Parse branch labels from RTL.  Each `if (...)` produces two labels
  /// (true branch / false/else branch); each case item is one label.
  static List<String> _parseBranches(String rtl) {
    final branches = <String>[];

    final ifRe = RegExp(r'\bif\s*\(([^)]+)\)', multiLine: true);
    for (final m in ifRe.allMatches(rtl)) {
      final cond = m.group(1)!.trim();
      branches.add('if ($cond) - true');
      branches.add('if ($cond) - false/else');
    }

    // Double-quoted raw string avoids single-quote closing the literal.
    final caseItemRe = RegExp(r"^\s*([\w']+(?:\s*,\s*[\w']+)*)\s*:", multiLine: true);
    bool inCase = false;
    for (final line in rtl.split('\n')) {
      if (RegExp(r'\bcase[xz]?\s*\(').hasMatch(line)) { inCase = true; continue; }
      if (inCase && line.trim().startsWith('endcase')) { inCase = false; continue; }
      if (inCase) {
        final m = caseItemRe.firstMatch(line);
        if (m != null) branches.add('case item: ${m.group(1)!.trim()}');
      }
    }
    return branches;
  }

  /// Extract all boolean conditions from `if (...)` guards.
  /// Each condition string corresponds to one condition-coverage point.
  static List<String> _parseConditions(String rtl) {
    final conditions = <String>[];
    final ifRe = RegExp(r'\bif\s*\(([^)]+)\)', multiLine: true);
    for (final m in ifRe.allMatches(rtl)) {
      final cond = m.group(1)!.trim();
      // Only count conditions that contain logic/comparison operators
      if (RegExp(r'[&|!<>=]').hasMatch(cond)) {
        conditions.add(cond);
      }
    }
    // Ternary conditions
    final ternaryRe = RegExp(r'(\b[\w\s\[\]]+)\s*\?', multiLine: true);
    for (final m in ternaryRe.allMatches(rtl)) {
      final cond = m.group(1)!.trim();
      if (cond.isNotEmpty && RegExp(r'[&|!<>=]').hasMatch(cond)) {
        conditions.add('ternary: $cond');
      }
    }
    return conditions;
  }

  /// Count executable statements inside `always` and `initial` blocks.
  static int _countAlwaysLines(String rtl) {
    int count = 0;
    bool inBlock = false;
    int depth = 0;
    for (final line in rtl.split('\n')) {
      final trimmed = line.trim();
      if (!inBlock) {
        if (RegExp(r'\b(always|initial)\b').hasMatch(trimmed)) {
          inBlock = true;
          depth = 0;
        }
        continue;
      }
      if (trimmed.startsWith('begin')) depth++;
      if (trimmed.startsWith('end') && !trimmed.startsWith('endmodule')) {
        depth--;
        if (depth <= 0) { inBlock = false; continue; }
      }
      // Count non-blank, non-comment lines as executable
      if (trimmed.isNotEmpty &&
          !trimmed.startsWith('//') &&
          !trimmed.startsWith('/*') &&
          !trimmed.startsWith('begin') &&
          !trimmed.startsWith('end')) {
        count++;
      }
    }
    return count;
  }

  // ── Monitor output parser ─────────────────────────────────────────────────

  /// Parse `[<time>] name=val name=val ...` lines.
  /// Returns `Map<String, List<String>>` (signalName → ordered values).
  static Map<String, List<String>> _parseMonitorOutput(String output) {
    final result = <String, List<String>>{};
    final lineRe = RegExp(r'^\s*\[\s*(\d+)\s*\]\s*(.+)$', multiLine: true);
    final pairRe = RegExp(r'(\w+)=([0-9a-fA-FxzXZ?]+)');

    for (final line in lineRe.allMatches(output)) {
      final rest = line.group(2)!;
      for (final pair in pairRe.allMatches(rest)) {
        result.putIfAbsent(pair.group(1)!, () => []).add(pair.group(2)!);
      }
    }
    return result;
  }

  // ── State detection ────────────────────────────────────────────────────────

  static const _stateSignalNames = ['state', 'cur_state', 'current_state',
    'st', 'cs', 'state_reg'];

  static String? _findStateSignal(Set<String> traceKeys, _PortNames ports) {
    for (final name in _stateSignalNames) {
      if (traceKeys.contains(name)) return name;
    }
    for (final k in traceKeys) {
      if (_stateSignalNames.contains(k.toLowerCase())) return k;
    }
    return null;
  }

  static List<String?> _resolveStateSequence(
      List<String> rawValues, Map<int, String> encoding) {
    return rawValues.map((v) {
      final dec = int.tryParse(v, radix: 16)
          ?? int.tryParse(v, radix: 2)
          ?? int.tryParse(v);
      return dec != null ? encoding[dec] : null;
    }).toList();
  }

  static List<String?> _inferStateSequence(
    Map<String, List<String>> trace,
    DesignSpecification spec,
    _PortNames ports,
  ) {
    if (trace.isEmpty || spec.states.isEmpty) return [];
    final len = trace.values.map((l) => l.length).fold(0, math.max);
    final seq = <String?>[];

    for (var i = 0; i < len; i++) {
      final snapshot = <String, String>{};
      for (final entry in trace.entries) {
        if (i < entry.value.length) snapshot[entry.key] = entry.value[i];
      }
      String? matched;
      for (final state in spec.states) {
        if (state.outputs.isEmpty) continue;
        bool allMatch = true;
        for (final out in state.outputs.entries) {
          final observed = snapshot[out.key];
          if (observed == null) { allMatch = false; break; }
          final expected = out.value.toLowerCase().replaceAll(RegExp(r'[^01]'), 'x');
          final actual   = observed.toLowerCase();
          if (expected != 'x' && actual != 'x' && expected != actual) {
            allMatch = false; break;
          }
        }
        if (allMatch) { matched = state.name; break; }
      }
      seq.add(matched);
    }
    return seq;
  }

  static List<(String, String)> _extractTransitionPairs(List<String?> seq) {
    final pairs = <(String, String)>[];
    String? prev;
    for (final cur in seq) {
      if (cur != null && prev != null && prev != cur) pairs.add((prev, cur));
      if (cur != null) prev = cur;
    }
    return pairs;
  }

  // ── Branch coverage ────────────────────────────────────────────────────────

  static (List<String>, List<String>) _analyzeBranchCoverage({
    required List<String> branches,
    required Set<String> visitedStates,
    required String rtlSource,
    required Map<String, List<String>> trace,
  }) {
    if (branches.isEmpty) return ([], []);
    final covered   = <String>[];
    final uncovered = <String>[];
    final observed  = <String, Set<String>>{
      for (final e in trace.entries) e.key: e.value.toSet(),
    };
    final hasOutput = trace.isNotEmpty;

    for (final branch in branches) {
      if (!hasOutput) { uncovered.add(branch); continue; }

      if (branch.startsWith('case item:')) {
        (visitedStates.isNotEmpty ? covered : uncovered).add(branch);
        continue;
      }

      final condMatch = RegExp(r'if \((.+)\) - (true|false.*)').firstMatch(branch);
      if (condMatch == null) { uncovered.add(branch); continue; }

      final cond          = condMatch.group(1)!;
      final isTrueBranch  = condMatch.group(2) == 'true';
      final sigNames      = RegExp(r'\b([a-zA-Z_]\w*)\b')
          .allMatches(cond)
          .map((m) => m.group(1)!)
          .where(observed.containsKey)
          .toList();

      if (sigNames.isEmpty) {
        (visitedStates.isNotEmpty ? covered : uncovered).add(branch);
        continue;
      }

      bool seen = false;
      for (final sig in sigNames) {
        final vals = observed[sig]!;
        seen = isTrueBranch
            ? vals.any((v) => v != '0' && v != 'x' && v != 'z')
            : vals.contains('0');
        if (seen) break;
      }
      (seen ? covered : uncovered).add(branch);
    }
    return (covered, uncovered);
  }

  // ── Condition coverage ─────────────────────────────────────────────────────

  static (List<String>, List<String>) _analyzeConditionCoverage({
    required List<String> conditions,
    required Map<String, List<String>> trace,
    required bool hasSimOutput,
  }) {
    if (conditions.isEmpty) return ([], []);
    final covered   = <String>[];
    final uncovered = <String>[];
    final observed  = <String, Set<String>>{
      for (final e in trace.entries) e.key: e.value.toSet(),
    };

    for (final cond in conditions) {
      if (!hasSimOutput) { uncovered.add(cond); continue; }

      // Extract signal names from the condition expression
      final sigNames = RegExp(r'\b([a-zA-Z_]\w*)\b')
          .allMatches(cond)
          .map((m) => m.group(1)!)
          .where(observed.containsKey)
          .toList();

      if (sigNames.isEmpty) {
        // Condition has no trace-visible signals — assume covered if sim ran
        covered.add(cond);
        continue;
      }

      // A condition is "fully covered" when the primary signal was both
      // asserted (non-zero) and de-asserted (zero) at some point.
      bool sawTrue  = false;
      bool sawFalse = false;
      for (final sig in sigNames) {
        final vals = observed[sig]!;
        sawTrue  = sawTrue  || vals.any((v) => v != '0' && v != 'x' && v != 'z');
        sawFalse = sawFalse || vals.contains('0');
      }
      (sawTrue && sawFalse ? covered : uncovered).add(cond);
    }
    return (covered, uncovered);
  }

  // ── Warning generation ─────────────────────────────────────────────────────

  static List<CoverageWarning> _buildCoverageWarnings({
    required List<String> unvisitedStates,
    required List<String> untakenTransitions,
    required List<String> uncoveredBranches,
    required List<String> untoggledSignals,
    required List<String> uncoveredConditions,
    required double stateCov,
  }) {
    final warnings = <CoverageWarning>[];

    for (final s in unvisitedStates) {
      warnings.add(CoverageWarning(
        category:   CoverageWarningCategory.state,
        target:     s,
        message:    "State '$s' was never entered during simulation.",
        severity:   'warning',
        suggestion: 'Add stimulus that drives the FSM into the $s state.',
      ));
    }

    for (final t in untakenTransitions) {
      warnings.add(CoverageWarning(
        category:   CoverageWarningCategory.transition,
        target:     t,
        message:    'Transition $t was never observed in simulation.',
        severity:   'info',
        suggestion: 'Add a test case that triggers this transition.',
      ));
    }

    for (final b in uncoveredBranches) {
      warnings.add(CoverageWarning(
        category:   CoverageWarningCategory.branch,
        target:     b,
        message:    "Branch '$b' was not exercised.",
        severity:   'info',
        suggestion: 'Extend the testbench stimulus to cover this branch.',
      ));
    }

    for (final sig in untoggledSignals) {
      warnings.add(CoverageWarning(
        category:   CoverageWarningCategory.toggle,
        target:     sig,
        message:    "Signal '$sig' did not change value during simulation.",
        severity:   'info',
        suggestion: "Drive '$sig' to both 0 and 1 in the testbench.",
      ));
    }

    for (final cond in uncoveredConditions) {
      warnings.add(CoverageWarning(
        category:   CoverageWarningCategory.condition,
        target:     cond,
        message:    "Condition '$cond' was not fully evaluated (both true and false).",
        severity:   'info',
        suggestion: 'Add stimulus that exercises both branches of this condition.',
      ));
    }

    // Dead logic: if state coverage is very low, flag potential dead logic
    if (stateCov < 0.30 && unvisitedStates.isNotEmpty) {
      warnings.add(CoverageWarning(
        category:   CoverageWarningCategory.deadLogic,
        target:     'FSM',
        message:    'State coverage is critically low (${(stateCov * 100).toStringAsFixed(0)}%). '
            'Logic in unvisited states may be dead code.',
        severity:   stateCov == 0 ? 'critical' : 'warning',
        suggestion: 'Verify that all states are reachable and expand testbench coverage.',
      ));
    }

    return warnings;
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static double _clamp(double v) => v.clamp(0.0, 1.0);
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

class _PortNames {
  final Set<String> inputs;
  final Set<String> outputs;
  const _PortNames({required this.inputs, required this.outputs});
}

// ─── CoverageEngine (backward-compatible wrapper) ─────────────────────────────

/// Thin wrapper around [CoverageAnalyzer] for backward compatibility.
/// New code should use [CoverageAnalyzer.analyze] directly.
class CoverageEngine {
  CoverageEngine._();

  static CoverageResult analyze({
    required String simulationOutput,
    required DesignSpecification spec,
    required String rtlSource,
  }) =>
      CoverageAnalyzer.analyze(
        simulationOutput: simulationOutput,
        spec:             spec,
        rtlSource:        rtlSource,
      ).result;
}
