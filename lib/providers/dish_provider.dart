import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/dish.dart';
import '../models/dish_item.dart';
import '../models/food.dart';
import '../services/dish_service.dart';
import '../utils/recipe_ingredient_matcher.dart';

class HungerDishMatch {
  final Dish dish;
  final double score; // inStockCount / totalCount (0.0 - 1.0)
  final int inStockCount;
  final int totalCount;
  final bool isMainInStock;
  final DishItem mainItem;

  HungerDishMatch({
    required this.dish,
    required this.score,
    required this.inStockCount,
    required this.totalCount,
    required this.isMainInStock,
    required this.mainItem,
  });

  String get scorePercentageText => '${(score * 100).round()}%';
}

class DishProvider extends ChangeNotifier {
  DishProvider({
    DishService? dishService,
    this.loadTimeout = const Duration(seconds: 15),
  }) : _dishService = dishService ?? DishService();

  final DishService _dishService;
  final Duration loadTimeout;

  List<Dish> _dishes = [];
  String? _currentHouseholdId;
  Food? _selectedHungerFood;
  bool _isLoading = false;
  String? _errorMessage;

  List<Dish> get dishes {
    // Sort: Favorites first, then name
    final sorted = List<Dish>.from(_dishes);
    sorted.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  Food? get selectedHungerFood => _selectedHungerFood;
  int get favoriteCount => _dishes.where((d) => d.isFavorite).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setHungerFood(Food? food) {
    _selectedHungerFood = food;
    notifyListeners();
  }

  void clearHungerSearch() {
    _selectedHungerFood = null;
    notifyListeners();
  }

  /// Calculates matching dishes for a selected hunger food, checks stock, and sorts by:
  /// 1. Higher score (inStockCount / totalCount)
  /// 2. Higher absolute inStockCount
  /// 3. Alphabetical / Favorite
  List<HungerDishMatch> getRankedDishesForHunger({
    required Food hungerFood,
    required Set<String> inStockFoodIds,
    FoodIdsByNormalizedName? foodIdsByName,
  }) {
    final normalizedSearchName = RecipeIngredientMatcher.normalizeName(
      hungerFood.name,
    );
    final indexedFoods = foodIdsByName ?? <String, Set<String>>{};
    final List<HungerDishMatch> matches = [];

    for (final dish in _dishes) {
      // Find if dish contains the searched food
      DishItem? matchingItem;
      for (final item in dish.items) {
        if (item.foodId != null && item.foodId == hungerFood.id) {
          matchingItem = item;
          break;
        }
        if (item.food?.id != null && item.food!.id == hungerFood.id) {
          matchingItem = item;
          break;
        }
        if (RecipeIngredientMatcher.normalizeName(item.displayName) ==
            normalizedSearchName) {
          matchingItem = item;
          break;
        }
      }

      if (matchingItem == null) continue; // Not a match

      // Check stock status for each ingredient in this dish
      var inStockCount = 0;
      final totalCount = dish.items.length;

      for (final item in dish.items) {
        final isInStock = RecipeIngredientMatcher.isInStock(
          item: item,
          inStockFoodIds: inStockFoodIds,
          foodIdsByName: indexedFoods,
        );

        if (isInStock) {
          inStockCount++;
        }
      }

      final isMainInStock = RecipeIngredientMatcher.isInStock(
        item: matchingItem,
        inStockFoodIds: inStockFoodIds,
        foodIdsByName: indexedFoods,
      );

      final score = totalCount > 0 ? (inStockCount / totalCount) : 0.0;

      matches.add(
        HungerDishMatch(
          dish: dish,
          score: score,
          inStockCount: inStockCount,
          totalCount: totalCount,
          isMainInStock: isMainInStock,
          mainItem: matchingItem,
        ),
      );
    }

    // Sort: Score descending -> inStockCount descending -> Favorite -> Name
    matches.sort((a, b) {
      final scoreComp = b.score.compareTo(a.score);
      if (scoreComp != 0) return scoreComp;

      final countComp = b.inStockCount.compareTo(a.inStockCount);
      if (countComp != 0) return countComp;

      if (a.dish.isFavorite && !b.dish.isFavorite) return -1;
      if (!a.dish.isFavorite && b.dish.isFavorite) return 1;
      return a.dish.name.toLowerCase().compareTo(b.dish.name.toLowerCase());
    });

    return matches;
  }

  Future<void> loadDishes(String householdId) async {
    if (_currentHouseholdId != householdId) {
      _selectedHungerFood = null;
      _currentHouseholdId = householdId;
      _dishes = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _dishService
          .fetchDishes(householdId)
          .timeout(loadTimeout);
      if (_currentHouseholdId != householdId) return;
      _dishes = list;
    } on TimeoutException catch (e, stackTrace) {
      if (_currentHouseholdId != householdId) return;
      _errorMessage = 'Gerichte konnten nicht rechtzeitig geladen werden.';
      debugPrint('Dish load timeout: $e\n$stackTrace');
      _dishes = [];
    } catch (e, stackTrace) {
      if (_currentHouseholdId != householdId) return;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading dishes: $e\n$stackTrace');
      _dishes = [];
    } finally {
      if (_currentHouseholdId == householdId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createDish({
    required String householdId,
    required String name,
    required List<Map<String, dynamic>> items,
  }) async {
    if (_currentHouseholdId != householdId) {
      _currentHouseholdId = householdId;
      _selectedHungerFood = null;
      _dishes = [];
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dish = await _dishService.createDish(
        householdId: householdId,
        name: name,
        items: items,
      );
      if (_currentHouseholdId != householdId) return true;
      _dishes.add(dish);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDish({
    required String dishId,
    required String name,
    required List<Map<String, dynamic>> items,
  }) async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _dishService.updateDish(
        dishId: dishId,
        name: name,
        items: items,
        householdId: householdId,
      );
      if (_currentHouseholdId != householdId) return true;

      final index = _dishes.indexWhere((d) => d.id == dishId);
      if (index != -1) {
        _dishes[index] = updated.copyWith(
          isFavorite: _dishes[index].isFavorite,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDish(String dishId) async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return;
    _dishes.removeWhere((d) => d.id == dishId);
    notifyListeners();

    await _dishService.deleteDish(dishId, householdId: householdId);
  }

  /// Toggles favorite status. Returns false if limit of 5 favorites is reached.
  Future<bool> toggleFavorite(String dishId) async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return false;
    final index = _dishes.indexWhere((d) => d.id == dishId);
    if (index == -1) return false;

    final currentFav = _dishes[index].isFavorite;
    final willBeFav = !currentFav;

    if (willBeFav && favoriteCount >= 5) {
      // Max 5 favorites reached!
      return false;
    }

    _dishes[index] = _dishes[index].copyWith(isFavorite: willBeFav);
    notifyListeners();

    await _dishService.toggleFavorite(
      dishId,
      willBeFav,
      householdId: householdId,
    );
    return true;
  }

  Future<int> addItemsToShoppingList({
    required String householdId,
    required List<DishItem> items,
  }) async {
    if (_currentHouseholdId != householdId) return 0;
    try {
      return await _dishService.addItemsToShoppingList(
        householdId: householdId,
        items: items,
      );
    } catch (e) {
      debugPrint('Error transferring dish items to shopping list: $e');
      return 0;
    }
  }

  void reset() {
    _dishes = [];
    _currentHouseholdId = null;
    _selectedHungerFood = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
