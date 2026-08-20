import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/screens/shopping_list/add_edit_item_dialog.dart';
import 'package:dino_food/screens/dishes/add_dish_dialog.dart';
import 'package:dino_food/widgets/add_to_catalog_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddToCatalogDialog Tests', () {
    testWidgets('Renders properly and returns addToCatalog with chosen category', (WidgetTester tester) async {
      AddToCatalogDecision? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AddToCatalogDialog.show(context, 'Drachenfrucht');
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AddToCatalogDialog), findsOneWidget);
      expect(find.text('Zum Katalog hinzufügen?'), findsOneWidget);
      expect(find.descendant(of: find.byType(AddToCatalogDialog), matching: find.textContaining('Drachenfrucht')), findsOneWidget);
      expect(find.text('Ja, zum Katalog hinzufügen'), findsOneWidget);
      expect(find.text('Nein, nur einmalig verwenden'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);

      // Select category 'Obst'
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obst').last);
      await tester.pumpAndSettle();

      // Click "Ja, zum Katalog hinzufügen"
      await tester.tap(find.text('Ja, zum Katalog hinzufügen'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.shouldAddToCatalog, isTrue);
      expect(result!.category, 'Obst');
    });

    testWidgets('Returns useOnce when clicking "Nein, nur einmalig verwenden"', (WidgetTester tester) async {
      AddToCatalogDecision? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AddToCatalogDialog.show(context, 'Spezial-Gewürz');
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nein, nur einmalig verwenden'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.shouldUseOnce, isTrue);
      expect(result!.shouldAddToCatalog, isFalse);
    });

    testWidgets('Returns cancel when clicking "Abbrechen"', (WidgetTester tester) async {
      AddToCatalogDecision? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AddToCatalogDialog.show(context, 'Test-Item');
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isCanceled, isTrue);
    });
  });

  group('Shopping List Unknown Food Flow', () {
    testWidgets('Prompts AddToCatalogDialog when adding unknown food and adds to catalog if confirmed', (WidgetTester tester) async {
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

      // Enter unknown food name
      final nameFinder = find.byType(TextFormField).first;
      await tester.enterText(nameFinder, 'Pitahaya');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      // Expect AddToCatalogDialog to appear
      expect(find.byType(AddToCatalogDialog), findsOneWidget);
      expect(find.text('Zum Katalog hinzufügen?'), findsOneWidget);
      expect(find.descendant(of: find.byType(AddToCatalogDialog), matching: find.textContaining('Pitahaya')), findsOneWidget);

      // Confirm add to catalog
      await tester.tap(find.text('Ja, zum Katalog hinzufügen'));
      await tester.pumpAndSettle();

      // Verify that food was added to catalog
      final addedFood = foodProvider.foods.where((f) => f.name.toLowerCase() == 'pitahaya').firstOrNull;
      expect(addedFood, isNotNull);

      // Verify shopping item was added with foodId
      final addedItem = shoppingProvider.allItems.where((i) => i.displayName == 'Pitahaya').firstOrNull;
      expect(addedItem, isNotNull);
      expect(addedItem!.foodId, equals(addedFood!.id));
    });

    testWidgets('Prompts AddToCatalogDialog and adds as custom name without catalog when declining', (WidgetTester tester) async {
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

      // Enter unknown food name
      final nameFinder = find.byType(TextFormField).first;
      await tester.enterText(nameFinder, 'Exotische Sauce');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      // Decline catalog addition
      await tester.tap(find.text('Nein, nur einmalig verwenden'));
      await tester.pumpAndSettle();

      // Verify that food was NOT added to catalog
      final catalogMatch = foodProvider.foods.where((f) => f.name.toLowerCase() == 'exotische sauce').firstOrNull;
      expect(catalogMatch, isNull);

      // Verify shopping item was added with customName
      final addedItem = shoppingProvider.allItems.where((i) => i.displayName == 'Exotische Sauce').firstOrNull;
      expect(addedItem, isNotNull);
      expect(addedItem!.foodId, isNull);
      expect(addedItem.customName, equals('Exotische Sauce'));
    });
  });

  group('Dish Unknown Ingredient Flow', () {
    testWidgets('Prompts AddToCatalogDialog when adding unknown ingredient in AddDishDialog', (WidgetTester tester) async {
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

      // Enter dish name
      await tester.enterText(find.byType(TextField).first, 'Spezial-Curry');

      // Enter unknown ingredient in search field
      final ingField = find.widgetWithText(TextField, 'Zutat suchen (z. B. Tomaten)...');
      await tester.enterText(ingField, 'Zitronengras');
      await tester.pumpAndSettle();

      // Click "Zutat hinzufügen"
      await tester.tap(find.text('Zutat hinzufügen'));
      await tester.pumpAndSettle();

      // AddToCatalogDialog should be visible
      expect(find.byType(AddToCatalogDialog), findsOneWidget);
      expect(find.text('Zum Katalog hinzufügen?'), findsOneWidget);
      expect(find.descendant(of: find.byType(AddToCatalogDialog), matching: find.textContaining('Zitronengras')), findsOneWidget);

      // Accept
      await tester.tap(find.text('Ja, zum Katalog hinzufügen'));
      await tester.pumpAndSettle();

      // Ingredient should now be in the dish ingredients list
      expect(find.text('Zitronengras'), findsOneWidget);

      // And in food catalog
      final catalogFood = foodProvider.foods.where((f) => f.name.toLowerCase() == 'zitronengras').firstOrNull;
      expect(catalogFood, isNotNull);
    });
  });
}
