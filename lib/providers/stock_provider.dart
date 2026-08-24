import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../services/stock_service.dart';
import '../services/food_service.dart';

class StockProvider extends ChangeNotifier {
  StockProvider({
    StockService? stockService,
    this.loadTimeout = const Duration(seconds: 15),
  }) : _stockService = stockService ?? StockService();

  final StockService _stockService;
  final Duration loadTimeout;

  static final Map<String, Set<String>> _householdMockStock = {};

  Set<String> _inStockFoodIds = {};
  StreamSubscription<Set<String>>? _subscription;
  String? _currentHouseholdId;
  bool _isLoading = false;
  String? _errorMessage;

  Set<String> get inStockFoodIds => _inStockFoodIds;
  String? get currentHouseholdId => _currentHouseholdId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isInStock(String foodId) => _inStockFoodIds.contains(foodId);

  int countForFoodIds(Iterable<String> foodIds) =>
      foodIds.where(_inStockFoodIds.contains).toSet().length;

  void retryLoad() {
    final householdId = _currentHouseholdId;
    if (householdId == null) return;
    _subscription?.cancel();
    _subscription = null;
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
        final refreshed = await _stockService
            .fetchStock(householdId)
            .timeout(loadTimeout);
        if (_currentHouseholdId != householdId) return false;
        _inStockFoodIds = refreshed;
        _errorMessage = null;
        await _subscription?.cancel();
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
        ? 'Der Vorrat konnte nicht rechtzeitig aktualisiert werden.'
        : 'Der Vorrat konnte nicht aktualisiert werden: $lastError';
    debugPrint('Stock refresh failed: $lastError\n$lastStackTrace');
    notifyListeners();
    return false;
  }

  void bindToHousehold(String? householdId) {
    if (householdId == null || householdId.isEmpty) {
      _inStockFoodIds = {};
      _subscription?.cancel();
      _subscription = null;
      _currentHouseholdId = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (_currentHouseholdId == householdId && _subscription != null) {
      return;
    }

    _currentHouseholdId = householdId;
    _subscription?.cancel();
    _inStockFoodIds = {};
    _errorMessage = null;

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
    _stockService
        .fetchStock(householdId)
        .timeout(loadTimeout)
        .then((set) {
          if (_currentHouseholdId != householdId) return;
          _inStockFoodIds = set;
          _isLoading = false;
          notifyListeners();
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (_currentHouseholdId != householdId) return null;
          _errorMessage = error is TimeoutException
              ? 'Der Vorrat konnte nicht rechtzeitig geladen werden.'
              : 'Der Vorrat konnte nicht geladen werden: $error';
          _isLoading = false;
          debugPrint('Stock load failed: $error\n$stackTrace');
          notifyListeners();
          return null;
        });

    // Realtime stream
    _listenToHousehold(householdId);
  }

  void _listenToHousehold(String householdId) {
    _subscription = _stockService
        .streamStock(householdId)
        .listen(
          (set) {
            if (_currentHouseholdId != householdId) return;
            _inStockFoodIds = set;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (_currentHouseholdId != householdId) return;
            debugPrint('Stock stream failed: $error\n$stackTrace');
            if (_inStockFoodIds.isEmpty) {
              _errorMessage =
                  'Der Vorrat konnte nicht aktualisiert werden: $error';
              _isLoading = false;
              notifyListeners();
            } else {
              unawaited(refresh());
            }
          },
        );
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
