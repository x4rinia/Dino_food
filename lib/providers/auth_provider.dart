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
  bool _needsEmailConfirmation = false;

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get needsEmailConfirmation => _needsEmailConfirmation;
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
        _needsEmailConfirmation = false;
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _status = AuthStatus.unauthenticated;
        _profile = null;
        _needsEmailConfirmation = false;
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
        _needsEmailConfirmation = false;
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

      // Check if session was created immediately or requires email confirmation
      if (response?.session == null && response?.user != null) {
        // E-Mail confirmation required by Supabase project settings
        _needsEmailConfirmation = true;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else if (response?.session != null) {
        _needsEmailConfirmation = false;
        _status = AuthStatus.authenticated;
        await _loadProfile();
        notifyListeners();
        return true;
      }

      throw Exception('Registrierung konnte nicht abgeschlossen werden.');
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _profile = null;
    _needsEmailConfirmation = false;
    notifyListeners();
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

  void resetEmailConfirmationFlag() {
    _needsEmailConfirmation = false;
    notifyListeners();
  }
}
