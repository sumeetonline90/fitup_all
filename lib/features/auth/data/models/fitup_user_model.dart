import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/fitup_user.dart';

/// Firestore DTO for `users/{uid}` (profile fields).
class FitupUserModel extends FitupUser {
  const FitupUserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.isOnboarded,
    required super.createdAt,
  });

  factory FitupUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> d = doc.data() ?? <String, dynamic>{};
    final Timestamp? ts = d['createdAt'] as Timestamp?;
    return FitupUserModel(
      id: doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String?,
      photoUrl: d['photoUrl'] as String?,
      isOnboarded: d['isOnboarded'] as bool? ?? false,
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isOnboarded': isOnboarded,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
