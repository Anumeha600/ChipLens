import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart' show immutable;
import 'navigation_destination.dart';
import 'navigation_item.dart';

/// Immutable state container for workbench navigation.
///
/// All mutation methods return new [NavigationController] instances —
/// the original is never modified. This makes it safe to pass between widgets
/// without defensive copying.
///
/// ```dart
/// // Typical usage:
/// var ctrl = NavigationController.workspaces();
/// ctrl = ctrl.selectById('verification');
/// ```
@immutable
class NavigationController {
  /// Ordered list of destinations available in this controller.
  final List<NavigationItem> destinations;

  /// Zero-based index of the currently selected destination.
  final int selectedIndex;

  /// Creates a [NavigationController] with an explicit [destinations] list.
  ///
  /// [selectedIndex] must be in the range `[0, destinations.length)` when
  /// destinations is non-empty.
  const NavigationController({
    required this.destinations,
    this.selectedIndex = 0,
  });

  /// Convenience factory that initialises with the primary workspace destinations.
  factory NavigationController.workspaces({int selectedIndex = 0}) =>
      NavigationController(
        destinations: NavigationDestinations.workspaces,
        selectedIndex: selectedIndex,
      );

  /// Convenience factory that initialises with all destinations.
  factory NavigationController.all({int selectedIndex = 0}) =>
      NavigationController(
        destinations: NavigationDestinations.all,
        selectedIndex: selectedIndex,
      );

  // ── Accessors ─────────────────────────────────────────────────────────────

  /// The currently selected [NavigationItem].
  ///
  /// Requires [destinations] to be non-empty and [selectedIndex] in range.
  NavigationItem get selectedDestination {
    assert(destinations.isNotEmpty, 'destinations must not be empty');
    return destinations[selectedIndex];
  }

  /// True when [selectedIndex] is a valid index into [destinations].
  bool get hasValidSelection =>
      destinations.isNotEmpty &&
      selectedIndex >= 0 &&
      selectedIndex < destinations.length;

  // ── Mutation (returns new instances) ──────────────────────────────────────

  /// Returns a new controller with [selectedIndex] set to [index].
  ///
  /// Returns `this` unchanged when [index] equals the current [selectedIndex].
  NavigationController selectDestination(int index) {
    assert(
      index >= 0 && index < destinations.length,
      'index $index out of range [0, ${destinations.length})',
    );
    if (index == selectedIndex) return this;
    return NavigationController(
      destinations:  destinations,
      selectedIndex: index,
    );
  }

  /// Returns a new controller selecting the destination whose [NavigationItem.id]
  /// matches [id].
  ///
  /// Returns `this` unchanged when no match is found.
  NavigationController selectById(String id) {
    final index = destinations.indexWhere((d) => d.id == id);
    if (index == -1) return this;
    return selectDestination(index);
  }

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationController &&
        selectedIndex == other.selectedIndex &&
        listEquals(destinations, other.destinations);
  }

  @override
  int get hashCode =>
      Object.hash(selectedIndex, Object.hashAll(destinations));
}
