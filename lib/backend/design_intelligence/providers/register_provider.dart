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
/// continuous `assign` statements, including concatenation assigns
/// (`assign {a, b} = …`).
///
/// Note: this is a structural heuristic.  Signals shared with other providers
/// (state registers, counters) are not filtered out here — consumers can apply
/// their own domain-specific deduplication against the relevant provider lists.
class RegisterProvider implements KnowledgeProvider {
  const RegisterProvider();

  @override
  String get providerKey => 'register';

  // ── Regex ────────────────────────────────────────────────────────────────

  // All reg declarations.  Capture groups:
  //   1: numeric packed-width high bit  — null when no numeric width bracket
  //   2: symbolic packed-width expr     — non-null for e.g. [B:0], [WIDTH-1:0]
  //   3: identifier name
  //   4: numeric depth high index       — null when no numeric depth bracket
  //   5: numeric depth low index        — null when no numeric depth bracket
  //   6: symbolic depth expr            — non-null for e.g. [DEPTH-1:0]
  //
  // (?!\w) prevents matching 'reg' as a prefix inside longer identifiers
  // such as 'regs', 'register', 'reg_data', etc.
  static final _regDeclRe = RegExp(
    r'\breg(?!\w)\s*'
    r'(?:\[(\d+):\d+\]|\[([^\]]*)\])?\s*'
    r'(\w+)\s*'
    r'(?:\[(\d+):(\d+)\]|\[([^\]]*)\])?',
    caseSensitive: false,
  );

  // assign <target> = …  — continuous assignment (combinational)
  static final _assignTargetRe = RegExp(
    r'\bassign\s+(\w+)\s*=',
    caseSensitive: false,
  );

  // assign {a, b, …} = …  — concatenation assign
  static final _assignConcatRe = RegExp(
    r'\bassign\s+\{([^}]+)\}\s*=',
    caseSensitive: false,
  );

  // Identifier (starting with letter/underscore) for concat content extraction
  static final _identInConcatRe = RegExp(r'\b([a-zA-Z_]\w*)\b');

  // always @(posedge …) → the module has a clocked domain
  static final _posedgeBlockRe = RegExp(
    r'\balways\s*@\s*\(\s*posedge',
    caseSensitive: false,
  );

  // Port, wire, and logic declarations — used to infer widths for assign
  // targets that have no reg declaration.  Capture groups:
  //   1: numeric high bit  — null when no numeric bracket
  //   2: symbolic expr     — non-null for e.g. [B:0], [WIDTH-1:0]
  //   3: signal name
  static final _widthDeclRe = RegExp(
    r'\b(?:input|output|inout|wire|logic)\s+(?:(?:wire|reg)\s+)?'
    r'(?:\[(\d+):\d+\]|\[([^\]]*)\])?\s*(\w+)',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final rtl       = context.rtlSource;
    final registers = <RegisterInfo>[];
    final seen      = <String>{};

    final hasSeqBlock = _posedgeBlockRe.hasMatch(rtl);

    // Build width map and symbolic-width set from port/wire/logic declarations.
    // Only numeric brackets are stored in declaredWidths; symbolic bracket
    // declarations are tracked in symbolicallyWide so widthIsKnown can be set
    // correctly on assign-target signals.
    final declaredWidths   = <String, int>{};
    final symbolicallyWide = <String>{};
    for (final m in _widthDeclRe.allMatches(rtl)) {
      final numHighBit = m.group(1);
      final symExpr    = m.group(2);
      final sigName    = m.group(3)!;
      if (numHighBit != null) {
        declaredWidths[sigName] = int.parse(numHighBit) + 1;
      } else if (symExpr != null) {
        symbolicallyWide.add(sigName);
      }
    }

    // Collect simple assign targets (combinational signals).
    final combNames = <String>{};
    for (final m in _assignTargetRe.allMatches(rtl)) {
      combNames.add(m.group(1)!);
    }

    // Collect concatenation assign targets, e.g. assign {carry, result} = …
    for (final m in _assignConcatRe.allMatches(rtl)) {
      for (final id in _identInConcatRe.allMatches(m.group(1)!)) {
        combNames.add(id.group(1)!);
      }
    }

    // Walk all reg declarations.
    for (final m in _regDeclRe.allMatches(rtl)) {
      final numHighBit = m.group(1);
      final symWidth   = m.group(2);
      final name       = m.group(3)!;
      final depthHigh  = m.group(4);
      final depthLow   = m.group(5);
      final symDepth   = m.group(6);
      if (!seen.add(name)) continue;

      final width        = numHighBit != null ? int.parse(numHighBit) + 1 : 1;
      // widthIsKnown: true for numeric bracket or no bracket (1-bit scalar);
      //               false only when a symbolic parameter expression is present.
      final widthIsKnown = numHighBit != null || symWidth == null;
      final isArray      = depthHigh != null || symDepth != null;
      // depthIsKnown: false only when a symbolic depth expression is present.
      final depthIsKnown = symDepth == null;
      final depth        = (depthHigh != null && depthLow != null)
          ? (int.parse(depthHigh) - int.parse(depthLow)).abs() + 1
          : 0;
      final isComb = combNames.contains(name);
      final isSeq  = hasSeqBlock && !isComb;

      registers.add(RegisterInfo(
        name:            name,
        width:           width,
        isSequential:    isSeq,
        isCombinational: isComb,
        isMemoryArray:   isArray,
        depth:           depth,
        widthIsKnown:    widthIsKnown,
        depthIsKnown:    depthIsKnown,
      ));
    }

    // Emit combinational-only signals from assign that are not declared as reg.
    // Use declared port/wire width when available.  For symbolically-typed
    // signals, width defaults to 1 and widthIsKnown is false.
    for (final name in combNames) {
      if (seen.contains(name)) continue;
      registers.add(RegisterInfo(
        name:            name,
        width:           declaredWidths[name] ?? 1,
        isSequential:    false,
        isCombinational: true,
        widthIsKnown:    !symbolicallyWide.contains(name),
      ));
    }

    return KnowledgeResult(providerKey: providerKey, registers: registers);
  }
}
