import 'community_geo_point.dart';

/// High-level challenge type for community events.
///
/// Legacy types (run / walk / cycle / workout / custom) are still supported
/// for older documents; newer creation flows primarily use
/// [stepChallenge] and [walkingChallenge].
enum EventType {
  run,
  walk,
  cycle,
  workout,
  custom,
  stepChallenge,
  walkingChallenge,
}

enum EventStatus { upcoming, live, completed, cancelled }

/// Whether an event appears in public listings or only via exact code search.
enum EventVisibility { public, private }

class CommunityEvent {
  const CommunityEvent({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.eventCode,
    required this.visibility,
    this.location,
    this.locationName,
    this.distanceKm,
    this.targetSteps,
    this.targetDistanceKm,
    required this.maxParticipants,
    required this.participantIds,
    required this.fitcoinsReward,
    required this.createdAt,
  });

  final String id;
  final String organizerId;
  final String organizerName;
  final String title;
  final String description;
  final EventType type;
  final EventStatus status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String eventCode;
  final EventVisibility visibility;
  final CommunityGeoPoint? location;
  final String? locationName;
  final double? distanceKm;
  final int? targetSteps;
  final double? targetDistanceKm;
  final int maxParticipants;
  final List<String> participantIds;
  final int fitcoinsReward;
  final DateTime createdAt;

  /// UI alias for horizontal event cards.
  int get participantCount => participantIds.length;

  /// UI alias (Fitcoin reward label).
  int get rewardFc => fitcoinsReward;

  /// UI list/detail label when [locationName] is null.
  String get locationLabel => locationName ?? 'Virtual / TBA';

  /// Legacy screen copy used "about" for the description body.
  String get about => description;

  bool get isCompleted => status == EventStatus.completed;

  /// Convenience: true when [visibility] is [EventVisibility.public].
  bool get isPublic => visibility == EventVisibility.public;

  /// Whether [userId] has joined (compare with signed-in user id).
  bool isJoinedBy(String? userId) =>
      userId != null && participantIds.contains(userId);
}
