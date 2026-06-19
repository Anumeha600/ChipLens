import 'verification_context.dart';
import 'verification_result.dart';

export 'verification_context.dart';

/// Common interface for all external EDA verification tools.
///
/// Implementing [VerificationTool] is the only change required to integrate a
/// new tool (SymbiYosys, OpenSTA, OpenROAD, …) into the framework.
abstract class VerificationTool {
  const VerificationTool();

  String get toolName;
  Future<bool> isAvailable();
  Future<VerificationResult> run(VerificationContext context);
}
