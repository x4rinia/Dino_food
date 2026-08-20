import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/providers/household_provider.dart';

void main() {
  group('HouseholdProvider Logic Tests', () {
    test('Initial load creates default household and sets it as active and favorite', () async {
      final provider = HouseholdProvider();
      await provider.loadHouseholds();

      expect(provider.households.length, 1);
      expect(provider.currentHousehold, isNotNull);
      expect(provider.defaultHouseholdId, provider.currentHousehold!.id);
      expect(provider.isDefaultHousehold(provider.currentHousehold!.id), isTrue);
      expect(provider.isCurrentHousehold(provider.currentHousehold!.id), isTrue);
    });

    test('Creating a second household keeps first as favorite but sets new as active', () async {
      final provider = HouseholdProvider();
      await provider.loadHouseholds();

      final firstId = provider.currentHousehold!.id;

      final success = await provider.createHousehold(name: 'Einkauf WG');
      expect(success, isTrue);
      expect(provider.households.length, 2);

      // First household is still default/favorite
      expect(provider.defaultHouseholdId, firstId);
      expect(provider.isDefaultHousehold(firstId), isTrue);

      // New household is currently active
      final secondId = provider.currentHousehold!.id;
      expect(secondId, isNot(firstId));
      expect(provider.isDefaultHousehold(secondId), isFalse);
      expect(provider.isCurrentHousehold(secondId), isTrue);
    });

    test('Switching active household does not alter default/favorite status', () async {
      final provider = HouseholdProvider();
      await provider.loadHouseholds();
      final first = provider.currentHousehold!;

      await provider.createHousehold(name: 'Urlaub');
      final second = provider.currentHousehold!;

      // Switch active back to first
      provider.setCurrentHousehold(first);
      expect(provider.isCurrentHousehold(first.id), isTrue);
      expect(provider.isDefaultHousehold(first.id), isTrue);

      // Switch active to second
      provider.setCurrentHousehold(second);
      expect(provider.isCurrentHousehold(second.id), isTrue);
      // Favorite is still first
      expect(provider.isDefaultHousehold(first.id), isTrue);
      expect(provider.isDefaultHousehold(second.id), isFalse);
    });

    test('Changing default household updates exactly one favorite', () async {
      final provider = HouseholdProvider();
      await provider.loadHouseholds();
      final first = provider.currentHousehold!;

      await provider.createHousehold(name: 'WG 2');
      final second = provider.currentHousehold!;

      expect(provider.defaultHouseholdId, first.id);

      // Set second as default
      final success = await provider.setDefaultHousehold(second.id);
      expect(success, isTrue);
      expect(provider.defaultHouseholdId, second.id);
      expect(provider.isDefaultHousehold(second.id), isTrue);
      expect(provider.isDefaultHousehold(first.id), isFalse);
    });

    test('Cannot delete when only one household exists', () async {
      final provider = HouseholdProvider();
      await provider.loadHouseholds();
      expect(provider.households.length, 1);

      final onlyId = provider.households.first.id;
      final deleted = await provider.deleteHousehold(onlyId);
      expect(deleted, isFalse);
      expect(provider.errorMessage, 'Mindestens ein Haushalt muss bestehen bleiben.');
      expect(provider.households.length, 1);
    });

    test('Deleting non-default active household falls back to default household', () async {
      final provider = HouseholdProvider();
      await provider.loadHouseholds();
      final first = provider.currentHousehold!;

      await provider.createHousehold(name: 'Temporary');
      final second = provider.currentHousehold!;

      expect(provider.households.length, 2);
      expect(provider.defaultHouseholdId, first.id);
      expect(provider.currentHousehold!.id, second.id);

      final deleted = await provider.deleteHousehold(second.id);
      expect(deleted, isTrue);
      expect(provider.households.length, 1);
      expect(provider.currentHousehold!.id, first.id);
      expect(provider.defaultHouseholdId, first.id);
    });

    test('Deleting default household assigns new default from remaining households', () async {
      final provider = HouseholdProvider();
      await provider.loadHouseholds();
      final first = provider.currentHousehold!;

      await provider.createHousehold(name: 'Remaining');
      final second = provider.currentHousehold!;

      // first is default
      expect(provider.defaultHouseholdId, first.id);

      final deleted = await provider.deleteHousehold(first.id);
      expect(deleted, isTrue);
      expect(provider.households.length, 1);
      expect(provider.households.first.id, second.id);
      expect(provider.defaultHouseholdId, second.id);
      expect(provider.isDefaultHousehold(second.id), isTrue);
    });
  });
}
