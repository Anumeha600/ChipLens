import '../../synthesizer/candidate_property_type.dart';

// ─── PropertyTypeScore ────────────────────────────────────────────────────────

/// Assigns a priority weight in [0.0, 1.0] to each [CandidatePropertyType].
///
/// Safety invariants rank highest — a violated safety property can cause
/// immediate hardware failure.  Assumptions rank lowest because they constrain
/// the input space rather than checking design behaviour.
///
/// Stateless and const-constructible — safe to share as a singleton.
class PropertyTypeScore {
  const PropertyTypeScore();

  static const Map<CandidatePropertyType, double> _weights = {
    CandidatePropertyType.safetyInvariant:   1.0,
    CandidatePropertyType.livenessCondition: 0.9,
    CandidatePropertyType.boundedness:       0.8,
    CandidatePropertyType.reachability:      0.7,
    CandidatePropertyType.stability:         0.6,
    CandidatePropertyType.assumption:        0.5,
    CandidatePropertyType.custom:            0.3,
  };

  ({double score, String explanation}) compute(CandidatePropertyType type) {
    final score = _weights[type] ?? 0.3;
    return (
      score: score,
      explanation: '${type.name} has priority weight ${score.toStringAsFixed(2)}',
    );
  }
}
