import 'profile.dart';

class HouseholdMember {
  final String householdId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final Profile? profile;

  HouseholdMember({
    required this.householdId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
    this.profile,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'household_id': householdId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
