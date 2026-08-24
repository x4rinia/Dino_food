import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../services/dish_service.dart';
import '../services/food_service.dart';
import '../services/household_service.dart';

enum HouseholdState { initial, loading, loaded, error }

class HouseholdProvider extends ChangeNotifier {
  HouseholdProvider({
    HouseholdService? householdService,
    FoodService? foodService,
    DishService? dishService,
    bool? isSupabaseConfigured,
    this.startupTimeout = const Duration(seconds: 15),
  }) : _householdService = householdService ?? HouseholdService(),
       _foodService = foodService ?? FoodService(),
       _dishService = dishService ?? DishService(),
       _isSupabaseConfiguredOverride = isSupabaseConfigured;

  final HouseholdService _householdService;
  final FoodService _foodService;
  final DishService _dishService;
  final bool? _isSupabaseConfiguredOverride;
  final Duration startupTimeout;

  bool get _isSupabaseConfigured =>
      _isSupabaseConfiguredOverride ?? SupabaseConfig.isConfigured;

  HouseholdState _state = HouseholdState.initial;
  List<Household> _households = [];
  String? _defaultHouseholdId;
  Household? _currentHousehold;
  List<HouseholdMember> _members = [];
  String? _errorMessage;
  bool _isRefreshing = false;

  HouseholdState get state => _state;
  List<Household> get households => _households;
  String? get defaultHouseholdId => _defaultHouseholdId;
  Household? get currentHousehold => _currentHousehold;
  List<HouseholdMember> get members => _members;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == HouseholdState.loading;
  bool get isLoaded => _state == HouseholdState.loaded;
  bool get hasError => _state == HouseholdState.error;
  bool get hasHousehold => _currentHousehold != null;

  bool isDefaultHousehold(String householdId) =>
      _defaultHouseholdId == householdId;
  bool isCurrentHousehold(String householdId) =>
      _currentHousehold?.id == householdId;

  Future<void> loadHouseholds({bool force = false}) async {
    // If already loading or loaded, don't re-trigger unless force is true
    if (!force &&
        (_state == HouseholdState.loading || _state == HouseholdState.loaded)) {
      return;
    }

    _state = HouseholdState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_isSupabaseConfigured) {
        final mockHousehold = Household(
          id: 'demo-household-id',
          name: 'Dino Zuhause 🦕',
          color: '#2A9D8F',
          inviteCode: 'DINO-4F8K',
          createdAt: DateTime.now(),
        );
        _households = [mockHousehold];
        _defaultHouseholdId = mockHousehold.id;
        _currentHousehold = mockHousehold;
        _members = [
          HouseholdMember(
            householdId: mockHousehold.id,
            userId: 'demo-user-1',
            joinedAt: DateTime.now(),
          ),
        ];
        // Seed default foods & dishes for demo mock household if not yet seeded
        final foodMap = await _foodService.seedDefaultFoodsForHousehold(
          mockHousehold.id,
        );
        await _dishService.seedDefaultDishesForHousehold(
          mockHousehold.id,
          foodMap,
        );

        _state = HouseholdState.loaded;
        _errorMessage = null;
        notifyListeners();
        return;
      }

      _households = await _startupStep(
        _householdService.fetchUserHouseholds(),
        'Haushaltszuordnungen',
      );

      if (_households.isNotEmpty) {
        // Fetch default household from profile
        String? defaultId = await _startupStep(
          _householdService.fetchDefaultHouseholdId(),
          'Standardhaushalt',
        );

        // If default household is not valid or not set, pick the first household and persist
        if (defaultId == null || !_households.any((h) => h.id == defaultId)) {
          defaultId = _households.first.id;
          await _startupStep(
            _householdService.setDefaultHousehold(defaultId),
            'Standardhaushalt speichern',
          );
        }
        _defaultHouseholdId = defaultId;

        // On app start / fresh load, activate the default / favorite household
        _currentHousehold = _households.firstWhere(
          (h) => h.id == _defaultHouseholdId,
          orElse: () => _households.first,
        );

        _members = await _startupStep(
          _householdService.fetchMembers(_currentHousehold!.id),
          'Haushaltsmitglieder',
        );
      } else {
        _currentHousehold = null;
        _defaultHouseholdId = null;
        _members = [];
      }

      _state = HouseholdState.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Household load failed: $e\n$stackTrace');
      _state = HouseholdState.error;
      _errorMessage = _friendlyStartupError(e);
      notifyListeners();
    }
  }

  Future<bool> refreshOnResume({int attempts = 2}) async {
    if (_isRefreshing) return false;
    if (!_isSupabaseConfigured) return true;
    final activeHouseholdId = _currentHousehold?.id;
    if (activeHouseholdId == null) return false;

    _isRefreshing = true;
    Object? lastError;
    StackTrace? lastStackTrace;
    try {
      for (var attempt = 0; attempt < attempts; attempt++) {
        try {
          final households = await _startupStep(
            _householdService.fetchUserHouseholds(),
            'Haushaltszuordnungen',
          );
          final defaultId = await _startupStep(
            _householdService.fetchDefaultHouseholdId(),
            'Standardhaushalt',
          );
          if (!households.any(
            (household) => household.id == activeHouseholdId,
          )) {
            throw const HouseholdStartupException(
              'Der aktive Haushalt ist nicht mehr verfügbar.',
            );
          }
          final activeHousehold = households.firstWhere(
            (household) => household.id == activeHouseholdId,
          );
          final members = await _startupStep(
            _householdService.fetchMembers(activeHouseholdId),
            'Haushaltsmitglieder',
          );

          _households = households;
          _defaultHouseholdId = defaultId;
          _currentHousehold = activeHousehold;
          _members = members;
          _state = HouseholdState.loaded;
          _errorMessage = null;
          notifyListeners();
          return true;
        } catch (error, stackTrace) {
          lastError = error;
          lastStackTrace = stackTrace;
          if (attempt + 1 < attempts) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      debugPrint(
        'Household resume refresh failed: $lastError\n$lastStackTrace',
      );
      _state = HouseholdState.error;
      _errorMessage = _friendlyStartupError(lastError ?? Exception());
      notifyListeners();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<T> _startupStep<T>(Future<T> future, String label) async {
    debugPrint('Household startup: $label...');
    try {
      final result = await future.timeout(startupTimeout);
      debugPrint('Household startup: $label loaded.');
      return result;
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('Household startup timeout at $label: $e\n$stackTrace');
      throw HouseholdStartupException(
        '$label konnte nicht rechtzeitig geladen werden.',
      );
    } catch (e, stackTrace) {
      debugPrint('Household startup failed at $label: $e\n$stackTrace');
      rethrow;
    }
  }

  String _friendlyStartupError(Object error) {
    if (error is HouseholdStartupException) {
      return '${error.message} Bitte prüfe deine Verbindung und versuche es erneut.';
    }
    return 'Der Haushalt konnte nicht geladen werden. Bitte versuche es erneut. (${error.toString().replaceFirst('Exception: ', '')})';
  }

  void setCurrentHousehold(Household household) {
    _currentHousehold = household;
    loadMembers();
    notifyListeners();
  }

  Future<bool> setDefaultHousehold(String householdId) async {
    if (!_households.any((h) => h.id == householdId)) return false;
    if (_defaultHouseholdId == householdId) return true;

    final previousDefault = _defaultHouseholdId;
    _defaultHouseholdId = householdId;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _householdService.setDefaultHousehold(householdId);
        return true;
      } catch (e) {
        debugPrint('Error setting default household: $e');
        _defaultHouseholdId = previousDefault;
        _errorMessage = 'Der Standardhaushalt konnte nicht geändert werden.';
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<void> loadMembers() async {
    if (_currentHousehold == null) return;
    if (!_isSupabaseConfigured) return;

    try {
      _members = await _householdService.fetchMembers(_currentHousehold!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading members: $e');
    }
  }

  Future<bool> createHousehold({
    required String name,
    String color = '#2A9D8F',
  }) async {
    _state = HouseholdState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
        final newH = Household(
          id: 'h_${DateTime.now().microsecondsSinceEpoch}_${_households.length + 1}',
          name: name,
          color: color,
          inviteCode: 'DINO-8888',
          createdAt: DateTime.now(),
        );

        // Seed default foods & dishes for new mock household
        final foodMap = await _foodService.seedDefaultFoodsForHousehold(
          newH.id,
          replaceExistingDefaults: true,
        );
        final dishes = await _dishService.seedDefaultDishesForHousehold(
          newH.id,
          foodMap,
          replaceExistingDefaults: true,
        );

        if (dishes.length < 10) {
          throw Exception(
            'Nicht alle Standardgerichte konnten initialisiert werden.',
          );
        }

        _households.add(newH);
        _currentHousehold = newH;
        if (_defaultHouseholdId == null || _households.length == 1) {
          _defaultHouseholdId = newH.id;
        }

        _state = HouseholdState.loaded;
        notifyListeners();
        return true;
      }

      final household = await _householdService.createHousehold(
        name: name,
        color: color,
      );
      _households.add(household);
      _currentHousehold = household;

      // If this is the user's first household, set it as default
      if (_defaultHouseholdId == null || _households.length == 1) {
        _defaultHouseholdId = household.id;
        try {
          await _householdService.setDefaultHousehold(household.id);
        } catch (e) {
          debugPrint('Error setting default household on create: $e');
        }
      }

      _members = await _householdService.fetchMembers(household.id);
      _state = HouseholdState.loaded;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Household creation failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = HouseholdState
          .loaded; // keep current state loaded so UI stays interactive
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinHousehold(String inviteCode) async {
    _state = HouseholdState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
        throw Exception('Supabase ist noch nicht konfiguriert.');
      }

      final household = await _householdService.joinHouseholdByCode(inviteCode);
      if (!_households.any((h) => h.id == household.id)) {
        _households.add(household);
      }
      _currentHousehold = household;

      // If this is the user's first household, set it as default
      if (_defaultHouseholdId == null || _households.length == 1) {
        _defaultHouseholdId = household.id;
        try {
          await _householdService.setDefaultHousehold(household.id);
        } catch (e) {
          debugPrint('Error setting default household on join: $e');
        }
      }

      _members = await _householdService.fetchMembers(household.id);
      _state = HouseholdState.loaded;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Join household failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = HouseholdState.loaded;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHousehold(String householdId) async {
    if (_households.length <= 1) {
      _errorMessage = 'Mindestens ein Haushalt muss bestehen bleiben.';
      notifyListeners();
      return false;
    }

    _state = HouseholdState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        await _householdService.deleteHousehold(householdId);
      }

      _households.removeWhere((h) => h.id == householdId);

      // If deleted household was the default/favorite
      if (_defaultHouseholdId == householdId) {
        if (_households.isNotEmpty) {
          _defaultHouseholdId = _households.first.id;
          if (SupabaseConfig.isConfigured) {
            try {
              await _householdService.setDefaultHousehold(_defaultHouseholdId!);
            } catch (e) {
              debugPrint('Error updating default household after delete: $e');
            }
          }
        } else {
          _defaultHouseholdId = null;
        }
      }

      // If deleted household was the active household
      if (_currentHousehold?.id == householdId) {
        if (_households.isNotEmpty) {
          // Prefer default household if available, otherwise first remaining
          _currentHousehold = _households.firstWhere(
            (h) => h.id == _defaultHouseholdId,
            orElse: () => _households.first,
          );
          try {
            _members = await _householdService.fetchMembers(
              _currentHousehold!.id,
            );
          } catch (e) {
            debugPrint('Error loading members after delete: $e');
          }
        } else {
          _currentHousehold = null;
          _members = [];
        }
      }

      _state = HouseholdState.loaded;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete household failed: $e');
      _errorMessage = 'Der Haushalt konnte nicht gelöscht werden.';
      _state = HouseholdState.loaded;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHouseholdDetails(String newName, String newColor) async {
    if (_currentHousehold == null) return false;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    final updated = Household(
      id: _currentHousehold!.id,
      name: trimmed,
      color: newColor,
      inviteCode: _currentHousehold!.inviteCode,
      createdBy: _currentHousehold!.createdBy,
      createdAt: _currentHousehold!.createdAt,
    );

    final index = _households.indexWhere((h) => h.id == _currentHousehold!.id);
    if (index != -1) {
      _households[index] = updated;
    }
    _currentHousehold = updated;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _householdService.updateHousehold(updated);
      } catch (e) {
        debugPrint('Error updating household details: $e');
        return false;
      }
    }
    return true;
  }

  /// Reset is ONLY called on explicit user logout / account switch
  void reset() {
    _state = HouseholdState.initial;
    _households = [];
    _defaultHouseholdId = null;
    _currentHousehold = null;
    _members = [];
    _errorMessage = null;
    notifyListeners();
  }
}

class HouseholdStartupException implements Exception {
  const HouseholdStartupException(this.message);

  final String message;

  @override
  String toString() => message;
}
