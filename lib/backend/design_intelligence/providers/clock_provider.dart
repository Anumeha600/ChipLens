import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── ClockProvider ────────────────────────────────────────────────────────────

/// Detects clock signals by scanning `posedge` triggers in always-block
/// sensitivity lists.
///
/// Classification:
/// - **Primary** — name exactly matches one of the recognised clock names.
/// - **Candidate** — appears in a posedge trigger but name is non-standard.
/// - **Generated** — reserved for future derived-clock inference (always false).
///
/// **Supported primary clock naming conventions:**
///
/// | Convention | Examples | Notes |
/// |-----------|---------|-------|
/// | Bare name | `clk`, `clock` | Most common |
/// | Prefixed bare | `sys_clk`, `ref_clk`, `pclk`, `aclk`, `hclk`, `mclk`, `sclk`, `osc_clk` | Original set |
/// | Direction prefix | `i_clk`, `i_clock` | ZipCPU / AXI convention |
/// | Direction suffix | `clk_i`, `clock_i` | AMBA / lowRISC convention |
/// | Domain-qualified | `core_clk`, `system_clock` | Common in SoC designs |
class ClockProvider implements KnowledgeProvider {
  const ClockProvider();

  @override
  String get providerKey => 'clock';

  // ── Regex ────────────────────────────────────────────────────────────────

  // Matches any posedge signal, whether inside a sensitivity list or expression.
  static final _posedgeRe = RegExp(r'\bposedge\s+(\w+)', caseSensitive: false);

  // Primary clock name: must exactly match one of the recognised clock names.
  // Names are anchored at start and end to avoid matching e.g. "fast_clk"
  // as a primary clock via partial prefix overlap.
  static final _primaryRe = RegExp(
    r'^(clk|clock|sys_clk|ref_clk|pclk|aclk|hclk|mclk|sclk|osc_clk'
    r'|i_clk|clk_i|clock_i|i_clock|core_clk|system_clock)$',
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
