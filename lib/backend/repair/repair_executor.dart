import 'repair_suggestion.dart';

/// Applies a list of [RepairSuggestion]s to an RTL source string.
///
/// Separated from [RepairPipeline] so it can be tested in isolation and
/// reused by any future pipeline stage that needs to apply code patches.
abstract class RepairExecutor {
  RepairExecutor._();

  /// Apply [suggestions] sequentially to [rtlSource] and return the result.
  ///
  /// Non-auto-fixable suggestions (empty [RepairSuggestion.originalCode]) are
  /// skipped.  If a later suggestion's [originalCode] was already replaced by
  /// an earlier one, that suggestion is skipped gracefully.
  static String applyAll(String rtlSource, List<RepairSuggestion> suggestions) {
    var result = rtlSource;
    for (final s in suggestions) {
      if (!s.isAutoFixable) continue;
      if (result.contains(s.originalCode)) {
        result = result.replaceFirst(s.originalCode, s.replacementCode);
      }
    }
    return result;
  }
}
