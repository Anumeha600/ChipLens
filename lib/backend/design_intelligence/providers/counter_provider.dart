import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── CounterProvider ──────────────────────────────────────────────────────────

/// Detects counter registers in the RTL.
///
/// A signal is classified as a counter when:
/// 1. Its name contains a counter keyword (`cnt`, `count`, `counter`, `idx`,
///    `index`) OR it appears in an increment/decrement self-assignment.
/// 2. It is used in `NAME <= NAME + …` (increment) or `NAME <= NAME - …`
///    (decrement).
///
/// Bit-width is derived from the `reg [N:0]` declaration when present.
class CounterProvider implements KnowledgeProvider {
  const CounterProvider();

  @override
  String get providerKey => 'counter';

  // ── Regex ────────────────────────────────────────────────────────────────

  // Counter-named registers: reg [N:0] <counter_name>
  // (?!\w) prevents matching 'reg' as a prefix inside longer identifiers.
  static final _counterDeclRe = RegExp(
    r'\breg(?!\w)\s*(?:\[(\d+):0\])?\s*(\w*(?:cnt|count|counter|idx|index)\w*)',
    caseSensitive: false,
  );

  // All reg declarations — to capture width for signals found via assignment.
  // (?!\w) prevents matching 'reg' as a prefix inside longer identifiers.
  static final _regDeclRe = RegExp(
    r'\breg(?!\w)\s*\[(\d+):0\]\s*(\w+)',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final rtl      = context.rtlSource;
    final counters = <CounterInfo>[];
    final seen     = <String>{};

    // Build a width map from all reg declarations for fast lookup.
    final widths = <String, int>{};
    for (final m in _regDeclRe.allMatches(rtl)) {
      widths[m.group(2)!] = int.parse(m.group(1)!) + 1;
    }

    // ── Pass 1: counter-named registers ─────────────────────────────────────
    for (final m in _counterDeclRe.allMatches(rtl)) {
      final highBit = m.group(1);
      final name    = m.group(2)!;
      if (!seen.add(name)) continue;

      final width   = highBit != null ? int.parse(highBit) + 1 : (widths[name] ?? 1);
      final isIncr  = _hasIncrement(rtl, name);
      final isDecr  = _hasDecrement(rtl, name);

      counters.add(CounterInfo(
        name:        name,
        width:       width,
        isIncrement: isIncr,
        isDecrement: isDecr,
      ));
    }

    // ── Pass 2: any register with a self-increment/decrement assignment ──────
    for (final entry in widths.entries) {
      final name = entry.key;
      if (seen.contains(name)) continue;

      final isIncr = _hasIncrement(rtl, name);
      final isDecr = _hasDecrement(rtl, name);
      if (!isIncr && !isDecr) continue;

      if (seen.add(name)) {
        counters.add(CounterInfo(
          name:        name,
          width:       entry.value,
          isIncrement: isIncr,
          isDecrement: isDecr,
        ));
      }
    }

    return KnowledgeResult(providerKey: providerKey, counters: counters);
  }

  static bool _hasIncrement(String rtl, String name) => RegExp(
    r'\b' + RegExp.escape(name) + r'\s*<=\s*' + RegExp.escape(name) + r'\s*\+',
    caseSensitive: false,
  ).hasMatch(rtl);

  static bool _hasDecrement(String rtl, String name) => RegExp(
    r'\b' + RegExp.escape(name) + r'\s*<=\s*' + RegExp.escape(name) + r'\s*-',
    caseSensitive: false,
  ).hasMatch(rtl);
}
