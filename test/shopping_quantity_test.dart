import 'package:dino_food/models/shopping_item.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/screens/shopping_list/add_edit_item_dialog.dart';
import 'package:dino_food/screens/shopping_list/shopping_list_screen.dart';
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

    test('Keeps quantity out of the optional note text', () {
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

      expect(quantityOnly.detailsText, isNull);
      expect(noteAndQuantity.detailsText, 'Cherry');
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

    testWidgets(
      'Shows quantity beside the name without narrow-screen overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final shoppingProvider = ShoppingProvider();
        shoppingProvider.bindToHousehold('shopping-quantity-layout');
        await shoppingProvider.addItem(
          customName: 'Tomaten',
          note: 'Cherry',
          quantity: 4,
        );
        await shoppingProvider.addItem(customName: 'Spülmittel');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: shoppingProvider),
              ChangeNotifierProvider(create: (_) => HouseholdProvider()),
            ],
            child: const MaterialApp(home: ShoppingListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tomaten'), findsOneWidget);
        expect(find.text('Cherry'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.textContaining('Anzahl:'), findsNothing);
        expect(find.text('Spülmittel'), findsOneWidget);

        final nameCenter = tester.getCenter(find.text('Tomaten'));
        final quantityCenter = tester.getCenter(find.text('4'));
        final noteCenter = tester.getCenter(find.text('Cherry'));
        final quantityRect = tester.getRect(find.text('4'));
        final menuRect = tester.getRect(find.byIcon(Icons.more_vert).last);
        expect(quantityCenter.dx, greaterThan(nameCenter.dx));
        expect(quantityRect.right, lessThan(menuRect.left));
        expect(menuRect.left - quantityRect.right, greaterThanOrEqualTo(8));
        expect(noteCenter.dy, greaterThan(nameCenter.dy));
        expect(
          quantityCenter.dy,
          closeTo((nameCenter.dy + noteCenter.dy) / 2, 4),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
