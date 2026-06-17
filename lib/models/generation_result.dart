// Data models for the NL-to-RTL generation API response.

class GenerationResult {
  final String designType;
  final String displayName;
  final Map<String, dynamic> params;
  final DesignSpec spec;
  final String rtl;
  final String testbench;
  final FsmData? fsm;
  final AnalysisData analysis;
  final String explanation;

  const GenerationResult({
    required this.designType,
    required this.displayName,
    required this.params,
    required this.spec,
    required this.rtl,
    required this.testbench,
    this.fsm,
    required this.analysis,
    required this.explanation,
  });

  factory GenerationResult.fromJson(Map<String, dynamic> j) {
    final fsmRaw = j['fsm'] as Map<String, dynamic>?;
    return GenerationResult(
      designType:  j['designType']  as String,
      displayName: j['displayName'] as String,
      params:      Map<String, dynamic>.from(j['params'] as Map),
      spec:        DesignSpec.fromJson(j['spec'] as Map<String, dynamic>),
      rtl:         j['rtl']         as String,
      testbench:   j['testbench']   as String,
      fsm:         (fsmRaw != null && fsmRaw['error'] == null)
                       ? FsmData.fromJson(fsmRaw)
                       : null,
      analysis:    AnalysisData.fromJson(j['analysis'] as Map<String, dynamic>),
      explanation: j['explanation'] as String? ?? '',
    );
  }
}

class DesignSpec {
  final String title;
  final String description;
  final List<SpecSignal> inputs;
  final List<SpecSignal> outputs;
  final List<SpecState> states;
  final String functionality;
  final String designNotes;

  const DesignSpec({
    required this.title,
    required this.description,
    required this.inputs,
    required this.outputs,
    required this.states,
    required this.functionality,
    required this.designNotes,
  });

  factory DesignSpec.fromJson(Map<String, dynamic> j) => DesignSpec(
        title:         j['title']         as String,
        description:   j['description']   as String,
        inputs:        _signals(j['inputs']),
        outputs:       _signals(j['outputs']),
        states:        _states(j['states']),
        functionality: j['functionality'] as String? ?? '',
        designNotes:   j['designNotes']   as String? ?? '',
      );

  static List<SpecSignal> _signals(dynamic raw) =>
      (raw as List?)?.map((e) => SpecSignal.fromJson(e as Map<String, dynamic>)).toList() ?? [];

  static List<SpecState> _states(dynamic raw) =>
      (raw as List?)?.map((e) => SpecState.fromJson(e as Map<String, dynamic>)).toList() ?? [];
}

class SpecSignal {
  final String name;
  final int width;
  final String description;

  const SpecSignal({required this.name, required this.width, required this.description});

  factory SpecSignal.fromJson(Map<String, dynamic> j) => SpecSignal(
        name:        j['name']        as String,
        width:       (j['width'] as num).toInt(),
        description: j['description'] as String? ?? '',
      );
}

class SpecState {
  final String name;
  final String description;

  const SpecState({required this.name, required this.description});

  factory SpecState.fromJson(Map<String, dynamic> j) => SpecState(
        name:        j['name']        as String,
        description: j['description'] as String? ?? '',
      );
}

class FsmData {
  final List<String> states;
  final List<FsmEdge> edges;
  final String? entryState;
  final List<String> deadStates;
  final List<String> unreachableStates;

  const FsmData({
    required this.states,
    required this.edges,
    this.entryState,
    required this.deadStates,
    required this.unreachableStates,
  });

  factory FsmData.fromJson(Map<String, dynamic> j) => FsmData(
        states:             List<String>.from(j['states'] as List? ?? []),
        edges:              ((j['edges'] as List?) ?? [])
                                .map((e) => FsmEdge.fromJson(e as Map<String, dynamic>))
                                .toList(),
        entryState:         j['entryState'] as String?,
        deadStates:         List<String>.from(j['deadStates'] as List? ?? []),
        unreachableStates:  List<String>.from(j['unreachableStates'] as List? ?? []),
      );
}

class FsmEdge {
  final String from;
  final String to;
  final String? condition;

  const FsmEdge({required this.from, required this.to, this.condition});

  factory FsmEdge.fromJson(Map<String, dynamic> j) => FsmEdge(
        from:      j['from'] as String,
        to:        j['to']   as String,
        condition: j['condition'] as String?,
      );
}

class AnalysisData {
  final int total;
  final String grade;
  final Map<String, dynamic> categories;
  final int warningCount;
  final List<dynamic> warnings;
  final bool hasFsm;

  const AnalysisData({
    required this.total,
    required this.grade,
    required this.categories,
    required this.warningCount,
    required this.warnings,
    required this.hasFsm,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> j) => AnalysisData(
        total:        (j['total'] as num?)?.toInt() ?? 0,
        grade:        j['grade'] as String? ?? 'F',
        categories:   Map<String, dynamic>.from(j['categories'] as Map? ?? {}),
        warningCount: (j['warningCount'] as num?)?.toInt() ?? 0,
        warnings:     j['warnings'] as List? ?? [],
        hasFsm:       j['hasFsm'] as bool? ?? false,
      );
}
