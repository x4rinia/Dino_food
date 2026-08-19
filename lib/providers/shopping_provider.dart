import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';

class ShoppingProvider extends ChangeNotifier {
  final ShoppingService _shoppingService = ShoppingService();

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
      // Setup demo items
      if (_items.isEmpty) {
        _items = [
          ShoppingItem(
            id: 'mock_1',
            householdId: householdId,
            customName: 'Milch',
            quantity: 2,
            note: 'laktosefrei',
            checked: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
            updatedAt: DateTime.now(),
          ),
          ShoppingItem(
            id: 'mock_2',
            householdId: householdId,
            customName: 'Tomaten',
            quantity: 4,
            note: 'Cherrytomaten',
            checked: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
            updatedAt: DateTime.now(),
          ),
          ShoppingItem(
            id: 'mock_3',
            householdId: householdId,
            customName: 'Brot',
            quantity: 1,
            checked: true,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            updatedAt: DateTime.now(),
          ),
        ];
      }
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
      final newItem = ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        householdId: _currentHouseholdId!,
        foodId: foodId,
        customName: customName,
        quantity: quantity,
        note: note,
        checked: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _items.insert(0, newItem);
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
      } catch (e) {
        debugPrint('Error clearing checked items: $e');
      }
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
