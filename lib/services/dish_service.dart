import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/dish.dart';
import '../models/dish_item.dart';

class DishService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Dish>> fetchDishes(String householdId) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) {
      return _mockDishes(householdId);
    }

    final currentUserId = SupabaseConfig.currentUserId;

    try {
      // 1. Fetch dishes and items
      final dishesData = await _client
          .from('dishes')
          .select('*, dish_items(*, foods(*))')
          .eq('household_id', householdId)
          .order('name', ascending: true);

      // 2. Fetch user's favorite dish IDs
      Set<String> favoriteDishIds = {};
      if (currentUserId != null) {
        try {
          final favsData = await _client
              .from('dish_favorites')
              .select('dish_id')
              .eq('user_id', currentUserId);

          for (final row in favsData as List) {
            final dId = row['dish_id'] as String?;
            if (dId != null) favoriteDishIds.add(dId);
          }
        } catch (e) {
          debugPrint('Info: dish_favorites table query: $e');
        }
      }

      final List<Dish> list = (dishesData as List).map((d) {
        final dId = d['id'] as String;
        final isFav = favoriteDishIds.contains(dId);
        return Dish.fromJson(d, isFavorite: isFav);
      }).toList();

      if (list.isEmpty) {
        return _mockDishes(householdId);
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching dishes: $e');
      return _mockDishes(householdId);
    }
  }

  Future<Dish> createDish({
    required String householdId,
    required String name,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase ist nicht konfiguriert');
    }

    final userId = SupabaseConfig.currentUserId;

    final dishMap = <String, dynamic>{
      'household_id': householdId,
      'name': name.trim(),
    };
    if (userId != null) {
      dishMap['created_by'] = userId;
    }

    // 1. Insert dish
    final dishData = await _client
        .from('dishes')
        .insert(dishMap)
        .select()
        .single();

    final dishId = dishData['id'] as String;

    // 2. Insert dish items
    if (items.isNotEmpty) {
      final itemsToInsert = items.map((i) {
        return {
          'dish_id': dishId,
          'food_id': i['food_id'],
          'custom_name': i['custom_name'],
          'quantity': i['quantity'] ?? 1.0,
        };
      }).toList();

      await _client.from('dish_items').insert(itemsToInsert);
    }

    // 3. Re-fetch dish with full details
    final completeData = await _client
        .from('dishes')
        .select('*, dish_items(*, foods(*))')
        .eq('id', dishId)
        .single();

    return Dish.fromJson(completeData, isFavorite: false);
  }

  Future<Dish> updateDish({
    required String dishId,
    required String name,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase ist nicht konfiguriert');
    }

    // 1. Update dish name
    await _client.from('dishes').update({
      'name': name.trim(),
    }).eq('id', dishId);

    // 2. Replace dish items: delete old items and insert updated ones
    await _client.from('dish_items').delete().eq('dish_id', dishId);

    if (items.isNotEmpty) {
      final itemsToInsert = items.map((i) {
        return {
          'dish_id': dishId,
          'food_id': i['food_id'],
          'custom_name': i['custom_name'],
          'quantity': i['quantity'] ?? 1.0,
        };
      }).toList();

      await _client.from('dish_items').insert(itemsToInsert);
    }

    // 3. Re-fetch
    final completeData = await _client
        .from('dishes')
        .select('*, dish_items(*, foods(*))')
        .eq('id', dishId)
        .single();

    return Dish.fromJson(completeData);
  }

  Future<void> deleteDish(String dishId) async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      await _client.from('dishes').delete().eq('id', dishId);
    } catch (e) {
      debugPrint('Error deleting dish: $e');
    }
  }

  Future<void> toggleFavorite(String dishId, bool isFavorite) async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) return;

    final userId = SupabaseConfig.currentUserId!;

    try {
      if (isFavorite) {
        await _client.from('dish_favorites').upsert({
          'user_id': userId,
          'dish_id': dishId,
        });
      } else {
        await _client
            .from('dish_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('dish_id', dishId);
      }
    } catch (e) {
      debugPrint('Error toggling dish favorite: $e');
    }
  }

  Future<int> addItemsToShoppingList({
    required String householdId,
    required List<DishItem> items,
  }) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty || items.isEmpty) {
      return 0;
    }

    final userId = SupabaseConfig.currentUserId;

    final shoppingItemsToInsert = items.map((item) {
      final map = <String, dynamic>{
        'household_id': householdId,
        'food_id': item.foodId,
        'custom_name': item.food?.name ?? item.customName,
        'quantity': item.quantity > 0 ? item.quantity : 1.0,
        'unit': '',
        'checked': false,
      };
      if (userId != null) {
        map['added_by'] = userId;
      }
      return map;
    }).toList();

    await _client.from('shopping_items').insert(shoppingItemsToInsert);
    return shoppingItemsToInsert.length;
  }

  List<Dish> _mockDishes(String householdId) {
    return [
      Dish(
        id: 'mock_dish_1',
        householdId: householdId,
        name: 'Spaghetti Bolognese',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd1_1', dishId: 'mock_dish_1', customName: 'Spaghetti', quantity: 1),
          DishItem(id: 'd1_2', dishId: 'mock_dish_1', customName: 'Hackfleisch', quantity: 1),
          DishItem(id: 'd1_3', dishId: 'mock_dish_1', customName: 'Passierte Tomaten', quantity: 1),
          DishItem(id: 'd1_4', dishId: 'mock_dish_1', customName: 'Tomatenmark', quantity: 1),
          DishItem(id: 'd1_5', dishId: 'mock_dish_1', customName: 'Zwiebeln', quantity: 1),
          DishItem(id: 'd1_6', dishId: 'mock_dish_1', customName: 'Knoblauch', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_2',
        householdId: householdId,
        name: 'Chili con Carne',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd2_1', dishId: 'mock_dish_2', customName: 'Hackfleisch', quantity: 1),
          DishItem(id: 'd2_2', dishId: 'mock_dish_2', customName: 'Kidneybohnen', quantity: 1),
          DishItem(id: 'd2_3', dishId: 'mock_dish_2', customName: 'Mais', quantity: 1),
          DishItem(id: 'd2_4', dishId: 'mock_dish_2', customName: 'Gehackte Tomaten', quantity: 1),
          DishItem(id: 'd2_5', dishId: 'mock_dish_2', customName: 'Zwiebeln', quantity: 1),
          DishItem(id: 'd2_6', dishId: 'mock_dish_2', customName: 'Paprika', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_3',
        householdId: householdId,
        name: 'Kartoffelauflauf',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd3_1', dishId: 'mock_dish_3', customName: 'Kartoffeln', quantity: 6),
          DishItem(id: 'd3_2', dishId: 'mock_dish_3', customName: 'Sahne', quantity: 1),
          DishItem(id: 'd3_3', dishId: 'mock_dish_3', customName: 'Reibekäse', quantity: 1),
          DishItem(id: 'd3_4', dishId: 'mock_dish_3', customName: 'Zwiebeln', quantity: 1),
          DishItem(id: 'd3_5', dishId: 'mock_dish_3', customName: 'Kochschinken', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_4',
        householdId: householdId,
        name: 'Nudelauflauf',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd4_1', dishId: 'mock_dish_4', customName: 'Penne', quantity: 1),
          DishItem(id: 'd4_2', dishId: 'mock_dish_4', customName: 'Kochschinken', quantity: 1),
          DishItem(id: 'd4_3', dishId: 'mock_dish_4', customName: 'Sahne', quantity: 1),
          DishItem(id: 'd4_4', dishId: 'mock_dish_4', customName: 'Reibekäse', quantity: 1),
          DishItem(id: 'd4_5', dishId: 'mock_dish_4', customName: 'Tomaten', quantity: 2),
        ],
      ),
      Dish(
        id: 'mock_dish_5',
        householdId: householdId,
        name: 'Gemüse-Reis-Pfanne',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd5_1', dishId: 'mock_dish_5', customName: 'Reis', quantity: 1),
          DishItem(id: 'd5_2', dishId: 'mock_dish_5', customName: 'Paprika', quantity: 2),
          DishItem(id: 'd5_3', dishId: 'mock_dish_5', customName: 'Zucchini', quantity: 1),
          DishItem(id: 'd5_4', dishId: 'mock_dish_5', customName: 'Karotten', quantity: 2),
          DishItem(id: 'd5_5', dishId: 'mock_dish_5', customName: 'Zwiebeln', quantity: 1),
          DishItem(id: 'd5_6', dishId: 'mock_dish_5', customName: 'Erbsen', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_6',
        householdId: householdId,
        name: 'Bratkartoffeln mit Spiegelei',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd6_1', dishId: 'mock_dish_6', customName: 'Kartoffeln', quantity: 6),
          DishItem(id: 'd6_2', dishId: 'mock_dish_6', customName: 'Eier', quantity: 4),
          DishItem(id: 'd6_3', dishId: 'mock_dish_6', customName: 'Zwiebeln', quantity: 1),
          DishItem(id: 'd6_4', dishId: 'mock_dish_6', customName: 'Bacon', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_7',
        householdId: householdId,
        name: 'Wraps',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd7_1', dishId: 'mock_dish_7', customName: 'Wraps', quantity: 1),
          DishItem(id: 'd7_2', dishId: 'mock_dish_7', customName: 'Hackfleisch', quantity: 1),
          DishItem(id: 'd7_3', dishId: 'mock_dish_7', customName: 'Tomaten', quantity: 2),
          DishItem(id: 'd7_4', dishId: 'mock_dish_7', customName: 'Gurke', quantity: 1),
          DishItem(id: 'd7_5', dishId: 'mock_dish_7', customName: 'Eisbergsalat', quantity: 1),
          DishItem(id: 'd7_6', dishId: 'mock_dish_7', customName: 'Reibekäse', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_8',
        householdId: householdId,
        name: 'Tomaten-Mozzarella-Pasta',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd8_1', dishId: 'mock_dish_8', customName: 'Nudeln', quantity: 1),
          DishItem(id: 'd8_2', dishId: 'mock_dish_8', customName: 'Tomaten', quantity: 4),
          DishItem(id: 'd8_3', dishId: 'mock_dish_8', customName: 'Mozzarella', quantity: 2),
          DishItem(id: 'd8_4', dishId: 'mock_dish_8', customName: 'Basilikum', quantity: 1),
          DishItem(id: 'd8_5', dishId: 'mock_dish_8', customName: 'Knoblauch', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_9',
        householdId: householdId,
        name: 'Kartoffelsuppe',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd9_1', dishId: 'mock_dish_9', customName: 'Kartoffeln', quantity: 6),
          DishItem(id: 'd9_2', dishId: 'mock_dish_9', customName: 'Karotten', quantity: 3),
          DishItem(id: 'd9_3', dishId: 'mock_dish_9', customName: 'Lauch', quantity: 1),
          DishItem(id: 'd9_4', dishId: 'mock_dish_9', customName: 'Zwiebeln', quantity: 1),
          DishItem(id: 'd9_5', dishId: 'mock_dish_9', customName: 'Gemüsebrühe', quantity: 1),
          DishItem(id: 'd9_6', dishId: 'mock_dish_9', customName: 'Sahne', quantity: 1),
        ],
      ),
      Dish(
        id: 'mock_dish_10',
        householdId: householdId,
        name: 'Hähnchen-Reis-Pfanne',
        isFavorite: false,
        createdAt: DateTime.now(),
        items: [
          DishItem(id: 'd10_1', dishId: 'mock_dish_10', customName: 'Hähnchenbrust', quantity: 1),
          DishItem(id: 'd10_2', dishId: 'mock_dish_10', customName: 'Reis', quantity: 1),
          DishItem(id: 'd10_3', dishId: 'mock_dish_10', customName: 'Paprika', quantity: 2),
          DishItem(id: 'd10_4', dishId: 'mock_dish_10', customName: 'Zucchini', quantity: 1),
          DishItem(id: 'd10_5', dishId: 'mock_dish_10', customName: 'Zwiebeln', quantity: 1),
          DishItem(id: 'd10_6', dishId: 'mock_dish_10', customName: 'Kochsahne', quantity: 1),
        ],
      ),
    ];
  }
}
