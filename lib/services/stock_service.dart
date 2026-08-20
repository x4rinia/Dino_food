import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StockService {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<Set<String>> streamStock(String householdId) {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) {
      return Stream.value({});
    }

    try {
      return _client
          .from('household_stock')
          .stream(primaryKey: ['household_id', 'food_id'])
          .eq('household_id', householdId)
          .map((dataList) {
            final set = <String>{};
            for (final row in dataList) {
              final foodId = row['food_id'] as String?;
              if (foodId != null && foodId.isNotEmpty) {
                set.add(foodId);
              }
            }
            return set;
          });
    } catch (e) {
      debugPrint('Error streaming household stock: $e');
      return Stream.value({});
    }
  }

  Future<Set<String>> fetchStock(String householdId) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) return {};

    try {
      final data = await _client
          .from('household_stock')
          .select('food_id')
          .eq('household_id', householdId);

      final set = <String>{};
      for (final row in data as List) {
        final foodId = row['food_id'] as String?;
        if (foodId != null && foodId.isNotEmpty) {
          set.add(foodId);
        }
      }
      return set;
    } catch (e) {
      debugPrint('Error fetching household stock: $e');
      return {};
    }
  }

  Future<void> setInStock({
    required String householdId,
    required String foodId,
    required bool inStock,
  }) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty || foodId.isEmpty) {
      return;
    }

    try {
      if (inStock) {
        await _client.from('household_stock').upsert({
          'household_id': householdId,
          'food_id': foodId,
        });
      } else {
        await _client
            .from('household_stock')
            .delete()
            .eq('household_id', householdId)
            .eq('food_id', foodId);
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating household stock ($householdId, food: $foodId): $e\n$stackTrace');
      rethrow;
    }
  }
}
