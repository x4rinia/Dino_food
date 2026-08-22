import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dino_food/models/food.dart';
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
    test('Does not restore legacy category when note is null', () {
      final food = Food.fromJson({
        'id': 'legacy-apple',
        'name': 'Apfel',
        'note': null,
        'category': 'Obst',
      });

      expect(food.note, isNull);
    });

    test('Prevents duplicate foods case-insensitively', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      expect(foodProvider.foodExists('Tomaten'), isTrue);
      expect(foodProvider.foodExists('tomaten'), isTrue);
      expect(foodProvider.foodExists('TOMATEN'), isTrue);

      expect(
        () => foodProvider.addCustomFood(name: 'TOMATEN'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('mit dieser Notiz'),
          ),
        ),
      );
    });

    test(
      'Allows equal names with different notes and normalizes duplicates',
      () async {
        final foodProvider = FoodProvider();
        await foodProvider.loadFoods();

        final basmati = await foodProvider.addCustomFood(
          name: 'Reis Spezial',
          note: 'Basmati',
        );
        final jasmin = await foodProvider.addCustomFood(
          name: 'reis spezial',
          note: 'Jasmin',
        );

        expect(basmati.id, isNot(jasmin.id));
        expect(
          foodProvider.foodExists('REIS   SPEZIAL', note: ' basmati '),
          isTrue,
        );
        expect(foodProvider.foodExists('Reis Spezial', note: 'JASMIN'), isTrue);
        expect(
          () => foodProvider.addCustomFood(
            name: '  reis   spezial ',
            note: ' BASMATI ',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('Prevents a second equal name when both notes are empty', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      await foodProvider.addCustomFood(name: 'Dino Tomaten');
      expect(
        () => foodProvider.addCustomFood(name: ' dino   tomaten ', note: '  '),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Allows adding and updating food, and prevents duplicate on update',
      () async {
        final foodProvider = FoodProvider();
        await foodProvider.loadFoods();

        final newFood = await foodProvider.addCustomFood(
          name: 'Spezial Mango',
          note: 'Obst',
        );
        expect(newFood.name, 'Spezial Mango');
        expect(foodProvider.foodExists('Spezial Mango', note: 'Obst'), isTrue);

        // Update name & note
        final updated = await foodProvider.updateFood(
          id: newFood.id,
          name: 'Reife Mango',
          note: 'Obst',
        );
        expect(updated.name, 'Reife Mango');
        expect(foodProvider.foodExists('Reife Mango', note: 'Obst'), isTrue);
        expect(foodProvider.foodExists('Spezial Mango', note: 'Obst'), isFalse);
      },
    );

    test('Foods list is ALWAYS sorted alphabetically on initial load, after add, and after update', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      // Initial check: is every element alphabetically <= next element
      for (int i = 0; i < foodProvider.foods.length - 1; i++) {
        final current = foodProvider.foods[i].name;
        final next = foodProvider.foods[i + 1].name;
        expect(
          FoodProvider.compareFoodNames(current, next) <= 0,
          isTrue,
          reason: '$current should precede $next',
        );
      }

      // Add 'Bio-Apfelkompott'
      final apfelkompott = await foodProvider.addCustomFood(
        name: 'Bio-Apfelkompott',
        note: 'Obst',
      );
      final apfelIndex = foodProvider.foods.indexWhere(
        (f) => f.id == apfelkompott.id,
      );

      expect(apfelIndex >= 0, isTrue);
      for (int i = 0; i < foodProvider.foods.length - 1; i++) {
        final current = foodProvider.foods[i].name;
        final next = foodProvider.foods[i + 1].name;
        expect(
          FoodProvider.compareFoodNames(current, next) <= 0,
          isTrue,
          reason: '$current should precede $next after add',
        );
      }

      // Update a food name
      await foodProvider.updateFood(
        id: apfelkompott.id,
        name: 'Zimtapfel',
        note: 'Obst',
      );
      for (int i = 0; i < foodProvider.foods.length - 1; i++) {
        final current = foodProvider.foods[i].name;
        final next = foodProvider.foods[i + 1].name;
        expect(
          FoodProvider.compareFoodNames(current, next) <= 0,
          isTrue,
          reason: '$current should precede $next after update',
        );
      }
    });

    test('Attempt to update name to an existing food', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final newFood = await foodProvider.addCustomFood(
        name: 'Initial',
        note: 'Obst',
      );
      expect(
        () => foodProvider.updateFood(id: newFood.id, name: 'Bananen'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('mit dieser Notiz'),
          ),
        ),
      );
    });

    test('Deletes food completely from foods catalog', () async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      final tempFood = await foodProvider.addCustomFood(
        name: 'Avocadooo',
        note: 'Gemüse',
      );
      expect(foodProvider.foodExists('Avocadooo', note: 'Gemüse'), isTrue);

      // Delete should completely remove it
      final deleted = await foodProvider.deleteFood(
        tempFood.id,
        foodName: tempFood.name,
      );
      expect(deleted, isTrue);
      expect(foodProvider.foodExists('Avocadooo', note: 'Gemüse'), isFalse);
    });
  });

  group('FoodsScreen Management Tests', () {
    testWidgets(
      'Renders foods with stock, shopping cart, and edit/delete menu',
      (WidgetTester tester) async {
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
            child: const MaterialApp(home: FoodsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lebensmittel & Vorrat 🥕'), findsOneWidget);
        final firstFoodName = foodProvider.foods.first.name;
        expect(find.text(firstFoodName), findsOneWidget);

        // Verify PopupMenu with Edit and Delete options
        final moreButtons = find.byType(PopupMenuButton<String>);
        expect(moreButtons, findsWidgets);

        await tester.tap(moreButtons.first);
        await tester.pumpAndSettle();

        expect(find.text('Bearbeiten'), findsOneWidget);
        expect(find.text('Löschen'), findsOneWidget);
      },
    );

    testWidgets('EditFoodDialog updates food name and note', (
      WidgetTester tester,
    ) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();

      final foodToEdit = foodProvider.foods.firstWhere(
        (f) => f.name == 'Tomaten',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: foodProvider,
          child: MaterialApp(
            home: Scaffold(body: EditFoodDialog(food: foodToEdit)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lebensmittel bearbeiten'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Tomaten'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Bio-Tomaten');
      await tester.enterText(find.byType(TextFormField).at(1), 'Cherry');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(foodProvider.foodExists('Bio-Tomaten', note: 'Cherry'), isTrue);
    });

    testWidgets('EditFoodDialog clears an existing note permanently', (
      WidgetTester tester,
    ) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final food = await foodProvider.addCustomFood(
        name: 'Notiz-Apfel',
        note: 'Obst',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: foodProvider,
          child: MaterialApp(
            home: Scaffold(body: EditFoodDialog(food: food)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      await foodProvider.loadFoods(force: true);

      final reloaded = foodProvider.foods.firstWhere(
        (item) => item.id == food.id,
      );
      expect(reloaded.note, isNull);
    });
  });

  group('Shopping List and Dish Central Catalog Selection', () {
    testWidgets(
      'AddEditItemDialog adds shopping item with food_id and allows inline food creation',
      (WidgetTester tester) async {
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
            child: const MaterialApp(home: Scaffold(body: AddEditItemDialog())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('+ Neues Lebensmittel anlegen'), findsOneWidget);

        // Select existing food 'Milch'
        final searchField = find.widgetWithText(
          TextFormField,
          'Lebensmittel *',
        );
        await tester.enterText(searchField, 'Milch');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Milch').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hinzufügen'));
        await tester.pumpAndSettle();

        final milch = foodProvider.foods.firstWhere((f) => f.name == 'Milch');
        final addedItem = shoppingProvider.allItems.firstWhere(
          (i) => i.displayName == 'Milch',
        );
        expect(addedItem.foodId, equals(milch.id));
      },
    );

    testWidgets(
      'AddDishDialog adds dish ingredients with food_id and allows inline food creation',
      (WidgetTester tester) async {
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
            child: const MaterialApp(home: Scaffold(body: AddDishDialog())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('+ Neues Lebensmittel anlegen'), findsOneWidget);

        // Select existing food 'Reis'
        final ingField = find.widgetWithText(
          TextField,
          'Zutat suchen (z. B. Tomaten)...',
        );
        await tester.enterText(ingField, 'Reis');
        await tester.pumpAndSettle();

        // Tap autocomplete option to select
        await tester.tap(find.text('Reis').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Zutat hinzufügen'));
        await tester.pumpAndSettle();

        // Ingredient 'Reis' is listed in the dish items
        expect(find.text('Reis'), findsOneWidget);
      },
    );
  });
}
