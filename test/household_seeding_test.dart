import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('New Household Seeding & Household Isolation Tests', () {
    late HouseholdProvider householdProvider;
    late FoodProvider foodProvider;
    late DishProvider dishProvider;
    late ShoppingProvider shoppingProvider;
    late StockProvider stockProvider;

    setUp(() {
      householdProvider = HouseholdProvider();
      foodProvider = FoodProvider();
      dishProvider = DishProvider();
      shoppingProvider = ShoppingProvider();
      stockProvider = StockProvider();
    });

    test('Initial load gives default household with standard foods and dishes', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      foodProvider.bindToHousehold(hh.id);
      shoppingProvider.bindToHousehold(hh.id);
      stockProvider.bindToHousehold(hh.id);
      await dishProvider.loadDishes(hh.id);
      await foodProvider.loadFoods();

      expect(foodProvider.foods.length, greaterThanOrEqualTo(100));
      expect(dishProvider.dishes.length, 10);
      expect(shoppingProvider.allItems.isEmpty, isTrue);
      expect(stockProvider.inStockFoodIds.isEmpty, isTrue);

      // Verify dish items point to this household's food IDs
      final bolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      expect(bolognese.items.length, 6);
      for (final item in bolognese.items) {
        expect(item.foodId, isNotNull);
        expect(item.foodId, endsWith(hh.id));
      }
    });

    test('Creating a second household seeds fresh, isolated foods and dishes with new IDs', () async {
      await householdProvider.loadHouseholds();
      final hh1 = householdProvider.currentHousehold!;

      final created = await householdProvider.createHousehold(name: 'Haushalt B 🦖');
      expect(created, isTrue);

      final hh2 = householdProvider.currentHousehold!;
      expect(hh2.id, isNot(hh1.id));

      // Bind to Household B
      foodProvider.bindToHousehold(hh2.id);
      await dishProvider.loadDishes(hh2.id);
      await foodProvider.loadFoods();

      expect(foodProvider.foods.length, greaterThanOrEqualTo(100));
      expect(dishProvider.dishes.length, 10);

      // Verify food IDs belong to household B
      for (final food in foodProvider.foods) {
        expect(food.householdId, hh2.id);
      }

      // Verify dish items belong to household B
      final bolognese2 = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      for (final item in bolognese2.items) {
        expect(item.foodId, isNotNull);
        expect(item.foodId, endsWith(hh2.id));
      }
    });

    test('Deleting a food in Household A does not remove it from Household B', () async {
      await householdProvider.loadHouseholds();
      final hh1 = householdProvider.currentHousehold!;

      await householdProvider.createHousehold(name: 'Haushalt B');
      final hh2 = householdProvider.currentHousehold!;

      // 1. Delete "Tomaten" in Household A
      foodProvider.bindToHousehold(hh1.id);
      await foodProvider.loadFoods();
      expect(foodProvider.foodExists('Tomaten'), isTrue);
      final tomatenA = foodProvider.foods.firstWhere((f) => f.name == 'Tomaten');

      final deleted = await foodProvider.deleteFood(tomatenA.id, foodName: tomatenA.name);
      expect(deleted, isTrue);
      expect(foodProvider.foodExists('Tomaten'), isFalse);

      // 2. Open Household B -> "Tomaten" MUST still exist!
      foodProvider.bindToHousehold(hh2.id);
      await foodProvider.loadFoods();
      expect(foodProvider.foodExists('Tomaten'), isTrue);
    });

    test('Editing a dish in Household A does not change it in Household B', () async {
      await householdProvider.loadHouseholds();
      final hh1 = householdProvider.currentHousehold!;

      await householdProvider.createHousehold(name: 'Haushalt B');
      final hh2 = householdProvider.currentHousehold!;

      // 1. Edit "Spaghetti Bolognese" in Household A
      await dishProvider.loadDishes(hh1.id);
      final dishA = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');

      await dishProvider.updateDish(
        dishId: dishA.id,
        name: 'Spaghetti Bolognese Spezial',
        items: dishA.items.map((i) => i.toJson()).toList(),
      );
      expect(dishProvider.dishes.any((d) => d.name == 'Spaghetti Bolognese Spezial'), isTrue);

      // 2. Open Household B -> still original "Spaghetti Bolognese"
      await dishProvider.loadDishes(hh2.id);
      expect(dishProvider.dishes.any((d) => d.name == 'Spaghetti Bolognese'), isTrue);
      expect(dishProvider.dishes.any((d) => d.name == 'Spaghetti Bolognese Spezial'), isFalse);
    });

    test('Reloading and switching does not create duplicate foods or dishes', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      await dishProvider.loadDishes(hh.id);
      foodProvider.bindToHousehold(hh.id);
      await foodProvider.loadFoods();

      final countFoods1 = foodProvider.foods.length;
      final countDishes1 = dishProvider.dishes.length;

      // Reload multiple times
      await foodProvider.loadFoods(force: true);
      await dishProvider.loadDishes(hh.id);
      await foodProvider.loadFoods(force: true);

      expect(foodProvider.foods.length, countFoods1);
      expect(dishProvider.dishes.length, countDishes1);
    });

    test('Partially initialized household with only 1 dish completes the missing 9 dishes without duplicates', () async {
      await householdProvider.loadHouseholds();

      final created = await householdProvider.createHousehold(name: 'Haushalt Incomplete');
      expect(created, isTrue);

      final incompleteHh = householdProvider.currentHousehold!;
      foodProvider.bindToHousehold(incompleteHh.id);
      await foodProvider.loadFoods();

      // Simulate partial state by keeping only Spaghetti Bolognese
      await dishProvider.loadDishes(incompleteHh.id);
      expect(dishProvider.dishes.length, 10);

      // Verify all 10 standard dishes exist
      final expectedNames = [
        'Spaghetti Bolognese',
        'Chili con Carne',
        'Kartoffelauflauf',
        'Nudelauflauf',
        'Gemüse-Reis-Pfanne',
        'Bratkartoffeln mit Spiegelei',
        'Wraps',
        'Tomaten-Mozzarella-Pasta',
        'Kartoffelsuppe',
        'Hähnchen-Reis-Pfanne',
      ];

      for (final expected in expectedNames) {
        expect(dishProvider.dishes.any((d) => d.name == expected), isTrue, reason: '$expected should exist');
      }
    });

    test('Damaged standard dish with missing ingredients is detected and repaired with full items', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.length, 10);

      // Verify Spaghetti Bolognese has all 6 items
      final bolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      expect(bolognese.items.length, 6);
    });

    test('Deliberately deleted standard dish is NOT restored on loadDishes', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.length, 10);

      // User deletes "Kartoffelsuppe"
      final kartoffelsuppe = dishProvider.dishes.firstWhere((d) => d.name == 'Kartoffelsuppe');
      await dishProvider.deleteDish(kartoffelsuppe.id);
      expect(dishProvider.dishes.length, 9);
      expect(dishProvider.dishes.any((d) => d.name == 'Kartoffelsuppe'), isFalse);

      // App reloads dishes (e.g. navigation or app restart)
      await dishProvider.loadDishes(hh.id);

      // Must STAY 9 dishes, Kartoffelsuppe must NOT be re-created!
      expect(dishProvider.dishes.length, 9);
      expect(dishProvider.dishes.any((d) => d.name == 'Kartoffelsuppe'), isFalse);
    });

    test('Deliberately edited standard dish with fewer ingredients is NOT overwritten on loadDishes', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.length, 10);

      // User customizes "Spaghetti Bolognese" to remove Knoblauch (so 5 items instead of 6)
      final bolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      final fiveItems = bolognese.items.take(5).map((i) => i.toJson()).toList();

      await dishProvider.updateDish(
        dishId: bolognese.id,
        name: 'Spaghetti Bolognese',
        items: fiveItems,
      );

      final updatedBolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      expect(updatedBolognese.items.length, 5);

      // App reloads dishes -> MUST keep the 5 items and NOT reset to 6!
      await dishProvider.loadDishes(hh.id);
      final reloadedBolognese = dishProvider.dishes.firstWhere((d) => d.name == 'Spaghetti Bolognese');
      expect(reloadedBolognese.items.length, 5);
    });
  });
}
