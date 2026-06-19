/// All inputs a [VerificationTool] needs to run.
///
/// Designed for extensibility: adding new fields (e.g. elaboration flags,
/// include paths) never requires changes to existing [VerificationTool]
/// implementations — they simply ignore fields they don't need.
class VerificationContext {
  final String rtlSource;
  final String? testbenchSource;
  final String? workingDirectory;
  final Duration timeout;

  /// Extra environment variables merged into the tool's process environment.
  final Map<String, String> environmentVariables;

  /// Arbitrary tool-specific configuration (e.g. lint flags, synthesis passes).
  final Map<String, dynamic> config;

  const VerificationContext({
    required this.rtlSource,
    this.testbenchSource,
    this.workingDirectory,
    this.timeout              = const Duration(seconds: 30),
    this.environmentVariables = const {},
    this.config               = const {},
  });
}
