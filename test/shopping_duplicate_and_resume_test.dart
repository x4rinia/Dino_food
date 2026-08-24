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

void main() {
  group('Food variants on the shopping list', () {
    test('matches duplicates by food id and keeps variants separate', () async {
      const householdId = 'duplicate-variant-household';
      final foods = FoodProvider()..bindToHousehold(householdId);
      final basmati = await foods.addCustomFood(name: 'Reis', note: 'Basmati');
      final jasmine = await foods.addCustomFood(name: 'Reis', note: 'Jasmin');
      final shopping = ShoppingProvider()..bindToHousehold(householdId);

      expect(
        await shopping.addItem(
          foodId: basmati.id,
          food: basmati,
          customName: basmati.name,
        ),
        isTrue,
      );
      expect(
        await shopping.addItem(
          foodId: basmati.id,
          food: basmati,
          customName: basmati.name,
        ),
        isFalse,
      );
      expect(shopping.allItems, hasLength(1));
      expect(shopping.itemForFood(basmati.id)?.detailsText, 'Basmati');

      expect(
        await shopping.addItem(
          foodId: jasmine.id,
          food: jasmine,
          customName: jasmine.name,
          note: 'Im Angebot nehmen',
        ),
        isTrue,
      );
      expect(shopping.allItems, hasLength(2));
      expect(
        shopping.itemForFood(jasmine.id)?.detailsText,
        'Jasmin · Im Angebot nehmen',
      );
    });

    testWidgets('duplicate quick-add offers the current quantity for editing', (
      tester,
    ) async {
      final household = HouseholdProvider();
      await household.loadHouseholds();
      final householdId = household.currentHousehold!.id;
      final foods = FoodProvider()..bindToHousehold(householdId);
      final baguette = await foods.addCustomFood(
        name: 'Baguette',
        note: 'Testvariante',
      );
      foods.setSearchQuery('Testvariante');
      final shopping = ShoppingProvider()..bindToHousehold(householdId);
      await shopping.addItem(
        foodId: baguette.id,
        food: baguette,
        customName: baguette.name,
        quantity: 2,
      );
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

      expect(find.text('Baguette ist bereits im Einkaufswagen.'), findsOne);
      expect(find.text('Artikel bearbeiten'), findsOne);
      final quantityField = find.widgetWithText(
        TextFormField,
        'Anzahl (optional)',
      );
      expect(tester.widget<TextFormField>(quantityField).controller?.text, '2');

      await tester.enterText(quantityField, '4');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(shopping.allItems.single.quantity, 4);
    });
  });

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

  testWidgets('resume keeps loaded shopping data visible', (tester) async {
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

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Resume-Baguette'), findsOneWidget);
    expect(find.textContaining('Fehler beim Laden'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Resume-Baguette'), findsOneWidget);
  });
}
