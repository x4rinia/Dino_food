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
  bool _isRecoveringPassword = false;

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isRecoveringPassword => _isRecoveringPassword;
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
      if (event == AuthChangeEvent.passwordRecovery) {
        _isRecoveringPassword = true;
        _status = AuthStatus.authenticated;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
        _status = AuthStatus.authenticated;
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _status = AuthStatus.unauthenticated;
        _profile = null;
        _isRecoveringPassword = false;
      }
      notifyListeners();
    });
  }

  Future<void> _loadProfile() async {
    _profile = await _authService.getCurrentProfile();
    notifyListeners();
  }

  Future<bool> updateDisplayName(String newDisplayName) async {
    _setLoading();
    try {
      final trimmedName = newDisplayName.trim();
      if (trimmedName.isEmpty) {
        throw Exception('Anzeigename darf nicht leer sein.');
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
        throw Exception('E-Mail-Adresse oder Passwort ist falsch.');
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

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading();
    try {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
        throw Exception('Bitte gib eine gültige E-Mail-Adresse ein.');
      }
      await _authService.sendPasswordResetEmail(trimmedEmail);
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AuthException) {
        debugPrint('Password reset failed: code = ${e.code}, message = ${e.message}, statusCode = ${e.statusCode}');
      } else {
        debugPrint('Password reset failed: $e');
      }
      _errorMessage = _formatError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _profile = null;
    _isRecoveringPassword = false;
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
      _isRecoveringPassword = false;
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
      _isRecoveringPassword = false;
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

  void clearPasswordRecovery() {
    _isRecoveringPassword = false;
    notifyListeners();
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
        errorStr.contains('already registered')) {
      return 'Für diese E-Mail-Adresse existiert bereits ein Account. Bitte melde dich an.';
    }

    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid_credentials') ||
        (isLogin && errorStr.contains('invalid'))) {
      return 'E-Mail-Adresse oder Passwort ist falsch.';
    }

    if (errorStr.contains('invalid email') ||
        errorStr.contains('invalid_email') ||
        errorStr.contains('ungültige e-mail')) {
      return 'Bitte gib eine gültige E-Mail-Adresse ein.';
    }

    if (errorStr.contains('weak password') ||
        errorStr.contains('weak_password') ||
        errorStr.contains('password should be') ||
        errorStr.contains('mindestens 6 zeichen')) {
      return 'Das Passwort ist zu schwach (mindestens 6 Zeichen erforderlich).';
    }

    if (errorStr.contains('otp_expired') ||
        errorStr.contains('token has expired') ||
        errorStr.contains('expired')) {
      return 'Dieser Reset-Link ist ungültig oder abgelaufen. Bitte fordere einen neuen an.';
    }

    if (errorStr.contains('confirm email') || errorStr.contains('supabase-dashboard')) {
      return e.toString().replaceFirst('Exception: ', '');
    }

    if (isSignup) {
      return 'Der Account konnte nicht erstellt werden.';
    }

    return e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
  }
}
