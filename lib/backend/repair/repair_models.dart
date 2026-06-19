// Internal repair framework types.
// Shared between RepairMatcher, RepairCatalog, and RepairPipeline.
// Not part of the public API — import via specific file paths, not repair.dart.

/// Canonical fix-group identifiers.
///
/// RepairMatcher maps warning type strings → one of these constants.
/// RepairCatalog uses these as keys to select the right repair strategy.
/// Using typed constants instead of raw strings prevents typos and makes
/// the dispatch auditable.
abstract class RepairFixGroup {
  RepairFixGroup._();

  static const String missingDefault     = 'missing_default';
  static const String blockingAssignment = 'blocking_assignment';
  static const String missingReset       = 'missing_reset';
  static const String incompleteSens     = 'incomplete_sensitivity';
  static const String unusedSignal       = 'unused_signal';
  static const String unreachableState   = 'unreachable_state';
  static const String combinatorialLoop  = 'combinatorial_loop';
  static const String multipleDrivers    = 'multiple_drivers';
  static const String widthMismatch      = 'width_mismatch';
  static const String implicitWire       = 'implicit_wire';
}
