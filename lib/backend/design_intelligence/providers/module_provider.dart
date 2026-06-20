import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── ModuleProvider ───────────────────────────────────────────────────────────

/// Detects module declarations, their ports, and their parameters.
///
/// Extracted information:
/// - Module name from `module NAME(…)`.
/// - `input` / `output` / `inout` ports with optional bit-width.
/// - `parameter` declarations.
/// - Sub-module instance names (future hierarchy; currently empty).
class ModuleProvider implements KnowledgeProvider {
  const ModuleProvider();

  @override
  String get providerKey => 'module';

  // ── Regex ────────────────────────────────────────────────────────────────

  // module NAME
  static final _moduleRe = RegExp(r'\bmodule\s+(\w+)', caseSensitive: false);

  // Port declaration:
  //   (input|output|inout) [reg] [optional_range] port_name
  //
  // Two alternatives inside the optional range group:
  //   • Numeric:      \[(\d+):(\d+)\]   → groups 2 & 3 hold the bit indices
  //   • Parameterised: \[[^\]]*\]        → consumed but not captured (width=1)
  //
  // This lets [WIDTH-1:0] be skipped without stopping capture of the name.
  static final _portRe = RegExp(
    r'\b(input|output|inout)\s+(?:reg\s+)?'
    r'(?:\[(\d+):(\d+)\]|\[[^\]]*\])?\s*(\w+)',
    caseSensitive: false,
  );

  // parameter [type] NAME = VALUE
  static final _paramRe = RegExp(
    r'\bparameter\s+(?:\w+\s+)?(\w+)\s*=\s*(\w+)',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final rtl     = context.rtlSource;
    final modules = <ModuleInfo>[];

    for (final mm in _moduleRe.allMatches(rtl)) {
      final name   = mm.group(1)!;
      final ports  = <PortInfo>[];
      final params = <String, String>{};

      for (final pm in _portRe.allMatches(rtl)) {
        final dir     = pm.group(1)!.toLowerCase();
        final highStr = pm.group(2);
        final lowStr  = pm.group(3);
        final pName   = pm.group(4)!;

        final width = (highStr != null && lowStr != null)
            ? int.parse(highStr) - int.parse(lowStr) + 1
            : 1;

        ports.add(PortInfo(name: pName, direction: dir, width: width));
      }

      for (final p in _paramRe.allMatches(rtl)) {
        params[p.group(1)!] = p.group(2)!;
      }

      modules.add(ModuleInfo(name: name, ports: ports, parameters: params));
    }

    return KnowledgeResult(providerKey: providerKey, modules: modules);
  }
}
