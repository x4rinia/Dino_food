import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/profile.dart';
import 'dish_service.dart';
import 'food_service.dart';

class UserHouseholdsResult {
  final List<Household> households;
  final Map<String, String> roles; // householdId -> role ('owner' or 'member')

  UserHouseholdsResult({required this.households, required this.roles});
}

class HouseholdService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<UserHouseholdsResult> fetchUserHouseholdsWithRoles() async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      return UserHouseholdsResult(households: [], roles: {});
    }

    final userId = SupabaseConfig.currentUserId!;
    try {
      final memberRows = await _client
          .from('household_members')
          .select('household_id, role, households(*)')
          .eq('user_id', userId);

      final List<Household> households = [];
      final Map<String, String> roles = {};

      for (final row in memberRows) {
        final householdId = row['household_id'] as String?;
        final role = row['role'] as String? ?? 'member';
        if (householdId != null) {
          roles[householdId] = role;
        }
        if (row['households'] != null) {
          households.add(Household.fromJson(row['households'] as Map<String, dynamic>));
        }
      }
      return UserHouseholdsResult(households: households, roles: roles);
    } catch (e) {
      debugPrint('Error fetching households with roles: $e');
      rethrow;
    }
  }

  Future<List<Household>> fetchUserHouseholds() async {
    final result = await fetchUserHouseholdsWithRoles();
    return result.households;
  }

  Future<String?> fetchDefaultHouseholdId() async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      return null;
    }

    try {
      final data = await _client
          .from('profiles')
          .select('default_household_id')
          .eq('id', SupabaseConfig.currentUserId!)
          .maybeSingle();

      return data?['default_household_id'] as String?;
    } catch (e) {
      debugPrint('Error fetching default_household_id: $e');
      return null;
    }
  }

  Future<void> setDefaultHousehold(String householdId) async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      return;
    }

    try {
      await _client.from('profiles').update({
        'default_household_id': householdId,
      }).eq('id', SupabaseConfig.currentUserId!);
    } catch (e) {
      debugPrint('Error updating default_household_id in profile: $e');
      rethrow;
    }
  }

  Future<void> deleteHousehold(String householdId) async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      return;
    }

    try {
      await _client.from('households').delete().eq('id', householdId);
    } catch (e) {
      debugPrint('Error deleting household: $e');
      rethrow;
    }
  }

  Future<Household> createHousehold({
    required String name,
    required String color,
  }) async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      throw Exception('Benutzer ist nicht angemeldet.');
    }

    try {
      final response = await _client.rpc('create_household_and_join', params: {
        'name': name.trim(),
        'color': color,
      });

      Household household;
      final userId = SupabaseConfig.currentUserId;

      if (response != null) {
        household = Household.fromJson(Map<String, dynamic>.from(response as Map));
      } else {
        throw Exception('Haushalt konnte nicht erstellt werden.');
      }

      // Seed standard food catalogue and dishes for this newly created household
      try {
        final foodMap = await FoodService().seedDefaultFoodsForHousehold(household.id);
        final dishes = await DishService().seedDefaultDishesForHousehold(household.id, foodMap, userId: userId);

        // Validation: verify all 10 standard dishes exist and have all expected ingredients
        if (dishes.length < 10) {
          throw Exception('Nicht alle Standardgerichte konnten erstellt werden (${dishes.length} von 10).');
        }

        for (final dish in dishes) {
          final template = DishService.defaultDishesTemplate.firstWhere(
            (t) => (t['name'] as String).toLowerCase() == dish.name.toLowerCase(),
            orElse: () => {},
          );
          final expectedCount = (template['items'] as List?)?.length ?? 0;
          if (expectedCount > 0 && dish.items.length < expectedCount) {
            throw Exception('Gericht "${dish.name}" ist unvollständig (${dish.items.length} von $expectedCount Zutaten).');
          }
        }
      } catch (seedErr) {
        debugPrint('Household initial seeding failed: $seedErr. Rolling back household ${household.id}...');
        try {
          await deleteHousehold(household.id);
        } catch (rollbackErr) {
          debugPrint('Error rolling back household ${household.id}: $rollbackErr');
        }
        throw Exception('Haushalt konnte nicht vollständig initialisiert werden ($seedErr). Bitte versuche es erneut.');
      }

      return household;
    } catch (e) {
      if (e.toString().contains('Haushalt konnte nicht vollständig initialisiert werden')) {
        rethrow;
      }

      debugPrint('RPC create_household_and_join failed: $e. Falling back to direct insert.');
      final userId = SupabaseConfig.currentUserId!;
      final householdData = await _client
          .from('households')
          .insert({
            'name': name.trim(),
            'color': color,
            'created_by': userId,
          })
          .select()
          .single();

      final household = Household.fromJson(householdData);

      await _client.from('household_members').upsert({
        'household_id': household.id,
        'user_id': userId,
        'role': 'owner',
      });

      // Seed standard food catalogue and dishes for this newly created household
      try {
        final foodMap = await FoodService().seedDefaultFoodsForHousehold(household.id);
        final dishes = await DishService().seedDefaultDishesForHousehold(household.id, foodMap, userId: userId);

        if (dishes.length < 10) {
          throw Exception('Nicht alle Standardgerichte konnten erstellt werden (${dishes.length} von 10).');
        }

        for (final dish in dishes) {
          final template = DishService.defaultDishesTemplate.firstWhere(
            (t) => (t['name'] as String).toLowerCase() == dish.name.toLowerCase(),
            orElse: () => {},
          );
          final expectedCount = (template['items'] as List?)?.length ?? 0;
          if (expectedCount > 0 && dish.items.length < expectedCount) {
            throw Exception('Gericht "${dish.name}" ist unvollständig (${dish.items.length} von $expectedCount Zutaten).');
          }
        }
      } catch (seedErr) {
        debugPrint('Household direct initial seeding failed: $seedErr. Rolling back household ${household.id}...');
        try {
          await deleteHousehold(household.id);
        } catch (rollbackErr) {
          debugPrint('Error rolling back household ${household.id}: $rollbackErr');
        }
        throw Exception('Haushalt konnte nicht vollständig initialisiert werden ($seedErr). Bitte versuche es erneut.');
      }

      return household;
    }
  }

  Future<Household> joinHouseholdByCode(String inviteCode) async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      throw Exception('Benutzer ist nicht angemeldet.');
    }

    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw Exception('Bitte gib einen gültigen Einladungscode ein.');
    }

    try {
      final response = await _client.rpc('join_household_by_code', params: {
        'code': code,
      });

      if (response != null) {
        return Household.fromJson(Map<String, dynamic>.from(response as Map));
      }
      throw Exception('Ungültiger Einladungscode.');
    } catch (e) {
      debugPrint('RPC join_household_by_code failed: $e. Falling back to query.');
      final householdData = await _client
          .from('households')
          .select()
          .ilike('invite_code', code)
          .maybeSingle();

      if (householdData == null) {
        throw Exception('Kein Haushalt mit dem Code "$code" gefunden.');
      }

      final household = Household.fromJson(householdData);
      final userId = SupabaseConfig.currentUserId!;

      await _client.from('household_members').upsert({
        'household_id': household.id,
        'user_id': userId,
        'role': 'member',
      });

      return household;
    }
  }

  Future<void> updateHousehold(Household household) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client.from('households').update({
      'name': household.name,
      'color': household.color,
    }).eq('id', household.id);
  }

  /// Robust 2-step member and profile fetcher
  Future<List<HouseholdMember>> fetchMembers(String householdId) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) return [];

    try {
      // Step 1: fetch raw household_members
      final membersData = await _client
          .from('household_members')
          .select('household_id, user_id, role, joined_at')
          .eq('household_id', householdId)
          .order('joined_at', ascending: true);

      final List<dynamic> rawList = membersData as List;
      if (rawList.isEmpty) return [];

      final List<Map<String, dynamic>> rawMembers = rawList.cast<Map<String, dynamic>>();

      // Step 2: fetch profiles for these user_ids
      final userIds = rawMembers
          .map((m) => m['user_id'] as String?)
          .where((uid) => uid != null && uid.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      Map<String, Profile> profilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profilesData = await _client
              .from('profiles')
              .select('id, display_name, avatar_url, created_at')
              .filter('id', 'in', userIds);

          for (final p in profilesData as List) {
            final profile = Profile.fromJson(p as Map<String, dynamic>);
            profilesMap[profile.id] = profile;
          }
        } catch (e) {
          debugPrint('Profiles fetch info: $e');
        }
      }

      return rawMembers.map((m) {
        final uid = m['user_id'] as String;
        final profile = profilesMap[uid];
        return HouseholdMember(
          householdId: m['household_id'] as String,
          userId: uid,
          role: m['role'] as String? ?? 'member',
          joinedAt: m['joined_at'] != null ? DateTime.parse(m['joined_at'] as String) : DateTime.now(),
          profile: profile,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching household members: $e');
      return [];
    }
  }
}
