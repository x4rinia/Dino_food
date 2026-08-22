import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/shopping_item.dart';

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
          .map((dataList) {
            return dataList.map((item) => ShoppingItem.fromJson(item)).toList();
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

      return (data as List).map((i) => ShoppingItem.fromJson(i)).toList();
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
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase ist nicht konfiguriert');
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
    String? customName,
    String? note,
    bool? checked,
  }) async {
    if (!SupabaseConfig.isConfigured) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (customName != null) updates['custom_name'] = customName.trim();
    if (note != null) updates['note'] = note.trim();
    if (checked != null) updates['checked'] = checked;

    await _client.from('shopping_items').update(updates).eq('id', itemId);
  }

  Future<void> toggleChecked(String itemId, bool checked) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client
        .from('shopping_items')
        .update({
          'checked': checked,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  Future<void> deleteItem(String itemId) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client.from('shopping_items').delete().eq('id', itemId);
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
