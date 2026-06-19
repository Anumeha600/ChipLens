// ─── FormalMode ───────────────────────────────────────────────────────────────

/// Which formal verification strategy to run.
///
/// - [bmc] — Bounded Model Checking: prove safety properties up to [FormalContext.depth] steps.
/// - [prove] — k-induction unbounded proof (requires all-reachable-state invariants).
/// - [cover] — Reachability: find a trace that satisfies a `cover()` statement.
enum FormalMode {
  /// Bounded Model Checking.
  bmc,

  /// Unbounded k-induction proof.
  prove,

  /// Cover-point reachability.
  cover,
}

// ─── FormalContext ────────────────────────────────────────────────────────────

/// All inputs a [FormalEngine] needs to run one formal verification pass.
///
/// Designed for extensibility: future formal engines consume only the fields
/// they need and ignore the rest.
class FormalContext {
  /// Verilog / SystemVerilog RTL source to verify.
  final String rtlSource;

  /// Top-level module name.  When null the engine infers it from the RTL or
  /// lets the tool's `prep` command pick automatically.
  final String? topModule;

  /// Named SVA / PSL properties to check, in addition to inline `assert`
  /// statements.  May be empty when assertions are embedded in the RTL.
  final List<String> properties;

  /// Verification strategy.  Defaults to [FormalMode.bmc].
  final FormalMode mode;

  /// Number of time-steps for BMC.  Ignored for [FormalMode.prove] and
  /// [FormalMode.cover].
  final int depth;

  /// Wall-clock budget for the engine subprocess.
  final Duration timeout;

  /// Arbitrary engine-specific configuration (solver flags, include paths, …).
  final Map<String, dynamic> config;

  const FormalContext({
    required this.rtlSource,
    this.topModule,
    this.properties        = const [],
    this.mode              = FormalMode.bmc,
    this.depth             = 20,
    this.timeout           = const Duration(minutes: 5),
    this.config            = const {},
  });
}
