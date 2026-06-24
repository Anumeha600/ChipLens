import 'package:flutter/material.dart';

/// Centralized icon mappings for the ChipLens design system.
///
/// All icons use the `_rounded` variant for visual consistency.
/// Reference these constants instead of `Icons.*` directly so icon swaps
/// require only one-line changes here.
class AppIcons {
  const AppIcons._();

  // ── Navigation ────────────────────────────────────────────────────────────

  static const IconData dashboard    = Icons.dashboard_rounded;
  static const IconData folder       = Icons.folder_rounded;
  static const IconData settings     = Icons.settings_rounded;
  static const IconData help         = Icons.help_outline_rounded;
  static const IconData home         = Icons.home_rounded;
  static const IconData menu         = Icons.menu_rounded;

  // ── ChipLens feature set ──────────────────────────────────────────────────

  static const IconData verification = Icons.verified_user_rounded;
  static const IconData coverage     = Icons.show_chart_rounded;
  static const IconData diagnostics  = Icons.bar_chart_rounded;
  static const IconData repair       = Icons.build_rounded;
  static const IconData analysis     = Icons.analytics_rounded;
  static const IconData hierarchy    = Icons.account_tree_rounded;

  // ── Actions ───────────────────────────────────────────────────────────────

  static const IconData search    = Icons.search_rounded;
  static const IconData play      = Icons.play_arrow_rounded;
  static const IconData stop      = Icons.stop_rounded;
  static const IconData refresh   = Icons.refresh_rounded;
  static const IconData export    = Icons.download_rounded;
  static const IconData add       = Icons.add_rounded;
  static const IconData close     = Icons.close_rounded;
  static const IconData more      = Icons.more_vert_rounded;
  static const IconData copy      = Icons.copy_rounded;
  static const IconData filter    = Icons.filter_list_rounded;
  static const IconData expand    = Icons.expand_more_rounded;
  static const IconData collapse  = Icons.expand_less_rounded;

  // ── Status indicators ─────────────────────────────────────────────────────

  static const IconData success = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData failure = Icons.cancel_rounded;
  static const IconData info    = Icons.info_rounded;
  static const IconData pending = Icons.hourglass_empty_rounded;
}
