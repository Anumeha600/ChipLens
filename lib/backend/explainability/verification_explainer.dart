import '../formal/formal_property_set.dart';
import 'explanation_builder.dart';
import 'explanation_context.dart';
import 'verification_explanation_set.dart';

// ─── VerificationExplainer ────────────────────────────────────────────────────

/// High-level orchestrator that produces a [VerificationExplanationSet] from
/// a [FormalPropertySet].
///
/// Produces exactly one [VerificationExplanation] per [FormalProperty], in the
/// same order as [FormalPropertySet.properties].
///
/// Invariants:
/// - Does NOT perform verification.
/// - Does NOT format output (that is [ExplanationFormatter]'s responsibility).
/// - Does NOT modify [FormalProperty] or [FormalPropertySet].
/// - Output ordering matches input ordering.
/// - Stateless — every call is independent.
class VerificationExplainer {
  /// Creates a [VerificationExplainer].
  ///
  /// Stateless: all behaviour is driven by [context].
  const VerificationExplainer();

  /// Generates one [VerificationExplanation] for each property in [properties].
  ///
  /// The returned [VerificationExplanationSet] is immutable and ordered to
  /// match [FormalPropertySet.properties].
  ///
  /// Throws [ArgumentError] when a property has an empty id (malformed input).
  VerificationExplanationSet explain(
    FormalPropertySet properties,
    ExplanationContext context,
  ) {
    final explanations = [
      for (final property in properties.properties)
        ExplanationBuilder.build(property, context),
    ];
    return VerificationExplanationSet(explanations);
  }
}
