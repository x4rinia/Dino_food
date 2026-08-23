import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class _HouseholdData {
  _HouseholdData(this.id, this.name, Set<String> members)
    : members = Set.of(members);

  final String id;
  final String name;
  final Set<String> members;
  final List<String> foods = ['food'];
  final List<String> stock = ['stock'];
  final List<String> shopping = ['shopping'];
  final List<String> dishes = ['dish'];
  final List<String> dishItems = ['dish-item'];
  final List<String> favorites = ['favorite'];
}

class _AccountLifecycleModel {
  final Map<String, _HouseholdData> households = {};

  void deleteAccount(String userId) {
    for (final household in households.values.toList()) {
      household.members.remove(userId);
      if (household.members.isEmpty) households.remove(household.id);
    }
  }

  Set<String> cleanupOrphans() {
    final orphanIds = households.values
        .where((household) => household.members.isEmpty)
        .map((household) => household.id)
        .toSet();
    households.removeWhere((id, _) => orphanIds.contains(id));
    return orphanIds;
  }
}

void main() {
  group('equal membership account lifecycle', () {
    test('deleting one of two members preserves household data and access', () {
      final model = _AccountLifecycleModel();
      final elystron = _HouseholdData('elystron', 'Elystron', {'a', 'b'});
      model.households[elystron.id] = elystron;

      model.deleteAccount('a');

      expect(model.households['elystron'], same(elystron));
      expect(elystron.members, {'b'});
      expect(elystron.foods, isNotEmpty);
      expect(elystron.stock, isNotEmpty);
      expect(elystron.shopping, isNotEmpty);
      expect(elystron.dishes, isNotEmpty);
      expect(elystron.dishItems, isNotEmpty);
      expect(elystron.favorites, isNotEmpty);
    });

    test('deleting the final member deletes household and all owned data', () {
      final model = _AccountLifecycleModel();
      final household = _HouseholdData('solo', 'Solo', {'a'});
      model.households[household.id] = household;

      model.deleteAccount('a');

      expect(model.households, isEmpty);
      expect(model.households.values.expand((h) => h.foods), isEmpty);
      expect(model.households.values.expand((h) => h.stock), isEmpty);
      expect(model.households.values.expand((h) => h.shopping), isEmpty);
      expect(model.households.values.expand((h) => h.dishes), isEmpty);
      expect(model.households.values.expand((h) => h.dishItems), isEmpty);
    });

    test('cleanup deletes zero-member households only and ignores names', () {
      final model = _AccountLifecycleModel();
      model.households['orphan-a'] = _HouseholdData('orphan-a', 'Dino WG', {});
      model.households['orphan-b'] = _HouseholdData(
        'orphan-b',
        'fressbuddys',
        {},
      );
      model.households['troja-a'] = _HouseholdData('troja-a', 'Troja', {'a'});
      model.households['troja-b'] = _HouseholdData('troja-b', 'Troja', {'b'});

      expect(model.cleanupOrphans(), {'orphan-a', 'orphan-b'});
      expect(model.households.keys, {'troja-a', 'troja-b'});
      expect(model.households.values.map((h) => h.name), ['Troja', 'Troja']);
    });

    test(
      'SQL implements equal membership, safe join and account deletion',
      () async {
        final hardening = await File(
          'supabase/migrations/zzzzzz_household_isolation_hardening.sql',
        ).readAsString();
        final lifecycle = await File(
          'supabase/migrations/zzzzzzz_equal_membership_account_lifecycle.sql',
        ).readAsString();
        final householdService = await File(
          'lib/services/household_service.dart',
        ).readAsString();
        final householdScreen = await File(
          'lib/screens/household/household_screen.dart',
        ).readAsString();

        expect(hardening, contains('Members can remove household memberships'));
        expect(hardening, contains('Members can delete household'));
        expect(
          hardening,
          isNot(
            contains('create or replace function public.is_household_owner'),
          ),
        );
        expect(hardening, contains('can_initialize_household_membership'));
        expect(hardening, contains('not exists'));
        expect(hardening, contains('join_household_by_code'));
        expect(householdService, contains("'join_household_by_code'"));
        expect(householdService, isNot(contains("role': 'owner'")));
        expect(householdScreen, isNot(contains('Inhaberschaft')));
        expect(householdScreen, isNot(contains("'Inhaber'")));

        final isolationSql =
            '${hardening.toLowerCase()}\n${lifecycle.toLowerCase()}';
        expect(isolationSql, isNot(contains('create unique index')));
        expect(isolationSql, isNot(contains('unique (name')));

        expect(lifecycle, contains("set role = 'member'"));
        expect(lifecycle, contains('delete_household_when_empty'));
        expect(
          lifecycle,
          contains('create or replace function public.delete_user_account'),
        );
        expect(lifecycle, contains('delete from public.household_members'));
        expect(lifecycle, contains('delete from auth.users'));
        expect(
          lifecycle.indexOf('delete from public.household_members'),
          lessThan(lifecycle.indexOf('delete from auth.users')),
        );
        expect(lifecycle, contains("c.confdeltype = 'c'"));
        expect(lifecycle, contains('join pg_attribute child_attribute'));
        expect(
          lifecycle,
          contains('child_attribute.attnum = any(c.conkey)'),
        );
        expect(lifecycle.toLowerCase(), isNot(contains('get_attnum')));
      },
    );

    test(
      'orphan preflight is read-only and cleanup has membership predicate',
      () async {
        final preflight = await File('supabase_preflight_orphan_households.sql')
            .readAsString();
        final cleanup = await File(
          'supabase/migrations/zzzzzzzz_cleanup_orphan_households.sql',
        ).readAsString();

        expect(preflight.toLowerCase(), isNot(contains('delete from')));
        expect(preflight, contains('where not exists'));
        expect(cleanup, contains('delete from public.households'));
        expect(cleanup, contains('where not exists'));
        expect(cleanup, isNot(contains('where h.name')));
        expect(cleanup, isNot(contains('created_by is null')));
        expect(
          cleanup,
          isNot(contains('4459f3f4-de1a-4f4d-89e6-3993fb284513')),
        );
        expect(
          cleanup,
          isNot(contains('1eda83a8-fa46-4a48-ab0a-79a7992d7e0a')),
        );
      },
    );
  });
}
