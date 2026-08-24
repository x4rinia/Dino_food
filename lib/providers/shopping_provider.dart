import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/shopping_item.dart';
import '../models/food.dart';
import '../services/shopping_service.dart';
import '../services/stock_service.dart';
import '../services/food_service.dart';
import 'stock_provider.dart';
import 'food_provider.dart';

class ShoppingProvider extends ChangeNotifier {
  ShoppingProvider({
    ShoppingService? shoppingService,
    this.loadTimeout = const Duration(seconds: 15),
  }) : _shoppingService = shoppingService ?? ShoppingService();

  final ShoppingService _shoppingService;
  final Duration loadTimeout;

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

  ShoppingItem? itemForFood(String foodId) {
    if (foodId.isEmpty) return null;
    return _items.where((item) => item.foodId == foodId).firstOrNull;
  }

  void retryLoad() {
    final householdId = _currentHouseholdId;
    if (householdId == null) return;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentHouseholdId = null;
    bindToHousehold(householdId);
  }

  Future<bool> refresh({int attempts = 2}) async {
    final householdId = _currentHouseholdId;
    if (householdId == null || householdId.isEmpty) return false;
    if (!SupabaseConfig.isConfigured) return true;

    _errorMessage = null;
    notifyListeners();
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final refreshed = await _shoppingService
            .fetchShoppingItems(householdId)
            .timeout(loadTimeout);
        if (_currentHouseholdId != householdId) return false;
        _items = refreshed;
        _errorMessage = null;
        await _streamSubscription?.cancel();
        if (_currentHouseholdId == householdId) {
          _listenToHousehold(householdId);
          notifyListeners();
        }
        return true;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (attempt + 1 < attempts) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    if (_currentHouseholdId != householdId) return false;
    _errorMessage = lastError is TimeoutException
        ? 'Die Einkaufsliste konnte nicht rechtzeitig aktualisiert werden.'
        : 'Die Einkaufsliste konnte nicht aktualisiert werden: $lastError';
    debugPrint('Shopping refresh failed: $lastError\n$lastStackTrace');
    notifyListeners();
    return false;
  }

  void bindToHousehold(String? householdId) {
    if (householdId == null || householdId.isEmpty) {
      _items = [];
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _currentHouseholdId = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (_currentHouseholdId == householdId && _streamSubscription != null) {
      return;
    }

    _currentHouseholdId = householdId;
    _streamSubscription?.cancel();
    _items = [];

    if (!SupabaseConfig.isConfigured) {
      _items = _householdMockItems.putIfAbsent(householdId, () => []);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Initial fetch to get relational data
    _shoppingService
        .fetchShoppingItems(householdId)
        .timeout(loadTimeout)
        .then((initialList) {
          if (_currentHouseholdId != householdId) return;
          _items = initialList;
          _isLoading = false;
          notifyListeners();
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (_currentHouseholdId != householdId) return null;
          _errorMessage = error is TimeoutException
              ? 'Die Einkaufsliste konnte nicht rechtzeitig geladen werden.'
              : 'Die Einkaufsliste konnte nicht geladen werden: $error';
          _isLoading = false;
          debugPrint('Shopping load failed: $error\n$stackTrace');
          notifyListeners();
          return null;
        });

    _listenToHousehold(householdId);
  }

  void _listenToHousehold(String householdId) {
    _streamSubscription = _shoppingService
        .streamShoppingItems(householdId)
        .listen(
          (items) {
            if (_currentHouseholdId != householdId) return;
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
            if (_currentHouseholdId != householdId) return;
            debugPrint('Shopping stream failed: $e');
            if (_items.isEmpty) {
              _errorMessage = 'Fehler beim Laden der Einkaufsliste: $e';
              _isLoading = false;
              notifyListeners();
            } else {
              unawaited(refresh());
            }
          },
        );
  }

  Future<bool> addItem({
    String? foodId,
    Food? food,
    String? customName,
    String? note,
    int? quantity,
  }) async {
    if (_currentHouseholdId == null) return false;
    final householdId = _currentHouseholdId!;

    if (foodId != null && itemForFood(foodId) != null) {
      _errorMessage = '${food?.name ?? 'Dieses Lebensmittel'} ist bereits im Einkaufswagen.';
      notifyListeners();
      return false;
    }

    if (!SupabaseConfig.isConfigured) {
      if (foodId != null &&
          !await FoodService().foodBelongsToHousehold(foodId, householdId)) {
        return false;
      }
      if (_currentHouseholdId != householdId) return false;
      final newItem = ShoppingItem(
        id: 'mock_${DateTime.now().microsecondsSinceEpoch}_${_items.length + 1}',
        householdId: householdId,
        foodId: foodId,
        customName: customName,
        note: note,
        quantity: quantity,
        checked: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        food: food?.id == foodId ? food : null,
      );
      _items.insert(0, newItem);
      _householdMockItems[householdId] = _items;
      notifyListeners();
      return true;
    }

    try {
      final newItem = await _shoppingService.addItem(
        householdId: householdId,
        foodId: foodId,
        customName: customName,
        note: note,
        quantity: quantity,
      );
      if (_currentHouseholdId != householdId) return false;
      final hydratedItem = food?.id == foodId
          ? newItem.copyWith(food: food)
          : newItem;
      final existingIndex = _items.indexWhere((i) => i.id == newItem.id);
      if (existingIndex != -1) {
        _items[existingIndex] = hydratedItem;
      } else {
        _items.insert(0, hydratedItem);
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
    final householdId = _currentHouseholdId;
    if (householdId == null) return;
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
        await _shoppingService.toggleChecked(
          itemId,
          checked,
          householdId: householdId,
        );
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
    int? quantity,
    bool replaceQuantity = false,
  }) async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return;
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        customName: customName,
        note: note,
        quantity: quantity,
        clearQuantity: replaceQuantity && quantity == null,
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
          householdId: householdId,
          customName: customName,
          note: note,
          quantity: quantity,
          replaceQuantity: replaceQuantity,
        );
      } catch (e) {
        debugPrint('Error updating item: $e');
      }
    }
  }

  Future<void> deleteItem(String itemId) async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return;
    _items.removeWhere((i) => i.id == itemId);
    if (!SupabaseConfig.isConfigured && _currentHouseholdId != null) {
      _householdMockItems[_currentHouseholdId!] = _items;
    }
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _shoppingService.deleteItem(itemId, householdId: householdId);
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
    final householdId = _currentHouseholdId!;
    if (stockProvider != null &&
        stockProvider.currentHouseholdId != householdId) {
      return 0;
    }
    if (foodProvider != null &&
        foodProvider.currentHouseholdId != householdId) {
      return 0;
    }

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
              foodProvider?.foods ?? await foodSvc.fetchFoods(householdId);
          if (_currentHouseholdId != householdId) return 0;
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
                householdId: householdId,
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
                  householdId: householdId,
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
              await _shoppingService.deleteItem(
                item.id,
                householdId: householdId,
              );
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
      if (_currentHouseholdId != householdId) return 0;
      _items.removeWhere((i) => successfullyHandledIds.contains(i.id));
      if (!SupabaseConfig.isConfigured) {
        _householdMockItems[householdId] = _items;
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
