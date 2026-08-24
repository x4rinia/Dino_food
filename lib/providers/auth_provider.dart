import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  Profile? _profile;
  String? _errorMessage;

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitializing => _status == AuthStatus.uninitialized;
  User? get currentUser => _authService.currentUser;

  AuthProvider() {
    _init();
  }

  void _init() {
    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (_authService.currentUser != null) {
      _status = AuthStatus.authenticated;
      _loadProfile();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();

    _authService.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
        _status = AuthStatus.authenticated;
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _status = AuthStatus.unauthenticated;
        _profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadProfile() async {
    _profile = await _authService.getCurrentProfile();
    notifyListeners();
  }

  Future<bool> refreshSessionOnResume({int attempts = 2}) async {
    if (!SupabaseConfig.isConfigured) return true;
    final session = SupabaseConfig.client.auth.currentSession;
    if (session == null) return false;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await SupabaseConfig.client.auth.refreshSession();
        if (response.session != null) {
          _status = AuthStatus.authenticated;
          return true;
        }
      } catch (error, stackTrace) {
        debugPrint('Session refresh attempt ${attempt + 1} failed: $error\n$stackTrace');
      }
      if (attempt + 1 < attempts) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  Future<bool> updateDisplayName(String newDisplayName) async {
    _setLoading();
    try {
      final trimmedName = newDisplayName.trim();
      if (trimmedName.isEmpty) {
        throw Exception('Benutzername darf nicht leer sein.');
      }
      await _authService.updateProfile(displayName: trimmedName);
      _profile = await _authService.getCurrentProfile();
      _errorMessage = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update display name failed: $e');
      _errorMessage = _formatError(e);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(Uint8List imageBytes, String fileExtension) async {
    try {
      final imageUrl = await _authService.uploadAvatar(imageBytes, fileExtension);
      if (_profile != null) {
        _profile = Profile(
          id: _profile!.id,
          displayName: _profile!.displayName,
          avatarUrl: imageUrl,
          createdAt: _profile!.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Upload avatar failed: $e');
      _errorMessage = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String usernameOrEmail, String password) async {
    _setLoading();
    try {
      final trimmedIdentifier = usernameOrEmail.trim();
      if (trimmedIdentifier.isEmpty) {
        throw Exception('Bitte gib deinen Benutzernamen ein.');
      }
      final response = await _authService.signIn(
        usernameOrEmail: trimmedIdentifier,
        password: password,
      );
      if (response?.user != null) {
        _errorMessage = null;
        _status = AuthStatus.authenticated;
        await _loadProfile();
        notifyListeners();
        return true;
      } else {
        throw Exception('Benutzername oder Passwort ist falsch.');
      }
    } catch (e) {
      if (e is AuthException) {
        debugPrint('Signin failed: code = ${e.code}, message = ${e.message}, statusCode = ${e.statusCode}');
      } else {
        debugPrint('Signin failed: $e');
      }
      _errorMessage = _formatError(e, isLogin: true);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String username, String password) async {
    _setLoading();
    try {
      final trimmedUsername = username.trim();
      if (trimmedUsername.isEmpty) {
        throw Exception('Bitte gib einen Benutzernamen ein.');
      }

      final response = await _authService.signUp(
        username: trimmedUsername,
        password: password,
      );

      _errorMessage = null;

      if (response?.session != null) {
        _status = AuthStatus.authenticated;
        await _loadProfile();
        notifyListeners();
        return true;
      } else if (response?.user != null) {
        throw Exception('Die direkte Anmeldung ist nicht möglich, da die E-Mail-Bestätigung in Supabase noch aktiv ist. Bitte deaktiviere "Confirm Email" im Supabase-Dashboard.');
      }

      throw Exception('Der Account konnte nicht erstellt werden.');
    } catch (e) {
      if (e is AuthException) {
        debugPrint('Signup failed: code = ${e.code}, message = ${e.message}, statusCode = ${e.statusCode}');
      } else {
        debugPrint('Signup failed: $e');
      }
      _errorMessage = _formatError(e, isSignup: true);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _profile = null;
    notifyListeners();
  }

  Future<bool> changePassword(String newPassword) async {
    _setLoading();
    try {
      if (newPassword.isEmpty || newPassword.length < 6) {
        throw Exception('Das Passwort muss mindestens 6 Zeichen lang sein.');
      }
      await _authService.updatePassword(newPassword);
      _errorMessage = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AuthException) {
        debugPrint('Change password failed: code = ${e.code}, message = ${e.message}, statusCode = ${e.statusCode}');
      } else {
        debugPrint('Change password failed: $e');
      }
      _errorMessage = _formatError(e);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading();
    try {
      await _authService.deleteAccount();
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      _profile = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete account failed: $e');
      _errorMessage = _formatError(e);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _formatError(dynamic e, {bool isLogin = false, bool isSignup = false}) {
    final errorStr = e.toString().toLowerCase();

    if (errorStr.contains('already exists') ||
        errorStr.contains('user_already_exists') ||
        errorStr.contains('already registered') ||
        errorStr.contains('bereits verwendet')) {
      return 'Dieser Benutzername ist bereits vergeben. Bitte wähle einen anderen oder melde dich an.';
    }

    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid_credentials') ||
        (isLogin && errorStr.contains('invalid'))) {
      return 'Benutzername oder Passwort ist falsch.';
    }

    if (errorStr.contains('weak password') ||
        errorStr.contains('weak_password') ||
        errorStr.contains('password should be') ||
        errorStr.contains('mindestens 6 zeichen')) {
      return 'Das Passwort ist zu schwach (mindestens 6 Zeichen erforderlich).';
    }

    if (errorStr.contains('rate limit') ||
        errorStr.contains('over_email_send_rate_limit') ||
        errorStr.contains('email rate limit')) {
      return 'Supabase versucht eine E-Mail zu senden: Bitte deaktiviere "Confirm email" im Supabase-Dashboard (Authentication -> Providers -> Email).';
    }

    if (errorStr.contains('confirm email') || errorStr.contains('supabase-dashboard')) {
      return e.toString().replaceFirst('Exception: ', '');
    }

    if (isSignup) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
      return cleanMsg.isNotEmpty ? cleanMsg : 'Der Account konnte nicht erstellt werden.';
    }

    return e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
  }
}
