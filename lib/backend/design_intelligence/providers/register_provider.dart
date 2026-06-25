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

  // All reg declarations: optional packed width, identifier, optional depth.
  // (?!\w) ensures the 'reg' keyword is not matched as a prefix of identifiers
  // like 'regs', 'register', 'reg_data', etc.
  static final _regDeclRe = RegExp(
    r'\breg(?!\w)\s*(?:\[(\d+):\d+\])?\s*(\w+)\s*(?:\[(\d+):(\d+)\])?',
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

  // Port, wire, and logic declarations — used to infer widths for assign
  // targets that have no reg declaration.
  // Matches: (input|output|inout|wire|logic) [reg] [N:M] name
  static final _widthDeclRe = RegExp(
    r'\b(?:input|output|inout|wire|logic)\s+(?:reg\s+)?'
    r'(?:\[(\d+):\d+\])?\s*(\w+)',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final rtl       = context.rtlSource;
    final registers = <RegisterInfo>[];
    final seen      = <String>{};

    final hasSeqBlock = _posedgeBlockRe.hasMatch(rtl);

    // Build width map from port/wire/logic declarations for assign-target
    // width inference.  Only entries with an explicit [N:M] are stored;
    // 1-bit signals fall back to the default width of 1.
    final declaredWidths = <String, int>{};
    for (final m in _widthDeclRe.allMatches(rtl)) {
      final highBit = m.group(1);
      if (highBit != null) {
        declaredWidths[m.group(2)!] = int.parse(highBit) + 1;
      }
    }

    // Collect assign targets — these are combinational regardless of type.
    final combNames = <String>{};
    for (final m in _assignTargetRe.allMatches(rtl)) {
      combNames.add(m.group(1)!);
    }

    // Walk all reg declarations.
    for (final m in _regDeclRe.allMatches(rtl)) {
      final highBit   = m.group(1);
      final name      = m.group(2)!;
      final depthHigh = m.group(3);
      final depthLow  = m.group(4);
      if (!seen.add(name)) continue;

      final width   = highBit != null ? int.parse(highBit) + 1 : 1;
      final isArray = depthHigh != null && depthLow != null;
      final depth   = isArray
          ? (int.parse(depthHigh) - int.parse(depthLow)).abs() + 1
          : 0;
      final isComb  = combNames.contains(name);
      final isSeq   = hasSeqBlock && !isComb;

      registers.add(RegisterInfo(
        name:            name,
        width:           width,
        isSequential:    isSeq,
        isCombinational: isComb,
        isMemoryArray:   isArray,
        depth:           depth,
      ));
    }

    // Emit combinational-only signals from assign that are not declared as reg.
    // Use declared port/wire width when available; default to 1.
    for (final name in combNames) {
      if (seen.contains(name)) continue;
      registers.add(RegisterInfo(
        name:            name,
        width:           declaredWidths[name] ?? 1,
        isSequential:    false,
        isCombinational: true,
      ));
    }

    return KnowledgeResult(providerKey: providerKey, registers: registers);
  }
}
