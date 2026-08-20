import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/models/dish.dart';
import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/models/shopping_item.dart';

void main() {
  group('Dish to Shopping List Transfer Filtering Tests', () {
    test('Items in stock or already on shopping list are excluded', () {
      final inStockFoodIds = {'food_zwiebeln', 'food_milch'};
      final openShoppingItems = [
        ShoppingItem(
          id: 's1',
          householdId: 'h1',
          foodId: 'food_brot',
          customName: 'Brot',
          checked: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final catalogFoods = [
        Food(id: 'food_zwiebeln', name: 'Zwiebeln', category: 'Gemüse', defaultUnit: '', createdAt: DateTime.now()),
        Food(id: 'food_milch', name: 'Milch', category: 'Milchprodukte', defaultUnit: '', createdAt: DateTime.now()),
        Food(id: 'food_brot', name: 'Brot', category: 'Backwaren', defaultUnit: '', createdAt: DateTime.now()),
        Food(id: 'food_hackfleisch', name: 'Hackfleisch', category: 'Fleisch', defaultUnit: '', createdAt: DateTime.now()),
      ];

      final dish = Dish(
        id: 'dish_1',
        householdId: 'h1',
        name: 'Test Gericht',
        createdAt: DateTime.now(),
        items: [
          // 1. In stock by foodId
          DishItem(id: 'd1', dishId: 'dish_1', foodId: 'food_zwiebeln', customName: 'Zwiebeln'),
          // 2. In stock by matching name
          DishItem(id: 'd2', dishId: 'dish_1', customName: 'Milch'),
          // 3. Already on shopping list by foodId & name
          DishItem(id: 'd3', dishId: 'dish_1', foodId: 'food_brot', customName: 'Brot'),
          // 4. Neither in stock nor on list -> should be added
          DishItem(id: 'd4', dishId: 'dish_1', foodId: 'food_hackfleisch', customName: 'Hackfleisch'),
          // 5. Custom ingredient not in catalog, not in stock, not on list -> should be added
          DishItem(id: 'd5', dishId: 'dish_1', customName: 'Spezialsauce'),
        ],
      );

      final List<DishItem> itemsToAdd = [];
      final List<DishItem> inStockItems = [];
      final List<DishItem> alreadyOnListItems = [];

      for (final item in dish.items) {
        final itemName = item.displayName.toLowerCase().trim();
        final itemCustomName = item.customName?.toLowerCase().trim();

        final matchingFood = catalogFoods.where((f) {
          final fName = f.name.toLowerCase().trim();
          return fName == itemName || (itemCustomName != null && fName == itemCustomName);
        }).firstOrNull;

        final matchedFoodId = item.foodId ?? item.food?.id ?? matchingFood?.id;

        bool isInStock = false;
        if (item.foodId != null && inStockFoodIds.contains(item.foodId!)) {
          isInStock = true;
        } else if (item.food != null && inStockFoodIds.contains(item.food!.id)) {
          isInStock = true;
        } else if (matchedFoodId != null && inStockFoodIds.contains(matchedFoodId)) {
          isInStock = true;
        }

        bool isAlreadyOnList = false;
        if (!isInStock) {
          isAlreadyOnList = openShoppingItems.any((openItem) {
            final openFoodId = openItem.foodId ?? openItem.food?.id;
            if (matchedFoodId != null && openFoodId != null && matchedFoodId == openFoodId) {
              return true;
            }
            final openName = openItem.displayName.toLowerCase().trim();
            if (openName == itemName) {
              return true;
            }
            final openCustomName = openItem.customName?.toLowerCase().trim();
            if (openCustomName != null && itemCustomName != null && openCustomName == itemCustomName) {
              return true;
            }
            return false;
          });
        }

        if (isInStock) {
          inStockItems.add(item);
        } else if (isAlreadyOnList) {
          alreadyOnListItems.add(item);
        } else {
          itemsToAdd.add(item);
        }
      }

      // Zwiebeln & Milch must be detected as in stock
      expect(inStockItems.length, 2);
      expect(inStockItems.map((i) => i.displayName).toSet(), {'Zwiebeln', 'Milch'});

      // Brot must be detected as already on shopping list
      expect(alreadyOnListItems.length, 1);
      expect(alreadyOnListItems.first.displayName, 'Brot');

      // Hackfleisch & Spezialsauce are the only ones to be added
      expect(itemsToAdd.length, 2);
      expect(itemsToAdd.map((i) => i.displayName).toSet(), {'Hackfleisch', 'Spezialsauce'});
    });
  });
}
