import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/widgets/food_variant_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dish ingredient renders only its food name and suffix', (
    tester,
  ) async {
    final item = DishItem(
      id: 'item-1',
      dishId: 'dish-1',
      foodId: 'food-1',
      food: Food(
        id: 'food-1',
        name: 'Nudeln',
        note: 'Spaghetti',
        createdAt: DateTime(2026),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: FoodVariantText.forDishItem(
              item,
              key: const Key('ingredient'),
              suffix: ' · vorhanden',
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
    final root = text.textSpan! as TextSpan;
    final spans = root.children!.cast<TextSpan>();

    expect(root.toPlainText(), 'Nudeln · vorhanden');
    expect(spans[0].style?.fontStyle, isNot(FontStyle.italic));
    expect(root.toPlainText(), isNot(contains('Spaghetti')));
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
