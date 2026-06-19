import 'repair_models.dart';

/// Maps diagnostic warning type strings to [RepairFixGroup] constants.
///
/// This is the *detection* layer of the repair pipeline: given a warning type,
/// it answers "is there a known repair strategy for this?" and returns the
/// canonical fix-group identifier if so.
///
/// The mapping is intentionally flat (a single switch) so that adding support
/// for a new tool's warning alias requires a single new `case` line here and a
/// corresponding strategy entry in [RepairCatalog].
abstract class RepairMatcher {
  RepairMatcher._();

  /// Return the [RepairFixGroup] constant for [warningType], or `null` if no
  /// repair strategy is registered for that warning type.
  static String? detect(String warningType) {
    switch (warningType) {
      // ── Latch / missing default ───────────────────────────────────────────
      case 'missing_default':
      case 'inferred_latch':
      case 'latch_risk':
      case 'verilator_latch':
      case 'verilator_nolatch':
      case 'yosys_infer_latch':
        return RepairFixGroup.missingDefault;

      // ── Blocking assignments ──────────────────────────────────────────────
      case 'blocking_seq':
      case 'no_nonblocking':
      case 'blocking_assignment':
      case 'verilator_blkloopinit':
      case 'verilator_combdly':
      case 'verilator_blkandnblk':
        return RepairFixGroup.blockingAssignment;

      // ── Missing reset ─────────────────────────────────────────────────────
      case 'missing_reset':
      case 'no_reset':
      case 'verilator_resetall':
        return RepairFixGroup.missingReset;

      // ── Incomplete sensitivity list ───────────────────────────────────────
      case 'incomplete_sensitivity':
        return RepairFixGroup.incompleteSens;

      // ── Unused signal ─────────────────────────────────────────────────────
      case 'unused_signal':
        return RepairFixGroup.unusedSignal;

      // ── Unreachable state ─────────────────────────────────────────────────
      case 'unreachable_state':
      case 'dead_code':
        return RepairFixGroup.unreachableState;

      // ── Combinatorial loop ────────────────────────────────────────────────
      case 'combinatorial_loop':
      case 'yosys_loop':
        return RepairFixGroup.combinatorialLoop;

      // ── Multiple drivers ──────────────────────────────────────────────────
      case 'multiple_drivers':
      case 'yosys_multiple_drivers':
        return RepairFixGroup.multipleDrivers;

      // ── Width mismatch ────────────────────────────────────────────────────
      case 'verilator_width':
      case 'icarus_type_error':
        return RepairFixGroup.widthMismatch;

      // ── Undeclared / implicit wire ────────────────────────────────────────
      case 'icarus_implicit_wire':
      case 'icarus_undefined':
        return RepairFixGroup.implicitWire;

      default:
        return null;
    }
  }
}
