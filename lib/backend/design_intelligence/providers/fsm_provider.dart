import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── FSMProvider ──────────────────────────────────────────────────────────────

/// Detects Finite State Machines in the RTL.
///
/// **Fast path** — if [DesignContext.parsedIr] contains a `'states'` list
/// (e.g. pre-computed by `LocalFsmExtractor.extract()`), the result is read
/// directly from there.
///
/// **Heuristic fallback** — scans the RTL source for:
/// - `reg [N:0] <name containing "state">` → state register + encoding width.
/// - `localparam` definitions → candidate state names.
///
/// No transition inference is performed.
class FSMProvider implements KnowledgeProvider {
  const FSMProvider();

  @override
  String get providerKey => 'fsm';

  // ── Regex ────────────────────────────────────────────────────────────────

  // State register: reg [N:0] <something with "state" in the name>
  static final _stateRegRe = RegExp(
    r'\breg\s*(?:\[(\d+):\d+\])?\s*(\w*state\w*)',
    caseSensitive: false,
  );

  // localparam STATE_NAME = …
  static final _localparamRe = RegExp(
    r'\blocalparam\s+(?:\[\d+:\d+\]\s*)?(\w+)\s*=',
    caseSensitive: false,
  );

  // parameter STATE_NAME = …
  static final _paramRe = RegExp(
    r'\bparameter\s+(?:\w+\s+)?(\w+)\s*=\s*\d',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    // Fast path: pre-computed IR from LocalFsmExtractor or equivalent.
    final ir = context.parsedIr;
    if (ir != null) {
      final states = (ir['states'] as List?)?.cast<String>() ?? [];
      if (states.isNotEmpty) {
        return KnowledgeResult(
          providerKey: providerKey,
          fsms: [
            FSMInfo(
              stateRegister:  ir['stateRegister'] as String? ?? 'state',
              encodingWidth:  ir['encodingWidth']  as int?    ?? 0,
              candidateStates: states,
              encodingStyle:  ir['encodingStyle'] as String? ?? 'unknown',
            ),
          ],
        );
      }
    }

    // Heuristic fallback: scan RTL source.
    return _analyzeSource(context.rtlSource);
  }

  static KnowledgeResult _analyzeSource(String rtl) {
    final fsms = <FSMInfo>[];

    for (final m in _stateRegRe.allMatches(rtl)) {
      final highBit = m.group(1);
      final width   = highBit != null ? int.parse(highBit) + 1 : 1;
      final regName = m.group(2)!;

      // Collect candidate state names from localparam / parameter definitions.
      final candidates = <String>[];
      for (final lp in _localparamRe.allMatches(rtl)) {
        candidates.add(lp.group(1)!);
      }
      if (candidates.isEmpty) {
        for (final p in _paramRe.allMatches(rtl)) {
          candidates.add(p.group(1)!);
        }
      }

      final style = candidates.isNotEmpty ? 'localparam' : 'none';

      fsms.add(FSMInfo(
        stateRegister:   regName,
        encodingWidth:   width,
        candidateStates: candidates,
        encodingStyle:   style,
      ));
    }

    return KnowledgeResult(providerKey: 'fsm', fsms: fsms);
  }
}
