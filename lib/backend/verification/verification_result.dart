import '../diagnostics/diagnostic.dart';

class VerificationResult {
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;

  /// Parsed diagnostics — populated by [VerificationRunner] convenience methods;
  /// empty when the service's [run] method is called directly.
  final List<Diagnostic> diagnostics;

  final Duration executionTime;

  /// Tool-specific metadata (e.g. `{'compileSuccess': bool}` for Icarus).
  final Map<String, Object> metadata;

  const VerificationResult({
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.diagnostics   = const [],
    this.executionTime = Duration.zero,
    this.metadata      = const {},
  });

  /// stderr + stdout concatenated and trimmed — the format all parsers expect.
  String get combined => '$stderr\n$stdout'.trim();

  @override
  String toString() =>
      'VerificationResult(success: $success, exitCode: $exitCode, '
      'time: ${executionTime.inMilliseconds}ms)';
}
