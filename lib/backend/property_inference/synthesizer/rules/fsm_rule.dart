import '../../semantic/semantic_category.dart';
import '../../semantic/semantic_evidence.dart';
import '../candidate_property.dart';
import '../candidate_property_type.dart';
import '../synthesis_rule.dart';

// ─── FSMRule ──────────────────────────────────────────────────────────────────

/// Synthesises candidate properties from FSM semantic evidence.
///
/// Per FSM:
/// - **Safety invariant** — state register must stay within the known state set.
/// - **Reachability** — every candidate state must be reachable (one per state).
/// - **One-hot invariant (candidate)** — when encoding width equals state count.
///
/// Transition properties are deferred to a future rule.
class FSMRule implements SynthesisRule {
  const FSMRule();

  @override
  bool appliesTo(SemanticEvidence evidence) =>
      evidence.category == SemanticCategory.fsm;

  @override
  List<CandidateProperty> synthesize(SemanticEvidence evidence) {
    final stateReg  = evidence.metadata['stateRegister'] as String? ?? 'state';
    final rawStates = evidence.metadata['candidateStates'];
    final states    = rawStates is List ? rawStates.cast<String>() : <String>[];
    final count     = evidence.metadata['stateCount']    as int? ?? states.length;
    final width     = evidence.metadata['encodingWidth'] as int? ?? 0;

    if (states.isEmpty) return const [];

    final props = <CandidateProperty>[];

    // Safety: legal-state invariant.
    props.add(CandidateProperty(
      id:           'synth.fsm.$stateReg.legal_state',
      title:        'Legal state invariant for $stateReg',
      description:  '$stateReg must only ever hold a value that corresponds '
                    'to one of its $count known states.',
      propertyType: CandidatePropertyType.safetyInvariant,
      evidenceIds:  [evidence.id],
      rationale:    'FSM $stateReg has $count candidate states: ${states.join(', ')}. '
                    'An illegal encoding indicates a control-flow error that could leave '
                    'the design in an undefined operational mode.',
    ));

    // Reachability: one cover point per state.
    for (final state in states) {
      props.add(CandidateProperty(
        id:           'synth.fsm.$stateReg.$state.reachable',
        title:        '$state is reachable in $stateReg',
        description:  'State $state of $stateReg must be reachable from the initial state.',
        propertyType: CandidatePropertyType.reachability,
        evidenceIds:  [evidence.id],
        rationale:    'Every known state of $stateReg should be exercisable in at least '
                      'one valid execution trace. An unreachable state represents dead '
                      'logic or a missing transition.',
        metadata:     {'state': state, 'fsm': stateReg},
      ));
    }

    // One-hot candidate: when encoding width equals state count.
    if (width > 1 && width == count) {
      props.add(CandidateProperty(
        id:           'synth.fsm.$stateReg.one_hot',
        title:        '$stateReg one-hot encoding invariant',
        description:  '$stateReg may use one-hot encoding — exactly one bit set at all times.',
        propertyType: CandidatePropertyType.safetyInvariant,
        evidenceIds:  [evidence.id],
        rationale:    'Encoding width ($width) equals state count ($count), which is '
                      'consistent with one-hot encoding. If confirmed, the invariant '
                      '"exactly one bit set" must hold in every reachable state.',
        metadata:     {'encodingWidth': width, 'stateCount': count},
      ));
    }

    return props;
  }
}
