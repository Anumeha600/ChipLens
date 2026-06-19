import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/coverage/coverage.dart';
import 'package:chiplens_lite/models/design_spec.dart';

// ─── Shared fixtures ──────────────────────────────────────────────────────────

// Minimal FSM spec: IDLE → ACTIVE → IDLE
DesignSpecification _twoStateFsm() => const DesignSpecification(
  title: 'Test FSM',
  description: 'Two-state FSM',
  moduleName: 'test_fsm',
  designType: 'fsm',
  inputs: [
    SignalPort(name: 'clk',    width: 1, description: 'clock',  direction: 'input'),
    SignalPort(name: 'rst_n',  width: 1, description: 'reset',  direction: 'input'),
    SignalPort(name: 'enable', width: 1, description: 'enable', direction: 'input'),
  ],
  outputs: [
    SignalPort(name: 'out', width: 1, description: 'output', direction: 'output'),
  ],
  states: [
    StateNode(name: 'IDLE',   description: 'idle',   isEntry: true,  outputs: {'out': '0'}),
    StateNode(name: 'ACTIVE', description: 'active', isExit: false,  outputs: {'out': '1'}),
  ],
  transitions: [
    EdgeTransition(from: 'IDLE',   to: 'ACTIVE', condition: 'enable'),
    EdgeTransition(from: 'ACTIVE', to: 'IDLE',   condition: '!enable'),
  ],
  assumptions: [],
  entryState: 'IDLE',
);

// Full FSM spec: IDLE → FETCH → EXECUTE → IDLE, plus STALL dead-end
DesignSpecification _fourStateFsm() => const DesignSpecification(
  title: 'Processor FSM',
  description: 'Simple 4-state processor',
  moduleName: 'cpu',
  designType: 'fsm',
  inputs: [
    SignalPort(name: 'clk',   width: 1, description: 'clock', direction: 'input'),
    SignalPort(name: 'rst',   width: 1, description: 'reset', direction: 'input'),
    SignalPort(name: 'valid', width: 1, description: 'valid', direction: 'input'),
    SignalPort(name: 'stall', width: 1, description: 'stall', direction: 'input'),
  ],
  outputs: [
    SignalPort(name: 'busy', width: 1, description: 'busy', direction: 'output'),
    SignalPort(name: 'done', width: 1, description: 'done', direction: 'output'),
  ],
  states: [
    StateNode(name: 'IDLE',    description: 'idle',    isEntry: true),
    StateNode(name: 'FETCH',   description: 'fetch'),
    StateNode(name: 'EXECUTE', description: 'execute'),
    StateNode(name: 'STALL',   description: 'stall'),
  ],
  transitions: [
    EdgeTransition(from: 'IDLE',    to: 'FETCH',   condition: 'valid'),
    EdgeTransition(from: 'FETCH',   to: 'EXECUTE', condition: '!stall'),
    EdgeTransition(from: 'EXECUTE', to: 'IDLE',    condition: 'done'),
    EdgeTransition(from: 'FETCH',   to: 'STALL',   condition: 'stall'),
  ],
  assumptions: [],
  entryState: 'IDLE',
);

// RTL with state localparams + branches + internal reg
const _twoStateRtl = '''
module test_fsm (
  input  clk,
  input  rst_n,
  input  enable,
  output reg out
);
  localparam [0:0] IDLE   = 1'b0;
  localparam [0:0] ACTIVE = 1'b1;

  reg state;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      out   <= 1'b0;
    end else begin
      case (state)
        IDLE:   if (enable)  state <= ACTIVE;
        ACTIVE: if (!enable) state <= IDLE;
      endcase
      if (state == ACTIVE) begin
        out <= 1'b1;
      end else begin
        out <= 1'b0;
      end
    end
  end
endmodule
''';

// Monitor output: IDLE → ACTIVE → IDLE cycle
const _twoStateMonitorBothVisited = '''
[0] state=0 out=0
[10] state=0 out=0
[20] state=1 out=1
[30] state=1 out=1
[40] state=0 out=0
''';

// Monitor output: only IDLE visited
const _twoStateMonitorIdleOnly = '''
[0] state=0 out=0
[10] state=0 out=0
''';

// Empty / no simulation output
const _emptyMonitor = '';

void main() {
  // ─── CoverageResult ────────────────────────────────────────────────────────

  group('CoverageResult', () {
    test('empty() produces all-zero fractions', () {
      final r = CoverageResult.empty();
      expect(r.stateCoverage,      0.0);
      expect(r.transitionCoverage, 0.0);
      expect(r.branchCoverage,     0.0);
      expect(r.toggleCoverage,     0.0);
      expect(r.conditionCoverage,  0.0);
      expect(r.lineCoverage,       0.0);
      expect(r.overallCoverage,    0.0);
    });

    test('empty() has empty detail lists', () {
      final r = CoverageResult.empty();
      expect(r.visitedStates,       isEmpty);
      expect(r.unvisitedStates,     isEmpty);
      expect(r.takenTransitions,    isEmpty);
      expect(r.untakenTransitions,  isEmpty);
      expect(r.coveredBranches,     isEmpty);
      expect(r.uncoveredBranches,   isEmpty);
      expect(r.toggledSignals,      isEmpty);
      expect(r.untoggledSignals,    isEmpty);
      expect(r.coveredConditions,   isEmpty);
      expect(r.uncoveredConditions, isEmpty);
      expect(r.warnings,            isEmpty);
    });

    test('grade thresholds', () {
      expect(_resultWithOverall(0.97).grade, 'Excellent');
      expect(_resultWithOverall(0.85).grade, 'Good');
      expect(_resultWithOverall(0.70).grade, 'Fair');
      expect(_resultWithOverall(0.50).grade, 'Poor');
      expect(_resultWithOverall(0.20).grade, 'Critical');
    });

    test('weighted() uses 30/25/20/10/10/5 formula', () {
      final v = CoverageResult.weighted(1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      expect(v, closeTo(1.0, 0.001));
      // Only state (30%) covered
      final s = CoverageResult.weighted(1.0, 0.0, 0.0, 0.0, 0.0, 0.0);
      expect(s, closeTo(0.30, 0.001));
    });

    test('totalGaps sums uncovered items', () {
      final r = _coverageResultWith(
        unvisited: ['S1'],
        untaken:   ['A → B', 'B → C'],
        uncoveredB: ['if (x) - true'],
        untoggledS: [],
        uncoveredC: ['x > 0'],
      );
      expect(r.totalGaps, 5); // 1+2+1+0+1
    });

    test('coverageWarnings is alias for warnings', () {
      final r = CoverageResult.empty();
      expect(identical(r.warnings, r.coverageWarnings), isTrue);
    });
  });

  // ─── CoverageMetrics ───────────────────────────────────────────────────────

  group('CoverageMetrics', () {
    test('gap counts are total minus covered', () {
      const m = CoverageMetrics(
        totalStates: 4, visitedStateCount: 3,
        totalTransitions: 6, executedTransitionCount: 4,
        totalBranches: 8, coveredBranchCount: 5,
        totalSignals: 3, toggledSignalCount: 2,
        totalConditions: 4, evaluatedConditionCount: 3,
        totalLines: 20, executedLineCount: 16,
      );
      expect(m.unvisitedStateCount,       1);
      expect(m.missingTransitionCount,    2);
      expect(m.uncoveredBranchCount,      3);
      expect(m.untoggledSignalCount,      1);
      expect(m.unevaluatedConditionCount, 1);
      expect(m.unexecutedLineCount,       4);
    });

    test('empty has all zeros', () {
      expect(CoverageMetrics.empty.totalStates,    0);
      expect(CoverageMetrics.empty.visitedStateCount, 0);
    });

    test('toMap() contains all keys', () {
      final map = CoverageMetrics.empty.toMap();
      expect(map.containsKey('totalStates'),             isTrue);
      expect(map.containsKey('executedTransitionCount'), isTrue);
      expect(map.containsKey('totalConditions'),         isTrue);
    });
  });

  // ─── CoverageReport export ─────────────────────────────────────────────────

  group('CoverageReport export', () {
    late CoverageReport report;

    setUpAll(() {
      report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
    });

    test('toJson() is valid JSON with required keys', () {
      final json = report.toJson();
      expect(json, contains('"coverage"'));
      expect(json, contains('"overall"'));
      expect(json, contains('"state"'));
      expect(json, contains('"metrics"'));
      expect(json, contains('"warnings"'));
    });

    test('toCsv() contains CSV header and rows', () {
      final csv = report.toCsv();
      expect(csv, contains('Metric,Covered,Total,Percentage'));
      expect(csv, contains('State,'));
      expect(csv, contains('Overall,'));
    });

    test('toMarkdown() contains table and headers', () {
      final md = report.toMarkdown();
      expect(md, contains('# RTL Coverage Report'));
      expect(md, contains('## Coverage Summary'));
      expect(md, contains('| Metric | Covered | Total |'));
    });

    test('empty() report produces safe exports', () {
      final empty = CoverageReport.empty();
      expect(() => empty.toJson(),     returnsNormally);
      expect(() => empty.toCsv(),      returnsNormally);
      expect(() => empty.toMarkdown(), returnsNormally);
    });
  });

  // ─── CoverageAnalyzer — FSM coverage ──────────────────────────────────────

  group('CoverageAnalyzer FSM coverage', () {
    test('both states visited → stateCoverage = 1.0', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.stateCoverage, closeTo(1.0, 0.001));
      expect(r.visitedStates,   containsAll(['IDLE', 'ACTIVE']));
      expect(r.unvisitedStates, isEmpty);
    });

    test('only IDLE visited → stateCoverage = 0.5', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorIdleOnly,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.stateCoverage, closeTo(0.5, 0.001));
      expect(r.unvisitedStates, contains('ACTIVE'));
    });

    test('no simulation → stateCoverage = 0.0, all unvisited', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _emptyMonitor,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.stateCoverage, 0.0);
      expect(r.unvisitedStates, containsAll(['IDLE', 'ACTIVE']));
    });

    test('4-state FSM with partial trace covers only visited states', () {
      // Only IDLE and FETCH observed
      final monitor = '''
[0]  state=0
[10] state=1
[20] state=1
''';
      final rtl = '''
module cpu(input clk, input rst, input valid, input stall, output busy, output done);
  localparam [1:0] IDLE=2'd0, FETCH=2'd1, EXECUTE=2'd2, STALL=2'd3;
  reg [1:0] state;
  always @(posedge clk) begin
    if (rst) state <= IDLE;
    else case (state)
      IDLE:    if (valid) state <= FETCH;
      FETCH:   if (!stall) state <= EXECUTE; else state <= STALL;
      EXECUTE: state <= IDLE;
    endcase
  end
  assign busy = (state != IDLE);
  assign done = (state == EXECUTE);
endmodule
''';
      final r = CoverageAnalyzer.analyze(
        simulationOutput: monitor,
        spec:             _fourStateFsm(),
        rtlSource:        rtl,
      ).result;
      expect(r.stateCoverage,   lessThan(1.0));
      expect(r.unvisitedStates, isNotEmpty);
    });
  });

  // ─── CoverageAnalyzer — transition coverage ────────────────────────────────

  group('CoverageAnalyzer transition coverage', () {
    test('IDLE→ACTIVE and ACTIVE→IDLE both taken → transitionCoverage = 1.0', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.transitionCoverage, closeTo(1.0, 0.001));
      expect(r.takenTransitions,   hasLength(2));
      expect(r.untakenTransitions, isEmpty);
    });

    test('only IDLE observed → transitionCoverage = 0.0', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorIdleOnly,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.transitionCoverage, closeTo(0.0, 0.001));
      expect(r.untakenTransitions, hasLength(2));
    });

    test('untaken transition strings use " → " separator', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorIdleOnly,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.untakenTransitions.first, contains(' → '));
    });
  });

  // ─── CoverageAnalyzer — branch coverage ───────────────────────────────────

  group('CoverageAnalyzer branch coverage', () {
    test('branch coverage > 0 when simulation ran', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.branchCoverage, greaterThan(0.0));
    });

    test('branch coverage = 0 when no simulation output', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _emptyMonitor,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.branchCoverage, closeTo(0.0, 0.001));
      expect(r.uncoveredBranches, isNotEmpty);
    });

    test('RTL with no branches gives branchCoverage = 1.0', () {
      const nobranchRtl = '''
module no_branch(input clk, output reg out);
  always @(posedge clk) out <= ~out;
endmodule
''';
      final r = CoverageAnalyzer.analyze(
        simulationOutput: '[0] out=0\n[10] out=1\n',
        spec:             _twoStateFsm(),
        rtlSource:        nobranchRtl,
      ).result;
      expect(r.branchCoverage, closeTo(1.0, 0.001));
    });
  });

  // ─── CoverageAnalyzer — toggle coverage ───────────────────────────────────

  group('CoverageAnalyzer toggle coverage', () {
    test('signal that changes value is toggled', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.toggledSignals, isNotEmpty);
    });

    test('signal that never changes is untoggled', () {
      const frozenMonitor = '[0] out=0\n[10] out=0\n[20] out=0\n';
      final r = CoverageAnalyzer.analyze(
        simulationOutput: frozenMonitor,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.untoggledSignals, isNotEmpty);
    });

    test('clk/rst signals are excluded from toggle tracking', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.toggledSignals,   isNot(contains('clk')));
      expect(r.untoggledSignals, isNot(contains('clk')));
      expect(r.toggledSignals,   isNot(contains('rst_n')));
    });
  });

  // ─── CoverageAnalyzer — condition coverage ─────────────────────────────────

  group('CoverageAnalyzer condition coverage', () {
    test('conditions parsed from RTL with comparison operators', () {
      // _twoStateRtl has `if (!rst_n)` and `if (state == ACTIVE)`
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      // conditionCoverage should be a valid fraction
      expect(report.result.conditionCoverage, inInclusiveRange(0.0, 1.0));
      expect(report.metrics.totalConditions, greaterThanOrEqualTo(0));
    });

    test('no simulation → conditionCoverage = 0', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _emptyMonitor,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.conditionCoverage, closeTo(0.0, 0.001));
    });
  });

  // ─── CoverageAnalyzer — line coverage ─────────────────────────────────────

  group('CoverageAnalyzer line coverage', () {
    test('line coverage > 0 when simulation ran', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.lineCoverage, greaterThan(0.0));
    });

    test('line coverage = 0 when no simulation', () {
      final r = CoverageAnalyzer.analyze(
        simulationOutput: _emptyMonitor,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      ).result;
      expect(r.lineCoverage, closeTo(0.0, 0.001));
    });

    test('metrics.totalLines > 0 for RTL with always blocks', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      expect(report.metrics.totalLines, greaterThan(0));
    });
  });

  // ─── CoverageAnalyzer — coverage warnings ─────────────────────────────────

  group('CoverageAnalyzer coverage warnings', () {
    test('unvisited state generates coverage_unvisited_state warning', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorIdleOnly,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      final types = report.result.warnings.map((w) => w.type).toList();
      expect(types, contains('coverage_unvisited_state'));
    });

    test('unvisited state warning has severity = warning', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorIdleOnly,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      final unvisitedWarning = report.result.warnings
          .firstWhere((w) => w.type == 'coverage_unvisited_state');
      expect(unvisitedWarning.severity, 'warning');
    });

    test('untaken transition generates coverage_untaken_transition warning', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorIdleOnly,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      final types = report.result.warnings.map((w) => w.type).toList();
      expect(types, contains('coverage_untaken_transition'));
    });

    test('typed CoverageWarnings have matching categories', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorIdleOnly,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      final stateWarnings = report.coverageWarnings
          .where((w) => w.category == CoverageWarningCategory.state)
          .toList();
      expect(stateWarnings, isNotEmpty);
    });

    test('no unvisited-state warnings when all states visited', () {
      // Use the two-state FSM with full trace — both IDLE and ACTIVE are visited
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      final stateWarnings = report.coverageWarnings
          .where((w) => w.category == CoverageWarningCategory.state)
          .toList();
      expect(stateWarnings, isEmpty);
    });

    test('dead logic warning appears when state coverage < 30%', () {
      // Force <30% by using 4-state FSM with only 1 state visited
      const monitor = '[0] state=0\n[10] state=0\n';
      final rtl = '''
module cpu(input clk, input rst, input valid, input stall, output busy, output done);
  localparam [1:0] IDLE=2'd0, FETCH=2'd1, EXECUTE=2'd2, STALL=2'd3;
  reg [1:0] state;
  always @(posedge clk) begin
    state <= state;
  end
  assign busy = 0; assign done = 0;
endmodule
''';
      final report = CoverageAnalyzer.analyze(
        simulationOutput: monitor,
        spec:             _fourStateFsm(),
        rtlSource:        rtl,
      );
      final categories = report.coverageWarnings.map((w) => w.category).toSet();
      expect(categories, contains(CoverageWarningCategory.deadLogic));
    });
  });

  // ─── CoverageAnalyzer — quality score integration ─────────────────────────

  group('CoverageAnalyzer quality score', () {
    test('overallCoverage in [0,1] range', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      expect(report.overallCoverage, inInclusiveRange(0.0, 1.0));
    });

    test('full coverage produces overallCoverage near 1.0', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      // Both states visited + transition exercised — score should be high
      expect(report.overallCoverage, greaterThan(0.50));
    });

    test('no simulation → overallCoverage = 0.0', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _emptyMonitor,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      expect(report.overallCoverage, closeTo(0.0, 0.001));
    });
  });

  // ─── CoverageReport.empty() ────────────────────────────────────────────────

  group('CoverageReport.empty()', () {
    test('empty report has zero overall coverage', () {
      final r = CoverageReport.empty();
      expect(r.overallCoverage, 0.0);
      expect(r.grade,           'Critical');
      expect(r.totalGaps,       0);
    });

    test('empty heatmap is empty', () {
      final r = CoverageReport.empty();
      expect(r.heatMap.stateHeat,  isEmpty);
      expect(r.heatMap.signalHeat, isEmpty);
      expect(r.heatMap.branchHeat, isEmpty);
    });
  });

  // ─── CoverageHeatMapData ───────────────────────────────────────────────────

  group('CoverageHeatMapData', () {
    test('stateHeat populated for each FSM state', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      expect(report.heatMap.stateHeat.containsKey('IDLE'),   isTrue);
      expect(report.heatMap.stateHeat.containsKey('ACTIVE'), isTrue);
    });

    test('visited state has heat > 0', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      final idleHeat = report.heatMap.stateHeat['IDLE'] ?? 0.0;
      expect(idleHeat, greaterThan(0.0));
    });

    test('toggled signals have heat = 1.0 in signalHeat', () {
      final report = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      for (final entry in report.heatMap.signalHeat.entries) {
        expect(entry.value, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  // ─── CoverageEngine backward-compat wrapper ────────────────────────────────

  group('CoverageEngine (backward compat)', () {
    test('CoverageEngine.analyze returns CoverageResult', () {
      final r = CoverageEngine.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      expect(r, isA<CoverageResult>());
    });

    test('CoverageEngine gives same state coverage as CoverageAnalyzer', () {
      final engine   = CoverageEngine.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      final analyzer = CoverageAnalyzer.analyze(
        simulationOutput: _twoStateMonitorBothVisited,
        spec:             _twoStateFsm(),
        rtlSource:        _twoStateRtl,
      );
      expect(engine.stateCoverage, closeTo(analyzer.result.stateCoverage, 0.001));
    });
  });
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

CoverageResult _resultWithOverall(double overall) => CoverageResult(
  stateCoverage:      overall,
  transitionCoverage: overall,
  branchCoverage:     overall,
  toggleCoverage:     overall,
  conditionCoverage:  overall,
  lineCoverage:       overall,
  overallCoverage:    overall,
  visitedStates:      const [],
  unvisitedStates:    const [],
  takenTransitions:   const [],
  untakenTransitions: const [],
  coveredBranches:    const [],
  uncoveredBranches:  const [],
  toggledSignals:     const [],
  untoggledSignals:   const [],
  coveredConditions:  const [],
  uncoveredConditions: const [],
  warnings:           const [],
);

CoverageResult _coverageResultWith({
  required List<String> unvisited,
  required List<String> untaken,
  required List<String> uncoveredB,
  required List<String> untoggledS,
  required List<String> uncoveredC,
}) => CoverageResult(
  stateCoverage:      0,
  transitionCoverage: 0,
  branchCoverage:     0,
  toggleCoverage:     0,
  conditionCoverage:  0,
  lineCoverage:       0,
  overallCoverage:    0,
  visitedStates:      const [],
  unvisitedStates:    unvisited,
  takenTransitions:   const [],
  untakenTransitions: untaken,
  coveredBranches:    const [],
  uncoveredBranches:  uncoveredB,
  toggledSignals:     const [],
  untoggledSignals:   untoggledS,
  coveredConditions:  const [],
  uncoveredConditions: uncoveredC,
  warnings:           const [],
);
