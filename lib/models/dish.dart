import 'dish_item.dart';

class Dish {
  final String id;
  final String householdId;
  final String name;
  final bool isFavorite;
  final String? createdBy;
  final DateTime createdAt;
  final List<DishItem> items;

  Dish({
    required this.id,
    required this.householdId,
    required this.name,
    this.isFavorite = false,
    this.createdBy,
    required this.createdAt,
    this.items = const [],
  });

  Dish copyWith({
    String? id,
    String? householdId,
    String? name,
    bool? isFavorite,
    String? createdBy,
    DateTime? createdAt,
    List<DishItem>? items,
  }) {
    return Dish(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  factory Dish.fromJson(Map<String, dynamic> json, {bool isFavorite = false}) {
    var rawItems = json['dish_items'];
    List<DishItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => DishItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Dish(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String? ?? 'Gericht',
      isFavorite: isFavorite,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'name': name,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
