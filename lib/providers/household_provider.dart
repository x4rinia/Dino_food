import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../services/dish_service.dart';
import '../services/food_service.dart';
import '../services/household_service.dart';

enum HouseholdState {
  initial,
  loading,
  loaded,
  error,
}

class HouseholdProvider extends ChangeNotifier {
  final HouseholdService _householdService = HouseholdService();
  final FoodService _foodService = FoodService();
  final DishService _dishService = DishService();

  HouseholdState _state = HouseholdState.initial;
  List<Household> _households = [];
  String? _defaultHouseholdId;
  Household? _currentHousehold;
  Map<String, String> _userRoles = {}; // householdId -> role
  List<HouseholdMember> _members = [];
  String? _errorMessage;

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

  bool isDefaultHousehold(String householdId) => _defaultHouseholdId == householdId;
  bool isCurrentHousehold(String householdId) => _currentHousehold?.id == householdId;

  bool isOwnerOf(String householdId) {
    if (_userRoles[householdId] == 'owner') return true;
    final h = _households.where((item) => item.id == householdId).firstOrNull;
    if (h != null && h.createdBy != null && h.createdBy == SupabaseConfig.currentUserId) {
      return true;
    }
    return false;
  }

  Future<void> loadHouseholds({bool force = false}) async {
    // If already loading or loaded, don't re-trigger unless force is true
    if (!force && (_state == HouseholdState.loading || _state == HouseholdState.loaded)) {
      return;
    }

    _state = HouseholdState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
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
        _userRoles = {mockHousehold.id: 'owner'};
        _members = [
          HouseholdMember(
            householdId: mockHousehold.id,
            userId: 'demo-user-1',
            role: 'owner',
            joinedAt: DateTime.now(),
          )
        ];
        // Seed default foods & dishes for demo mock household if not yet seeded
        final foodMap = await _foodService.seedDefaultFoodsForHousehold(mockHousehold.id);
        await _dishService.seedDefaultDishesForHousehold(mockHousehold.id, foodMap);

        _state = HouseholdState.loaded;
        _errorMessage = null;
        notifyListeners();
        return;
      }

      final result = await _householdService.fetchUserHouseholdsWithRoles();
      _households = result.households;
      _userRoles = result.roles;

      if (_households.isNotEmpty) {
        // Fetch default household from profile
        String? defaultId = await _householdService.fetchDefaultHouseholdId();

        // If default household is not valid or not set, pick the first household and persist
        if (defaultId == null || !_households.any((h) => h.id == defaultId)) {
          defaultId = _households.first.id;
          try {
            await _householdService.setDefaultHousehold(defaultId);
          } catch (e) {
            debugPrint('Error setting initial default household: $e');
          }
        }
        _defaultHouseholdId = defaultId;

        // On app start / fresh load, activate the default / favorite household
        _currentHousehold = _households.firstWhere(
          (h) => h.id == _defaultHouseholdId,
          orElse: () => _households.first,
        );

        // Fetch members safely without crashing or triggering extra loops
        try {
          _members = await _householdService.fetchMembers(_currentHousehold!.id);
        } catch (e) {
          debugPrint('Members load info: $e');
        }
      } else {
        _currentHousehold = null;
        _defaultHouseholdId = null;
        _members = [];
      }

      _state = HouseholdState.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Household load failed: $e');
      _state = HouseholdState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
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
    if (!SupabaseConfig.isConfigured) return;

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
          id: 'h_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          color: color,
          inviteCode: 'DINO-8888',
          createdAt: DateTime.now(),
        );

        // Seed default foods & dishes for new mock household
        final foodMap = await _foodService.seedDefaultFoodsForHousehold(newH.id);
        final dishes = await _dishService.seedDefaultDishesForHousehold(newH.id, foodMap);

        if (dishes.length < 10) {
          throw Exception('Nicht alle Standardgerichte konnten initialisiert werden.');
        }

        _households.add(newH);
        _userRoles[newH.id] = 'owner';
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
      _userRoles[household.id] = 'owner';
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
      _state = HouseholdState.loaded; // keep current state loaded so UI stays interactive
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
      _userRoles[household.id] = 'member';
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

    if (!isOwnerOf(householdId)) {
      _errorMessage = 'Nur der Inhaber darf den Haushalt löschen.';
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
      _userRoles.remove(householdId);

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
            _members = await _householdService.fetchMembers(_currentHousehold!.id);
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
    _userRoles = {};
    _members = [];
    _errorMessage = null;
    notifyListeners();
  }
}
