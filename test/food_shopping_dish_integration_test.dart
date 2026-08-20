import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/screens/foods/foods_screen.dart';
import 'package:dino_food/screens/shopping_list/add_edit_item_dialog.dart';
import 'package:dino_food/widgets/add_to_foods_prompt_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping List Free-Text and Food Linking Tests', () {
    testWidgets('Recognizes existing food and links food_id without prompting', (WidgetTester tester) async {
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

      // Enter 'Milch' (which exists in default foods)
      final searchField = find.widgetWithText(TextFormField, 'Lebensmittel suchen *');
      await tester.enterText(searchField, 'milch');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      // No prompt dialog appeared; directly saved with food_id
      expect(find.byType(AddToFoodsPromptDialog), findsNothing);

      final milch = foodProvider.foods.firstWhere((f) => f.name.toLowerCase() == 'milch');
      final item = shoppingProvider.allItems.firstWhere((i) => i.displayName.toLowerCase() == 'milch');
      expect(item.foodId, equals(milch.id));
    });

    testWidgets('Prompts for unknown food and option "Nur Einkaufsliste" creates free-text item without foods entry', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final shoppingProvider = ShoppingProvider();
      shoppingProvider.bindToHousehold('test_hh');

      expect(foodProvider.foodExists('Spezialbrot'), isFalse);

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

      // Enter unknown food
      final searchField = find.widgetWithText(TextFormField, 'Lebensmittel suchen *');
      await tester.enterText(searchField, 'Spezialbrot');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      // Prompt dialog appeared!
      expect(find.byType(AddToFoodsPromptDialog), findsOneWidget);
      expect(find.text('Nur Einkaufsliste'), findsOneWidget);

      // Choose "Nur Einkaufsliste"
      await tester.tap(find.text('Nur Einkaufsliste'));
      await tester.pumpAndSettle();

      // Item is on shopping list with custom_name and no food_id
      final item = shoppingProvider.allItems.firstWhere((i) => i.displayName == 'Spezialbrot');
      expect(item.customName, equals('Spezialbrot'));
      expect(item.foodId, isNull);

      // Food was NOT added to foods catalog
      expect(foodProvider.foodExists('Spezialbrot'), isFalse);
    });

    testWidgets('Prompts for unknown food and option "Lebensmittel hinzufügen" creates foods entry and links food_id', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final shoppingProvider = ShoppingProvider();
      shoppingProvider.bindToHousehold('test_hh');

      expect(foodProvider.foodExists('Bio-Avocado'), isFalse);

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

      // Enter unknown food
      final searchField = find.widgetWithText(TextFormField, 'Lebensmittel suchen *');
      await tester.enterText(searchField, 'Bio-Avocado');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      // Prompt dialog appeared
      expect(find.byType(AddToFoodsPromptDialog), findsOneWidget);

      // Choose "Lebensmittel hinzufügen"
      await tester.tap(find.text('Lebensmittel hinzufügen'));
      await tester.pumpAndSettle();

      // Food WAS created in foods catalog!
      expect(foodProvider.foodExists('Bio-Avocado'), isTrue);
      final newFood = foodProvider.foods.firstWhere((f) => f.name == 'Bio-Avocado');

      // Shopping item is linked to this food_id
      final item = shoppingProvider.allItems.firstWhere((i) => i.displayName == 'Bio-Avocado');
      expect(item.foodId, equals(newFood.id));
    });
  });

  group('Stock Removal vs Food Deletion Tests', () {
    testWidgets('Removing from stock removes household_stock but keeps food in foods', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final stockProvider = StockProvider();
      stockProvider.bindToHousehold('test_hh');

      final milch = foodProvider.foods.firstWhere((f) => f.name == 'Milch');

      // Add to stock
      await stockProvider.toggleStock(milch.id);
      expect(stockProvider.isInStock(milch.id), isTrue);

      // Remove from stock
      await stockProvider.toggleStock(milch.id);
      expect(stockProvider.isInStock(milch.id), isFalse);

      // Food still exists in foods!
      expect(foodProvider.foodExists('Milch'), isTrue);
    });

    testWidgets('Deleting food on FoodsScreen deletes from foods table', (WidgetTester tester) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final stockProvider = StockProvider();
      stockProvider.bindToHousehold('test_hh');
      final shoppingProvider = ShoppingProvider();
      shoppingProvider.bindToHousehold('test_hh');

      await foodProvider.addCustomFood(name: 'Einmaliger Artikel', category: 'Snacks');
      expect(foodProvider.foodExists('Einmaliger Artikel'), isTrue);

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

      // Search for our item
      final searchField = find.widgetWithText(TextField, 'Lebensmittel suchen...');
      await tester.enterText(searchField, 'Einmaliger Artikel');
      await tester.pumpAndSettle();

      // Open popup menu on the card
      final moreButton = find.byType(PopupMenuButton<String>).first;
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Tap Löschen
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears with exact text
      expect(find.text('„Einmaliger Artikel“ wirklich vollständig aus der Lebensmittel-Liste löschen?'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Löschen'));
      await tester.pumpAndSettle();

      // Food is deleted from foods!
      expect(foodProvider.foodExists('Einmaliger Artikel'), isFalse);
    });
  });
}
