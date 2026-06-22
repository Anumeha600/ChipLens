import '../semantic/semantic_evidence_set.dart';
import 'candidate_property.dart';
import 'candidate_property_set.dart';
import 'rules/counter_rule.dart';
import 'rules/fsm_rule.dart';
import 'rules/handshake_rule.dart';
import 'rules/register_rule.dart';
import 'rules/reset_rule.dart';
import 'synthesis_rule.dart';

// ─── PropertySynthesizer ──────────────────────────────────────────────────────

/// Coordinates rule-based synthesis of [CandidateProperty] objects from a
/// [SemanticEvidenceSet].
///
/// This class has **no dependencies** on:
/// - DesignKnowledge
/// - RTL parsers
/// - Formal Framework
/// - Repair Framework
/// - Verification Framework
/// - Flutter / UI
///
/// It may only consume [SemanticEvidenceSet] and [SynthesisRule] instances.
///
/// Synthesis is:
/// - **Synchronous** — the evidence model is pure data; no I/O required.
/// - **Deterministic** — same input evidence produces same output, in order.
/// - **Non-ranking** — ranking, scoring, and prioritisation are deferred to
///   a future layer (Task 1C / PropertyRanking).
/// - **Non-emitting** — [CandidateProperty.expression] is always `null` here;
///   formal expression generation belongs to the emitter layer.
abstract class PropertySynthesizer {
  PropertySynthesizer._();

  static const List<SynthesisRule> _defaultRules = [
    FSMRule(),
    CounterRule(),
    ResetRule(),
    HandshakeRule(),
    RegisterRule(),
  ];

  /// Synthesises candidate verification properties from [evidence].
  ///
  /// Each [SemanticEvidence] item is offered to every applicable rule.  Results
  /// are merged and deduplicated by [CandidateProperty.id] before returning.
  ///
  /// Pass a custom [rules] list to run a subset or inject test doubles.
  static CandidatePropertySet synthesize(
    SemanticEvidenceSet evidence, {
    List<SynthesisRule>? rules,
  }) {
    final rs    = rules ?? _defaultRules;
    final items = <CandidateProperty>[];

    for (final e in evidence.items) {
      for (final rule in rs) {
        if (rule.appliesTo(e)) {
          items.addAll(rule.synthesize(e));
        }
      }
    }

    return CandidatePropertySet(items).deduplicate();
  }
}
