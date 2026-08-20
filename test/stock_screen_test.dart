import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/screens/foods/stock_screen.dart';

void main() {
  testWidgets('StockScreen displays only items in stock and allows removal', (WidgetTester tester) async {
    final stockProvider = StockProvider();
    final foodProvider = FoodProvider();

    // Seed mock foods and stock
    final food1 = Food(id: 'f1', name: 'Zwiebeln', category: 'Gemüse', defaultUnit: '', createdAt: DateTime.now());
    final food2 = Food(id: 'f2', name: 'Kartoffeln', category: 'Gemüse', defaultUnit: '', createdAt: DateTime.now());
    final food3 = Food(id: 'f3', name: 'Milch', category: 'Milchprodukte', defaultUnit: '', createdAt: DateTime.now());

    foodProvider.foods.addAll([food1, food2, food3]);
    // Set f1 and f3 as in stock
    stockProvider.bindToHousehold('test_household');
    stockProvider.inStockFoodIds.clear();
    stockProvider.inStockFoodIds.addAll({'f1', 'f3'});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FoodProvider>.value(value: foodProvider),
          ChangeNotifierProvider<StockProvider>.value(value: stockProvider),
        ],
        child: const MaterialApp(
          home: StockScreen(),
        ),
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
}
