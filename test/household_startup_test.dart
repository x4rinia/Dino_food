import 'dart:async';
import 'dart:io';

import 'package:dino_food/models/household.dart';
import 'package:dino_food/models/household_member.dart';
import 'package:dino_food/providers/household_provider.dart';
import 'package:dino_food/services/household_service.dart';
import 'package:dino_food/widgets/household_load_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeHouseholdService extends HouseholdService {
  FakeHouseholdService({
    this.availableHouseholds = const [],
    this.defaultId,
    this.loadError,
    this.failuresBeforeSuccess = 0,
    this.neverCompletes = false,
  });

  final List<Household> availableHouseholds;
  String? defaultId;
  final Object? loadError;
  final int failuresBeforeSuccess;
  final bool neverCompletes;
  String? savedDefaultId;
  int fetchCount = 0;

  @override
  Future<List<Household>> fetchUserHouseholds() {
    fetchCount++;
    if (neverCompletes) return Completer<List<Household>>().future;
    if (loadError != null && fetchCount <= failuresBeforeSuccess) {
      return Future.error(loadError!);
    }
    return Future.value(availableHouseholds);
  }

  @override
  Future<String?> fetchDefaultHouseholdId() => Future.value(defaultId);

  @override
  Future<void> setDefaultHousehold(String householdId) async {
    savedDefaultId = householdId;
    defaultId = householdId;
  }

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) async => [
    HouseholdMember(
      householdId: householdId,
      userId: 'membership-only-user',
      role: 'member',
      joinedAt: DateTime(2026),
    ),
  ];
}

Household household(String id, {String? createdBy}) => Household(
  id: id,
  name: 'Haushalt $id',
  inviteCode: 'CODE-$id',
  createdBy: createdBy,
  createdAt: DateTime(2026),
);

HouseholdProvider providerFor(
  FakeHouseholdService service, {
  Future<void> Function()? sessionRefresher,
}) => HouseholdProvider(
  householdService: service,
  sessionRefresher: sessionRefresher,
  isSupabaseConfigured: true,
  startupTimeout: const Duration(milliseconds: 30),
);

void main() {
  group('authenticated household startup', () {
    test('one household becomes active and loading finishes', () async {
      final service = FakeHouseholdService(
        availableHouseholds: [household('one')],
      );
      final provider = providerFor(service);

      await provider.loadHouseholds();

      expect(provider.state, HouseholdState.loaded);
      expect(provider.currentHousehold?.id, 'one');
      expect(provider.defaultHouseholdId, 'one');
      expect(service.savedDefaultId, 'one');
    });

    test('multiple households honor the favorite household', () async {
      final provider = providerFor(
        FakeHouseholdService(
          availableHouseholds: [household('one'), household('two')],
          defaultId: 'two',
        ),
      );

      await provider.loadHouseholds();

      expect(provider.state, HouseholdState.loaded);
      expect(provider.households, hasLength(2));
      expect(provider.currentHousehold?.id, 'two');
    });

    test(
      'membership-only user loads without owner or creator status',
      () async {
        final provider = providerFor(
          FakeHouseholdService(
            availableHouseholds: [household('member', createdBy: 'other-user')],
            defaultId: 'member',
          ),
        );

        await provider.loadHouseholds();

        expect(provider.state, HouseholdState.loaded);
        expect(provider.currentHousehold?.id, 'member');
        expect(provider.members.single.role, 'member');
      },
    );

    test('user without a household reaches the empty state', () async {
      final provider = providerFor(FakeHouseholdService());

      await provider.loadHouseholds();

      expect(provider.state, HouseholdState.loaded);
      expect(provider.hasHousehold, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('Supabase error ends loading and is exposed', () async {
      final provider = providerFor(
        FakeHouseholdService(
          loadError: Exception('PostgREST 42501'),
          failuresBeforeSuccess: 99,
        ),
      );

      await provider.loadHouseholds();

      expect(provider.state, HouseholdState.error);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Versuch es bitte nochmal.');
      expect(provider.errorMessage, isNot(contains('PostgREST 42501')));
    });

    test('timeout ends loading and offers a useful error', () async {
      final provider = providerFor(FakeHouseholdService(neverCompletes: true));

      await provider.loadHouseholds();

      expect(provider.state, HouseholdState.error);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Versuch es bitte nochmal.');
    });

    test('PGRST303 refreshes the session once and then succeeds', () async {
      var refreshCount = 0;
      final service = FakeHouseholdService(
        availableHouseholds: [household('after-refresh')],
        defaultId: 'after-refresh',
        loadError: const PostgrestException(
          message: 'JWT issued at future',
          code: 'PGRST303',
        ),
        failuresBeforeSuccess: 1,
      );
      final provider = providerFor(
        service,
        sessionRefresher: () async {
          refreshCount++;
        },
      );

      await provider.loadHouseholds();

      expect(provider.state, HouseholdState.loaded);
      expect(provider.currentHousehold?.id, 'after-refresh');
      expect(service.fetchCount, 2);
      expect(refreshCount, 1);
    });

    test('failed PGRST303 retry stops after one refresh', () async {
      var refreshCount = 0;
      final service = FakeHouseholdService(
        loadError: const PostgrestException(
          message: 'JWT issued at future',
          code: 'PGRST303',
        ),
        failuresBeforeSuccess: 99,
      );
      final provider = providerFor(
        service,
        sessionRefresher: () async {
          refreshCount++;
        },
      );

      await provider.loadHouseholds();

      expect(provider.state, HouseholdState.error);
      expect(provider.errorMessage, 'Versuch es bitte nochmal.');
      expect(service.fetchCount, 2);
      expect(refreshCount, 1);
    });

    test('switching households still changes the active household', () async {
      final first = household('one');
      final second = household('two');
      final provider = providerFor(
        FakeHouseholdService(
          availableHouseholds: [first, second],
          defaultId: first.id,
        ),
      );
      await provider.loadHouseholds();

      provider.setCurrentHousehold(second);

      expect(provider.currentHousehold?.id, second.id);
      expect(provider.defaultHouseholdId, first.id);
    });
  });

  testWidgets('provider error can be rendered with retry action', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HouseholdLoadErrorState(onRetry: () => retried = true),
        ),
      ),
    );

    expect(
      find.text('Dino konnte deinen Haushalt gerade nicht laden'),
      findsOneWidget,
    );
    expect(find.text('Versuch es bitte nochmal.'), findsOneWidget);
    expect(find.textContaining('PostgrestException'), findsNothing);
    await tester.tap(find.text('Erneut versuchen'));
    expect(retried, isTrue);
  });

  test(
    'startup query and RLS contain no legacy authorization requirement',
    () async {
      final service = await File('lib/services/household_service.dart')
          .readAsString();
      final migration = await File(
        'supabase/migrations/zzzzzzzzz_restore_member_startup_reads.sql',
      ).readAsString();

      final startupMethod = service.substring(
        service.indexOf('Future<List<Household>> fetchUserHouseholds()'),
        service.indexOf('Future<String?> fetchDefaultHouseholdId()'),
      );
      expect(startupMethod, contains("from('household_members')"));
      expect(startupMethod, contains(".eq('user_id', userId)"));
      expect(startupMethod, isNot(contains("select('role")));
      expect(startupMethod, isNot(contains(".eq('role'")));
      expect(startupMethod, isNot(contains(".eq('created_by'")));
      expect(migration, contains('security definer'));
      expect(migration, contains('user_id = auth.uid()'));
      expect(migration, isNot(contains("role = 'owner'")));
      expect(migration, isNot(contains('created_by = auth.uid()')));
    },
  );
}
