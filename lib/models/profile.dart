class Profile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? defaultHouseholdId;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.defaultHouseholdId,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Benutzer',
      avatarUrl: json['avatar_url'] as String?,
      defaultHouseholdId: json['default_household_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'default_household_id': defaultHouseholdId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? defaultHouseholdId,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      defaultHouseholdId: defaultHouseholdId ?? this.defaultHouseholdId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
