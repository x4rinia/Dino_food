import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../services/stock_service.dart';
import '../services/food_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService _stockService = StockService();

  static final Map<String, Set<String>> _householdMockStock = {};

  Set<String> _inStockFoodIds = {};
  StreamSubscription<Set<String>>? _subscription;
  String? _currentHouseholdId;
  bool _isLoading = false;

  Set<String> get inStockFoodIds => _inStockFoodIds;
  String? get currentHouseholdId => _currentHouseholdId;
  bool get isLoading => _isLoading;

  bool isInStock(String foodId) => _inStockFoodIds.contains(foodId);

  int countForFoodIds(Iterable<String> foodIds) =>
      foodIds.where(_inStockFoodIds.contains).toSet().length;

  void bindToHousehold(String? householdId) {
    if (householdId == null || householdId.isEmpty) {
      _inStockFoodIds = {};
      _subscription?.cancel();
      _subscription = null;
      _currentHouseholdId = null;
      notifyListeners();
      return;
    }

    if (_currentHouseholdId == householdId && _subscription != null) {
      return;
    }

    _currentHouseholdId = householdId;
    _subscription?.cancel();
    _inStockFoodIds = {};

    if (!SupabaseConfig.isConfigured) {
      // Demo mock stock starts empty per household
      _inStockFoodIds = _householdMockStock.putIfAbsent(
        householdId,
        () => <String>{},
      );
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Initial fetch
    _stockService.fetchStock(householdId).then((set) {
      if (_currentHouseholdId != householdId) return;
      _inStockFoodIds = set;
      _isLoading = false;
      notifyListeners();
    });

    // Realtime stream
    _subscription = _stockService.streamStock(householdId).listen((set) {
      if (_currentHouseholdId != householdId) return;
      _inStockFoodIds = set;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> addToStock(String foodId) async {
    if (_currentHouseholdId == null || foodId.isEmpty) return false;

    if (_inStockFoodIds.contains(foodId)) {
      return true;
    }

    final householdId = _currentHouseholdId!;
    if (!await FoodService().foodBelongsToHousehold(foodId, householdId)) {
      return false;
    }
    if (_currentHouseholdId != householdId) return false;

    _inStockFoodIds.add(foodId);
    if (!SupabaseConfig.isConfigured) {
      _householdMockStock[_currentHouseholdId!] = _inStockFoodIds;
    }
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _stockService.setInStock(
          householdId: householdId,
          foodId: foodId,
          inStock: true,
        );
        return true;
      } catch (e) {
        debugPrint('Error adding food $foodId to stock: $e');
        if (_currentHouseholdId != householdId) return false;
        _inStockFoodIds.remove(foodId);
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  Future<void> toggleStock(String foodId) async {
    if (_currentHouseholdId == null || foodId.isEmpty) return;

    final householdId = _currentHouseholdId!;
    final willBeInStock = !_inStockFoodIds.contains(foodId);
    if (willBeInStock &&
        !await FoodService().foodBelongsToHousehold(foodId, householdId)) {
      return;
    }
    if (_currentHouseholdId != householdId) return;

    // Optimistic update
    if (willBeInStock) {
      _inStockFoodIds.add(foodId);
    } else {
      _inStockFoodIds.remove(foodId);
    }
    if (!SupabaseConfig.isConfigured) {
      _householdMockStock[_currentHouseholdId!] = _inStockFoodIds;
    }
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      await _stockService.setInStock(
        householdId: householdId,
        foodId: foodId,
        inStock: willBeInStock,
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
