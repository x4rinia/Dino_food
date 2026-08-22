import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../services/stock_service.dart';
import '../services/food_service.dart';
import 'stock_provider.dart';
import 'food_provider.dart';

class ShoppingProvider extends ChangeNotifier {
  final ShoppingService _shoppingService = ShoppingService();

  static final Map<String, List<ShoppingItem>> _householdMockItems = {};

  List<ShoppingItem> _items = [];
  StreamSubscription<List<ShoppingItem>>? _streamSubscription;
  String? _currentHouseholdId;
  bool _isLoading = false;
  String? _errorMessage;

  List<ShoppingItem> get allItems => _items;
  List<ShoppingItem> get activeItems =>
      _items.where((i) => !i.checked).toList();
  List<ShoppingItem> get checkedItems =>
      _items.where((i) => i.checked).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCount => _items.length;
  int get activeCount => activeItems.length;
  int get checkedCount => checkedItems.length;

  void bindToHousehold(String? householdId) {
    if (householdId == null || householdId.isEmpty) {
      _items = [];
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _currentHouseholdId = null;
      notifyListeners();
      return;
    }

    if (_currentHouseholdId == householdId && _streamSubscription != null) {
      return;
    }

    _currentHouseholdId = householdId;
    _streamSubscription?.cancel();

    if (!SupabaseConfig.isConfigured) {
      _items = _householdMockItems.putIfAbsent(householdId, () => []);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Initial fetch to get relational data
    _shoppingService.fetchShoppingItems(householdId).then((initialList) {
      _items = initialList;
      _isLoading = false;
      notifyListeners();
    });

    _streamSubscription = _shoppingService
        .streamShoppingItems(householdId)
        .listen(
          (items) {
            final foodMap = {
              for (final item in _items)
                if (item.food != null) item.id: item.food,
            };
            _items = items.map((i) {
              if (i.food == null && foodMap.containsKey(i.id)) {
                return i.copyWith(food: foodMap[i.id]);
              }
              return i;
            }).toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Fehler beim Laden der Einkaufsliste: $e';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> addItem({
    String? foodId,
    String? customName,
    String? note,
  }) async {
    if (_currentHouseholdId == null) return false;

    if (!SupabaseConfig.isConfigured) {
      final newItem = ShoppingItem(
        id: 'mock_${DateTime.now().microsecondsSinceEpoch}_${_items.length + 1}',
        householdId: _currentHouseholdId!,
        foodId: foodId,
        customName: customName,
        note: note,
        checked: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _items.insert(0, newItem);
      _householdMockItems[_currentHouseholdId!] = _items;
      notifyListeners();
      return true;
    }

    try {
      final newItem = await _shoppingService.addItem(
        householdId: _currentHouseholdId!,
        foodId: foodId,
        customName: customName,
        note: note,
      );
      final existingIndex = _items.indexWhere((i) => i.id == newItem.id);
      if (existingIndex != -1) {
        _items[existingIndex] = newItem;
      } else {
        _items.insert(0, newItem);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding shopping item: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleItem(String itemId, bool checked) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(checked: checked);
      if (!SupabaseConfig.isConfigured && _currentHouseholdId != null) {
        _householdMockItems[_currentHouseholdId!] = _items;
      }
      notifyListeners();
    }

    if (SupabaseConfig.isConfigured) {
      try {
        await _shoppingService.toggleChecked(itemId, checked);
      } catch (e) {
        debugPrint('Error toggling item: $e');
      }
    }
  }

  Future<void> toggleItemChecked(String itemId) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;
    await toggleItem(itemId, !_items[index].checked);
  }

  Future<void> updateItem({
    required String itemId,
    String? customName,
    String? note,
  }) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        customName: customName,
        note: note,
      );
      if (!SupabaseConfig.isConfigured && _currentHouseholdId != null) {
        _householdMockItems[_currentHouseholdId!] = _items;
      }
      notifyListeners();
    }

    if (SupabaseConfig.isConfigured) {
      try {
        await _shoppingService.updateItem(
          itemId: itemId,
          customName: customName,
          note: note,
        );
      } catch (e) {
        debugPrint('Error updating item: $e');
      }
    }
  }

  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((i) => i.id == itemId);
    if (!SupabaseConfig.isConfigured && _currentHouseholdId != null) {
      _householdMockItems[_currentHouseholdId!] = _items;
    }
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _shoppingService.deleteItem(itemId);
      } catch (e) {
        debugPrint('Error deleting item: $e');
      }
    }
  }

  Future<int> clearCheckedItems({
    StockProvider? stockProvider,
    FoodProvider? foodProvider,
  }) async {
    if (_currentHouseholdId == null) return 0;

    final checked = _items.where((i) => i.checked).toList();
    if (checked.isEmpty) return 0;

    final stockSvc = StockService();
    final foodSvc = FoodService();

    final successfullyHandledIds = <String>[];

    for (final item in checked) {
      try {
        String? targetFoodId = item.foodId;

        // 1. If foodId is missing, resolve by customName
        if (targetFoodId == null &&
            item.customName != null &&
            item.customName!.trim().isNotEmpty) {
          final trimmed = item.customName!.trim();
          final normalized = trimmed.toLowerCase();

          // Search in loaded foods or fetch from service
          final existingFoods =
              foodProvider?.foods ??
              await foodSvc.fetchFoods(_currentHouseholdId);
          final match = existingFoods
              .where((f) => f.name.trim().toLowerCase() == normalized)
              .firstOrNull;

          if (match != null) {
            targetFoodId = match.id;
          } else {
            // Create new food in active household
            if (foodProvider != null) {
              try {
                final newFood = await foodProvider.addCustomFood(
                  name: trimmed,
                  note: null,
                );
                targetFoodId = newFood.id;
              } catch (e) {
                // If it already exists or was created concurrently
                final retryMatch = foodProvider.foods
                    .where((f) => f.name.trim().toLowerCase() == normalized)
                    .firstOrNull;
                targetFoodId = retryMatch?.id;
              }
            } else {
              final newFood = await foodSvc.addCustomFood(
                name: trimmed,
                note: null,
                householdId: _currentHouseholdId,
              );
              targetFoodId = newFood.id;
            }
          }
        }

        // 2. Add to stock
        if (targetFoodId != null && targetFoodId.isNotEmpty) {
          bool stockSuccess = false;
          if (stockProvider != null) {
            stockSuccess = await stockProvider.addToStock(targetFoodId);
          } else {
            try {
              if (SupabaseConfig.isConfigured) {
                await stockSvc.setInStock(
                  householdId: _currentHouseholdId!,
                  foodId: targetFoodId,
                  inStock: true,
                );
              }
              stockSuccess = true;
            } catch (stockErr) {
              debugPrint('Error setting stock in clearCheckedItems: $stockErr');
              stockSuccess = false;
            }
          }

          // 3. Only delete shopping item if stock addition was successful
          if (stockSuccess) {
            if (SupabaseConfig.isConfigured) {
              await _shoppingService.deleteItem(item.id);
            }
            successfullyHandledIds.add(item.id);
          } else {
            debugPrint(
              'Could not transfer item ${item.id} to stock. Preserving on shopping list.',
            );
          }
        } else {
          debugPrint(
            'Could not resolve foodId for item ${item.id} (${item.customName}). Preserving on shopping list.',
          );
        }
      } catch (err, stackTrace) {
        debugPrint(
          'Error processing checked item ${item.id}: $err\n$stackTrace',
        );
      }
    }

    if (successfullyHandledIds.isNotEmpty) {
      _items.removeWhere((i) => successfullyHandledIds.contains(i.id));
      if (!SupabaseConfig.isConfigured) {
        _householdMockItems[_currentHouseholdId!] = _items;
      }
      notifyListeners();
    }

    return successfullyHandledIds.length;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
