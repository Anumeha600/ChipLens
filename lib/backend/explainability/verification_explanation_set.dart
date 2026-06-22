import 'verification_explanation.dart';

// ─── VerificationExplanationSet ───────────────────────────────────────────────

/// Immutable ordered collection of [VerificationExplanation] objects.
///
/// Produced by [VerificationExplainer.explain] with one explanation per
/// [FormalProperty], in the same order as the input [FormalPropertySet].
///
/// All structural methods return new instances; the original is never modified.
class VerificationExplanationSet {
  final List<VerificationExplanation> _explanations;

  VerificationExplanationSet([List<VerificationExplanation>? explanations])
      : _explanations =
            List.unmodifiable(List.of(explanations ?? const []));

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Unmodifiable ordered view of all explanations.
  List<VerificationExplanation> get explanations => _explanations;

  /// Number of explanations in the set.
  int get length => _explanations.length;

  bool get isEmpty    => _explanations.isEmpty;
  bool get isNotEmpty => _explanations.isNotEmpty;

  /// Returns the explanation at [index].
  ///
  /// Throws [RangeError] when [index] is out of bounds.
  VerificationExplanation operator [](int index) => _explanations[index];

  // ── Lookup / filtering ────────────────────────────────────────────────────

  /// Returns the explanation for [propertyId], or `null` if not found.
  VerificationExplanation? findById(String propertyId) {
    for (final e in _explanations) {
      if (e.propertyId == propertyId) return e;
    }
    return null;
  }

  /// Returns a new set containing only explanations that satisfy [predicate].
  VerificationExplanationSet filter(
      bool Function(VerificationExplanation) predicate) =>
      VerificationExplanationSet(
          _explanations.where(predicate).toList());

  @override
  String toString() => 'VerificationExplanationSet(length: $length)';
}
