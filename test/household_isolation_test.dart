import 'dart:io';

import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/services/dish_service.dart';
import 'package:dino_food/services/stock_service.dart';
import 'package:dino_food/utils/recipe_ingredient_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('two-household isolation', () {
    test(
      'switching A -> B -> A never mixes foods, stock, shopping or dishes',
      () async {
        final households = HouseholdProvider();
        final foods = FoodProvider();
        final stock = StockProvider();
        final shopping = ShoppingProvider();
        final dishes = DishProvider();

        await households.loadHouseholds();
        await households.createHousehold(name: 'Isolation A');
        final householdA = households.currentHousehold!;
        await households.createHousehold(name: 'Isolation B');
        final householdB = households.currentHousehold!;

        Future<void> bind(String householdId) async {
          foods.bindToHousehold(householdId);
          stock.bindToHousehold(householdId);
          shopping.bindToHousehold(householdId);
          await foods.loadFoods(force: true);
          await dishes.loadDishes(householdId);
        }

        await bind(householdA.id);
        final riceA = foods.foods.firstWhere(
          (food) => food.name == 'Reis' && food.note == 'Basmati',
        );
        final tomatoA = foods.foods.firstWhere(
          (food) => food.name == 'Tomaten' && food.note == 'gehackt',
        );
        expect(await stock.addToStock(riceA.id), isTrue);
        expect(await shopping.addItem(customName: 'Milch'), isTrue);
        expect(
          await dishes.createDish(
            householdId: householdA.id,
            name: 'Testgericht A',
            items: [
              {'food_id': riceA.id},
              {'food_id': tomatoA.id},
            ],
          ),
          isTrue,
        );

        await bind(householdB.id);
        final riceB = foods.foods.firstWhere(
          (food) => food.name == 'Reis' && food.note == 'Jasmin',
        );
        expect(await shopping.addItem(customName: 'Brot'), isTrue);
        expect(
          await dishes.createDish(
            householdId: householdB.id,
            name: 'Testgericht B',
            items: [
              {'food_id': riceB.id},
            ],
          ),
          isTrue,
        );

        expect(foods.foods, isNotEmpty);
        expect(
          foods.foods.every((food) => food.householdId == householdB.id),
          isTrue,
        );
        expect(foods.foods.any((food) => food.id == riceA.id), isFalse);
        expect(
          shopping.allItems.map((item) => item.customName),
          contains('Brot'),
        );
        expect(
          shopping.allItems.map((item) => item.customName),
          isNot(contains('Milch')),
        );
        expect(
          dishes.dishes.map((dish) => dish.name),
          contains('Testgericht B'),
        );
        expect(
          dishes.dishes.map((dish) => dish.name),
          isNot(contains('Testgericht A')),
        );
        expect(stock.isInStock(riceB.id), isFalse);
        expect(stock.isInStock(riceA.id), isFalse);
        final matchesB = dishes.getRankedDishesForHunger(
          hungerFood: riceB,
          inStockFoodIds: stock.inStockFoodIds,
          foodIdsByName: RecipeIngredientMatcher.indexFoods(foods.foods),
        );
        expect(matchesB, isNotEmpty);
        expect(matchesB.every((match) => !match.isMainInStock), isTrue);

        await bind(householdA.id);
        expect(
          foods.foods.every((food) => food.householdId == householdA.id),
          isTrue,
        );
        expect(foods.foods.any((food) => food.id == riceB.id), isFalse);
        expect(
          shopping.allItems.map((item) => item.customName),
          contains('Milch'),
        );
        expect(
          shopping.allItems.map((item) => item.customName),
          isNot(contains('Brot')),
        );
        expect(
          dishes.dishes.map((dish) => dish.name),
          contains('Testgericht A'),
        );
        expect(
          dishes.dishes.map((dish) => dish.name),
          isNot(contains('Testgericht B')),
        );
        expect(stock.isInStock(riceA.id), isTrue);
        final matchesA = dishes.getRankedDishesForHunger(
          hungerFood: riceA,
          inStockFoodIds: stock.inStockFoodIds,
          foodIdsByName: RecipeIngredientMatcher.indexFoods(foods.foods),
        );
        expect(matchesA, isNotEmpty);
        expect(matchesA.every((match) => match.isMainInStock), isTrue);
      },
    );

    test(
      'services and providers reject food IDs from another household',
      () async {
        final households = HouseholdProvider();
        final foodsA = FoodProvider();
        final foodsB = FoodProvider();
        final shoppingA = ShoppingProvider();
        final stockA = StockProvider();
        final stockB = StockProvider();
        final dishesA = DishProvider();

        await households.loadHouseholds();
        await households.createHousehold(name: 'Write isolation A');
        final householdA = households.currentHousehold!;
        await households.createHousehold(name: 'Write isolation B');
        final householdB = households.currentHousehold!;

        foodsA.bindToHousehold(householdA.id);
        foodsB.bindToHousehold(householdB.id);
        await foodsA.loadFoods(force: true);
        await foodsB.loadFoods(force: true);
        final foreignRice = foodsB.foods.firstWhere(
          (food) => food.name == 'Reis',
        );

        shoppingA.bindToHousehold(householdA.id);
        stockA.bindToHousehold(householdA.id);
        stockB.bindToHousehold(householdB.id);
        await dishesA.loadDishes(householdA.id);

        expect(await shoppingA.addItem(foodId: foreignRice.id), isFalse);
        expect(await shoppingA.addItem(customName: 'Nur Haushalt A'), isTrue);
        await shoppingA.toggleItemChecked(shoppingA.allItems.single.id);
        expect(
          await shoppingA.clearCheckedItems(
            stockProvider: stockB,
            foodProvider: foodsB,
          ),
          0,
        );
        expect(shoppingA.allItems, hasLength(1));
        expect(await stockA.addToStock(foreignRice.id), isFalse);
        expect(
          await dishesA.createDish(
            householdId: householdA.id,
            name: 'Ungültige Verknüpfung',
            items: [
              {'food_id': foreignRice.id},
            ],
          ),
          isFalse,
        );
        expect(
          () => StockService().setInStock(
            householdId: householdA.id,
            foodId: foreignRice.id,
            inStock: true,
          ),
          throwsStateError,
        );
        expect(
          DishService().addItemsToShoppingList(
            householdId: householdA.id,
            items: [
              DishItem(
                id: 'foreign-item',
                dishId: 'foreign-dish',
                foodId: foreignRice.id,
              ),
            ],
          ),
          throwsStateError,
        );
      },
    );

    test('SQL hardening covers RLS, link triggers and diagnostics', () async {
      final migration = await File(
        'supabase/migrations/zzzzzz_household_isolation_hardening.sql',
      ).readAsString();
      final diagnostics = await File('supabase_diagnose_household_links.sql')
          .readAsString();

      expect(migration, contains('enforce_household_food_link'));
      expect(migration, contains('prevent_household_reassignment'));
      expect(
        migration,
        contains('Household creator can initialize membership'),
      );
      expect(
        migration,
        isNot(contains('create or replace function public.is_household_owner')),
      );
      expect(migration, contains('food_id is null or exists'));
      expect(diagnostics.toLowerCase(), isNot(contains('delete from')));
      expect(diagnostics.toLowerCase(), isNot(contains('update public')));
      expect(diagnostics, contains('food_actual_household_id'));
    });
  });
}
