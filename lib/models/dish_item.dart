import 'food.dart';

class DishItem {
  final String id;
  final String dishId;
  final String? foodId;
  final String? customName;
  final double quantity;
  final Food? food;

  DishItem({
    required this.id,
    required this.dishId,
    this.foodId,
    this.customName,
    this.quantity = 1.0,
    this.food,
  });

  String get displayName {
    if (food != null) return food!.name;
    if (customName != null && customName!.trim().isNotEmpty) return customName!;
    return 'Zutat';
  }

  String get formattedQuantity {
    if (quantity <= 0) return '';
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString().replaceAll('.', ',');
  }

  factory DishItem.fromJson(Map<String, dynamic> json) {
    return DishItem(
      id: json['id'] as String,
      dishId: json['dish_id'] as String,
      foodId: json['food_id'] as String?,
      customName: json['custom_name'] as String?,
      quantity: (json['quantity'] != null)
          ? double.tryParse(json['quantity'].toString()) ?? 1.0
          : 1.0,
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
      'quantity': quantity,
    };
  }
}
