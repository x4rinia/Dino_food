import 'food.dart';
import 'profile.dart';

class ShoppingItem {
  final String id;
  final String householdId;
  final String? foodId;
  final String? customName;
  final String? note;
  final int? quantity;
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
    this.quantity,
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

  String? get detailsText {
    final parts = <String>[
      if (note != null && note!.trim().isNotEmpty) note!.trim(),
      if (quantity != null) 'Anzahl: $quantity',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  ShoppingItem copyWith({
    String? id,
    String? householdId,
    String? foodId,
    String? customName,
    String? note,
    int? quantity,
    bool clearQuantity = false,
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
      quantity: clearQuantity ? null : quantity ?? this.quantity,
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
      quantity: _parseQuantity(json['quantity']),
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
      'quantity': quantity,
      'checked': checked,
      if (addedBy != null) 'added_by': addedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static int? _parseQuantity(dynamic value) {
    if (value is! num || value <= 0 || value != value.truncate()) return null;
    return value.toInt();
  }
}
