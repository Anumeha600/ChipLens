import 'package:flutter/material.dart';

/// Immutable value object representing a single navigation destination.
///
/// All fields that can be null (selectedIcon, routeName, badgeCount) are
/// optional and have well-defined defaults. Two [NavigationItem]s with the
/// same field values are considered equal.
@immutable
class NavigationItem {
  /// Stable identifier used for programmatic selection (e.g. deep-linking).
  final String id;

  /// Human-readable label shown in navigation chrome.
  final String title;

  /// Icon shown in the unselected state.
  final IconData icon;

  /// Icon shown in the selected state; falls back to [icon] when null.
  final IconData? selectedIcon;

  /// Tooltip / semantic label for accessibility.
  /// Defaults to [title] when not explicitly provided.
  final String tooltip;

  /// Optional route name; consumed by the caller's navigation layer.
  final String? routeName;

  /// Whether this destination can be activated.
  final bool enabled;

  /// Optional badge count (e.g. pending tasks). Null means no badge.
  final int? badgeCount;

  const NavigationItem({
    required this.id,
    required this.title,
    required this.icon,
    this.selectedIcon,
    String? tooltip,
    this.routeName,
    this.enabled = true,
    this.badgeCount,
  }) : tooltip = tooltip ?? title;

  // ── copyWith ─────────────────────────────────────────────────────────────

  NavigationItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    IconData? selectedIcon,
    String? tooltip,
    String? routeName,
    bool? enabled,
    int? badgeCount,
  }) {
    return NavigationItem(
      id:           id           ?? this.id,
      title:        title        ?? this.title,
      icon:         icon         ?? this.icon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      tooltip:      tooltip      ?? this.tooltip,
      routeName:    routeName    ?? this.routeName,
      enabled:      enabled      ?? this.enabled,
      badgeCount:   badgeCount   ?? this.badgeCount,
    );
  }

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationItem &&
        id          == other.id          &&
        title       == other.title       &&
        icon        == other.icon        &&
        selectedIcon == other.selectedIcon &&
        tooltip     == other.tooltip     &&
        routeName   == other.routeName   &&
        enabled     == other.enabled     &&
        badgeCount  == other.badgeCount;
  }

  @override
  int get hashCode => Object.hash(
      id, title, icon, selectedIcon, tooltip, routeName, enabled, badgeCount);
}
