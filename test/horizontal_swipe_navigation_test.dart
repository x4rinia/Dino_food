import 'dart:io';

import 'package:dino_food/navigation/no_swipe_material_page_route.dart';
import 'package:dino_food/providers/auth_provider.dart';
import 'package:dino_food/providers/dish_provider.dart';
import 'package:dino_food/providers/food_provider.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/providers/shopping_provider.dart';
import 'package:dino_food/providers/stock_provider.dart';
import 'package:dino_food/screens/home/main_navigation_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('web shell blocks horizontal browser overscroll', () {
    final webShell = File('web/index.html').readAsStringSync();

    expect(webShell, contains('overscroll-behavior-x: none;'));
    expect(webShell, contains('touch-action: none;'));
    expect(webShell, contains('background-color: #F6FBF7;'));
  });

  testWidgets(
    'horizontal swipes never change tabs, routes, or shopping content',
    (tester) async {
      final shoppingProvider = ShoppingProvider()
        ..bindToHousehold('horizontal-swipe-test');
      await shoppingProvider.addItem(customName: 'Swipe-Testartikel');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => HouseholdProvider()),
            ChangeNotifierProvider.value(value: shoppingProvider),
            ChangeNotifierProvider(create: (_) => StockProvider()),
            ChangeNotifierProvider(create: (_) => FoodProvider()),
            ChangeNotifierProvider(create: (_) => DishProvider()),
          ],
          child: const MaterialApp(home: MainNavigationScreen()),
        ),
      );
      await tester.pump();

      void expectStableFirstTab() {
        final navigation = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navigation.currentIndex, 0);
        expect(find.text('Swipe-Testartikel'), findsOneWidget);
        expect(shoppingProvider.allItems, hasLength(1));
        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.direction, DismissDirection.none);
        expect(tester.takeException(), isNull);
      }

      expectStableFirstTab();

      // Fast swipes in both directions, repeated to catch state races.
      for (var attempt = 0; attempt < 3; attempt++) {
        await tester.flingFrom(
          const Offset(650, 300),
          const Offset(-500, 0),
          4000,
        );
        await tester.pump();
        expectStableFirstTab();

        await tester.flingFrom(
          const Offset(150, 300),
          const Offset(500, 0),
          4000,
        );
        await tester.pump();
        expectStableFirstTab();
      }

      // Slow swipe through intermediate frames in the middle of the screen.
      final slowSwipe = await tester.startGesture(const Offset(650, 300));
      for (var step = 1; step <= 10; step++) {
        await slowSwipe.moveTo(Offset(650.0 - (50 * step), 300));
        await tester.pump(const Duration(milliseconds: 40));
        expectStableFirstTab();
      }
      await slowSwipe.up();
      await tester.pump();
      expectStableFirstTab();

      // The iPhone/Safari back-swipe starts at the left display edge.
      final edgeSwipe = await tester.startGesture(const Offset(1, 300));
      await edgeSwipe.moveTo(const Offset(400, 300));
      await tester.pump(const Duration(milliseconds: 100));
      expectStableFirstTab();
      await edgeSwipe.up();
      await tester.pumpAndSettle();
      expectStableFirstTab();
    },
  );

  testWidgets('pushed app routes ignore the iOS edge-back gesture', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    late NoSwipeMaterialPageRoute<void> route;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                route = NoSwipeMaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Zielseite')),
                );
                Navigator.of(context).push(route);
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(route.popGestureEnabled, isFalse);

    await tester.flingFrom(const Offset(1, 300), const Offset(500, 0), 4000);
    await tester.pumpAndSettle();

    expect(find.text('Zielseite'), findsOneWidget);
    expect(route.isCurrent, isTrue);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
