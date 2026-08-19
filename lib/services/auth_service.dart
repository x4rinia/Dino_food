import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<AuthState> get authStateChanges =>
      SupabaseConfig.isConfigured ? _client.auth.onAuthStateChange : const Stream.empty();

  User? get currentUser => SupabaseConfig.currentUser;

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase ist nicht konfiguriert. Bitte trage deine URL und Anon Key in die .env Datei ein.');
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    return response;
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase ist nicht konfiguriert. Bitte trage deine URL und Anon Key in die .env Datei ein.');
    }

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response;
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await _client.auth.signOut();
    }
  }

  Future<Profile?> getCurrentProfile() async {
    if (!SupabaseConfig.isConfigured || currentUser == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (data != null) {
        return Profile.fromJson(data);
      } else {
        // Create profile if missing
        final newProfile = Profile(
          id: currentUser!.id,
          displayName: currentUser!.userMetadata?['display_name'] ??
              currentUser!.email?.split('@').first ??
              'Dino-Freund',
          createdAt: DateTime.now(),
        );
        await _client.from('profiles').upsert(newProfile.toJson());
        return newProfile;
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    if (!SupabaseConfig.isConfigured || currentUser == null) return;

    final updates = <String, dynamic>{
      'id': currentUser!.id,
    };
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('profiles').upsert(updates);
  }

  Future<String> uploadAvatar(Uint8List imageBytes, String fileExtension) async {
    if (!SupabaseConfig.isConfigured || currentUser == null) throw Exception('Nicht angemeldet');

    final userId = currentUser!.id;
    final imagePath = '$userId/avatar.$fileExtension';

    await _client.storage.from('avatars').uploadBinary(
      imagePath,
      imageBytes,
      fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExtension'),
    );

    // Cache-Busting Parameter hinzufügen
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imageUrl = '${_client.storage.from('avatars').getPublicUrl(imagePath)}?t=$timestamp';

    await updateProfile(avatarUrl: imageUrl);
    
    return imageUrl;
  }

  Future<void> updatePassword(String newPassword) async {
    if (!SupabaseConfig.isConfigured || currentUser == null) {
      throw Exception('Nicht angemeldet.');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> deleteAccount() async {
    if (!SupabaseConfig.isConfigured || currentUser == null) {
      throw Exception('Nicht angemeldet.');
    }
    await _client.rpc('delete_user_account');
    await signOut();
  }
}
