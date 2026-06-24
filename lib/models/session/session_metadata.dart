/// Immutable identity and timestamp envelope for a [VerificationSession].
///
/// [SessionMetadata] answers the questions "which session is this?" and
/// "when was it created and last touched?" without encoding any workflow state.
class SessionMetadata {
  /// Unique identifier for this session (e.g. UUID v4 or a human-readable slug).
  final String id;

  /// Wall-clock time when this session was first created.
  final DateTime createdAt;

  /// Wall-clock time of the most recent change to any session field.
  final DateTime updatedAt;

  const SessionMetadata({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns a copy with selected fields replaced.
  SessionMetadata copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionMetadata(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionMetadata &&
          id == other.id &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt);
}
