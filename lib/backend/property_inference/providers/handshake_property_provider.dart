import '../../formal/formal_property.dart';
import '../../formal/formal_property_type.dart';
import '../property_context.dart';
import '../property_models.dart';
import '../property_provider.dart';
import '../property_result.dart';

// ─── HandshakePropertyProvider ────────────────────────────────────────────────

/// Infers formal properties from handshake pairs in [DesignKnowledge].
///
/// Protocol dispatch is driven by [HandshakeInfo.protocolHint]:
///
/// | Hint           | Property inferred                                  |
/// |----------------|----------------------------------------------------|
/// | `valid_ready`  | valid must remain stable while ready is deasserted |
/// | `req_ack`      | req must remain stable while ack is deasserted     |
/// | `start_done`   | done must eventually follow start (liveness)       |
/// | `enable_done`  | enable stable until done acknowledges              |
/// | anything else  | skipped                                            |
class HandshakePropertyProvider implements PropertyProvider {
  const HandshakePropertyProvider();

  @override
  String get providerKey => 'handshake';

  @override
  Future<PropertyResult> infer(PropertyContext context) async {
    final dk = context.knowledge;
    if (dk.handshakes.isEmpty) return PropertyResult.empty(providerKey);

    final props = <FormalProperty>[];

    for (final hs in dk.handshakes) {
      final lowerSignals = hs.signals.map((s) => s.toLowerCase()).toList();

      switch (hs.protocolHint) {
        case 'valid_ready':
          final valid = _pick(hs.signals, lowerSignals,
              (s) => s.contains('valid') || s.contains('vld'));
          final ready = _pick(hs.signals, lowerSignals,
              (s) => s.contains('ready') || s.contains('rdy'));
          props.add(FormalProperty(
            id:           '${PropertyIdPrefix.handshake}.${valid}_$ready.stability',
            name:         '$valid stable until $ready',
            description:  'Once $valid is asserted it must remain stable until $ready acknowledges.',
            propertyType: FormalPropertyType.assertion,
            severity:     'error',
            expression:   '$valid && !$ready |-> next(\$stable($valid))',
            metadata: {
              'confidence': PropertyConfidence.definite.name,
              'protocol':   'valid_ready',
              'valid':      valid,
              'ready':      ready,
            },
          ));

        case 'req_ack':
          final req = _pick(hs.signals, lowerSignals,
              (s) => s.contains('req'));
          final ack = _pick(hs.signals, lowerSignals,
              (s) => s.contains('ack'));
          props.add(FormalProperty(
            id:           '${PropertyIdPrefix.handshake}.${req}_$ack.stability',
            name:         '$req stable until $ack',
            description:  'Once $req is asserted it must remain stable until $ack is received.',
            propertyType: FormalPropertyType.assertion,
            severity:     'error',
            expression:   '$req && !$ack |-> next(\$stable($req))',
            metadata: {
              'confidence': PropertyConfidence.definite.name,
              'protocol':   'req_ack',
              'req':        req,
              'ack':        ack,
            },
          ));

        case 'start_done':
          final start = _pick(hs.signals, lowerSignals,
              (s) => s.contains('start'));
          final done  = _pick(hs.signals, lowerSignals,
              (s) => s.contains('done'));
          props.add(FormalProperty(
            id:           '${PropertyIdPrefix.handshake}.${start}_$done.completion',
            name:         '$done eventually follows $start',
            description:  'After $start is asserted, $done must eventually be observed.',
            propertyType: FormalPropertyType.liveness,
            severity:     'warning',
            expression:   '$start |-> eventually($done)',
            metadata: {
              'confidence': PropertyConfidence.likely.name,
              'protocol':   'start_done',
              'start':      start,
              'done':       done,
            },
          ));

        case 'enable_done':
          final en   = _pick(hs.signals, lowerSignals,
              (s) => s.contains('en') && !s.contains('done'));
          final done = _pick(hs.signals, lowerSignals,
              (s) => s.contains('done'));
          props.add(FormalProperty(
            id:           '${PropertyIdPrefix.handshake}.${en}_$done.stability',
            name:         '$en stable until $done',
            description:  'Once $en is asserted it must remain stable until $done.',
            propertyType: FormalPropertyType.assertion,
            severity:     'warning',
            expression:   '$en && !$done |-> next(\$stable($en))',
            metadata: {
              'confidence': PropertyConfidence.likely.name,
              'protocol':   'enable_done',
              'enable':     en,
              'done':       done,
            },
          ));
      }
    }

    return PropertyResult(providerKey: providerKey, properties: props);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _pick(
    List<String> signals,
    List<String> lower,
    bool Function(String) predicate,
  ) {
    for (var i = 0; i < lower.length; i++) {
      if (predicate(lower[i])) return signals[i];
    }
    return signals.isNotEmpty ? signals.first : '';
  }
}
