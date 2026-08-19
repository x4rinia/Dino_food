import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/profile.dart';

class HouseholdService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Household>> fetchUserHouseholds() async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      return [];
    }

    final userId = SupabaseConfig.currentUserId!;
    try {
      final memberRows = await _client
          .from('household_members')
          .select('household_id, households(*)')
          .eq('user_id', userId);

      final List<Household> households = [];
      for (final row in memberRows) {
        if (row['households'] != null) {
          households.add(Household.fromJson(row['households'] as Map<String, dynamic>));
        }
      }
      return households;
    } catch (e) {
      debugPrint('Error fetching households: $e');
      rethrow;
    }
  }

  Future<Household> createHousehold({
    required String name,
    String postalCode = '',
  }) async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      throw Exception('Benutzer ist nicht angemeldet.');
    }

    try {
      final response = await _client.rpc('create_household_and_join', params: {
        'name': name.trim(),
        'postal_code': postalCode.trim(),
      });

      if (response != null) {
        return Household.fromJson(Map<String, dynamic>.from(response as Map));
      }
      throw Exception('Haushalt konnte nicht erstellt werden.');
    } catch (e) {
      debugPrint('RPC create_household_and_join failed: $e. Falling back to direct insert.');
      final userId = SupabaseConfig.currentUserId!;
      final householdData = await _client
          .from('households')
          .insert({
            'name': name.trim(),
            'postal_code': postalCode.trim(),
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
      'postal_code': household.postalCode,
      if (household.imageUrl != null) 'image_url': household.imageUrl,
    }).eq('id', household.id);
  }

  Future<String> uploadHouseholdImage(String householdId, Uint8List imageBytes, String fileExtension) async {
    if (!SupabaseConfig.isConfigured) throw Exception('Supabase nicht konfiguriert');

    final fileName = '${householdId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final imagePath = 'households/$fileName';

    await _client.storage.from('household_images').uploadBinary(
      imagePath,
      imageBytes,
      fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExtension'),
    );

    final imageUrl = _client.storage.from('household_images').getPublicUrl(imagePath);

    await _client.from('households').update({'image_url': imageUrl}).eq('id', householdId);
    
    return imageUrl;
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
              .select('id, email, display_name, avatar_url, updated_at')
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
