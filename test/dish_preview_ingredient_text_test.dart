import 'package:dino_food/models/dish.dart';
import 'package:dino_food/models/dish_item.dart';
import 'package:dino_food/models/food.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/screens/dishes/dish_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('dish preview renders Tomaten without the food note große', (
    tester,
  ) async {
    final food = Food(
      id: 'tomatoes-large',
      name: 'Tomaten',
      note: 'große',
      createdAt: DateTime(2026),
    );
    final dish = Dish(
      id: 'tomato-dish',
      householdId: 'household',
      name: 'Tomatengericht',
      createdAt: DateTime(2026),
      items: [
        DishItem(
          id: 'tomato-item',
          dishId: 'tomato-dish',
          foodId: food.id,
          food: food,
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: DishProvider()),
          ChangeNotifierProvider.value(value: FoodProvider()),
          ChangeNotifierProvider.value(value: HouseholdProvider()),
          ChangeNotifierProvider.value(value: ShoppingProvider()),
          ChangeNotifierProvider.value(value: StockProvider()),
        ],
        child: MaterialApp(home: DishPreviewDialog(dish: dish)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tomaten'), findsOneWidget);
    expect(find.textContaining('große'), findsNothing);
    expect(dish.items.single.foodId, 'tomatoes-large');
    expect(dish.items.single.food?.note, 'große');
  });
}
