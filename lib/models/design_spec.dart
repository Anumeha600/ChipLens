// Core models for the local NL→RTL generation pipeline.
// These are distinct from the backend-API models in generation_result.dart.

import 'quality.dart';
import 'coverage_report.dart';

export 'quality.dart';

class SignalPort {
  final String name;
  final int width;
  final String description;
  final String direction; // 'input' | 'output'

  const SignalPort({
    required this.name,
    required this.width,
    required this.description,
    required this.direction,
  });
}

class StateNode {
  final String name;
  final String description;
  final bool isEntry;
  final bool isExit;
  final Map<String, String> outputs;

  const StateNode({
    required this.name,
    required this.description,
    this.isEntry = false,
    this.isExit = false,
    this.outputs = const {},
  });
}

class EdgeTransition {
  final String from;
  final String to;
  final String condition;
  final String? action;

  const EdgeTransition({
    required this.from,
    required this.to,
    required this.condition,
    this.action,
  });
}

class DesignSpecification {
  final String title;
  final String description;
  final String moduleName;
  final String designType;
  final List<SignalPort> inputs;
  final List<SignalPort> outputs;
  final List<StateNode> states;
  final List<EdgeTransition> transitions;
  final List<String> assumptions;
  final String entryState;
  final List<String> exitStates;
  final Map<String, dynamic> params;

  const DesignSpecification({
    required this.title,
    required this.description,
    required this.moduleName,
    required this.designType,
    required this.inputs,
    required this.outputs,
    required this.states,
    required this.transitions,
    required this.assumptions,
    required this.entryState,
    this.exitStates = const [],
    this.params = const {},
  });
}

class DesignResult {
  final DesignSpecification spec;
  final String rtl;
  final String testbench;
  final List<String> fsmStates;
  final List<Map<String, dynamic>> fsmEdges;
  final String? fsmEntryState;
  final List<String> fsmDeadStates;
  final List<String> fsmUnreachableStates;
  final QualityReport quality;
  final String explanation;

  /// Full coverage report from the simulation pass; null when simulation was
  /// skipped or produced no usable output.
  final CoverageReport? coverageReport;

  const DesignResult({
    required this.spec,
    required this.rtl,
    required this.testbench,
    required this.fsmStates,
    required this.fsmEdges,
    this.fsmEntryState,
    this.fsmDeadStates = const [],
    this.fsmUnreachableStates = const [],
    required this.quality,
    required this.explanation,
    this.coverageReport,
  });
}
