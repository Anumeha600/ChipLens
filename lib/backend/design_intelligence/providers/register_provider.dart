import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── RegisterProvider ─────────────────────────────────────────────────────────

/// Detects data registers and combinational signals.
///
/// **Sequential** — `reg` declarations in an RTL that contains at least one
/// posedge-clocked always block.  Every `reg` in such a module is presumed
/// sequential unless it also appears as an `assign` target.
///
/// **Combinational** — signals that appear on the left-hand side of
/// continuous `assign` statements.
///
/// Note: this is a structural heuristic.  Signals shared with other providers
/// (state registers, counters) are not filtered out here — consumers can apply
/// their own domain-specific deduplication against the relevant provider lists.
class RegisterProvider implements KnowledgeProvider {
  const RegisterProvider();

  @override
  String get providerKey => 'register';

  // ── Regex ────────────────────────────────────────────────────────────────

  // All reg declarations with optional bit-width.
  static final _regDeclRe = RegExp(
    r'\breg\s*(?:\[(\d+):\d+\])?\s*(\w+)',
    caseSensitive: false,
  );

  // assign <target> = …  — continuous assignment (combinational)
  static final _assignTargetRe = RegExp(
    r'\bassign\s+(\w+)\s*=',
    caseSensitive: false,
  );

  // always @(posedge …) → the module has a clocked domain
  static final _posedgeBlockRe = RegExp(
    r'\balways\s*@\s*\(\s*posedge',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final rtl         = context.rtlSource;
    final registers   = <RegisterInfo>[];
    final seen        = <String>{};

    final hasSeqBlock = _posedgeBlockRe.hasMatch(rtl);

    // Collect assign targets — these are combinational regardless of type.
    final combNames = <String>{};
    for (final m in _assignTargetRe.allMatches(rtl)) {
      combNames.add(m.group(1)!);
    }

    // Walk all reg declarations.
    for (final m in _regDeclRe.allMatches(rtl)) {
      final highBit      = m.group(1);
      final name         = m.group(2)!;
      if (!seen.add(name)) continue;

      final width        = highBit != null ? int.parse(highBit) + 1 : 1;
      final isComb       = combNames.contains(name);
      final isSeq        = hasSeqBlock && !isComb;

      registers.add(RegisterInfo(
        name:            name,
        width:           width,
        isSequential:    isSeq,
        isCombinational: isComb,
      ));
    }

    // Emit combinational-only signals from assign that are not declared as reg.
    for (final name in combNames) {
      if (seen.contains(name)) continue;
      registers.add(RegisterInfo(
        name:            name,
        width:           1,
        isSequential:    false,
        isCombinational: true,
      ));
    }

    return KnowledgeResult(providerKey: providerKey, registers: registers);
  }
}
