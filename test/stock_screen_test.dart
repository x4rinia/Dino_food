import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/screens/foods/foods_screen.dart';
import 'package:dino_food/screens/foods/stock_screen.dart';

void main() {
  testWidgets('StockScreen displays only items in stock and prompts before removal', (
    WidgetTester tester,
  ) async {
    final stockProvider = StockProvider();
    final foodProvider = FoodProvider();
    final shoppingProvider = ShoppingProvider()..bindToHousehold('test_household');

    await foodProvider.loadFoods();
    final food1 = foodProvider.foods[0];
    final food2 = foodProvider.foods[1];
    final food3 = foodProvider.foods[2];

    // Set food1 and food3 as in stock
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

    // Should show food1 and food3, but NOT food2
    expect(find.text(food1.name), findsOneWidget);
    expect(find.text(food3.name), findsOneWidget);
    expect(find.text(food2.name), findsNothing);

    // Should show '2 Lebensmittel zuhause im Vorrat'
    expect(find.text('2 Lebensmittel zuhause im Vorrat'), findsOneWidget);

    // Verify Zuhause button is present
    expect(find.text('Zuhause'), findsNWidgets(2));

    // Tap Zuhause button for food1
    await tester.tap(find.text('Zuhause').first);
    await tester.pumpAndSettle();

    // Verification prompt should appear
    expect(
      find.text(
        'Dieses Lebensmittel ist bereits im Vorrat. Möchtest du es aus dem Vorrat entfernen und auf die Einkaufsliste legen?',
      ),
      findsOneWidget,
    );

    // Tap "Nein" first -> item stays in stock
    await tester.tap(find.text('Nein'));
    await tester.pumpAndSettle();

    expect(stockProvider.isInStock(food1.id), isTrue);
    expect(shoppingProvider.allItems, isEmpty);

    // Tap Zuhause again and choose "Ja"
    await tester.tap(find.text('Zuhause').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();

    // Now food1 is removed from stock and added to shopping list
    expect(stockProvider.isInStock(food1.id), isFalse);
    expect(shoppingProvider.itemForFood(food1.id), isNotNull);
  });

  testWidgets(
    'FoodsScreen tabs: Lebensmittel tab has passive Vorrat badge, Vorrat tab has active Zuhause button with prompt',
    (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final visibleIds = foodProvider.foods
          .take(2)
          .map((food) => food.id)
          .toList();
      final stockProvider = StockProvider();
      stockProvider.bindToHousehold('count_household');
      stockProvider.inStockFoodIds.addAll({...visibleIds, 'legacy-orphan'});
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

      // Check two top tabs
      expect(find.text('Lebensmittel'), findsWidgets);
      expect(find.text('Vorrat'), findsWidgets);

      // In Lebensmittel tab: in-stock items show passive 'Vorrat' label (not 'Zuhause' button)
      expect(find.text('Vorrat'), findsWidgets);

      // Tapping passive 'Vorrat' badge should not open dialog
      await tester.tap(find.text('Vorrat').first);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Dieses Lebensmittel ist bereits im Vorrat. Möchtest du es aus dem Vorrat entfernen und auf die Einkaufsliste legen?',
        ),
        findsNothing,
      );

      // Switch to Vorrat tab
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      expect(find.text('2 Lebensmittel zuhause im Vorrat'), findsOneWidget);
      expect(find.text('Zuhause'), findsNWidgets(2));

      // Tap active Zuhause button on Vorrat tab
      await tester.tap(find.text('Zuhause').first);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Dieses Lebensmittel ist bereits im Vorrat. Möchtest du es aus dem Vorrat entfernen und auf die Einkaufsliste legen?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Ja'));
      await tester.pumpAndSettle();

      expect(find.text('1 Lebensmittel zuhause im Vorrat'), findsOneWidget);
    },
  );
}
