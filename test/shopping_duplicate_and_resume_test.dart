import 'dart:async';

import 'package:dino_food/config/supabase_config.dart';
import 'package:dino_food/models/shopping_item.dart';
import 'package:dino_food/providers/auth_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/screens/foods/foods_screen.dart';
import 'package:dino_food/screens/home/main_navigation_screen.dart';
import 'package:dino_food/screens/shopping_list/shopping_list_screen.dart';
import 'package:dino_food/services/shopping_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _RetryShoppingService extends ShoppingService {
  _RetryShoppingService(this.result, {this.failuresBeforeSuccess = 0});

  final List<ShoppingItem> result;
  final int failuresBeforeSuccess;
  int fetchCount = 0;

  @override
  Future<List<ShoppingItem>> fetchShoppingItems(String householdId) async {
    fetchCount++;
    if (fetchCount <= failuresBeforeSuccess) {
      throw Exception('temporarily offline');
    }
    return result;
  }

  @override
  Stream<List<ShoppingItem>> streamShoppingItems(String householdId) =>
      const Stream.empty();
}

class _DeleteShoppingService extends ShoppingService {
  _DeleteShoppingService(this.rows, {this.failDelete = false});

  List<ShoppingItem> rows;
  final bool failDelete;
  final streamController = StreamController<List<ShoppingItem>>.broadcast();

  @override
  Future<List<ShoppingItem>> fetchShoppingItems(String householdId) async =>
      List<ShoppingItem>.of(rows);

  @override
  Stream<List<ShoppingItem>> streamShoppingItems(String householdId) =>
      streamController.stream;

  @override
  Future<void> deleteItem(String itemId, {required String householdId}) async {
    if (failDelete) throw Exception('delete failed');
    rows = rows.where((item) => item.id != itemId).toList();
  }
}

class _ReconnectShoppingService extends ShoppingService {
  _ReconnectShoppingService(this.rows);

  List<ShoppingItem> rows;
  int fetchCount = 0;
  int streamCount = 0;
  int activeSubscriptions = 0;
  int maxActiveSubscriptions = 0;
  final controllers = <StreamController<List<ShoppingItem>>>[];

  @override
  Future<List<ShoppingItem>> fetchShoppingItems(String householdId) async {
    fetchCount++;
    return List<ShoppingItem>.of(rows);
  }

  @override
  Stream<List<ShoppingItem>> streamShoppingItems(String householdId) {
    streamCount++;
    final controller = StreamController<List<ShoppingItem>>.broadcast();
    controller.onListen = () {
      activeSubscriptions++;
      if (activeSubscriptions > maxActiveSubscriptions) {
        maxActiveSubscriptions = activeSubscriptions;
      }
    };
    controller.onCancel = () => activeSubscriptions--;
    controllers.add(controller);
    return controller.stream;
  }

  Future<void> close() async {
    for (final controller in controllers) {
      await controller.close();
    }
  }
}

void main() {
  group('Food variants on the shopping list', () {
    test('matches duplicates by food id and keeps variants separate', () async {
      const householdId = 'duplicate-variant-household';
      final foods = FoodProvider()..bindToHousehold(householdId);
      final basmati = await foods.addCustomFood(name: 'Reis', note: 'Basmati');
      final jasmine = await foods.addCustomFood(name: 'Reis', note: 'Jasmin');
      final shopping = ShoppingProvider()..bindToHousehold(householdId);

      final first = await shopping.addOrIncrementFood(basmati);
      expect(first.success, isTrue);
      expect(first.wasIncremented, isFalse);
      expect(shopping.allItems.single.quantity, isNull);

      final second = await shopping.addOrIncrementFood(basmati);
      expect(second.success, isTrue);
      expect(second.quantity, 2);
      expect(shopping.allItems, hasLength(1));
      expect(shopping.allItems.single.quantity, 2);
      expect(shopping.itemForFood(basmati.id)?.detailsText, 'Basmati');

      final third = await shopping.addOrIncrementFood(basmati);
      expect(third.quantity, 3);
      expect(shopping.allItems.single.quantity, 3);

      expect((await shopping.addOrIncrementFood(jasmine)).success, isTrue);
      await shopping.updateItem(
        itemId: shopping.itemForFood(jasmine.id)!.id,
        note: 'Im Angebot nehmen',
      );
      expect(shopping.allItems, hasLength(2));
      expect(
        shopping.itemForFood(jasmine.id)?.detailsText,
        'Jasmin · Im Angebot nehmen',
      );
    });

    testWidgets('quick-add dialog shows food note and suggested quantity', (
      tester,
    ) async {
      final household = HouseholdProvider();
      await household.loadHouseholds();
      final householdId = household.currentHousehold!.id;
      final foods = FoodProvider()..bindToHousehold(householdId);
      await foods.addCustomFood(name: 'Nudeln Dialogtest', note: 'Spaghetti');
      foods.setSearchQuery('Nudeln Dialogtest');
      final shopping = ShoppingProvider()..bindToHousehold(householdId);
      final stock = StockProvider()..bindToHousehold(householdId);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: household),
            ChangeNotifierProvider.value(value: foods),
            ChangeNotifierProvider.value(value: shopping),
            ChangeNotifierProvider.value(value: stock),
          ],
          child: const MaterialApp(home: FoodsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pump();

      expect(find.text('Artikel hinzufügen'), findsOneWidget);
      var foodNoteField = find.widgetWithText(
        TextFormField,
        'Lebensmittel-Notiz',
      );
      expect(
        tester.widget<TextFormField>(foodNoteField).initialValue,
        'Spaghetti',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(
                TextFormField,
                'Einkaufslisten-Notiz (optional)',
              ),
            )
            .controller
            ?.text,
        isEmpty,
      );
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();
      expect(shopping.allItems.single.quantity, isNull);
      expect(shopping.allItems.single.detailsText, 'Spaghetti');

      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pump();
      expect(
        find.text('Nudeln Dialogtest ist bereits in der Einkaufsliste.'),
        findsOneWidget,
      );
      expect(find.text('Artikel bearbeiten'), findsOneWidget);
      foodNoteField = find.widgetWithText(TextFormField, 'Lebensmittel-Notiz');
      expect(
        tester.widget<TextFormField>(foodNoteField).initialValue,
        'Spaghetti',
      );
      var quantityField = find.widgetWithText(
        TextFormField,
        'Anzahl (optional)',
      );
      expect(tester.widget<TextFormField>(quantityField).controller?.text, '2');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(shopping.allItems.single.quantity, 2);

      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pump();
      quantityField = find.widgetWithText(TextFormField, 'Anzahl (optional)');
      expect(tester.widget<TextFormField>(quantityField).controller?.text, '3');
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
    });

    testWidgets('stock prompt uses exact food id and removes only after Yes', (
      tester,
    ) async {
      final household = HouseholdProvider();
      await household.loadHouseholds();
      final householdId = household.currentHousehold!.id;
      final foods = FoodProvider()..bindToHousehold(householdId);
      final basmati = await foods.addCustomFood(
        name: 'Reis Vorratstest',
        note: 'Basmati',
      );
      final jasmine = await foods.addCustomFood(
        name: 'Reis Vorratstest',
        note: 'Jasmin',
      );
      final shopping = ShoppingProvider()..bindToHousehold(householdId);
      final stock = StockProvider()..bindToHousehold(householdId);
      expect(await stock.addToStock(basmati.id), isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: household),
            ChangeNotifierProvider.value(value: foods),
            ChangeNotifierProvider.value(value: shopping),
            ChangeNotifierProvider.value(value: stock),
          ],
          child: const MaterialApp(home: FoodsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      foods.setSearchQuery('Jasmin');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey(jasmine.id)),
          matching: find.byIcon(Icons.add_shopping_cart),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text('Lebensmittel im Vorrat'), findsNothing);
      expect(shopping.itemForFood(jasmine.id), isNotNull);
      expect(stock.isInStock(basmati.id), isTrue);

      foods.setSearchQuery('Basmati');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey(basmati.id)),
          matching: find.byIcon(Icons.add_shopping_cart),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text('Lebensmittel im Vorrat'), findsOneWidget);
      expect(find.textContaining('Reis Vorratstest (Basmati)'), findsOneWidget);
      expect(shopping.itemForFood(basmati.id), isNotNull);

      await tester.tap(find.text('Nein'));
      await tester.pumpAndSettle();
      expect(stock.isInStock(basmati.id), isTrue);

      await shopping.deleteItem(shopping.itemForFood(basmati.id)!.id);
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey(basmati.id)),
          matching: find.byIcon(Icons.add_shopping_cart),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ja'));
      await tester.pumpAndSettle();
      expect(stock.isInStock(basmati.id), isFalse);
      expect(shopping.itemForFood(basmati.id), isNotNull);
    });

    test('rapid quick-adds are serialized without duplicates', () async {
      const householdId = 'rapid-add-household';
      final foods = FoodProvider()..bindToHousehold(householdId);
      final spaghetti = await foods.addCustomFood(
        name: 'Nudeln',
        note: 'Spaghetti',
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final fusilli = await foods.addCustomFood(
        name: 'Nudeln',
        note: 'Fusilli',
      );
      final shopping = ShoppingProvider()..bindToHousehold(householdId);

      await Future.wait(
        List.generate(5, (_) => shopping.addOrIncrementFood(spaghetti)),
      );
      final fusilliResult = await shopping.addOrIncrementFood(fusilli);

      expect(fusilliResult.success, isTrue, reason: fusilliResult.errorMessage);
      expect(shopping.allItems, hasLength(2));
      expect(shopping.itemForFood(spaghetti.id)?.quantity, 5);
      expect(shopping.itemForFood(spaghetti.id)?.detailsText, 'Spaghetti');
      expect(shopping.itemForFood(fusilli.id)?.quantity, isNull);
    });
  });

  testWidgets(
    'editing or deleting a shopping item never opens the stock prompt',
    (tester) async {
      final household = HouseholdProvider();
      await household.loadHouseholds();
      final householdId = household.currentHousehold!.id;
      final foods = FoodProvider()..bindToHousehold(householdId);
      final food = await foods.addCustomFood(
        name: 'Einkaufslisten-Abgrenzungstest',
        note: 'Spaghetti',
      );
      final shopping = ShoppingProvider()..bindToHousehold(householdId);
      final stock = StockProvider()..bindToHousehold(householdId);
      expect(await stock.addToStock(food.id), isTrue);
      expect((await shopping.addOrIncrementFood(food)).success, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: household),
            ChangeNotifierProvider.value(value: foods),
            ChangeNotifierProvider.value(value: shopping),
            ChangeNotifierProvider.value(value: stock),
          ],
          child: const MaterialApp(home: ShoppingListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Einkaufslisten-Abgrenzungstest'));
      await tester.pump();
      expect(find.text('Artikel bearbeiten'), findsOneWidget);
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Lebensmittel im Vorrat'), findsNothing);
      expect(stock.isInStock(food.id), isTrue);

      expect(
        await shopping.deleteItem(shopping.itemForFood(food.id)!.id),
        isTrue,
      );
      await tester.pump();
      expect(find.text('Lebensmittel im Vorrat'), findsNothing);
      expect(stock.isInStock(food.id), isTrue);
    },
  );

  test('background refresh retries and preserves existing data', () async {
    const householdId = 'resume-retry-household';
    final existing = ShoppingItem(
      id: 'existing',
      householdId: householdId,
      customName: 'Baguette',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final refreshed = existing.copyWith(quantity: 3);
    final service = _RetryShoppingService([
      refreshed,
    ], failuresBeforeSuccess: 1);
    final provider = ShoppingProvider(shoppingService: service)
      ..bindToHousehold(householdId);
    await provider.addItem(customName: existing.customName);

    SupabaseConfig.isConfigured = true;
    addTearDown(() => SupabaseConfig.isConfigured = false);
    final future = provider.refresh();
    expect(provider.allItems.single.displayName, 'Baguette');
    expect(provider.errorMessage, isNull);
    expect(await future, isTrue);
    expect(service.fetchCount, 2);
    expect(provider.allItems.single.quantity, 3);
    expect(provider.errorMessage, isNull);
  });

  test('persistent refresh error keeps data and exposes retry error', () async {
    const householdId = 'resume-persistent-error-household';
    final service = _RetryShoppingService(const [], failuresBeforeSuccess: 99);
    final provider = ShoppingProvider(shoppingService: service)
      ..bindToHousehold(householdId);
    await provider.addItem(customName: 'Baguette');

    SupabaseConfig.isConfigured = true;
    addTearDown(() => SupabaseConfig.isConfigured = false);
    expect(await provider.refresh(attempts: 1), isFalse);
    expect(provider.allItems.single.displayName, 'Baguette');
    expect(provider.errorMessage, contains('aktualisiert'));
  });

  test('deleted item is not restored by stale stream or refresh', () async {
    const householdId = 'delete-stale-event-household';
    final item = ShoppingItem(
      id: 'deleted-item',
      householdId: householdId,
      foodId: 'food-spaghetti',
      customName: 'Nudeln',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final service = _DeleteShoppingService([item]);
    addTearDown(service.streamController.close);
    SupabaseConfig.isConfigured = true;
    addTearDown(() => SupabaseConfig.isConfigured = false);
    final provider = ShoppingProvider(shoppingService: service)
      ..bindToHousehold(householdId);
    await Future<void>.delayed(Duration.zero);
    expect(provider.allItems, hasLength(1));

    final staleRows = List<ShoppingItem>.of(service.rows);
    expect(await provider.deleteItem(item.id), isTrue);
    expect(provider.allItems, isEmpty);
    service.streamController.add(staleRows);
    await Future<void>.delayed(Duration.zero);
    expect(provider.allItems, isEmpty);
    expect(await provider.refresh(attempts: 1), isTrue);
    expect(provider.allItems, isEmpty);
  });

  test('failed delete rolls the optimistic removal back', () async {
    const householdId = 'delete-rollback-household';
    final item = ShoppingItem(
      id: 'rollback-item',
      householdId: householdId,
      customName: 'Baguette',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final service = _DeleteShoppingService([item], failDelete: true);
    addTearDown(service.streamController.close);
    SupabaseConfig.isConfigured = true;
    addTearDown(() => SupabaseConfig.isConfigured = false);
    final provider = ShoppingProvider(shoppingService: service)
      ..bindToHousehold(householdId);
    await Future<void>.delayed(Duration.zero);

    expect(await provider.deleteItem(item.id), isFalse);
    expect(provider.allItems.single.id, item.id);
    expect(provider.lastMutationError, contains('gelöscht'));
  });

  test(
    'channelError keeps data, fetches fallback and replaces subscription',
    () async {
      const householdId = 'realtime-reconnect-household';
      final item = ShoppingItem(
        id: 'realtime-item',
        householdId: householdId,
        customName: 'Nudeln',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final service = _ReconnectShoppingService([item]);
      SupabaseConfig.isConfigured = true;
      addTearDown(() => SupabaseConfig.isConfigured = false);
      final provider = ShoppingProvider(shoppingService: service)
        ..bindToHousehold(householdId);
      addTearDown(() async {
        provider.dispose();
        await service.close();
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.allItems.single.id, item.id);
      expect(service.fetchCount, 1);
      expect(service.streamCount, 1);
      expect(service.activeSubscriptions, 1);

      service.controllers.single.addError(
        Exception('RealtimeSubscribeException(status: channelError)'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.allItems.single.id, item.id);
      expect(provider.errorMessage, isNull);
      expect(service.fetchCount, 2);
      expect(service.streamCount, 2);
      expect(service.activeSubscriptions, 1);

      final realtimeUpdate = item.copyWith(quantity: 2);
      service.rows = [realtimeUpdate];
      service.controllers.last.add([realtimeUpdate]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.allItems.single.quantity, 2);

      await Future.wait([provider.refresh(), provider.refresh()]);
      expect(service.fetchCount, 3);
      expect(service.streamCount, 3);
      expect(service.activeSubscriptions, 1);
      expect(service.maxActiveSubscriptions, 1);
    },
  );

  testWidgets('deleted item stays absent after resume', (tester) async {
    final household = HouseholdProvider();
    await household.loadHouseholds();
    final householdId = household.currentHousehold!.id;
    final shopping = ShoppingProvider()..bindToHousehold(householdId);
    await shopping.addItem(customName: 'Resume-Baguette');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: household),
          ChangeNotifierProvider.value(value: shopping),
          ChangeNotifierProvider(create: (_) => StockProvider()),
          ChangeNotifierProvider(create: (_) => FoodProvider()),
          ChangeNotifierProvider(create: (_) => DishProvider()),
        ],
        child: const MaterialApp(home: MainNavigationScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resume-Baguette'), findsOneWidget);

    final resumeItem = shopping.allItems.firstWhere(
      (item) => item.displayName == 'Resume-Baguette',
    );
    expect(await shopping.deleteItem(resumeItem.id), isTrue);
    await tester.pump();
    expect(find.text('Resume-Baguette'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Resume-Baguette'), findsNothing);
    expect(find.textContaining('Fehler beim Laden'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Resume-Baguette'), findsNothing);
  });
}
