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

class AddFoodToShoppingResult {
  const AddFoodToShoppingResult({
    required this.success,
    required this.wasIncremented,
    this.quantity,
    this.errorMessage,
  });

  final bool success;
  final bool wasIncremented;
  final int? quantity;
  final String? errorMessage;
}

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
  String? _lastMutationError;
  final Set<String> _deletedItemIds = <String>{};
  final Map<String, Future<void>> _mutationTails = <String, Future<void>>{};
  Future<bool>? _refreshInFlight;
  String? _refreshHouseholdId;
  int? _refreshBindingGeneration;
  int _bindingGeneration = 0;
  int _subscriptionGeneration = 0;

  List<ShoppingItem> get allItems => _items;
  List<ShoppingItem> get activeItems =>
      _items.where((i) => !i.checked).toList();
  List<ShoppingItem> get checkedItems =>
      _items.where((i) => i.checked).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastMutationError => _lastMutationError;

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

  Future<bool> refresh({int attempts = 2}) {
    final householdId = _currentHouseholdId;
    if (householdId == null || householdId.isEmpty) {
      return Future.value(false);
    }
    if (!SupabaseConfig.isConfigured) return Future.value(true);
    final currentRefresh = _refreshInFlight;
    final bindingGeneration = _bindingGeneration;
    if (currentRefresh != null &&
        _refreshHouseholdId == householdId &&
        _refreshBindingGeneration == bindingGeneration) {
      return currentRefresh;
    }

    late final Future<bool> refreshFuture;
    refreshFuture = _performRefresh(householdId, attempts, bindingGeneration)
        .whenComplete(() {
          if (identical(_refreshInFlight, refreshFuture)) {
            _refreshInFlight = null;
            _refreshHouseholdId = null;
            _refreshBindingGeneration = null;
          }
        });
    _refreshInFlight = refreshFuture;
    _refreshHouseholdId = householdId;
    _refreshBindingGeneration = bindingGeneration;
    return refreshFuture;
  }

  Future<bool> _performRefresh(
    String householdId,
    int attempts,
    int bindingGeneration,
  ) async {
    _errorMessage = null;
    notifyListeners();
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final refreshed = await _shoppingService
            .fetchShoppingItems(householdId)
            .timeout(loadTimeout);
        if (_currentHouseholdId != householdId ||
            bindingGeneration != _bindingGeneration) {
          return false;
        }
        _acceptAuthoritativeItems(refreshed);
        _errorMessage = null;
        _isLoading = false;
        await _replaceSubscription(householdId);
        if (_currentHouseholdId == householdId) notifyListeners();
        return true;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (attempt + 1 < attempts) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    if (_currentHouseholdId != householdId ||
        bindingGeneration != _bindingGeneration) {
      return false;
    }
    _errorMessage = lastError is TimeoutException
        ? 'Die Einkaufsliste konnte nicht rechtzeitig aktualisiert werden.'
        : 'Die Einkaufsliste konnte nicht aktualisiert werden: $lastError';
    debugPrint('Shopping refresh failed: $lastError\n$lastStackTrace');
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void bindToHousehold(String? householdId) {
    if (householdId == null || householdId.isEmpty) {
      _items = [];
      _deletedItemIds.clear();
      _lastMutationError = null;
      _bindingGeneration++;
      _subscriptionGeneration++;
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
    _bindingGeneration++;
    _subscriptionGeneration++;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _items = [];
    _deletedItemIds.clear();
    _lastMutationError = null;

    if (!SupabaseConfig.isConfigured) {
      _items = _householdMockItems.putIfAbsent(householdId, () => []);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    unawaited(refresh());
  }

  Future<void> _replaceSubscription(String householdId) async {
    final generation = ++_subscriptionGeneration;
    final previousSubscription = _streamSubscription;
    _streamSubscription = null;
    await previousSubscription?.cancel();
    if (_currentHouseholdId != householdId ||
        generation != _subscriptionGeneration) {
      return;
    }

    _streamSubscription = _shoppingService
        .streamShoppingItems(householdId)
        .listen(
          (items) {
            if (_currentHouseholdId != householdId ||
                generation != _subscriptionGeneration) {
              return;
            }
            final foodMap = {
              for (final item in _items)
                if (item.food != null) item.id: item.food,
            };
            final hydratedItems = items.map((i) {
              if (i.food == null && foodMap.containsKey(i.id)) {
                return i.copyWith(food: foodMap[i.id]);
              }
              return i;
            }).toList();
            _acceptAuthoritativeItems(hydratedItems);
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            if (_currentHouseholdId != householdId ||
                generation != _subscriptionGeneration) {
              return;
            }
            debugPrint('Shopping stream failed: $e');
            unawaited(refresh());
          },
        );
  }

  Future<bool> addItem({
    String? foodId,
    Food? food,
    String? customName,
    String? note,
    int? quantity,
  }) {
    final householdId = _currentHouseholdId;
    if (foodId == null || householdId == null) {
      return _addItemInternal(
        foodId: foodId,
        food: food,
        customName: customName,
        note: note,
        quantity: quantity,
      );
    }
    return _serializeMutation(
      '$householdId:$foodId',
      () => _addItemInternal(
        foodId: foodId,
        food: food,
        customName: customName,
        note: note,
        quantity: quantity,
      ),
    );
  }

  Future<AddFoodToShoppingResult> addOrIncrementFood(Food food) {
    final householdId = _currentHouseholdId;
    if (householdId == null) {
      return Future.value(
        const AddFoodToShoppingResult(
          success: false,
          wasIncremented: false,
          errorMessage: 'Kein aktiver Haushalt.',
        ),
      );
    }

    return _serializeMutation('$householdId:${food.id}', () async {
      final existingItem = itemForFood(food.id);
      if (existingItem == null) {
        final success = await _addItemInternal(
          foodId: food.id,
          food: food,
          customName: food.name,
        );
        return AddFoodToShoppingResult(
          success: success,
          wasIncremented: false,
          errorMessage: success ? null : _lastMutationError,
        );
      }

      final nextQuantity = (existingItem.quantity ?? 1) + 1;
      final success = await _updateItemInternal(
        itemId: existingItem.id,
        quantity: nextQuantity,
        replaceQuantity: true,
      );
      return AddFoodToShoppingResult(
        success: success,
        wasIncremented: success,
        quantity: success ? nextQuantity : existingItem.quantity,
        errorMessage: success ? null : _lastMutationError,
      );
    });
  }

  Future<bool> _addItemInternal({
    String? foodId,
    Food? food,
    String? customName,
    String? note,
    int? quantity,
  }) async {
    if (_currentHouseholdId == null) return false;
    final householdId = _currentHouseholdId!;

    if (foodId != null && itemForFood(foodId) != null) {
      _lastMutationError =
          '${food?.name ?? 'Dieses Lebensmittel'} ist bereits im Einkaufswagen.';
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
      _lastMutationError = null;
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
      _lastMutationError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding shopping item: $e');
      _lastMutationError = e.toString().replaceFirst('Exception: ', '');
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

  Future<bool> updateItem({
    required String itemId,
    String? customName,
    String? note,
    int? quantity,
    bool replaceQuantity = false,
  }) {
    final item = _items.where((entry) => entry.id == itemId).firstOrNull;
    final householdId = _currentHouseholdId;
    final mutationKey = householdId == null
        ? itemId
        : '$householdId:${item?.foodId ?? itemId}';
    return _serializeMutation(
      mutationKey,
      () => _updateItemInternal(
        itemId: itemId,
        customName: customName,
        note: note,
        quantity: quantity,
        replaceQuantity: replaceQuantity,
      ),
    );
  }

  Future<bool> _updateItemInternal({
    required String itemId,
    String? customName,
    String? note,
    int? quantity,
    bool replaceQuantity = false,
  }) async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return false;
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return false;
    final previousItem = _items[index];
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

    try {
      if (SupabaseConfig.isConfigured) {
        await _shoppingService.updateItem(
          itemId: itemId,
          householdId: householdId,
          customName: customName,
          note: note,
          quantity: quantity,
          replaceQuantity: replaceQuantity,
        );
      }
      if (_currentHouseholdId != householdId) return false;
      _lastMutationError = null;
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error updating item: $e\n$stackTrace');
      if (_currentHouseholdId == householdId) {
        final rollbackIndex = _items.indexWhere((i) => i.id == itemId);
        if (rollbackIndex != -1) {
          _items[rollbackIndex] = previousItem;
        }
        _lastMutationError =
            'Der Einkaufsartikel konnte nicht aktualisiert werden.';
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) {
    final item = _items.where((entry) => entry.id == itemId).firstOrNull;
    final householdId = _currentHouseholdId;
    final mutationKey = householdId == null
        ? itemId
        : '$householdId:${item?.foodId ?? itemId}';
    return _serializeMutation(mutationKey, () => _deleteItemInternal(itemId));
  }

  Future<bool> _deleteItemInternal(String itemId) async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return false;
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return false;
    final deletedItem = _items[index];
    _deletedItemIds.add(itemId);
    _items.removeAt(index);
    if (!SupabaseConfig.isConfigured && _currentHouseholdId != null) {
      _householdMockItems[_currentHouseholdId!] = _items;
    }
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        await _shoppingService.deleteItem(itemId, householdId: householdId);
      }
      if (_currentHouseholdId != householdId) return false;
      _lastMutationError = null;
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error deleting item: $e\n$stackTrace');
      if (_currentHouseholdId == householdId) {
        _deletedItemIds.remove(itemId);
        if (!_items.any((item) => item.id == itemId)) {
          final rollbackIndex = index > _items.length ? _items.length : index;
          _items.insert(rollbackIndex, deletedItem);
        }
        _lastMutationError =
            'Der Einkaufsartikel konnte nicht gelöscht werden.';
        notifyListeners();
      }
      return false;
    }
  }

  void _acceptAuthoritativeItems(List<ShoppingItem> items) {
    _items = items.where((item) => !_deletedItemIds.contains(item.id)).toList();
  }

  Future<T> _serializeMutation<T>(String key, Future<T> Function() mutation) {
    final completer = Completer<T>();
    final previous = _mutationTails[key] ?? Future<void>.value();
    final ready = previous.then<void>((_) {}, onError: (_, _) {});
    late final Future<void> tail;
    tail = ready.then<void>((_) async {
      try {
        completer.complete(await mutation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _mutationTails[key] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_mutationTails[key], tail)) {
          _mutationTails.remove(key);
        }
      }),
    );
    return completer.future;
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
            _deletedItemIds.add(item.id);
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
    _bindingGeneration++;
    _subscriptionGeneration++;
    _streamSubscription?.cancel();
    super.dispose();
  }
}
