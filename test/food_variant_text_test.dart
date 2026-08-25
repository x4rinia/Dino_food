import 'package:dino_food/models/dish.dart';
import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/widgets/dish_ingredient_text.dart';
import 'package:dino_food/widgets/food_variant_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dish ingredient renders exactly the food name without note', (
    tester,
  ) async {
    final item = DishItem(
      id: 'item-1',
      dishId: 'dish-1',
      foodId: 'food-1',
      food: Food(
        id: 'food-1',
        name: 'Nudeln',
        note: 'Fusilli',
        createdAt: DateTime(2026),
      ),
    );
    final dish = Dish(
      id: 'dish-1',
      householdId: 'household-1',
      name: 'Nudelgericht',
      createdAt: DateTime(2026),
      items: [item],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: DishIngredientText(
              item: dish.items.single,
              key: const Key('ingredient'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('ingredient')),
        matching: find.byType(Text),
      ),
    );
    expect(text.data, 'Nudeln');
    expect(find.text('Nudeln'), findsOneWidget);
    expect(find.textContaining('Fusilli'), findsNothing);
    expect(item.foodId, 'food-1');
    expect(item.food?.note, 'Fusilli');
    expect(tester.takeException(), isNull);
  });

  testWidgets('generic food variant text still renders its note', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FoodVariantText(name: 'Nudeln', note: 'Fusilli'),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.textSpan!.toPlainText(), 'Nudeln (Fusilli)');
  });

  testWidgets('ingredient without note has no empty parentheses or overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 60,
            child: FoodVariantText(
              key: Key('ingredient'),
              name: 'Hackfleisch',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('ingredient')),
        matching: find.byType(Text),
      ),
    );
    expect(text.textSpan!.toPlainText(), 'Hackfleisch');
    expect(tester.takeException(), isNull);
  });
}
