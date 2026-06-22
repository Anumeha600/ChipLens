// ─── RankingPolicy ────────────────────────────────────────────────────────────

/// Named constants that govern how [RankingEngine] weights each scoring
/// component.
///
/// Invariant: the five [weight*] constants must always sum to 1.0.
/// No magic numbers appear in the engine — all weights reference this class.
abstract class RankingPolicy {
  RankingPolicy._();

  // ── Component weights (must sum to 1.0) ───────────────────────────────────

  /// Weight of the average evidence confidence score.
  static const double weightEvidence = 0.40;

  /// Weight of the property-type priority score.
  static const double weightPropertyType = 0.25;

  /// Weight of the metadata richness score.
  static const double weightMetadata = 0.15;

  /// Weight of the supporting evidence count score.
  static const double weightEvidenceCount = 0.10;

  /// Weight of the domain-category bonus.
  static const double weightDomainBonus = 0.10;

  // ── Domain-category bonuses ────────────────────────────────────────────────

  /// Raw bonus value (in [0.0, 1.0]) assigned per evidence category.
  ///
  /// Higher values reflect categories where formal verification has the
  /// greatest impact on detecting correctness failures.
  static const Map<String, double> domainCategoryBonus = {
    'fsm':           1.0,
    'reset':         1.0,
    'counter':       0.8,
    'handshake':     0.8,
    'sequential':    0.7,
    'clock':         0.7,
    'combinational': 0.6,
    'arithmetic':    0.6,
    'register':      0.4,
    'custom':        0.4,
  };

  // ── Evidence count thresholds ──────────────────────────────────────────────

  /// Number of supporting evidence items that saturates the count score to 1.0.
  static const int evidenceCountSaturation = 3;
}
