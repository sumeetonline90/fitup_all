/// Emergency contact for profile / edit.
class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  final String name;
  final String phone;
  final String relationship;

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relationship,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }
}
