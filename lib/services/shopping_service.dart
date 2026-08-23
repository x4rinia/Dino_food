import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/shopping_item.dart';
import 'food_service.dart';

class ShoppingService {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<List<ShoppingItem>> streamShoppingItems(String householdId) {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _client
          .from('shopping_items')
          .stream(primaryKey: ['id'])
          .eq('household_id', householdId)
          .order('checked', ascending: true)
          .order('created_at', ascending: false)
          .asyncMap((dataList) async {
            final householdFoodIds = (await FoodService().fetchFoods(
              householdId,
            )).map((food) => food.id).toSet();
            return dataList
                .where((item) {
                  final foodId = item['food_id'] as String?;
                  return foodId == null || householdFoodIds.contains(foodId);
                })
                .map((item) => ShoppingItem.fromJson(item))
                .toList();
          });
    } catch (e) {
      debugPrint('Error streaming shopping items: $e');
      return Stream.value([]);
    }
  }

  Future<List<ShoppingItem>> fetchShoppingItems(String householdId) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) return [];

    try {
      final data = await _client
          .from('shopping_items')
          .select('*, foods(*)')
          .eq('household_id', householdId)
          .order('checked', ascending: true)
          .order('created_at', ascending: false);

      return (data as List)
          .where((raw) {
            final item = raw as Map<String, dynamic>;
            final foodId = item['food_id'] as String?;
            final food = item['foods'] as Map<String, dynamic>?;
            return foodId == null || food?['household_id'] == householdId;
          })
          .map((i) => ShoppingItem.fromJson(i))
          .toList();
    } catch (e) {
      debugPrint('Error fetching shopping items: $e');
      try {
        final simpleData = await _client
            .from('shopping_items')
            .select()
            .eq('household_id', householdId)
            .order('checked', ascending: true)
            .order('created_at', ascending: false);
        return (simpleData as List)
            .map((i) => ShoppingItem.fromJson(i))
            .toList();
      } catch (e2) {
        debugPrint('Fallback fetch also failed: $e2');
        return [];
      }
    }
  }

  Future<ShoppingItem> addItem({
    required String householdId,
    String? foodId,
    String? customName,
    String? note,
    int? quantity,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase ist nicht konfiguriert');
    }

    if (foodId != null && foodId.trim().isNotEmpty) {
      await FoodService().requireFoodInHousehold(foodId.trim(), householdId);
    }

    final userId = SupabaseConfig.currentUserId;

    final itemMap = <String, dynamic>{
      'household_id': householdId,
      'checked': false,
    };

    if (foodId != null && foodId.trim().isNotEmpty) {
      itemMap['food_id'] = foodId.trim();
    }

    if (customName != null && customName.trim().isNotEmpty) {
      itemMap['custom_name'] = customName.trim();
    }

    if (note != null && note.trim().isNotEmpty) {
      itemMap['note'] = note.trim();
    }
    if (quantity != null) itemMap['quantity'] = quantity;

    if (userId != null) {
      itemMap['added_by'] = userId;
    }

    // Insert into Supabase
    final result = await _client
        .from('shopping_items')
        .insert(itemMap)
        .select()
        .single();

    return ShoppingItem.fromJson(result);
  }

  Future<void> updateItem({
    required String itemId,
    required String householdId,
    String? customName,
    String? note,
    int? quantity,
    bool replaceQuantity = false,
    bool? checked,
  }) async {
    if (!SupabaseConfig.isConfigured) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (customName != null) updates['custom_name'] = customName.trim();
    if (note != null) updates['note'] = note.trim();
    if (replaceQuantity) updates['quantity'] = quantity;
    if (checked != null) updates['checked'] = checked;

    await _client
        .from('shopping_items')
        .update(updates)
        .eq('id', itemId)
        .eq('household_id', householdId);
  }

  Future<void> toggleChecked(
    String itemId,
    bool checked, {
    required String householdId,
  }) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client
        .from('shopping_items')
        .update({
          'checked': checked,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId)
        .eq('household_id', householdId);
  }

  Future<void> deleteItem(String itemId, {required String householdId}) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client
        .from('shopping_items')
        .delete()
        .eq('id', itemId)
        .eq('household_id', householdId);
  }

  Future<void> clearCheckedItems(String householdId) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) return;

    await _client
        .from('shopping_items')
        .delete()
        .eq('household_id', householdId)
        .eq('checked', true);
  }
}
