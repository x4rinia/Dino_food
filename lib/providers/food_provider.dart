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

  Future<Food> addCustomFood({
    required String name,
    String category = 'Sonstiges',
    String defaultUnit = '',
  }) async {
    final food = await _foodService.addCustomFood(
      name: name,
      category: category,
      defaultUnit: defaultUnit,
    );
    _foods.insert(0, food);
    notifyListeners();
    return food;
  }
}
