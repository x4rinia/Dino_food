import 'package:dino_food/models/shopping_item.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/screens/shopping_list/add_edit_item_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Optional shopping-list quantity', () {
    test('ShoppingItem has no implicit quantity and hides empty details', () {
      final item = ShoppingItem.fromJson({
        'id': 'without-quantity',
        'household_id': 'household',
      });

      expect(item.quantity, isNull);
      expect(item.detailsText, isNull);
      expect(item.toJson()['quantity'], isNull);
    });

    test('Displays quantity alone or together with a note', () {
      final now = DateTime(2026);
      final quantityOnly = ShoppingItem(
        id: 'milk',
        householdId: 'household',
        customName: 'Milch',
        quantity: 2,
        createdAt: now,
        updatedAt: now,
      );
      final noteAndQuantity = ShoppingItem(
        id: 'tomatoes',
        householdId: 'household',
        customName: 'Tomaten',
        note: 'Cherry',
        quantity: 4,
        createdAt: now,
        updatedAt: now,
      );

      expect(quantityOnly.detailsText, 'Anzahl: 2');
      expect(noteAndQuantity.detailsText, 'Cherry · Anzahl: 4');
    });

    test('Quantity survives reload, can be changed and removed', () async {
      const householdId = 'shopping-quantity-reload';
      final firstProvider = ShoppingProvider();
      firstProvider.bindToHousehold(householdId);

      expect(await firstProvider.addItem(customName: 'Brot'), isTrue);
      expect(firstProvider.allItems.first.quantity, isNull);

      expect(
        await firstProvider.addItem(customName: 'Milch', quantity: 2),
        isTrue,
      );
      final milkId = firstProvider.allItems.first.id;

      final reloadedProvider = ShoppingProvider();
      reloadedProvider.bindToHousehold(householdId);
      expect(
        reloadedProvider.allItems
            .firstWhere((item) => item.id == milkId)
            .quantity,
        2,
      );

      await reloadedProvider.updateItem(
        itemId: milkId,
        quantity: 4,
        replaceQuantity: true,
      );
      expect(
        reloadedProvider.allItems
            .firstWhere((item) => item.id == milkId)
            .quantity,
        4,
      );

      await reloadedProvider.updateItem(
        itemId: milkId,
        quantity: null,
        replaceQuantity: true,
      );
      expect(
        reloadedProvider.allItems
            .firstWhere((item) => item.id == milkId)
            .quantity,
        isNull,
      );
    });

    test('Rejects invalid database quantity representations', () {
      ShoppingItem parse(dynamic quantity) => ShoppingItem.fromJson({
        'id': 'item-$quantity',
        'household_id': 'household',
        'quantity': quantity,
      });

      expect(parse(0).quantity, isNull);
      expect(parse(-2).quantity, isNull);
      expect(parse(1.5).quantity, isNull);
      expect(parse('2').quantity, isNull);
      expect(parse(12).quantity, 12);
    });

    testWidgets('Quantity field accepts digits only and rejects zero', (
      tester,
    ) async {
      final foodProvider = FoodProvider();
      await foodProvider.loadFoods();
      final milk = foodProvider.foods.firstWhere(
        (food) => food.name == 'Milch',
      );
      final shoppingProvider = ShoppingProvider();
      shoppingProvider.bindToHousehold('shopping-quantity-input');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: foodProvider),
            ChangeNotifierProvider.value(value: shoppingProvider),
          ],
          child: MaterialApp(
            home: Scaffold(body: AddEditItemDialog(preselectedFood: milk)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final quantityField = find.widgetWithText(
        TextFormField,
        'Anzahl (optional)',
      );
      await tester.enterText(quantityField, '0');
      await tester.tap(find.text('Hinzufügen'));
      await tester.pump();
      expect(find.text('Bitte eine positive ganze Zahl eingeben'), findsOne);
      expect(shoppingProvider.allItems, isEmpty);

      await tester.enterText(quantityField, '2a.3-');
      expect(
        tester.widget<TextFormField>(quantityField).controller!.text,
        '23',
      );
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      expect(shoppingProvider.allItems.single.quantity, 23);
    });
  });
}
