import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── ClockProvider ────────────────────────────────────────────────────────────

/// Detects clock signals by scanning `posedge` triggers in always-block
/// sensitivity lists.
///
/// Classification:
/// - **Primary** — name starts with a well-known clock prefix
///   (`clk`, `clock`, `sys_clk`, `pclk`, `aclk`, `hclk`, `mclk`, `sclk`).
/// - **Candidate** — appears in a posedge trigger but name is non-standard.
/// - **Generated** — reserved for future derived-clock inference (always false).
class ClockProvider implements KnowledgeProvider {
  const ClockProvider();

  @override
  String get providerKey => 'clock';

  // ── Regex ────────────────────────────────────────────────────────────────

  // Matches any posedge signal, whether inside a sensitivity list or expression.
  static final _posedgeRe = RegExp(r'\bposedge\s+(\w+)', caseSensitive: false);

  // Primary clock name: must start with one of the well-known prefixes.
  static final _primaryRe = RegExp(
    r'^(clk|clock|sys_clk|ref_clk|pclk|aclk|hclk|mclk|sclk|osc_clk)',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final seen   = <String, ClockInfo>{};

    for (final m in _posedgeRe.allMatches(context.rtlSource)) {
      final name = m.group(1)!;
      if (seen.containsKey(name)) continue;

      final isPrimary = _primaryRe.hasMatch(name);
      seen[name] = ClockInfo(
        name:           name,
        isPrimaryClock: isPrimary,
        isCandidate:    !isPrimary,
        isGenerated:    false,
      );
    }

    return KnowledgeResult(providerKey: providerKey, clocks: seen.values.toList());
  }
}
