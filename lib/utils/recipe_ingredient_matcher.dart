import '../models/dish_item.dart';
import '../models/food.dart';

typedef FoodIdsByNormalizedName = Map<String, Set<String>>;

class RecipeIngredientMatcher {
  const RecipeIngredientMatcher._();

  static String normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static FoodIdsByNormalizedName indexFoods(Iterable<Food> foods) {
    final result = <String, Set<String>>{};
    for (final food in foods) {
      result
          .putIfAbsent(normalizeName(food.name), () => <String>{})
          .add(food.id);
    }
    return result;
  }

  static bool isInStock({
    required DishItem item,
    required Set<String> inStockFoodIds,
    required FoodIdsByNormalizedName foodIdsByName,
  }) {
    final matchingIds = foodIdsByName[normalizeName(item.displayName)];
    if (matchingIds != null) {
      return matchingIds.any(inStockFoodIds.contains);
    }

    // Preserve support for legacy dish data when no catalog entry was loaded.
    final directId = item.foodId ?? item.food?.id;
    return directId != null && inStockFoodIds.contains(directId);
  }
}
