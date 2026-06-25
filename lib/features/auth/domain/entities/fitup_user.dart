/// Authenticated Fitup user — pure domain (no Firebase imports).
class FitupUser {
  const FitupUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isOnboarded = false,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isOnboarded;
  final DateTime createdAt;
}
