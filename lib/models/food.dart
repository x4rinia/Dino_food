import 'food_icon.dart';

class Food {
  final String id;
  final String? householdId;
  final String name;
  final String? note;
  final String iconKey;
  final String defaultUnit;
  final DateTime createdAt;

  Food({
    required this.id,
    this.householdId,
    required this.name,
    this.note,
    String? iconKey,
    this.defaultUnit = 'Stück',
    required this.createdAt,
  }) : iconKey = FoodIconCatalog.normalizeKey(
         iconKey ?? FoodIconCatalog.defaultForFoodId(id),
       );

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      householdId: json['household_id'] as String?,
      name: json['name'] as String? ?? '',
      note: json['note'] as String?,
      iconKey: json['icon_key'] as String?,
      defaultUnit: json['default_unit'] as String? ?? 'Stück',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (householdId != null) 'household_id': householdId,
      'name': name,
      'note': note,
      'icon_key': iconKey,
      'default_unit': defaultUnit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
