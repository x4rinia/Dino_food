import 'package:flutter/foundation.dart';
import '../models/dish.dart';
import '../models/dish_item.dart';
import '../models/food.dart';
import '../services/dish_service.dart';

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
  final DishService _dishService = DishService();

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
  }) {
    final normalizedSearchName = hungerFood.name.trim().toLowerCase();
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
        if (item.displayName.trim().toLowerCase() == normalizedSearchName) {
          matchingItem = item;
          break;
        }
      }

      if (matchingItem == null) continue; // Not a match

      // Check stock status for each ingredient in this dish
      var inStockCount = 0;
      final totalCount = dish.items.length;

      for (final item in dish.items) {
        final fId = item.foodId ?? item.food?.id;
        final isInStock = (fId != null && inStockFoodIds.contains(fId)) ||
            (item.displayName.trim().toLowerCase() == normalizedSearchName && inStockFoodIds.contains(hungerFood.id));

        if (isInStock) {
          inStockCount++;
        }
      }

      final mainFId = matchingItem.foodId ?? matchingItem.food?.id;
      final isMainInStock = (mainFId != null && inStockFoodIds.contains(mainFId)) ||
          inStockFoodIds.contains(hungerFood.id);

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
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dishes = await _dishService.fetchDishes(householdId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading dishes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDish({
    required String householdId,
    required String name,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dish = await _dishService.createDish(
        householdId: householdId,
        name: name,
        items: items,
      );
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _dishService.updateDish(
        dishId: dishId,
        name: name,
        items: items,
        householdId: _currentHouseholdId,
      );

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
    _dishes.removeWhere((d) => d.id == dishId);
    notifyListeners();

    await _dishService.deleteDish(dishId, householdId: _currentHouseholdId);
  }

  /// Toggles favorite status. Returns false if limit of 5 favorites is reached.
  Future<bool> toggleFavorite(String dishId) async {
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

    await _dishService.toggleFavorite(dishId, willBeFav, householdId: _currentHouseholdId);
    return true;
  }

  Future<int> addItemsToShoppingList({
    required String householdId,
    required List<DishItem> items,
  }) async {
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
}
