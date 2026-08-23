import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/food.dart';
import '../services/food_service.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider({
    FoodService? foodService,
    this.loadTimeout = const Duration(seconds: 15),
  }) : _foodService = foodService ?? FoodService();

  final FoodService _foodService;
  final Duration loadTimeout;

  List<Food> _foods = [];
  String _searchQuery = '';
  String? _currentHouseholdId;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  List<Food> get foods => _foods;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Food> get filteredFoods {
    final query = normalizeForComparison(_searchQuery);
    return _foods.where((food) {
      return query.isEmpty ||
          normalizeForComparison(food.name).contains(query) ||
          normalizeForComparison(food.note ?? '').contains(query);
    }).toList();
  }

  String? get currentHouseholdId => _currentHouseholdId;

  void bindToHousehold(String? householdId) {
    if (householdId == null || householdId.isEmpty) {
      _currentHouseholdId = null;
      _foods = [];
      _hasLoaded = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (_currentHouseholdId == householdId && _hasLoaded) return;

    _currentHouseholdId = householdId;
    _foods = [];
    _hasLoaded = false;
    _errorMessage = null;
    loadFoods(force: true);
  }

  static String normalizeForComparison(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static int compareFoodNames(String a, String b) {
    String normalize(String s) {
      return normalizeForComparison(s)
          .replaceAll('ä', 'ae')
          .replaceAll('ö', 'oe')
          .replaceAll('ü', 'ue')
          .replaceAll('ß', 'ss');
    }

    return normalize(a).compareTo(normalize(b));
  }

  void _sortFoods() {
    _foods.sort((a, b) {
      final nameResult = compareFoodNames(a.name, b.name);
      if (nameResult != 0) return nameResult;
      return normalizeForComparison(a.note ?? '')
          .compareTo(normalizeForComparison(b.note ?? ''));
    });
  }

  Future<void> loadFoods({bool force = false}) async {
    if (_hasLoaded && !force && _foods.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final requestedHouseholdId = _currentHouseholdId;

    try {
      final loaded = await _foodService
          .fetchFoods(requestedHouseholdId)
          .timeout(loadTimeout);
      if (_currentHouseholdId != requestedHouseholdId) return;
      _foods = loaded;
      _sortFoods();
      _hasLoaded = true;
    } on TimeoutException catch (e, stackTrace) {
      if (_currentHouseholdId != requestedHouseholdId) return;
      _errorMessage = 'Lebensmittel konnten nicht rechtzeitig geladen werden.';
      debugPrint('Food load timeout: $e\n$stackTrace');
    } catch (e, stackTrace) {
      if (_currentHouseholdId != requestedHouseholdId) return;
      _errorMessage = 'Lebensmittel konnten nicht geladen werden: $e';
      debugPrint('Error loading foods: $e\n$stackTrace');
    } finally {
      if (_currentHouseholdId == requestedHouseholdId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool foodExists(String name, {String? note, String? excludeId}) {
    final normalizedName = normalizeForComparison(name);
    final normalizedNote = normalizeForComparison(note ?? '');
    return _foods.any((food) {
      if (excludeId != null && food.id == excludeId) return false;
      return normalizeForComparison(food.name) == normalizedName &&
          normalizeForComparison(food.note ?? '') == normalizedNote;
    });
  }

  Future<Food> addCustomFood({
    required String name,
    String? note,
    String? iconKey,
    String defaultUnit = '',
  }) async {
    if (_currentHouseholdId == null && SupabaseConfig.isConfigured) {
      throw StateError('Kein aktiver Haushalt.');
    }
    final householdId = _currentHouseholdId;
    final trimmedName = name.trim();
    final trimmedNote = note?.trim();
    if (foodExists(trimmedName, note: trimmedNote)) {
      throw Exception('Dieses Lebensmittel mit dieser Notiz gibt es bereits.');
    }

    final food = await _foodService.addCustomFood(
      name: trimmedName,
      note: trimmedNote?.isEmpty == true ? null : trimmedNote,
      iconKey: iconKey,
      defaultUnit: defaultUnit,
      householdId: householdId,
    );
    if (_currentHouseholdId != householdId) return food;
    if (!_foods.any((f) => f.id == food.id)) {
      _foods.add(food);
      _sortFoods();
    }
    notifyListeners();
    return food;
  }

  Future<Food> updateFood({
    required String id,
    required String name,
    String? note,
    String? iconKey,
  }) async {
    if (_currentHouseholdId == null && SupabaseConfig.isConfigured) {
      throw StateError('Kein aktiver Haushalt.');
    }
    final householdId = _currentHouseholdId;
    final trimmedName = name.trim();
    final trimmedNote = note?.trim();
    if (foodExists(trimmedName, note: trimmedNote, excludeId: id)) {
      throw Exception('Dieses Lebensmittel mit dieser Notiz gibt es bereits.');
    }

    final updated = await _foodService.updateFood(
      id: id,
      name: trimmedName,
      note: trimmedNote?.isEmpty == true ? null : trimmedNote,
      iconKey: iconKey,
      householdId: householdId,
    );
    if (_currentHouseholdId != householdId) return updated;

    final index = _foods.indexWhere((f) => f.id == id);
    if (index != -1) {
      _foods[index] = updated;
      _sortFoods();
    }
    notifyListeners();
    return updated;
  }

  Future<bool> isFoodInUse(String foodId) {
    final householdId = _currentHouseholdId;
    if (householdId == null) return Future.value(false);
    return _foodService.isFoodInUse(foodId, householdId);
  }

  Future<bool> deleteFood(String foodId, {String? foodName}) async {
    if (_currentHouseholdId == null && SupabaseConfig.isConfigured) {
      return false;
    }
    final householdId = _currentHouseholdId;
    final name =
        foodName ?? _foods.where((f) => f.id == foodId).firstOrNull?.name;
    await _foodService.deleteFood(
      foodId,
      foodName: name,
      householdId: householdId,
    );
    if (_currentHouseholdId != householdId) return true;
    _foods.removeWhere((f) => f.id == foodId);
    notifyListeners();
    return true;
  }
}
