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
  testWidgets('StockScreen displays only items in stock and allows removal', (
    WidgetTester tester,
  ) async {
    final stockProvider = StockProvider();
    final foodProvider = FoodProvider();

    // Seed mock foods and stock
    final food1 = Food(
      id: 'f1',
      name: 'Zwiebeln',
      note: 'Gemüse',
      defaultUnit: '',
      createdAt: DateTime.now(),
    );
    final food2 = Food(
      id: 'f2',
      name: 'Kartoffeln',
      note: 'Gemüse',
      defaultUnit: '',
      createdAt: DateTime.now(),
    );
    final food3 = Food(
      id: 'f3',
      name: 'Milch',
      note: 'Milchprodukte',
      defaultUnit: '',
      createdAt: DateTime.now(),
    );

    foodProvider.foods.addAll([food1, food2, food3]);
    // Set f1 and f3 as in stock
    stockProvider.bindToHousehold('test_household');
    stockProvider.inStockFoodIds.clear();
    stockProvider.inStockFoodIds.addAll({'f1', 'f3', 'legacy-orphan'});

    // Raw stock may contain a stale/legacy ID, but both UI counters must only
    // count IDs that belong to the currently loaded food catalogue.
    expect(
      stockProvider.countForFoodIds(foodProvider.foods.map((food) => food.id)),
      2,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FoodProvider>.value(value: foodProvider),
          ChangeNotifierProvider<StockProvider>.value(value: stockProvider),
        ],
        child: const MaterialApp(home: StockScreen()),
      ),
    );

    // Should show Zwiebeln and Milch, but NOT Kartoffeln
    expect(find.text('Zwiebeln'), findsOneWidget);
    expect(find.text('Milch'), findsOneWidget);
    expect(find.text('Kartoffeln'), findsNothing);

    // Should show '2 Lebensmittel zuhause im Vorrat'
    expect(find.text('2 Lebensmittel zuhause im Vorrat'), findsOneWidget);

    // Verify toggle button is present
    expect(find.text('Zuhause'), findsNWidgets(2));

    // Tap toggle button for Zwiebeln
    await tester.tap(find.text('Zuhause').first);
    await tester.pumpAndSettle();

    // Now only 1 item in stock
    expect(stockProvider.isInStock('f1'), isFalse);
  });

  testWidgets(
    'Foods overview and stock screen use the same household food count',
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

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: foodProvider),
            ChangeNotifierProvider.value(value: stockProvider),
            ChangeNotifierProvider(create: (_) => ShoppingProvider()),
          ],
          child: const MaterialApp(home: FoodsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vorrat (2)'), findsOneWidget);
      await tester.tap(find.text('Vorrat (2)'));
      await tester.pumpAndSettle();
      expect(find.text('2 Lebensmittel zuhause im Vorrat'), findsOneWidget);

      await tester.tap(find.text('Zuhause').first);
      await tester.pumpAndSettle();
      expect(find.text('1 Lebensmittel zuhause im Vorrat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Vorrat (1)'), findsOneWidget);
    },
  );
}
