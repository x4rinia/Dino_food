import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../services/stock_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService _stockService = StockService();

  Set<String> _inStockFoodIds = {};
  StreamSubscription<Set<String>>? _subscription;
  String? _currentHouseholdId;
  bool _isLoading = false;

  Set<String> get inStockFoodIds => _inStockFoodIds;
  bool get isLoading => _isLoading;

  bool isInStock(String foodId) => _inStockFoodIds.contains(foodId);

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

    if (!SupabaseConfig.isConfigured) {
      // Demo mock stock
      _inStockFoodIds = {'5', '7', '8'}; // Zwiebeln, Knoblauch, Milch
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Initial fetch
    _stockService.fetchStock(householdId).then((set) {
      _inStockFoodIds = set;
      _isLoading = false;
      notifyListeners();
    });

    // Realtime stream
    _subscription = _stockService.streamStock(householdId).listen((set) {
      _inStockFoodIds = set;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> toggleStock(String foodId) async {
    if (_currentHouseholdId == null || foodId.isEmpty) return;

    final willBeInStock = !_inStockFoodIds.contains(foodId);

    // Optimistic update
    if (willBeInStock) {
      _inStockFoodIds.add(foodId);
    } else {
      _inStockFoodIds.remove(foodId);
    }
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      await _stockService.setInStock(
        householdId: _currentHouseholdId!,
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
