import 'package:flutter/material.dart' show IconData, immutable;

/// Immutable value object that describes a ChipLens workspace.
///
/// A workspace is a named engineering environment — it carries metadata
/// (id, title, optional icon, optional description) but contains no UI code.
/// Widget construction is the responsibility of [WorkspaceRegistry] and
/// the individual workspace files.
@immutable
class Workspace {
  /// Stable identifier used for programmatic lookup.
  final String id;

  /// Human-readable workspace name.
  final String title;

  /// Optional icon used in navigation chrome.
  final IconData? icon;

  /// Optional one-line workspace description.
  final String? description;

  const Workspace({
    required this.id,
    required this.title,
    this.icon,
    this.description,
  });

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workspace &&
        id          == other.id          &&
        title       == other.title       &&
        icon        == other.icon        &&
        description == other.description;
  }

  @override
  int get hashCode => Object.hash(id, title, icon, description);
}
