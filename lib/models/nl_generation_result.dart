// Model for the POST /api/v1/generate response.
// Reuses FsmData / FsmEdge from generation_result.dart.

import 'generation_result.dart';

class NlSpecSignal {
  final String name;
  final int width;
  final String description;
  const NlSpecSignal(
      {required this.name, required this.width, required this.description});

  factory NlSpecSignal.fromJson(Map<String, dynamic> j) => NlSpecSignal(
        name: j['name'] as String? ?? '',
        width: (j['width'] as num?)?.toInt() ?? 1,
        description: j['description'] as String? ?? '',
      );
}

class NlSpecState {
  final String name;
  final String description;
  const NlSpecState({required this.name, required this.description});

  factory NlSpecState.fromJson(Map<String, dynamic> j) => NlSpecState(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
      );
}

class NlDesignSpec {
  final String title;
  final String description;
  final List<NlSpecSignal> inputs;
  final List<NlSpecSignal> outputs;
  final List<NlSpecState> states;
  final String functionality;
  final String designNotes;

  const NlDesignSpec({
    required this.title,
    required this.description,
    required this.inputs,
    required this.outputs,
    required this.states,
    required this.functionality,
    required this.designNotes,
  });

  factory NlDesignSpec.fromJson(Map<String, dynamic> j) => NlDesignSpec(
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        inputs: (j['inputs'] as List<dynamic>? ?? [])
            .map((e) => NlSpecSignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        outputs: (j['outputs'] as List<dynamic>? ?? [])
            .map((e) => NlSpecSignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        states: (j['states'] as List<dynamic>? ?? [])
            .map((e) => NlSpecState.fromJson(e as Map<String, dynamic>))
            .toList(),
        functionality: j['functionality'] as String? ?? '',
        designNotes: j['designNotes'] as String? ?? '',
      );
}

class NlAnalysis {
  final String moduleName;
  final List<String> inputs;
  final List<String> outputs;
  final int total;
  final String grade;
  final Map<String, int> categories;
  final List<Map<String, dynamic>> warnings;
  final int warningCount;
  final bool hasFsm;

  const NlAnalysis({
    required this.moduleName,
    required this.inputs,
    required this.outputs,
    required this.total,
    required this.grade,
    required this.categories,
    required this.warnings,
    required this.warningCount,
    required this.hasFsm,
  });

  factory NlAnalysis.fromJson(Map<String, dynamic> j) => NlAnalysis(
        moduleName: j['moduleName'] as String? ?? '',
        inputs: (j['inputs'] as List<dynamic>? ?? []).cast<String>(),
        outputs: (j['outputs'] as List<dynamic>? ?? []).cast<String>(),
        total: (j['total'] as num?)?.toInt() ?? 0,
        grade: j['grade'] as String? ?? 'F',
        categories: (j['categories'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        warnings: (j['warnings'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        warningCount: (j['warningCount'] as num?)?.toInt() ?? 0,
        hasFsm: j['hasFsm'] as bool? ?? false,
      );
}

class NlGenerationResult {
  final String designType;
  final String displayName;
  final NlDesignSpec spec;
  final String rtl;
  final String testbench;
  final FsmData? fsm;
  final NlAnalysis analysis;
  final String explanation;

  const NlGenerationResult({
    required this.designType,
    required this.displayName,
    required this.spec,
    required this.rtl,
    required this.testbench,
    required this.fsm,
    required this.analysis,
    required this.explanation,
  });

  factory NlGenerationResult.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    final fsmRaw = d['fsm'] as Map<String, dynamic>?;
    final fsmData = (fsmRaw != null && !fsmRaw.containsKey('error'))
        ? FsmData.fromJson(fsmRaw)
        : null;

    return NlGenerationResult(
      designType:  d['designType']  as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      spec:        NlDesignSpec.fromJson(d['spec'] as Map<String, dynamic>? ?? {}),
      rtl:         d['rtl']         as String? ?? '',
      testbench:   d['testbench']   as String? ?? '',
      fsm:         fsmData,
      analysis:    NlAnalysis.fromJson(d['analysis'] as Map<String, dynamic>? ?? {}),
      explanation: d['explanation'] as String? ?? '',
    );
  }
}
