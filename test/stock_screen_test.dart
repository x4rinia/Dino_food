import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/screens/foods/foods_screen.dart';
import 'package:dino_food/screens/foods/stock_screen.dart';

void main() {
  testWidgets('StockScreen displays items in stock and toggles stock directly', (
    WidgetTester tester,
  ) async {
    final stockProvider = StockProvider();
    final foodProvider = FoodProvider();
    final shoppingProvider = ShoppingProvider()..bindToHousehold('test_household');

    await foodProvider.loadFoods();
    final food1 = foodProvider.foods[0];
    final food2 = foodProvider.foods[1];
    final food3 = foodProvider.foods[2];

    stockProvider.bindToHousehold('test_household');
    stockProvider.inStockFoodIds.clear();
    stockProvider.inStockFoodIds.addAll({food1.id, food3.id, 'legacy-orphan'});

    expect(
      stockProvider.countForFoodIds(foodProvider.foods.map((food) => food.id)),
      2,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FoodProvider>.value(value: foodProvider),
          ChangeNotifierProvider<StockProvider>.value(value: stockProvider),
          ChangeNotifierProvider<ShoppingProvider>.value(value: shoppingProvider),
        ],
        child: const MaterialApp(home: StockScreen()),
      ),
    );

    expect(find.text(food1.name), findsOneWidget);
    expect(find.text(food3.name), findsOneWidget);
    expect(find.text(food2.name), findsNothing);
    expect(find.text('2 Lebensmittel zuhause im Vorrat'), findsOneWidget);
    expect(find.text('Zuhause'), findsNWidgets(2));

    // Tap Zuhause button for food1 -> toggles stock off directly
    await tester.tap(find.text('Zuhause').first);
    await tester.pumpAndSettle();

    expect(stockProvider.isInStock(food1.id), isFalse);
  });

  testWidgets(
    'FoodsScreen filters by stock state (Alle, Im Vorrat, Nicht im Vorrat) and allows direct Zuhause toggle',
    (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final visibleIds = foodProvider.foods
          .take(2)
          .map((food) => food.id)
          .toList();
      final stockProvider = StockProvider();
      stockProvider.bindToHousehold('count_household');
      stockProvider.inStockFoodIds.addAll({...visibleIds});
      final shoppingProvider = ShoppingProvider()..bindToHousehold('count_household');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: foodProvider),
            ChangeNotifierProvider.value(value: stockProvider),
            ChangeNotifierProvider.value(value: shoppingProvider),
          ],
          child: const MaterialApp(home: FoodsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify filter chips exist
      expect(find.textContaining('Alle ('), findsOneWidget);
      expect(find.text('Im Vorrat (2)'), findsOneWidget);

      // Verify Zuhause button is active on food card
      expect(find.text('Zuhause'), findsWidgets);

      // Filter by 'Im Vorrat (2)'
      await tester.tap(find.text('Im Vorrat (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Zuhause'), findsNWidgets(2));
      expect(find.text('Vorrat?'), findsNothing);

      // Tap active Zuhause button on card -> toggles stock off directly
      await tester.tap(find.text('Zuhause').first);
      await tester.pumpAndSettle();

      expect(find.text('Im Vorrat (1)'), findsOneWidget);
    },
  );
}
