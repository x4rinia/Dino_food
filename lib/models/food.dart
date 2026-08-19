class Food {
  final String id;
  final String name;
  final String category;
  final String defaultUnit;
  final DateTime createdAt;

  Food({
    required this.id,
    required this.name,
    this.category = 'Sonstiges',
    this.defaultUnit = 'Stück',
    required this.createdAt,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Sonstiges',
      defaultUnit: json['default_unit'] as String? ?? 'Stück',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'default_unit': defaultUnit,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
