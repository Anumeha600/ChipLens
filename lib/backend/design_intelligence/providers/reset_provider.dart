import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── ResetProvider ────────────────────────────────────────────────────────────

/// Detects synchronous and asynchronous reset signals.
///
/// **Async** — signal appears alongside a posedge clock in a multi-edge
/// sensitivity list:
/// ```
/// always @(posedge clk or negedge rst_n)   → async, active-low
/// always @(posedge clk or posedge arst)    → async, active-high
/// ```
///
/// **Sync** — signal does NOT appear in any sensitivity list but is tested
/// in an `if` / `if (!...)` condition and its name matches a reset convention:
/// ```
/// always @(posedge clk) begin
///   if (!rst_n) ...    → sync, active-low
///   if (rst)    ...    → sync, active-high
/// ```
class ResetProvider implements KnowledgeProvider {
  const ResetProvider();

  @override
  String get providerKey => 'reset';

  // ── Regex ────────────────────────────────────────────────────────────────

  // Sensitivity list with two edges: always @(posedge CLK or [pos/neg]edge RST)
  static final _asyncSensRe = RegExp(
    r'always\s*@\s*\(\s*posedge\s+\w+\s+or\s+(posedge|negedge)\s+(\w+)\s*\)',
    caseSensitive: false,
  );

  // Active-low check: if (!X) or if (~X)
  static final _syncLowRe = RegExp(
    r'\bif\s*\(\s*[!~]\s*(\w+)\s*\)',
    caseSensitive: false,
  );

  // Active-high check: if (X) where X looks like a reset name
  static final _syncHighRe = RegExp(
    r'\bif\s*\(\s*(\w+)\s*\)',
    caseSensitive: false,
  );

  static final _resetNameRe = RegExp(
    r'^(rst|reset|arst|srst|nrst|rstb|areset|sreset)',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final rtl    = context.rtlSource;
    final resets = <ResetInfo>[];
    final seen   = <String>{};

    // ── Pass 1: async resets from multi-edge sensitivity lists ──────────────
    for (final m in _asyncSensRe.allMatches(rtl)) {
      final edge = m.group(1)!.toLowerCase();
      final name = m.group(2)!;
      if (seen.add(name)) {
        resets.add(ResetInfo(
          name:           name,
          isAsynchronous: true,
          isSynchronous:  false,
          isActiveHigh:   edge == 'posedge',
          isActiveLow:    edge == 'negedge',
        ));
      }
    }

    // ── Pass 2: sync active-low  — if (!X) or if (~X) ──────────────────────
    for (final m in _syncLowRe.allMatches(rtl)) {
      final name = m.group(1)!;
      if (seen.contains(name)) continue;          // already captured as async
      if (!_resetNameRe.hasMatch(name)) continue; // not a reset-like name
      if (seen.add(name)) {
        resets.add(ResetInfo(
          name:          name,
          isSynchronous: true,
          isAsynchronous: false,
          isActiveHigh:  false,
          isActiveLow:   true,
        ));
      }
    }

    // ── Pass 3: sync active-high — if (rst / reset / …) ────────────────────
    for (final m in _syncHighRe.allMatches(rtl)) {
      final name = m.group(1)!;
      if (seen.contains(name)) continue;
      if (!_resetNameRe.hasMatch(name)) continue;
      if (seen.add(name)) {
        resets.add(ResetInfo(
          name:          name,
          isSynchronous: true,
          isAsynchronous: false,
          isActiveHigh:  true,
          isActiveLow:   false,
        ));
      }
    }

    return KnowledgeResult(providerKey: providerKey, resets: resets);
  }
}
