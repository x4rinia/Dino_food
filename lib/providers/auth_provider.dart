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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading();
    try {
      final response = await _authService.signIn(email: email.trim(), password: password);
      if (response?.user != null) {
        _errorMessage = null;
        _status = AuthStatus.authenticated;
        await _loadProfile();
        notifyListeners();
        return true;
      } else {
        throw Exception('Anmeldung fehlgeschlagen.');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _setLoading();
    try {
      final response = await _authService.signUp(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
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
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('already exists') || errorStr.contains('user_already_exists') || errorStr.contains('bereits registriert')) {
        _errorMessage = 'Diese E-Mail-Adresse wird bereits verwendet.';
      } else if (errorStr.contains('invalid email') || errorStr.contains('invalid_email') || errorStr.contains('ungültige e-mail-adresse')) {
        _errorMessage = 'Bitte gib eine gültige E-Mail-Adresse ein.';
      } else if (errorStr.contains('weak password') || errorStr.contains('password should be') || errorStr.contains('weak_password')) {
        _errorMessage = 'Das Passwort ist zu schwach (mindestens 6 Zeichen erforderlich).';
      } else if (errorStr.contains('confirm email') || errorStr.contains('supabase-dashboard')) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        _errorMessage = 'Der Account konnte nicht erstellt werden.';
      }
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
      await _authService.updatePassword(newPassword);
      _errorMessage = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.authenticated; // Go back to authenticated state on failure
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
}
