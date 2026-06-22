import '../../semantic/semantic_category.dart';
import '../../semantic/semantic_evidence.dart';
import '../candidate_property.dart';
import '../candidate_property_type.dart';
import '../synthesis_rule.dart';

// ─── HandshakeRule ────────────────────────────────────────────────────────────

/// Synthesises candidate properties from handshake semantic evidence.
///
/// Per handshake:
/// - **Stability** — initiating signal remains stable while awaiting acknowledgement.
/// - **Liveness** — protocol must eventually complete (deadlock prevention).
class HandshakeRule implements SynthesisRule {
  const HandshakeRule();

  @override
  bool appliesTo(SemanticEvidence evidence) =>
      evidence.category == SemanticCategory.handshake;

  @override
  List<CandidateProperty> synthesize(SemanticEvidence evidence) {
    final hint    = evidence.metadata['protocolHint'] as String? ?? 'unknown';
    final rawSigs = evidence.metadata['signals'];
    final signals = rawSigs is List ? rawSigs.cast<String>() : <String>[];

    if (signals.isEmpty) return const [];

    final primary  = signals.first;
    final sigList  = signals.join(', ');

    return [
      // Stability: initiator holds until acknowledged.
      CandidateProperty(
        id:           'synth.handshake.$hint.$primary.stability',
        title:        '$primary stable while awaiting acknowledgement',
        description:  '$primary must remain stable until the acknowledging '
                      'signal in the "$hint" protocol responds.',
        propertyType: CandidatePropertyType.stability,
        evidenceIds:  [evidence.id],
        rationale:    'The "$hint" protocol requires the initiating signal '
                      'to hold its assertion stable until acknowledged. '
                      'Changing $primary before acknowledgement constitutes '
                      'a protocol violation and may corrupt the transaction.',
        metadata:     {'protocol': hint, 'primarySignal': primary},
      ),

      // Liveness: transaction must eventually complete.
      CandidateProperty(
        id:           'synth.handshake.$hint.$primary.completion',
        title:        '"$hint" transaction eventually completes',
        description:  'A transaction initiated on $primary must eventually '
                      'receive its acknowledgement signal.',
        propertyType: CandidatePropertyType.livenessCondition,
        evidenceIds:  [evidence.id],
        rationale:    'Deadlock prevention: the "$hint" handshake involving '
                      '$sigList must always complete within a bounded number '
                      'of cycles. An acknowledgement that never arrives blocks '
                      'all downstream logic waiting on this transaction.',
        metadata:     {'protocol': hint, 'signals': signals},
      ),
    ];
  }
}
