import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';

class ShoppingProvider extends ChangeNotifier {
  final ShoppingService _shoppingService = ShoppingService();

  static final Map<String, List<ShoppingItem>> _householdMockItems = {};

  List<ShoppingItem> _items = [];
  StreamSubscription<List<ShoppingItem>>? _streamSubscription;
  String? _currentHouseholdId;
  bool _isLoading = false;
  String? _errorMessage;

  List<ShoppingItem> get allItems => _items;
  List<ShoppingItem> get activeItems => _items.where((i) => !i.checked).toList();
  List<ShoppingItem> get checkedItems => _items.where((i) => i.checked).toList();
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
    notifyListeners();

    // Initial fetch to get relational data like foods and profiles
    _shoppingService.fetchShoppingItems(householdId).then((initialList) {
      _items = initialList;
      _isLoading = false;
      notifyListeners();
    });

    // Realtime stream subscription
    _streamSubscription = _shoppingService.streamShoppingItems(householdId).listen(
      (streamedList) {
        _items = streamedList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Shopping stream error: $error');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addItem({
    String? foodId,
    String? customName,
    double quantity = 1.0,
    String? note,
  }) async {
    if (_currentHouseholdId == null) return false;

    if (!SupabaseConfig.isConfigured) {
      _items.insert(
        0,
        ShoppingItem(
          id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          householdId: _currentHouseholdId!,
          foodId: foodId,
          customName: customName,
          quantity: quantity,
          note: note,
          checked: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _householdMockItems[_currentHouseholdId!] = _items;
      notifyListeners();
      return true;
    }

    try {
      await _shoppingService.addItem(
        householdId: _currentHouseholdId!,
        foodId: foodId,
        customName: customName,
        quantity: quantity,
        note: note,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleItem(String itemId, bool checked) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(checked: checked);
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

  Future<void> updateItem({
    required String itemId,
    String? customName,
    double? quantity,
    String? note,
  }) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        customName: customName,
        quantity: quantity,
        note: note,
      );
      notifyListeners();
    }

    if (SupabaseConfig.isConfigured) {
      try {
        await _shoppingService.updateItem(
          itemId: itemId,
          customName: customName,
          quantity: quantity,
          note: note,
        );
      } catch (e) {
        debugPrint('Error updating item: $e');
      }
    }
  }

  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _shoppingService.deleteItem(itemId);
        _forceRefresh();
      } catch (e) {
        debugPrint('Error deleting item: $e');
      }
    }
  }

  Future<void> clearCheckedItems() async {
    if (_currentHouseholdId == null) return;

    _items.removeWhere((i) => i.checked);
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _shoppingService.clearCheckedItems(_currentHouseholdId!);
        _forceRefresh();
      } catch (e) {
        debugPrint('Error clearing checked items: $e');
      }
    }
  }

  void _forceRefresh() {
    if (_currentHouseholdId == null || !SupabaseConfig.isConfigured) return;
    
    // Workaround for missing REPLICA IDENTITY FULL in Supabase:
    // Force a fresh fetch from DB so the local stream cache is reset
    // without the deleted items, preventing them from reappearing on next update.
    final currentId = _currentHouseholdId;
    _currentHouseholdId = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    
    Future.microtask(() => bindToHousehold(currentId));
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
