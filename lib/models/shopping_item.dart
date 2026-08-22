import 'food.dart';
import 'profile.dart';

class ShoppingItem {
  final String id;
  final String householdId;
  final String? foodId;
  final String? customName;
  final String? note;
  final bool checked;
  final String? addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Food? food;
  final Profile? addedByProfile;

  ShoppingItem({
    required this.id,
    required this.householdId,
    this.foodId,
    this.customName,
    this.note,
    this.checked = false,
    this.addedBy,
    required this.createdAt,
    required this.updatedAt,
    this.food,
    this.addedByProfile,
  });

  String get displayName {
    if (customName != null && customName!.trim().isNotEmpty) return customName!;
    if (food != null) return food!.name;
    return 'Unbenannter Artikel';
  }

  ShoppingItem copyWith({
    String? id,
    String? householdId,
    String? foodId,
    String? customName,
    String? note,
    bool? checked,
    String? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Food? food,
    Profile? addedByProfile,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      foodId: foodId ?? this.foodId,
      customName: customName ?? this.customName,
      note: note ?? this.note,
      checked: checked ?? this.checked,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      food: food ?? this.food,
      addedByProfile: addedByProfile ?? this.addedByProfile,
    );
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      foodId: json['food_id'] as String?,
      customName: json['custom_name'] as String?,
      note: json['note'] as String?,
      checked: json['checked'] as bool? ?? false,
      addedBy: json['added_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      food: json['foods'] != null
          ? Food.fromJson(json['foods'] as Map<String, dynamic>)
          : null,
      addedByProfile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      if (foodId != null) 'food_id': foodId,
      'custom_name': customName,
      'note': note,
      'checked': checked,
      if (addedBy != null) 'added_by': addedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
