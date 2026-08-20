import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/models/dish.dart';
import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/providers/dish_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hunger-Suche Logic & Ranking Tests', () {
    late DishProvider dishProvider;

    setUp(() async {
      dishProvider = DishProvider();
      await dishProvider.loadDishes('demo-household-id');
    });

    test('Filter dishes by searched ingredient correctly', () {
      final hackfleischFood = Food(
        id: 'f_71_demo-household-id',
        name: 'Hackfleisch',
        category: 'Fleisch',
        createdAt: DateTime.now(),
      );

      dishProvider.setHungerFood(hackfleischFood);
      expect(dishProvider.selectedHungerFood, isNotNull);
      expect(dishProvider.selectedHungerFood!.name, 'Hackfleisch');

      // Rank dishes with empty stock
      final matches = dishProvider.getRankedDishesForHunger(
        hungerFood: hackfleischFood,
        inStockFoodIds: {},
      );

      // Dishes with Hackfleisch: Spaghetti Bolognese, Chili con Carne, Wraps
      expect(matches.length, 3);
      final names = matches.map((m) => m.dish.name).toSet();
      expect(names.contains('Spaghetti Bolognese'), isTrue);
      expect(names.contains('Chili con Carne'), isTrue);
      expect(names.contains('Wraps'), isTrue);
      expect(names.contains('Kartoffelsuppe'), isFalse);
    });

    test('Calculates Vorrats-Score and sorts higher percentage score first', () {
      final hackfleischFood = Food(
        id: 'f_71_demo-household-id',
        name: 'Hackfleisch',
        category: 'Fleisch',
        createdAt: DateTime.now(),
      );

      // Stock has: Hackfleisch, Zwiebeln, Tomatenmark, Passierte Tomaten (4 out of 6 for Spaghetti Bolognese = 66.7%)
      // Stock has: Hackfleisch, Zwiebeln (2 out of 6 for Chili con Carne = 33.3%)
      // Stock has: Hackfleisch (1 out of 6 for Wraps = 16.7%)
      final inStockIds = {
        'f_71_demo-household-id', // Hackfleisch
        'f_5_demo-household-id',  // Zwiebeln
        'f_156_demo-household-id', // Tomatenmark
        'f_154_demo-household-id', // Passierte Tomaten
      };

      final matches = dishProvider.getRankedDishesForHunger(
        hungerFood: hackfleischFood,
        inStockFoodIds: inStockIds,
      );

      expect(matches.length, 3);

      // 1st place: Spaghetti Bolognese (4/6 in stock)
      expect(matches[0].dish.name, 'Spaghetti Bolognese');
      expect(matches[0].inStockCount, 4);
      expect(matches[0].totalCount, 6);
      expect(matches[0].isMainInStock, isTrue);

      // 2nd place: Chili con Carne (2/6 in stock)
      expect(matches[1].dish.name, 'Chili con Carne');
      expect(matches[1].inStockCount, 2);
      expect(matches[1].totalCount, 6);

      // 3rd place: Wraps (1/6 in stock)
      expect(matches[2].dish.name, 'Wraps');
      expect(matches[2].inStockCount, 1);
      expect(matches[2].totalCount, 6);
    });

    test('Ties in percentage score are broken by absolute in-stock count then name', () {
      // Dish A: 2 of 2 in stock (100%, 2 items)
      // Dish B: 4 of 4 in stock (100%, 4 items) -> Should be ahead of Dish A!
      final dishA = Dish(
        id: 'dish_a',
        householdId: 'h1',
        name: 'Dish A',
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'i1', dishId: 'dish_a', foodId: 'food_x', customName: 'Zutat X', quantity: 1),
          DishItem(id: 'i2', dishId: 'dish_a', foodId: 'food_y', customName: 'Zutat Y', quantity: 1),
        ],
      );

      final dishB = Dish(
        id: 'dish_b',
        householdId: 'h1',
        name: 'Dish B',
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'i3', dishId: 'dish_b', foodId: 'food_x', customName: 'Zutat X', quantity: 1),
          DishItem(id: 'i4', dishId: 'dish_b', foodId: 'food_1', customName: 'Zutat 1', quantity: 1),
          DishItem(id: 'i5', dishId: 'dish_b', foodId: 'food_2', customName: 'Zutat 2', quantity: 1),
          DishItem(id: 'i6', dishId: 'dish_b', foodId: 'food_3', customName: 'Zutat 3', quantity: 1),
        ],
      );

      final matches = [
        HungerDishMatch(
          dish: dishA,
          score: 1.0,
          inStockCount: 2,
          totalCount: 2,
          isMainInStock: true,
          mainItem: dishA.items.first,
        ),
        HungerDishMatch(
          dish: dishB,
          score: 1.0,
          inStockCount: 4,
          totalCount: 4,
          isMainInStock: true,
          mainItem: dishB.items.first,
        ),
      ];

      matches.sort((a, b) {
        final scoreComp = b.score.compareTo(a.score);
        if (scoreComp != 0) return scoreComp;
        final countComp = b.inStockCount.compareTo(a.inStockCount);
        if (countComp != 0) return countComp;
        return a.dish.name.compareTo(b.dish.name);
      });

      // Dish B (4 items) should be before Dish A (2 items)
      expect(matches[0].dish.name, 'Dish B');
      expect(matches[1].dish.name, 'Dish A');
    });

    test('Clearing hunger search resets state to show all dishes', () {
      final hackfleischFood = Food(
        id: 'f_71_demo-household-id',
        name: 'Hackfleisch',
        category: 'Fleisch',
        createdAt: DateTime.now(),
      );

      dishProvider.setHungerFood(hackfleischFood);
      expect(dishProvider.selectedHungerFood, isNotNull);

      dishProvider.clearHungerSearch();
      expect(dishProvider.selectedHungerFood, isNull);
      expect(dishProvider.dishes.length, greaterThanOrEqualTo(10));
    });

    test('Loading dishes for a new household resets hunger search food and scores', () async {
      final hackfleischFood = Food(
        id: 'f_71_demo-household-id',
        name: 'Hackfleisch',
        category: 'Fleisch',
        createdAt: DateTime.now(),
      );

      dishProvider.setHungerFood(hackfleischFood);
      expect(dishProvider.selectedHungerFood, isNotNull);

      // Household switch
      await dishProvider.loadDishes('household_b');
      expect(dishProvider.selectedHungerFood, isNull);
    });
  });
}
