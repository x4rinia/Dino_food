import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/models/dish.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cookable ("🔥 Kochbar") Dishes Calculation & Isolation Tests', () {
    late HouseholdProvider householdProvider;
    late DishProvider dishProvider;
    late FoodProvider foodProvider;
    late StockProvider stockProvider;

    setUp(() {
      householdProvider = HouseholdProvider();
      dishProvider = DishProvider();
      foodProvider = FoodProvider();
      stockProvider = StockProvider();
    });

    test('Test 1 & 2 & 3: Dish with 5/6 ingredients is not cookable, adding 6th makes it cookable, removing reverts it', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      foodProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);

      await dishProvider.loadDishes(hh.id);
      await foodProvider.loadFoods();

      final bolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      expect(bolognese.items.length, 6);

      // Helper to compute cookability
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

      // Initially stock is empty -> Not cookable
      expect(isCookable(bolognese), isFalse);

      // Put first 5 ingredients into stock
      final first5 = bolognese.items.take(5).toList();
      for (final it in first5) {
        final fId = it.foodId ?? it.food?.id ?? foodProvider.foods.firstWhere((f) => f.name == it.displayName).id;
        await stockProvider.toggleStock(fId);
      }

      // Test 1: 5 of 6 ingredients in stock -> NOT cookable
      expect(isCookable(bolognese), isFalse);

      // Test 2: Add the 6th ingredient to stock -> NOW cookable
      final lastItem = bolognese.items.last;
      final lastFId = lastItem.foodId ?? lastItem.food?.id ?? foodProvider.foods.firstWhere((f) => f.name == lastItem.displayName).id;
      await stockProvider.toggleStock(lastFId);

      expect(isCookable(bolognese), isTrue);

      // Test 3: Remove one ingredient from stock -> NOT cookable anymore
      await stockProvider.toggleStock(lastFId);
      expect(isCookable(bolognese), isFalse);
    });

    test('Test 4: Multiple cookable dishes are partitioned cleanly without duplicates', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      foodProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);

      await dishProvider.loadDishes(hh.id);
      await foodProvider.loadFoods();

      final bolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      final wraps = dishProvider.dishes.firstWhere((d) => d.name == 'Wraps');

      // Add all ingredients for both dishes to stock
      for (final it in [...bolognese.items, ...wraps.items]) {
        final fId = it.foodId ?? it.food?.id ?? foodProvider.foods.firstWhere((f) => f.name == it.displayName).id;
        if (!stockProvider.inStockFoodIds.contains(fId)) {
          await stockProvider.toggleStock(fId);
        }
      }

      final inStock = stockProvider.inStockFoodIds;
      final foodMap = {for (final f in foodProvider.foods) f.name.trim().toLowerCase(): f.id};

      final cookable = <Dish>[];
      final others = <Dish>[];

      for (final dish in dishProvider.dishes) {
        final ok = dish.items.isNotEmpty && dish.items.every((it) {
          final fId = it.foodId ?? it.food?.id;
          final resolvedByName = foodMap[it.displayName.trim().toLowerCase()];
          return (fId != null && inStock.contains(fId)) ||
              (resolvedByName != null && inStock.contains(resolvedByName));
        });
        if (ok) {
          cookable.add(dish);
        } else {
          others.add(dish);
        }
      }

      // Both must be in cookable
      expect(cookable.any((d) => d.name == 'Spaghetti Bolognese'), isTrue);
      expect(cookable.any((d) => d.name == 'Wraps'), isTrue);

      // NEITHER must be in others (no duplicates)
      expect(others.any((d) => d.name == 'Spaghetti Bolognese'), isFalse);
      expect(others.any((d) => d.name == 'Wraps'), isFalse);

      // Total sum of partition equals original list length
      expect(cookable.length + others.length, dishProvider.dishes.length);
    });

    test('Test 5: Custom user dish is recognized as cookable when all ingredients are in stock', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      foodProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);

      await foodProvider.loadFoods();

      // Create custom dish "Dino Snack Bowl"
      await dishProvider.createDish(
        householdId: hh.id,
        name: 'Dino Snack Bowl',
        items: [
          {'name': 'Bananen', 'quantity': 2.0},
          {'name': 'Milch', 'quantity': 1.0},
        ],
      );

      final customDish = dishProvider.dishes.firstWhere((d) => d.name == 'Dino Snack Bowl');

      final bananen = foodProvider.foods.firstWhere((f) => f.name == 'Bananen');
      final milch = foodProvider.foods.firstWhere((f) => f.name == 'Milch');

      // Before stock
      expect(stockProvider.inStockFoodIds.contains(bananen.id), isFalse);

      // Add only Bananen -> Not cookable
      await stockProvider.toggleStock(bananen.id);
      expect(stockProvider.inStockFoodIds.contains(milch.id), isFalse);

      // Add Milch -> Now cookable
      await stockProvider.toggleStock(milch.id);

      final inStock = stockProvider.inStockFoodIds;
      final foodMap = {for (final f in foodProvider.foods) f.name.trim().toLowerCase(): f.id};

      final ok = customDish.items.isNotEmpty && customDish.items.every((it) {
        final fId = it.foodId ?? it.food?.id;
        final resolvedByName = foodMap[it.displayName.trim().toLowerCase()];
        return (fId != null && inStock.contains(fId)) ||
            (resolvedByName != null && inStock.contains(resolvedByName));
      });

      expect(ok, isTrue);
    });

    test('Test 6: Dish with 0 items is NOT cookable', () {
      final emptyDish = Dish(
        id: 'empty-1',
        householdId: 'h-1',
        name: 'Leeres Gericht',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [],
      );

      final inStock = {'some-food-id'};

      final isCookable = emptyDish.items.isNotEmpty && emptyDish.items.every((it) {
        final fId = it.foodId ?? it.food?.id;
        return fId != null && inStock.contains(fId);
      });

      expect(isCookable, isFalse);
    });

    test('Test 7: Household boundary - stock in Household A does not make dish cookable in Household B', () async {
      await householdProvider.loadHouseholds();
      final hh1 = householdProvider.currentHousehold!;

      await householdProvider.createHousehold(name: 'Haushalt B 🦖');
      final hh2 = householdProvider.currentHousehold!;

      // In Household A, add all ingredients for Spaghetti Bolognese
      foodProvider.bindToHousehold(hh1.id);
      stockProvider.bindToHousehold(hh1.id);

      await dishProvider.loadDishes(hh1.id);
      await foodProvider.loadFoods();

      final bologneseA = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      for (final it in bologneseA.items) {
        final fId = it.foodId ?? it.food?.id ?? foodProvider.foods.firstWhere((f) => f.name == it.displayName).id;
        if (!stockProvider.inStockFoodIds.contains(fId)) {
          await stockProvider.toggleStock(fId);
        }
      }

      // Switch to Household B
      final stockProviderB = StockProvider();
      final foodProviderB = FoodProvider();
      final dishProviderB = DishProvider();

      foodProviderB.bindToHousehold(hh2.id);
      stockProviderB.bindToHousehold(hh2.id);

      await dishProviderB.loadDishes(hh2.id);
      await foodProviderB.loadFoods();

      // Household B's stock is empty -> Bolognese in Household B is NOT cookable
      final bologneseB = dishProviderB.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      final inStockB = stockProviderB.inStockFoodIds;
      final foodMapB = {for (final f in foodProviderB.foods) f.name.trim().toLowerCase(): f.id};

      final isCookableB = bologneseB.items.isNotEmpty && bologneseB.items.every((it) {
        final fId = it.foodId ?? it.food?.id;
        final resolvedByName = foodMapB[it.displayName.trim().toLowerCase()];
        return (fId != null && inStockB.contains(fId)) ||
            (resolvedByName != null && inStockB.contains(resolvedByName));
      });

      expect(isCookableB, isFalse);
    });
  });
}
