import 'food.dart';

class DishItem {
  final String id;
  final String dishId;
  final String? foodId;
  final String? customName;
  final Food? food;

  DishItem({
    required this.id,
    required this.dishId,
    this.foodId,
    this.customName,
    this.food,
  });

  String get displayName {
    if (food != null) return food!.name;
    if (customName != null && customName!.trim().isNotEmpty) return customName!;
    return 'Zutat';
  }

  factory DishItem.fromJson(Map<String, dynamic> json) {
    return DishItem(
      id: json['id'] as String,
      dishId: json['dish_id'] as String,
      foodId: json['food_id'] as String?,
      customName: json['custom_name'] as String?,
      food: json['foods'] != null
          ? Food.fromJson(json['foods'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dish_id': dishId,
      if (foodId != null) 'food_id': foodId,
      'custom_name': customName,
    };
  }
}
