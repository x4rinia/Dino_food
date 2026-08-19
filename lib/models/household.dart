class Household {
  final String id;
  final String name;
  final String color;
  final String inviteCode;
  final String? createdBy;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    this.color = '#2A9D8F',
    required this.inviteCode,
    this.createdBy,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Haushalt',
      color: json['color'] as String? ?? '#2A9D8F',
      inviteCode: json['invite_code'] as String? ?? '',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'invite_code': inviteCode,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
