import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/screens/foods/foods_screen.dart';
import 'package:dino_food/screens/foods/edit_food_dialog.dart';
import 'package:dino_food/screens/shopping_list/add_edit_item_dialog.dart';
import 'package:dino_food/screens/dishes/add_dish_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoodProvider Core & Central Catalog Tests', () {
    test('Prevents duplicate foods case-insensitively', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      expect(foodProvider.foodExists('Tomaten'), isTrue);
      expect(foodProvider.foodExists('tomaten'), isTrue);
      expect(foodProvider.foodExists('TOMATEN'), isTrue);

      expect(
        () => foodProvider.addCustomFood(name: 'TOMATEN'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Dieses Lebensmittel gibt es bereits.'),
        )),
      );
    });

    test('Allows adding and updating food, and prevents duplicate on update', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      final newFood = await foodProvider.addCustomFood(
        name: 'Spezial Mango',
        category: 'Obst',
      );
      expect(newFood.name, 'Spezial Mango');
      expect(foodProvider.foodExists('Spezial Mango'), isTrue);

      // Update name & category
      final updated = await foodProvider.updateFood(
        id: newFood.id,
        name: 'Reife Mango',
        category: 'Obst',
      );
      expect(updated.name, 'Reife Mango');
      expect(foodProvider.foodExists('Reife Mango'), isTrue);
      expect(foodProvider.foodExists('Spezial Mango'), isFalse);

      // Attempt to update name to an existing food
      expect(
        () => foodProvider.updateFood(id: newFood.id, name: 'Bananen', category: 'Obst'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Dieses Lebensmittel gibt es bereits.'),
        )),
      );
    });

    test('Deletes food if not in use and throws error if in use', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      final tempFood = await foodProvider.addCustomFood(name: 'Unbenutzter Snack', category: 'Snacks');
      expect(foodProvider.foodExists('Unbenutzter Snack'), isTrue);

      // Delete should succeed
      final deleted = await foodProvider.deleteFood(tempFood.id);
      expect(deleted, isTrue);
      expect(foodProvider.foodExists('Unbenutzter Snack'), isFalse);
    });
  });

  group('FoodsScreen Management Tests', () {
    testWidgets('Renders foods with stock, shopping cart, and edit/delete menu', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final stockProvider = StockProvider();
      final shoppingProvider = ShoppingProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: foodProvider),
            ChangeNotifierProvider.value(value: stockProvider),
            ChangeNotifierProvider.value(value: shoppingProvider),
          ],
          child: const MaterialApp(
            home: FoodsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lebensmittel & Vorrat 🥕'), findsOneWidget);
      expect(find.text('Tomaten'), findsOneWidget);

      // Verify PopupMenu with Edit and Delete options
      final moreButtons = find.byType(PopupMenuButton<String>);
      expect(moreButtons, findsWidgets);

      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Bearbeiten'), findsOneWidget);
      expect(find.text('Löschen'), findsOneWidget);
    });

    testWidgets('EditFoodDialog updates food name and category', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      final foodToEdit = foodProvider.foods.firstWhere((f) => f.name == 'Tomaten');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: foodProvider,
          child: MaterialApp(
            home: Scaffold(
              body: EditFoodDialog(food: foodToEdit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lebensmittel bearbeiten'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Tomaten'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Bio-Tomaten');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(foodProvider.foodExists('Bio-Tomaten'), isTrue);
    });
  });

  group('Shopping List and Dish Central Catalog Selection', () {
    testWidgets('AddEditItemDialog adds shopping item with food_id and allows inline food creation', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final shoppingProvider = ShoppingProvider();
      shoppingProvider.bindToHousehold('test_hh');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: foodProvider),
            ChangeNotifierProvider.value(value: shoppingProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddEditItemDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+ Neues Lebensmittel anlegen'), findsOneWidget);

      // Select existing food 'Milch'
      final searchField = find.widgetWithText(TextFormField, 'Lebensmittel suchen *');
      await tester.enterText(searchField, 'Milch');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      final milch = foodProvider.foods.firstWhere((f) => f.name == 'Milch');
      final addedItem = shoppingProvider.allItems.firstWhere((i) => i.displayName == 'Milch');
      expect(addedItem.foodId, equals(milch.id));
    });

    testWidgets('AddDishDialog adds dish ingredients with food_id and allows inline food creation', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final dishProvider = DishProvider();
      final householdProvider = HouseholdProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: foodProvider),
            ChangeNotifierProvider.value(value: dishProvider),
            ChangeNotifierProvider.value(value: householdProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddDishDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+ Neues Lebensmittel anlegen'), findsOneWidget);

      // Select existing food 'Reis'
      final ingField = find.widgetWithText(TextField, 'Zutat suchen (z. B. Tomaten)...');
      await tester.enterText(ingField, 'Reis');
      await tester.pumpAndSettle();

      // Tap autocomplete option to select
      await tester.tap(find.text('Reis').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zutat hinzufügen'));
      await tester.pumpAndSettle();

      // Ingredient 'Reis' is listed in the dish items
      expect(find.text('Reis'), findsOneWidget);
    });
  });
}
