/// Lat/lng for an event venue (maps to Firestore [GeoPoint] in the data layer).
class CommunityGeoPoint {
  const CommunityGeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
