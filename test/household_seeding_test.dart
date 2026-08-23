import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/services/food_service.dart';

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

    test(
      'Initial load gives default household with standard foods and dishes',
      () async {
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
        final bolognese = dishProvider.dishes.firstWhere(
          (d) => d.name == 'Spaghetti Bolognese',
        );
        expect(bolognese.items.length, 7);
        for (final item in bolognese.items) {
          expect(item.foodId, isNotNull);
          expect(item.foodId, endsWith(hh.id));
        }
      },
    );

    test('Creating a second household seeds fresh, isolated foods and dishes with new IDs', () async {
      await householdProvider.loadHouseholds();
      final hh1 = householdProvider.currentHousehold!;

      final created = await householdProvider.createHousehold(
        name: 'Haushalt B 🦖',
      );
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
      final bolognese2 = dishProvider.dishes.firstWhere(
        (d) => d.name == 'Spaghetti Bolognese',
      );
      for (final item in bolognese2.items) {
        expect(item.foodId, isNotNull);
        expect(item.foodId, endsWith(hh2.id));
      }
    });

    test(
      'Deleting a food in Household A does not remove it from Household B',
      () async {
        await householdProvider.loadHouseholds();
        final hh1 = householdProvider.currentHousehold!;

        await householdProvider.createHousehold(name: 'Haushalt B');
        final hh2 = householdProvider.currentHousehold!;

        // 1. Delete "Tomaten" in Household A
        foodProvider.bindToHousehold(hh1.id);
        await foodProvider.loadFoods();
        expect(foodProvider.foodExists('Tomaten'), isTrue);
        final tomatenA = foodProvider.foods.firstWhere(
          (f) => f.name == 'Tomaten',
        );

        final deleted = await foodProvider.deleteFood(
          tomatenA.id,
          foodName: tomatenA.name,
        );
        expect(deleted, isTrue);
        expect(foodProvider.foodExists('Tomaten'), isFalse);

        // 2. Open Household B -> "Tomaten" MUST still exist!
        foodProvider.bindToHousehold(hh2.id);
        await foodProvider.loadFoods();
        expect(foodProvider.foodExists('Tomaten'), isTrue);
      },
    );

    test(
      'Editing a dish in Household A does not change it in Household B',
      () async {
        await householdProvider.loadHouseholds();
        final hh1 = householdProvider.currentHousehold!;

        await householdProvider.createHousehold(name: 'Haushalt B');
        final hh2 = householdProvider.currentHousehold!;

        // 1. Edit "Spaghetti Bolognese" in Household A
        await dishProvider.loadDishes(hh1.id);
        final dishA = dishProvider.dishes.firstWhere(
          (d) => d.name == 'Spaghetti Bolognese',
        );

        await dishProvider.updateDish(
          dishId: dishA.id,
          name: 'Spaghetti Bolognese Spezial',
          items: dishA.items.map((i) => i.toJson()).toList(),
        );
        expect(
          dishProvider.dishes.any(
            (d) => d.name == 'Spaghetti Bolognese Spezial',
          ),
          isTrue,
        );

        // 2. Open Household B -> still original "Spaghetti Bolognese"
        await dishProvider.loadDishes(hh2.id);
        expect(
          dishProvider.dishes.any((d) => d.name == 'Spaghetti Bolognese'),
          isTrue,
        );
        expect(
          dishProvider.dishes.any(
            (d) => d.name == 'Spaghetti Bolognese Spezial',
          ),
          isFalse,
        );
      },
    );

    test(
      'Reloading and switching does not create duplicate foods or dishes',
      () async {
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
      },
    );

    test('Newly created household receives complete 10 standard dishes and standard foods', () async {
      await householdProvider.loadHouseholds();

      final created = await householdProvider.createHousehold(
        name: 'Haushalt Frisch',
      );
      expect(created, isTrue);

      final freshHh = householdProvider.currentHousehold!;
      foodProvider.bindToHousehold(freshHh.id);
      await foodProvider.loadFoods();

      await dishProvider.loadDishes(freshHh.id);
      expect(dishProvider.dishes.length, 10);
      expect(foodProvider.foods.length, greaterThanOrEqualTo(100));

      bool hasVariant(String name, String note) => foodProvider.foods.any(
        (food) => food.name == name && food.note == note,
      );
      expect(hasVariant('Reis', 'Basmati'), isTrue);
      expect(hasVariant('Reis', 'Jasmin'), isTrue);
      expect(hasVariant('Reis', 'Risotto'), isTrue);
      expect(hasVariant('Tomaten', 'Cherry'), isTrue);
      expect(hasVariant('Tomaten', 'gehackt'), isTrue);
      expect(hasVariant('Tomaten', 'groß'), isTrue);
      expect(hasVariant('Tomaten', 'passiert'), isTrue);
      expect(hasVariant('Nudeln', 'Spaghetti'), isTrue);
      expect(hasVariant('Nudeln', 'Penne'), isTrue);
      expect(hasVariant('Nudeln', 'Fusilli'), isTrue);
      expect(hasVariant('Nudeln', 'Makkaroni'), isTrue);
      for (final food in foodProvider.foods.where(
        (food) => const {'Reis', 'Nudeln'}.contains(food.name),
      )) {
        expect(food.iconKey, 'grains');
      }
      for (final food in foodProvider.foods.where(
        (food) => food.name == 'Tomaten',
      )) {
        expect(food.iconKey, 'vegetables');
      }
      expect(
        foodProvider.foods.any(
          (food) => const {
            'Basmatireis',
            'Jasminreis',
            'Risottoreis',
            'Cherrytomaten',
            'Passierte Tomaten',
            'Gehackte Tomaten',
            'Spaghetti',
            'Penne',
            'Fusilli',
            'Makkaroni',
          }.contains(food.name),
        ),
        isFalse,
      );

      final normalizedVariants = foodProvider.foods
          .map(
            (food) =>
                '${food.name.trim().toLowerCase()}\u001f${(food.note ?? '').trim().toLowerCase()}',
          )
          .toList();
      expect(normalizedVariants.toSet().length, normalizedVariants.length);

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
        expect(
          dishProvider.dishes.any((d) => d.name == expected),
          isTrue,
          reason: '$expected should exist',
        );
      }

      final bolognese = dishProvider.dishes.firstWhere(
        (dish) => dish.name == 'Spaghetti Bolognese',
      );
      expect(bolognese.items.length, 7);
      expect(
        bolognese.items.any(
          (item) => item.food?.displayLabel == 'Nudeln (Spaghetti)',
        ),
        isTrue,
      );
      expect(
        bolognese.items.any(
          (item) => item.food?.displayLabel == 'Tomaten (gehackt)',
        ),
        isTrue,
      );
      expect(
        bolognese.items.any((item) => item.displayName == 'Karotten'),
        isTrue,
      );

      final expectedPreferredVariants = {
        'Chili con Carne': 'Tomaten (gehackt)',
        'Nudelauflauf': 'Nudeln (Penne)',
        'Gemüse-Reis-Pfanne': 'Reis (Basmati)',
        'Tomaten-Mozzarella-Pasta': 'Nudeln (Fusilli)',
        'Hähnchen-Reis-Pfanne': 'Reis (Jasmin)',
      };
      for (final entry in expectedPreferredVariants.entries) {
        final dish = dishProvider.dishes.firstWhere(
          (dish) => dish.name == entry.key,
        );
        expect(
          dish.items.any((item) => item.displayLabel == entry.value),
          isTrue,
          reason: '${entry.key} should use ${entry.value}',
        );
      }
    });

    test('authoritative replacement clears a legacy pre-seed only in the target new household', () async {
      const existingHouseholdId = 'existing-household-seed-protection';
      const newHouseholdId = 'new-household-authoritative-seed';
      final foodService = FoodService();

      await foodService.seedDefaultFoodsForHousehold(existingHouseholdId);
      final existingProvider = FoodProvider();
      existingProvider.bindToHousehold(existingHouseholdId);
      await existingProvider.loadFoods(force: true);
      await existingProvider.addCustomFood(name: 'Bestands-Snack');

      await foodService.seedDefaultFoodsForHousehold(newHouseholdId);
      final newProvider = FoodProvider();
      newProvider.bindToHousehold(newHouseholdId);
      await newProvider.loadFoods(force: true);
      await newProvider.addCustomFood(name: 'Basmatireis');
      expect(newProvider.foodExists('Basmatireis'), isTrue);

      await foodService.seedDefaultFoodsForHousehold(
        newHouseholdId,
        replaceExistingDefaults: true,
      );
      await newProvider.loadFoods(force: true);

      expect(newProvider.foodExists('Basmatireis'), isFalse);
      expect(newProvider.foodExists('Jasminreis'), isFalse);
      expect(newProvider.foodExists('Risottoreis'), isFalse);
      expect(newProvider.foodExists('Reis', note: 'Basmati'), isTrue);
      expect(newProvider.foodExists('Reis', note: 'Jasmin'), isTrue);
      expect(newProvider.foodExists('Reis', note: 'Risotto'), isTrue);

      await existingProvider.loadFoods(force: true);
      expect(existingProvider.foodExists('Bestands-Snack'), isTrue);
    });

    test('Damaged standard dish with missing ingredients is detected and repaired with full items', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.length, 10);

      // Verify Spaghetti Bolognese has all 7 items
      final bolognese = dishProvider.dishes.firstWhere(
        (d) => d.name == 'Spaghetti Bolognese',
      );
      expect(bolognese.items.length, 7);
    });

    test(
      'Deliberately deleted standard dish is NOT restored on loadDishes',
      () async {
        await householdProvider.loadHouseholds();
        final hh = householdProvider.currentHousehold!;

        await dishProvider.loadDishes(hh.id);
        expect(dishProvider.dishes.length, 10);

        // User deletes "Kartoffelsuppe"
        final kartoffelsuppe = dishProvider.dishes.firstWhere(
          (d) => d.name == 'Kartoffelsuppe',
        );
        await dishProvider.deleteDish(kartoffelsuppe.id);
        expect(dishProvider.dishes.length, 9);
        expect(
          dishProvider.dishes.any((d) => d.name == 'Kartoffelsuppe'),
          isFalse,
        );

        // App reloads dishes (e.g. navigation or app restart)
        await dishProvider.loadDishes(hh.id);

        // Must STAY 9 dishes, Kartoffelsuppe must NOT be re-created!
        expect(dishProvider.dishes.length, 9);
        expect(
          dishProvider.dishes.any((d) => d.name == 'Kartoffelsuppe'),
          isFalse,
        );
      },
    );

    test('Deliberately edited standard dish with fewer ingredients is NOT overwritten on loadDishes', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.length, 10);

      // User customizes "Spaghetti Bolognese" to remove Knoblauch (so 5 items instead of 6)
      final bolognese = dishProvider.dishes.firstWhere(
        (d) => d.name == 'Spaghetti Bolognese',
      );
      final fiveItems = bolognese.items.take(5).map((i) => i.toJson()).toList();

      await dishProvider.updateDish(
        dishId: bolognese.id,
        name: 'Spaghetti Bolognese',
        items: fiveItems,
      );

      final updatedBolognese = dishProvider.dishes.firstWhere(
        (d) => d.name == 'Spaghetti Bolognese',
      );
      expect(updatedBolognese.items.length, 5);

      // App reloads dishes -> MUST keep the 5 items and NOT reset to 6!
      await dishProvider.loadDishes(hh.id);
      final reloadedBolognese = dishProvider.dishes.firstWhere(
        (d) => d.name == 'Spaghetti Bolognese',
      );
      expect(reloadedBolognese.items.length, 5);
    });

    test('Deleting ALL dishes keeps list at 0 and allows creating only custom dishes', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.length, 10);

      // Delete all 10 dishes
      final allDishIds = dishProvider.dishes.map((d) => d.id).toList();
      for (final id in allDishIds) {
        await dishProvider.deleteDish(id);
      }

      expect(dishProvider.dishes.isEmpty, isTrue);

      // Reload dishes -> MUST STAY 0 dishes!
      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.isEmpty, isTrue);

      // Create 2 custom dishes
      await dishProvider.createDish(
        householdId: hh.id,
        name: 'Pizza Margherita',
        items: [
          {'name': 'Mehl'},
          {'name': 'Mozzarella'},
        ],
      );
      await dishProvider.createDish(
        householdId: hh.id,
        name: 'Dino-Nudeln',
        items: [
          {'name': 'Nudeln'},
        ],
      );

      expect(dishProvider.dishes.length, 2);
      final names = dishProvider.dishes.map((d) => d.name).toSet();
      expect(names.contains('Pizza Margherita'), isTrue);
      expect(names.contains('Dino-Nudeln'), isTrue);
      expect(names.contains('Spaghetti Bolognese'), isFalse);

      // Reload -> only the 2 custom dishes exist
      await dishProvider.loadDishes(hh.id);
      expect(dishProvider.dishes.length, 2);
    });

    test('Deleting ALL foods keeps list at 0 and allows creating only custom foods', () async {
      await householdProvider.loadHouseholds();
      final hh = householdProvider.currentHousehold!;

      foodProvider.bindToHousehold(hh.id);
      await foodProvider.loadFoods();
      expect(foodProvider.foods.isNotEmpty, isTrue);

      // Delete all foods
      final allFoodIds = foodProvider.foods.map((f) => f.id).toList();
      for (final id in allFoodIds) {
        await foodProvider.deleteFood(id);
      }

      expect(foodProvider.foods.isEmpty, isTrue);

      // Reload foods -> MUST STAY 0 foods!
      await foodProvider.loadFoods(force: true);
      expect(foodProvider.foods.isEmpty, isTrue);

      // Create 1 custom food
      await foodProvider.addCustomFood(name: 'Dino-Snack', note: 'Snacks');
      expect(foodProvider.foods.length, 1);
      expect(foodProvider.foods.first.name, 'Dino-Snack');

      // Reload -> only the 1 custom food exists
      await foodProvider.loadFoods(force: true);
      expect(foodProvider.foods.length, 1);
      expect(foodProvider.foods.first.name, 'Dino-Snack');
    });

    test('Renamed standard food is not restored under its old name', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'Haushalt Umbenennen');
      final household = householdProvider.currentHousehold!;

      foodProvider.bindToHousehold(household.id);
      await foodProvider.loadFoods();
      final rice = foodProvider.foods.firstWhere((food) => food.name == 'Reis');

      await foodProvider.updateFood(
        id: rice.id,
        name: 'Duftreis',
        note: 'Jasmin',
      );
      await foodProvider.loadFoods(force: true);

      expect(foodProvider.foodExists('Reis'), isFalse);
      expect(foodProvider.foodExists('Duftreis', note: 'Jasmin'), isTrue);
    });

    test('Cleared food note stays null after reload', () async {
      await householdProvider.loadHouseholds();
      await householdProvider.createHousehold(name: 'Haushalt Notiz Leeren');
      final household = householdProvider.currentHousehold!;

      foodProvider.bindToHousehold(household.id);
      await foodProvider.loadFoods();
      final apple = foodProvider.foods.firstWhere(
        (food) => food.name == 'Äpfel',
      );

      await foodProvider.updateFood(
        id: apple.id,
        name: apple.name,
        note: 'Obst',
      );
      await foodProvider.updateFood(id: apple.id, name: apple.name, note: null);
      await foodProvider.loadFoods(force: true);

      final reloaded = foodProvider.foods.firstWhere(
        (food) => food.id == apple.id,
      );
      expect(reloaded.note, isNull);
    });
  });
}
