import 'package:flutter/foundation.dart';
import '../models/food.dart';
import '../services/food_service.dart';

class FoodProvider extends ChangeNotifier {
  final FoodService _foodService = FoodService();

  List<Food> _foods = [];
  String _searchQuery = '';
  String _selectedCategory = 'Alle';
  bool _isLoading = false;
  bool _hasLoaded = false;

  static const List<String> standardCategories = [
    'Alle',
    'Gemüse',
    'Obst',
    'Kartoffeln',
    'Fleisch',
    'Wurst',
    'Fisch',
    'Milchprodukte',
    'Käse',
    'Eier',
    'Brot & Backwaren',
    'Nudeln & Reis',
    'Konserven & Gläser',
    'Tiefkühl',
    'Gewürze',
    'Saucen',
    'Öle & Fette',
    'Frühstück',
    'Backen',
    'Getränke',
    'Snacks',
    'Sonstiges',
  ];

  List<Food> get foods => _foods;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  List<String> get categories {
    final available = <String>{'Alle'};
    for (final f in _foods) {
      if (f.category.isNotEmpty) available.add(f.category);
    }
    // Return standard categories that exist, plus any extras
    final ordered = <String>[];
    for (final cat in standardCategories) {
      if (cat == 'Alle' || available.contains(cat)) {
        ordered.add(cat);
      }
    }
    for (final cat in available) {
      if (!ordered.contains(cat)) {
        ordered.add(cat);
      }
    }
    return ordered;
  }

  List<Food> get filteredFoods {
    final query = _searchQuery.trim().toLowerCase();
    return _foods.where((food) {
      final matchesSearch = query.isEmpty || food.name.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'Alle' || food.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> loadFoods({bool force = false}) async {
    if (_hasLoaded && !force && _foods.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _foods = await _foodService.fetchFoods();
      _hasLoaded = true;
    } catch (e) {
      debugPrint('Error loading foods: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  bool foodExists(String name, {String? excludeId}) {
    final normalized = name.trim().toLowerCase();
    return _foods.any((f) {
      if (excludeId != null && f.id == excludeId) return false;
      return f.name.trim().toLowerCase() == normalized;
    });
  }

  Future<Food> addCustomFood({
    required String name,
    String category = 'Sonstiges',
    String defaultUnit = '',
  }) async {
    final trimmedName = name.trim();
    if (foodExists(trimmedName)) {
      throw Exception('Dieses Lebensmittel gibt es bereits.');
    }

    final food = await _foodService.addCustomFood(
      name: trimmedName,
      category: category,
      defaultUnit: defaultUnit,
    );
    if (!_foods.contains(food)) {
      _foods.insert(0, food);
    }
    notifyListeners();
    return food;
  }

  Future<Food> updateFood({
    required String id,
    required String name,
    required String category,
  }) async {
    final trimmedName = name.trim();
    if (foodExists(trimmedName, excludeId: id)) {
      throw Exception('Dieses Lebensmittel gibt es bereits.');
    }

    final updated = await _foodService.updateFood(
      id: id,
      name: trimmedName,
      category: category,
    );

    final index = _foods.indexWhere((f) => f.id == id);
    if (index != -1) {
      _foods[index] = updated;
    }
    notifyListeners();
    return updated;
  }

  Future<bool> isFoodInUse(String foodId) async {
    return await _foodService.isFoodInUse(foodId);
  }

  Future<bool> deleteFood(String foodId) async {
    final inUse = await isFoodInUse(foodId);
    if (inUse) {
      throw Exception('Dieses Lebensmittel wird noch verwendet und kann nicht gelöscht werden.');
    }

    await _foodService.deleteFood(foodId);
    _foods.removeWhere((f) => f.id == foodId);
    notifyListeners();
    return true;
  }
}
