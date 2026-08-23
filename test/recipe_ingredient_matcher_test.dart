import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/utils/recipe_ingredient_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recipe ingredient matching ignores food notes', () {
    late Food plainRice;
    late Food basmatiRice;
    late Food jasminRice;
    late DishItem riceIngredient;
    late FoodIdsByNormalizedName foodIndex;

    setUp(() {
      final now = DateTime(2026);
      plainRice = Food(id: 'rice-plain', name: 'Reis', createdAt: now);
      basmatiRice = Food(
        id: 'rice-basmati',
        name: ' Reis ',
        note: 'Basmati',
        createdAt: now,
      );
      jasminRice = Food(
        id: 'rice-jasmin',
        name: 'REIS',
        note: 'Jasmin',
        createdAt: now,
      );
      riceIngredient = DishItem(
        id: 'ingredient-rice',
        dishId: 'dish',
        foodId: plainRice.id,
        food: plainRice,
      );
      foodIndex = RecipeIngredientMatcher.indexFoods([
        plainRice,
        basmatiRice,
        jasminRice,
      ]);
    });

    test('Basmati and Jasmin each satisfy a plain Reis ingredient', () {
      for (final stockedId in [basmatiRice.id, jasminRice.id]) {
        expect(
          RecipeIngredientMatcher.isInStock(
            item: riceIngredient,
            inStockFoodIds: {stockedId},
            foodIdsByName: foodIndex,
          ),
          isTrue,
        );
      }
    });

    test('one stocked variant among several is enough', () {
      expect(
        RecipeIngredientMatcher.isInStock(
          item: riceIngredient,
          inStockFoodIds: {jasminRice.id},
          foodIdsByName: foodIndex,
        ),
        isTrue,
      );
      expect(
        RecipeIngredientMatcher.isInStock(
          item: riceIngredient,
          inStockFoodIds: const {},
          foodIdsByName: foodIndex,
        ),
        isFalse,
      );
    });

    test('ingredient counts remain correct across variants', () {
      final tomato = Food(
        id: 'tomato-cherry',
        name: 'Tomaten',
        note: 'Cherry',
        createdAt: DateTime(2026),
      );
      final tomatoIngredient = DishItem(
        id: 'ingredient-tomato',
        dishId: 'dish',
        foodId: tomato.id,
        food: tomato,
      );
      final index = RecipeIngredientMatcher.indexFoods([
        plainRice,
        basmatiRice,
        jasminRice,
        tomato,
      ]);
      final available = [riceIngredient, tomatoIngredient]
          .where(
            (item) => RecipeIngredientMatcher.isInStock(
              item: item,
              inStockFoodIds: {basmatiRice.id},
              foodIdsByName: index,
            ),
          )
          .length;

      expect(available, 1);
    });

    test('dish ingredient display name excludes the food note', () {
      final item = DishItem(
        id: 'ingredient-basmati',
        dishId: 'dish',
        foodId: basmatiRice.id,
        food: basmatiRice,
      );

      expect(item.displayName.trim(), 'Reis');
      expect(item.displayLabel, 'Reis (Basmati)');
    });

    test('preferred tomato and noodle variants match stock by name', () {
      final now = DateTime(2026);
      final choppedTomatoes = Food(
        id: 'tomatoes-chopped',
        name: 'Tomaten',
        note: 'gehackt',
        createdAt: now,
      );
      final largeTomatoes = Food(
        id: 'tomatoes-large',
        name: 'Tomaten',
        note: 'groß',
        createdAt: now,
      );
      final spaghetti = Food(
        id: 'pasta-spaghetti',
        name: 'Nudeln',
        note: 'Spaghetti',
        createdAt: now,
      );
      final fusilli = Food(
        id: 'pasta-fusilli',
        name: 'Nudeln',
        note: 'Fusilli',
        createdAt: now,
      );
      final index = RecipeIngredientMatcher.indexFoods([
        choppedTomatoes,
        largeTomatoes,
        spaghetti,
        fusilli,
      ]);

      for (final pair in [
        (recipe: choppedTomatoes, stocked: largeTomatoes),
        (recipe: spaghetti, stocked: fusilli),
      ]) {
        final item = DishItem(
          id: 'ingredient-${pair.recipe.id}',
          dishId: 'dish',
          foodId: pair.recipe.id,
          food: pair.recipe,
        );
        expect(
          RecipeIngredientMatcher.isInStock(
            item: item,
            inStockFoodIds: {pair.stocked.id},
            foodIdsByName: index,
          ),
          isTrue,
        );
      }
    });
  });
}
