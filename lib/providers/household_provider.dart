import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../services/household_service.dart';

enum HouseholdState {
  initial,
  loading,
  loaded,
  error,
}

class HouseholdProvider extends ChangeNotifier {
  final HouseholdService _householdService = HouseholdService();

  HouseholdState _state = HouseholdState.initial;
  List<Household> _households = [];
  Household? _currentHousehold;
  List<HouseholdMember> _members = [];
  String? _errorMessage;

  HouseholdState get state => _state;
  List<Household> get households => _households;
  Household? get currentHousehold => _currentHousehold;
  List<HouseholdMember> get members => _members;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == HouseholdState.loading;
  bool get isLoaded => _state == HouseholdState.loaded;
  bool get hasError => _state == HouseholdState.error;
  bool get hasHousehold => _currentHousehold != null;

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
        _currentHousehold = mockHousehold;
        _members = [
          HouseholdMember(
            householdId: mockHousehold.id,
            userId: 'demo-user-1',
            role: 'owner',
            joinedAt: DateTime.now(),
          )
        ];
        _state = HouseholdState.loaded;
        _errorMessage = null;
        notifyListeners();
        return;
      }

      _households = await _householdService.fetchUserHouseholds();

      if (_households.isNotEmpty) {
        if (_currentHousehold == null ||
            !_households.any((h) => h.id == _currentHousehold!.id)) {
          _currentHousehold = _households.first;
        } else {
          _currentHousehold =
              _households.firstWhere((h) => h.id == _currentHousehold!.id);
        }

        // Fetch members safely without crashing or triggering extra loops
        try {
          _members = await _householdService.fetchMembers(_currentHousehold!.id);
        } catch (e) {
          debugPrint('Members load info: $e');
        }
      } else {
        _currentHousehold = null;
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
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          color: color,
          inviteCode: 'DINO-8888',
          createdAt: DateTime.now(),
        );
        _households.add(newH);
        _currentHousehold = newH;
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
      _currentHousehold = household;
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

  Future<bool> renameHousehold(String newName) async {
    if (_currentHousehold == null) return false;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    final updated = Household(
      id: _currentHousehold!.id,
      name: trimmed,
      color: _currentHousehold!.color,
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
        debugPrint('Error renaming household: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> updateColor(String color) async {
    if (_currentHousehold == null) return;

    final updated = Household(
      id: _currentHousehold!.id,
      name: _currentHousehold!.name,
      color: color,
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
      await _householdService.updateHousehold(updated);
    }
  }



  /// Reset is ONLY called on explicit user logout / account switch
  void reset() {
    _state = HouseholdState.initial;
    _households = [];
    _currentHousehold = null;
    _members = [];
    _errorMessage = null;
    notifyListeners();
  }
}
