import 'package:flutter/foundation.dart';
import '../models/dish.dart';
import '../models/dish_item.dart';
import '../services/dish_service.dart';

class DishProvider extends ChangeNotifier {
  final DishService _dishService = DishService();

  List<Dish> _dishes = [];
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

  int get favoriteCount => _dishes.where((d) => d.isFavorite).length;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDishes(String householdId) async {
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

    await _dishService.deleteDish(dishId);
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

    await _dishService.toggleFavorite(dishId, willBeFav);
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
