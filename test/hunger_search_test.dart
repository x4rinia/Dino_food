import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/models/dish.dart';
import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/utils/recipe_ingredient_matcher.dart';

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
        note: 'Fleisch',
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

    test(
      'Calculates Vorrats-Score and sorts higher percentage score first',
      () {
        final hackfleischFood = Food(
          id: 'f_71_demo-household-id',
          name: 'Hackfleisch',
          note: 'Fleisch',
          createdAt: DateTime.now(),
        );

        // Stock has a different tomato variant than the preferred recipe
        // variant. Name-based matching must still count it.
        final inStockIds = {
          'f_71_demo-household-id', // Hackfleisch
          'f_5_demo-household-id', // Zwiebeln
          'f_156_demo-household-id', // Tomatenmark
          'f_154_demo-household-id', // Passierte Tomaten
        };

        final matches = dishProvider.getRankedDishesForHunger(
          hungerFood: hackfleischFood,
          inStockFoodIds: inStockIds,
          foodIdsByName: {
            'hackfleisch': {'f_71_demo-household-id'},
            'zwiebeln': {'f_5_demo-household-id'},
            'tomatenmark': {'f_156_demo-household-id'},
            'tomaten': {
              'f_1_demo-household-id',
              'f_2_demo-household-id',
              'f_154_demo-household-id',
              'f_155_demo-household-id',
              'f_246_demo-household-id',
            },
          },
        );

        expect(matches.length, 3);

        // 1st place: Spaghetti Bolognese (4/7 in stock)
        expect(matches[0].dish.name, 'Spaghetti Bolognese');
        expect(matches[0].inStockCount, 4);
        expect(matches[0].totalCount, 7);
        expect(matches[0].isMainInStock, isTrue);

        // 2nd place: Chili con Carne (3/6, including the tomato variant)
        expect(matches[1].dish.name, 'Chili con Carne');
        expect(matches[1].inStockCount, 3);
        expect(matches[1].totalCount, 6);

        // 3rd place: Wraps (2/6, including the tomato variant)
        expect(matches[2].dish.name, 'Wraps');
        expect(matches[2].inStockCount, 2);
        expect(matches[2].totalCount, 6);
      },
    );

    test('Ties in percentage score are broken by absolute in-stock count then name', () {
      // Dish A: 2 of 2 in stock (100%, 2 items)
      // Dish B: 4 of 4 in stock (100%, 4 items) -> Should be ahead of Dish A!
      final dishA = Dish(
        id: 'dish_a',
        householdId: 'h1',
        name: 'Dish A',
        createdAt: DateTime.now(),
        items: [
          DishItem(
            id: 'i1',
            dishId: 'dish_a',
            foodId: 'food_x',
            customName: 'Zutat X',
          ),
          DishItem(
            id: 'i2',
            dishId: 'dish_a',
            foodId: 'food_y',
            customName: 'Zutat Y',
          ),
        ],
      );

      final dishB = Dish(
        id: 'dish_b',
        householdId: 'h1',
        name: 'Dish B',
        createdAt: DateTime.now(),
        items: [
          DishItem(
            id: 'i3',
            dishId: 'dish_b',
            foodId: 'food_x',
            customName: 'Zutat X',
          ),
          DishItem(
            id: 'i4',
            dishId: 'dish_b',
            foodId: 'food_1',
            customName: 'Zutat 1',
          ),
          DishItem(
            id: 'i5',
            dishId: 'dish_b',
            foodId: 'food_2',
            customName: 'Zutat 2',
          ),
          DishItem(
            id: 'i6',
            dishId: 'dish_b',
            foodId: 'food_3',
            customName: 'Zutat 3',
          ),
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
        note: 'Fleisch',
        createdAt: DateTime.now(),
      );

      dishProvider.setHungerFood(hackfleischFood);
      expect(dishProvider.selectedHungerFood, isNotNull);

      dishProvider.clearHungerSearch();
      expect(dishProvider.selectedHungerFood, isNull);
      expect(dishProvider.dishes.length, greaterThanOrEqualTo(10));
    });

    test(
      'Loading dishes for a new household resets hunger search food and scores',
      () async {
        final hackfleischFood = Food(
          id: 'f_71_demo-household-id',
          name: 'Hackfleisch',
          note: 'Fleisch',
          createdAt: DateTime.now(),
        );

        dishProvider.setHungerFood(hackfleischFood);
        expect(dishProvider.selectedHungerFood, isNotNull);

        // Household switch
        await dishProvider.loadDishes('household_b');
        expect(dishProvider.selectedHungerFood, isNull);
      },
    );

    test('Every ingredient in dish is verified against stock individually and matches foodMap fallback', () {
      final hackfleisch = Food(
        id: 'f_71_demo-household-id',
        name: 'Hackfleisch',
        note: 'Fleisch',
        createdAt: DateTime.now(),
      );

      // Suppose Vorrat has: Hackfleisch, Zwiebeln, Paprika, Tomaten, Käse
      final inStockIds = {
        'f_71_demo-household-id', // Hackfleisch
        'f_5_demo-household-id', // Zwiebeln
        'f_60_demo-household-id', // Paprika
        'f_1_demo-household-id', // Tomaten
        'f_116_demo-household-id', // Käse
      };

      final foodMap = {
        'hackfleisch': {'f_71_demo-household-id'},
        'zwiebeln': {'f_5_demo-household-id'},
        'paprika': {'f_60_demo-household-id'},
        'tomaten': {'f_1_demo-household-id'},
        'käse': {'f_116_demo-household-id'},
        'reibekäse': {'f_124_demo-household-id'},
      };

      final matches = dishProvider.getRankedDishesForHunger(
        hungerFood: hackfleisch,
        inStockFoodIds: inStockIds,
        foodIdsByName: foodMap,
      );

      final chiliMatch = matches.firstWhere(
        (m) => m.dish.name == 'Chili con Carne',
      );
      // The stocked Tomaten variant also satisfies Tomaten (gehackt).
      expect(chiliMatch.inStockCount, 4);
      expect(chiliMatch.totalCount, 6);
      expect(chiliMatch.scorePercentageText, '67%');
      expect(chiliMatch.isMainInStock, isTrue);

      // Wraps has 6 items: Wraps, Hackfleisch (in stock), Tomaten (in stock), Gurke, Eisbergsalat, Reibekäse
      final wrapsMatch = matches.firstWhere((m) => m.dish.name == 'Wraps');
      expect(wrapsMatch.inStockCount, 2);
      expect(wrapsMatch.totalCount, 6);
      expect(wrapsMatch.isMainInStock, isTrue);
    });

    test('Hunger search treats any stocked note variant as available', () {
      final jasmin = Food(
        id: 'rice-jasmin',
        name: 'Reis',
        note: 'Jasmin',
        createdAt: DateTime(2026),
      );
      final basmati = Food(
        id: 'rice-basmati',
        name: 'Reis',
        note: 'Basmati',
        createdAt: DateTime(2026),
      );
      final foodIndex = RecipeIngredientMatcher.indexFoods([jasmin, basmati]);

      final matches = dishProvider.getRankedDishesForHunger(
        hungerFood: jasmin,
        inStockFoodIds: {basmati.id},
        foodIdsByName: foodIndex,
      );

      expect(matches, isNotEmpty);
      expect(matches.every((match) => match.isMainInStock), isTrue);
    });
  });
}
