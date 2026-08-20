import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/models/dish.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Broom ("Besen") Shopping to Stock Transfer Tests', () {
    late HouseholdProvider householdProvider;
    late ShoppingProvider shoppingProvider;
    late FoodProvider foodProvider;
    late StockProvider stockProvider;
    late DishProvider dishProvider;

    setUp(() {
      householdProvider = HouseholdProvider();
      shoppingProvider = ShoppingProvider();
      foodProvider = FoodProvider();
      stockProvider = StockProvider();
      dishProvider = DishProvider();
    });

    test('Test 1: Checked items transfer to stock, unchecked stay on shopping list', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'HH Test 1');
      final hh = householdProvider.currentHousehold!;

      shoppingProvider.bindToHousehold(hh.id);
      foodProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);

      await foodProvider.loadFoods();

      final milch = foodProvider.foods.firstWhere((f) => f.name == 'Milch');
      final nudeln = foodProvider.foods.firstWhere((f) => f.name == 'Nudeln');
      final tomaten = foodProvider.foods.firstWhere((f) => f.name == 'Tomaten');

      // Add 3 items to shopping list
      await shoppingProvider.addItem(foodId: milch.id, quantity: 1);
      await shoppingProvider.addItem(foodId: nudeln.id, quantity: 1);
      await shoppingProvider.addItem(foodId: tomaten.id, quantity: 1);

      // Check Milch and Nudeln
      final itemMilch = shoppingProvider.allItems.firstWhere((i) => i.foodId == milch.id);
      final itemNudeln = shoppingProvider.allItems.firstWhere((i) => i.foodId == nudeln.id);
      await shoppingProvider.toggleItemChecked(itemMilch.id);
      await shoppingProvider.toggleItemChecked(itemNudeln.id);

      expect(shoppingProvider.checkedCount, 2);
      expect(shoppingProvider.activeCount, 1);
      expect(stockProvider.isInStock(milch.id), isFalse);
      expect(stockProvider.isInStock(nudeln.id), isFalse);

      // Execute Besen (clearCheckedItems)
      await shoppingProvider.clearCheckedItems(
        stockProvider: stockProvider,
        foodProvider: foodProvider,
      );

      // Vorrat must have Milch and Nudeln
      expect(stockProvider.isInStock(milch.id), isTrue);
      expect(stockProvider.isInStock(nudeln.id), isTrue);
      expect(stockProvider.isInStock(tomaten.id), isFalse);

      // Shopping list must ONLY have Tomaten
      expect(shoppingProvider.allItems.length, 1);
      expect(shoppingProvider.allItems.first.foodId, tomaten.id);
      expect(shoppingProvider.checkedCount, 0);
    });

    test('Test 2: Already in stock items remain in stock without duplicates, item removed from list', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'HH Test 2');
      final hh = householdProvider.currentHousehold!;

      shoppingProvider.bindToHousehold(hh.id);
      foodProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);

      await foodProvider.loadFoods();
      final milch = foodProvider.foods.firstWhere((f) => f.name == 'Milch');

      // Put Milch in stock first
      await stockProvider.addToStock(milch.id);
      expect(stockProvider.isInStock(milch.id), isTrue);
      final initialStockSize = stockProvider.inStockFoodIds.length;

      // Add Milch to shopping list, check it, and run Besen
      await shoppingProvider.addItem(foodId: milch.id, quantity: 2);
      final item = shoppingProvider.allItems.firstWhere((i) => i.foodId == milch.id);
      await shoppingProvider.toggleItemChecked(item.id);

      await shoppingProvider.clearCheckedItems(
        stockProvider: stockProvider,
        foodProvider: foodProvider,
      );

      // Milch remains in stock, count of stock hasn't duplicated
      expect(stockProvider.isInStock(milch.id), isTrue);
      expect(stockProvider.inStockFoodIds.length, initialStockSize);
      expect(shoppingProvider.allItems.isEmpty, isTrue);
    });

    test('Test 3: Free-text item without food_id uses existing food or creates one and transfers to stock', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'HH Test 3');
      final hh = householdProvider.currentHousehold!;

      shoppingProvider.bindToHousehold(hh.id);
      foodProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);

      await foodProvider.loadFoods();

      // Case A: Free-text matching existing food "Bananen"
      await shoppingProvider.addItem(customName: 'bananen', quantity: 1);
      final itemBananen = shoppingProvider.allItems.firstWhere((i) => i.customName == 'bananen');
      await shoppingProvider.toggleItemChecked(itemBananen.id);

      // Case B: Free-text for non-existing food "Exotische Drachenfrucht"
      expect(foodProvider.foodExists('Exotische Drachenfrucht'), isFalse);
      await shoppingProvider.addItem(customName: 'Exotische Drachenfrucht', quantity: 1);
      final itemDrachen = shoppingProvider.allItems.firstWhere((i) => i.customName == 'Exotische Drachenfrucht');
      await shoppingProvider.toggleItemChecked(itemDrachen.id);

      // Run Besen
      await shoppingProvider.clearCheckedItems(
        stockProvider: stockProvider,
        foodProvider: foodProvider,
      );

      // Bananen should be in stock
      final bananen = foodProvider.foods.firstWhere((f) => f.name.toLowerCase() == 'bananen');
      expect(stockProvider.isInStock(bananen.id), isTrue);

      // Drachenfrucht was created and is in stock
      expect(foodProvider.foodExists('Exotische Drachenfrucht'), isTrue);
      final drachenFood = foodProvider.foods.firstWhere((f) => f.name == 'Exotische Drachenfrucht');
      expect(stockProvider.isInStock(drachenFood.id), isTrue);

      // Both items removed from shopping list
      expect(shoppingProvider.allItems.isEmpty, isTrue);
    });

    test('Test 4: Failing stock transfer preserves item on shopping list', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'HH Test 4');
      final hh = householdProvider.currentHousehold!;

      shoppingProvider.bindToHousehold(hh.id);
      foodProvider.bindToHousehold(hh.id);

      await foodProvider.loadFoods();
      final eier = foodProvider.foods.firstWhere((f) => f.name == 'Eier');

      await shoppingProvider.addItem(foodId: eier.id, quantity: 1);
      final item = shoppingProvider.allItems.first;
      await shoppingProvider.toggleItemChecked(item.id);

      // Mock a stock provider with un-bound household (cannot add to stock)
      final unconfiguredStockProvider = StockProvider(); // currentHouseholdId is null

      await shoppingProvider.clearCheckedItems(
        stockProvider: unconfiguredStockProvider,
        foodProvider: foodProvider,
      );

      // Since stock addition failed (household null), the item was NOT deleted
      expect(shoppingProvider.allItems.length, 1);
      expect(shoppingProvider.allItems.first.id, item.id);
    });

    test('Test 5: Household boundary isolation', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'HH Test 5A');
      final hhA = householdProvider.currentHousehold!;

      await householdProvider.createHousehold(name: 'HH Test 5B');
      final hhB = householdProvider.currentHousehold!;

      // In Household A: Buy Butter
      shoppingProvider.bindToHousehold(hhA.id);
      foodProvider.bindToHousehold(hhA.id);
      stockProvider.bindToHousehold(hhA.id);

      await foodProvider.loadFoods();
      final butterA = foodProvider.foods.firstWhere((f) => f.name == 'Butter');

      await shoppingProvider.addItem(foodId: butterA.id, quantity: 1);
      final itemA = shoppingProvider.allItems.first;
      await shoppingProvider.toggleItemChecked(itemA.id);

      await shoppingProvider.clearCheckedItems(
        stockProvider: stockProvider,
        foodProvider: foodProvider,
      );

      expect(stockProvider.isInStock(butterA.id), isTrue);

      // In Household B: Stock must NOT have Butter
      final stockProviderB = StockProvider();
      final foodProviderB = FoodProvider();

      stockProviderB.bindToHousehold(hhB.id);
      foodProviderB.bindToHousehold(hhB.id);
      await foodProviderB.loadFoods();

      final butterB = foodProviderB.foods.firstWhere((f) => f.name == 'Butter');
      expect(stockProviderB.isInStock(butterB.id), isFalse);
    });

    test('Test 6: Besen transfer automatically updates Kochbar dish state', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'HH Test 6');
      final hh = householdProvider.currentHousehold!;

      shoppingProvider.bindToHousehold(hh.id);
      foodProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);

      await dishProvider.loadDishes(hh.id);
      await foodProvider.loadFoods();

      final bolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');

      // Put first 5 ingredients into stock
      final first5 = bolognese.items.take(5).toList();
      for (final it in first5) {
        final fId = it.foodId ?? it.food?.id ?? foodProvider.foods.firstWhere((f) => f.name == it.displayName).id;
        await stockProvider.addToStock(fId);
      }

      bool isCookable(Dish dish) {
        final inStock = stockProvider.inStockFoodIds;
        final foodMap = {for (final f in foodProvider.foods) f.name.trim().toLowerCase(): f.id};
        if (dish.items.isEmpty) return false;
        return dish.items.every((item) {
          final fId = item.foodId ?? item.food?.id;
          final resolvedByName = foodMap[item.displayName.trim().toLowerCase()];
          return (fId != null && inStock.contains(fId)) ||
              (resolvedByName != null && inStock.contains(resolvedByName));
        });
      }

      // 5 of 6 -> NOT cookable
      expect(isCookable(bolognese), isFalse);

      // Buy the 6th ingredient via Shopping List
      final lastItem = bolognese.items.last;
      final lastFId = lastItem.foodId ?? lastItem.food?.id ?? foodProvider.foods.firstWhere((f) => f.name == lastItem.displayName).id;

      await shoppingProvider.addItem(foodId: lastFId, quantity: 1);
      final shopItem = shoppingProvider.allItems.firstWhere((i) => i.foodId == lastFId);
      await shoppingProvider.toggleItemChecked(shopItem.id);

      // Run Besen
      await shoppingProvider.clearCheckedItems(
        stockProvider: stockProvider,
        foodProvider: foodProvider,
      );

      // Now Bolognese is 6 of 6 -> KOCHBAR!
      expect(isCookable(bolognese), isTrue);
    });
  });
}
