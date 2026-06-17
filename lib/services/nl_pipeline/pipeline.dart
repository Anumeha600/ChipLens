// Local NL-to-RTL pipeline — orchestrates all stages.
// Call LocalPipeline.run(description) from a Future/isolate.

import '../../models/design_spec.dart';
import 'intent_extractor.dart';
import 'fsm_builder.dart';
import 'rtl_generator.dart';
import 'testbench_generator.dart';
import 'quality_analyzer.dart';
import 'explanation_engine.dart';

class LocalPipeline {
  /// Runs all pipeline stages synchronously and returns a [DesignResult].
  /// Wrap in Future.microtask() in the UI layer to avoid blocking the frame.
  static DesignResult run(String description) {
    // Stage 1 — intent extraction
    final intent = IntentExtractor.extract(description);

    // Stage 2 — FSM / DesignSpecification construction
    final spec = FsmBuilder.build(intent);

    // Stage 3 — RTL generation
    final rtl = RtlGenerator.generate(spec);

    // Stage 4 — testbench generation
    final testbench = TestbenchGenerator.generate(spec);

    // Stage 5 — quality analysis
    final quality = QualityAnalyzer.analyze(rtl, spec);

    // Stage 6 — engineering explanation
    final explanation = ExplanationEngine.explain(spec, quality);

    // Build FSM edge list for the canvas painter
    final fsmEdges = spec.transitions
        .map((t) => <String, dynamic>{
              'from': t.from,
              'to': t.to,
              'label': t.condition,
            })
        .toList();

    // Identify dead / unreachable states
    final reachable = _reachableStates(spec);
    final allStates  = spec.states.map((s) => s.name).toList();
    final unreachable = allStates.where((s) => !reachable.contains(s)).toList();

    final hasOutgoing = spec.transitions.map((t) => t.from).toSet();
    final dead = allStates.where((s) => !hasOutgoing.contains(s)).toList();

    return DesignResult(
      spec: spec,
      rtl: rtl,
      testbench: testbench,
      explanation: explanation,
      quality: quality,
      fsmStates: allStates,
      fsmEdges: fsmEdges,
      fsmEntryState: spec.entryState,
      fsmDeadStates: dead,
      fsmUnreachableStates: unreachable,
    );
  }

  /// BFS from entry state to find all reachable states.
  static Set<String> _reachableStates(DesignSpecification spec) {
    final adj = <String, List<String>>{};
    for (final t in spec.transitions) {
      adj.putIfAbsent(t.from, () => []).add(t.to);
    }
    final visited = <String>{};
    final queue   = [spec.entryState];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (visited.contains(cur)) continue;
      visited.add(cur);
      queue.addAll(adj[cur] ?? []);
    }
    return visited;
  }
}
