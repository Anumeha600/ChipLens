import '../design_context.dart';
import '../knowledge_models.dart';
import '../knowledge_provider.dart';
import '../knowledge_result.dart';

// ─── HandshakeProvider ────────────────────────────────────────────────────────

/// Detects common handshake / flow-control protocol pairs by matching signal
/// name patterns — no hardcoded protocol names are required.
///
/// Supported heuristics (in priority order):
/// | Pair detected                          | `protocolHint`    |
/// |----------------------------------------|-------------------|
/// | `*valid*` + `*ready*` (or `*vld*/*rdy*`) | `'valid_ready'`  |
/// | `*req*` + `*ack*`                       | `'req_ack'`       |
/// | `*start*` + `*done*`                    | `'start_done'`    |
/// | `*en*` + `*done*`                       | `'enable_done'`   |
///
/// Each detected pair produces one [HandshakeInfo].  Multiple protocols in
/// the same module each produce a separate [HandshakeInfo].
class HandshakeProvider implements KnowledgeProvider {
  const HandshakeProvider();

  @override
  String get providerKey => 'handshake';

  // ── Regex ────────────────────────────────────────────────────────────────

  // Collect all signal names from port and reg/wire declarations.
  static final _signalDeclRe = RegExp(
    r'\b(?:input|output|inout|wire|reg)\s*(?:reg\s*)?(?:\[\d+:\d+\]\s*)?(\w+)',
    caseSensitive: false,
  );

  // ── Analysis ─────────────────────────────────────────────────────────────

  @override
  Future<KnowledgeResult> analyze(DesignContext context) async {
    final signals = _collectSignalNames(context.rtlSource);
    final infos   = <HandshakeInfo>[];

    _detect(
      signals:       signals,
      sideA:         (n) => n.contains('valid') || n.contains('vld'),
      sideB:         (n) => n.contains('ready') || n.contains('rdy'),
      protocolHint:  'valid_ready',
      results:       infos,
    );

    _detect(
      signals:       signals,
      sideA:         (n) => n.contains('req'),
      sideB:         (n) => n.contains('ack'),
      protocolHint:  'req_ack',
      results:       infos,
    );

    _detect(
      signals:       signals,
      sideA:         (n) => n.contains('start'),
      sideB:         (n) => n.contains('done'),
      protocolHint:  'start_done',
      results:       infos,
    );

    // 'enable_done' only when there is no stronger match already (avoid double-
    // reporting modules that have both start+done and en+done).
    final alreadyHasDone = infos.any((h) => h.protocolHint == 'start_done');
    if (!alreadyHasDone) {
      _detect(
        signals:       signals,
        sideA:         (n) => n == 'en' || n.endsWith('_en') || n.startsWith('en_'),
        sideB:         (n) => n.contains('done'),
        protocolHint:  'enable_done',
        results:       infos,
      );
    }

    return KnowledgeResult(providerKey: providerKey, handshakes: infos);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<String> _collectSignalNames(String rtl) {
    final names = <String>{};
    for (final m in _signalDeclRe.allMatches(rtl)) {
      names.add(m.group(1)!);
    }
    return names.toList();
  }

  static void _detect({
    required List<String> signals,
    required bool Function(String) sideA,
    required bool Function(String) sideB,
    required String protocolHint,
    required List<HandshakeInfo> results,
  }) {
    final lower  = signals.map((s) => s.toLowerCase()).toList();
    final aNames = [
      for (var i = 0; i < signals.length; i++)
        if (sideA(lower[i])) signals[i]
    ];
    final bNames = [
      for (var i = 0; i < signals.length; i++)
        if (sideB(lower[i])) signals[i]
    ];

    if (aNames.isNotEmpty && bNames.isNotEmpty) {
      results.add(HandshakeInfo(
        signals:      [...aNames, ...bNames],
        protocolHint: protocolHint,
      ));
    }
  }
}
