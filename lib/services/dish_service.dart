import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/dish.dart';
import '../models/dish_item.dart';
import '../models/food.dart';
import 'food_service.dart';

class DishService {
  SupabaseClient get _client => SupabaseConfig.client;

  static String? _resolveTemplateFoodId(
    Map<String, String> foodLookup,
    Map<String, dynamic> item,
  ) {
    final name = item['name'] as String;
    final note = item['note'] as String?;
    return foodLookup[FoodService.seedLookupKey(name, note: note)] ??
        foodLookup[name.trim().toLowerCase()];
  }

  static String _templateItemLabel(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final note = (item['note'] as String?)?.trim();
    return note == null || note.isEmpty ? name : '$name ($note)';
  }

  // 10 Standard Dino_food dishes template
  static final List<Map<String, dynamic>> defaultDishesTemplate = [
    {
      'name': 'Spaghetti Bolognese',
      'items': [
        {'name': 'Nudeln', 'note': 'Spaghetti'},
        {'name': 'Hackfleisch'},
        {'name': 'Tomaten', 'note': 'gehackt'},
        {'name': 'Tomatenmark'},
        {'name': 'Zwiebeln'},
        {'name': 'Knoblauch'},
        {'name': 'Karotten'},
      ],
    },
    {
      'name': 'Chili con Carne',
      'items': [
        {'name': 'Hackfleisch'},
        {'name': 'Kidneybohnen'},
        {'name': 'Mais'},
        {'name': 'Tomaten', 'note': 'gehackt'},
        {'name': 'Zwiebeln'},
        {'name': 'Paprika'},
      ],
    },
    {
      'name': 'Kartoffelauflauf',
      'items': [
        {'name': 'Kartoffeln'},
        {'name': 'Sahne'},
        {'name': 'Reibekäse'},
        {'name': 'Zwiebeln'},
        {'name': 'Kochschinken'},
      ],
    },
    {
      'name': 'Nudelauflauf',
      'items': [
        {'name': 'Nudeln', 'note': 'Penne'},
        {'name': 'Kochschinken'},
        {'name': 'Sahne'},
        {'name': 'Reibekäse'},
        {'name': 'Tomaten', 'note': 'groß'},
      ],
    },
    {
      'name': 'Gemüse-Reis-Pfanne',
      'items': [
        {'name': 'Reis', 'note': 'Basmati'},
        {'name': 'Paprika'},
        {'name': 'Zucchini'},
        {'name': 'Karotten'},
        {'name': 'Zwiebeln'},
        {'name': 'Erbsen'},
      ],
    },
    {
      'name': 'Bratkartoffeln mit Spiegelei',
      'items': [
        {'name': 'Kartoffeln'},
        {'name': 'Eier'},
        {'name': 'Zwiebeln'},
        {'name': 'Bacon'},
      ],
    },
    {
      'name': 'Wraps',
      'items': [
        {'name': 'Wraps'},
        {'name': 'Hackfleisch'},
        {'name': 'Tomaten', 'note': 'groß'},
        {'name': 'Gurke'},
        {'name': 'Eisbergsalat'},
        {'name': 'Reibekäse'},
      ],
    },
    {
      'name': 'Tomaten-Mozzarella-Pasta',
      'items': [
        {'name': 'Nudeln', 'note': 'Fusilli'},
        {'name': 'Tomaten', 'note': 'Cherry'},
        {'name': 'Mozzarella'},
        {'name': 'Basilikum'},
        {'name': 'Knoblauch'},
      ],
    },
    {
      'name': 'Kartoffelsuppe',
      'items': [
        {'name': 'Kartoffeln'},
        {'name': 'Karotten'},
        {'name': 'Lauch'},
        {'name': 'Zwiebeln'},
        {'name': 'Gemüsebrühe'},
        {'name': 'Sahne'},
      ],
    },
    {
      'name': 'Hähnchen-Reis-Pfanne',
      'items': [
        {'name': 'Hähnchenbrust'},
        {'name': 'Reis', 'note': 'Jasmin'},
        {'name': 'Paprika'},
        {'name': 'Zucchini'},
        {'name': 'Zwiebeln'},
        {'name': 'Kochsahne'},
      ],
    },
  ];

  // Household-scoped mock storage for offline / testing
  static final Map<String, List<Dish>> _householdMockDishes = {};

  static List<Dish> _createDefaultDishesForHousehold(
    String householdId,
    Map<String, String> foodNameToIdMap, {
    Map<String, Food>? foodsById,
  }) {
    final List<Dish> result = [];
    var dishIndex = 1;

    for (final t in defaultDishesTemplate) {
      final dishId = 'dish_${householdId}_$dishIndex';
      final rawItems = t['items'] as List<Map<String, dynamic>>;
      var itemIndex = 1;

      final items = rawItems.map((raw) {
        final foodId = _resolveTemplateFoodId(foodNameToIdMap, raw);
        final foodObj = foodId != null && foodsById != null
            ? foodsById[foodId]
            : null;

        return DishItem(
          id: 'ditem_${dishId}_$itemIndex',
          dishId: dishId,
          foodId: foodId,
          customName: foodId == null ? _templateItemLabel(raw) : null,
          food: foodObj,
        );
      }).toList();

      result.add(
        Dish(
          id: dishId,
          householdId: householdId,
          name: t['name'] as String,
          isFavorite: false,
          createdAt: DateTime.now(),
          items: items,
        ),
      );
      dishIndex++;
    }

    return result;
  }

  /// Seeds default dishes for a newly created household with exact food IDs.
  /// Seeds or completes missing default dishes for a household.
  /// Idempotent: Skips dishes that already exist with items for this household.
  /// Rollback: Deletes dish header if dish_items insert fails.
  Future<List<Dish>> seedDefaultDishesForHousehold(
    String householdId,
    Map<String, String> foodNameToIdMap, {
    String? userId,
    bool replaceExistingDefaults = false,
  }) async {
    final shouldReplaceExistingDefaults =
        replaceExistingDefaults || userId != null;

    if (!SupabaseConfig.isConfigured || householdId.isEmpty) {
      final foods = await FoodService().fetchFoods(householdId);
      final foodsById = {for (final f in foods) f.id: f};
      final dishes = _createDefaultDishesForHousehold(
        householdId,
        foodNameToIdMap,
        foodsById: foodsById,
      );
      _householdMockDishes[householdId] = dishes;
      return dishes;
    }

    try {
      // 1. Ensure we have real food IDs for this household
      final foods = await FoodService().fetchFoods(householdId);
      final resolvedFoodMap = <String, String>{};
      for (final f in foods) {
        FoodService.addToSeedLookup(
          resolvedFoodMap,
          id: f.id,
          name: f.name,
          note: f.note,
        );
      }
      foodNameToIdMap.forEach((k, v) {
        resolvedFoodMap.putIfAbsent(k, () => v);
      });

      // 2. Fetch already existing dishes with items for this household
      final existingData = await _client
          .from('dishes')
          .select('id, name, dish_items(id)')
          .eq('household_id', householdId);

      final Map<String, Map<String, dynamic>> existingDishesByName = {};
      for (final d in existingData as List) {
        final dName = (d['name'] as String).trim().toLowerCase();
        final items = d['dish_items'] as List?;
        existingDishesByName[dName] = {
          'id': d['id'] as String,
          'item_count': items?.length ?? 0,
        };
      }

      for (final template in defaultDishesTemplate) {
        final dishName = template['name'] as String;
        final normalizedName = dishName.trim().toLowerCase();
        final rawItems = template['items'] as List<Map<String, dynamic>>;
        final expectedItemCount = rawItems.length;

        // If dish already exists, check if it has ALL expected items:
        if (existingDishesByName.containsKey(normalizedName)) {
          final existing = existingDishesByName[normalizedName]!;
          final actualItemCount = existing['item_count'] as int;

          // Existing households keep their dishes untouched. Replacement is
          // explicitly enabled only while creating a brand-new household, so
          // legacy RPC seeds cannot win over the current Flutter templates.
          if (!shouldReplaceExistingDefaults &&
              actualItemCount >= expectedItemCount) {
            continue;
          }

          // If it is incomplete (e.g. 0 items or fewer than expected items like 2/6),
          // attempt to clean it up before re-creating:
          debugPrint(
            shouldReplaceExistingDefaults
                ? 'Replacing legacy seed dish "$dishName" in newly created household...'
                : 'Repairing damaged dish "$dishName" (found $actualItemCount of $expectedItemCount expected items)...',
          );
          var deleteSucceeded = false;
          try {
            await _client
                .from('dishes')
                .delete()
                .eq('id', existing['id'] as String);
            deleteSucceeded = true;
          } catch (delErr) {
            debugPrint(
              'Error deleting damaged dish "$dishName" (${existing['id']}): $delErr',
            );
          }

          // If deletion failed, do NOT attempt to re-create to prevent duplicates!
          if (!deleteSucceeded) {
            debugPrint(
              'Skipping re-creation of "$dishName" because deleting the existing record failed.',
            );
            continue;
          }
        }

        String? createdDishId;
        try {
          final dishMap = <String, dynamic>{
            'household_id': householdId,
            'name': dishName,
          };
          if (userId != null) {
            dishMap['created_by'] = userId;
          }

          final dishData = await _client
              .from('dishes')
              .insert(dishMap)
              .select()
              .single();
          createdDishId = dishData['id'] as String;

          final itemsToInsert = rawItems.map((raw) {
            final rawFoodId = _resolveTemplateFoodId(resolvedFoodMap, raw);
            final isUuid =
                rawFoodId != null &&
                RegExp(
                  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                ).hasMatch(rawFoodId);

            return {
              'dish_id': createdDishId,
              'food_id': isUuid ? rawFoodId : null,
              'custom_name': isUuid ? null : _templateItemLabel(raw),
            };
          }).toList();

          if (itemsToInsert.isNotEmpty) {
            await _client.from('dish_items').insert(itemsToInsert);
          }
        } catch (singleDishError) {
          debugPrint(
            'Error inserting single dish "$dishName" for household $householdId: $singleDishError',
          );
          // Rollback: Clean up empty dish if items failed
          if (createdDishId != null) {
            try {
              await _client.from('dishes').delete().eq('id', createdDishId);
            } catch (rollbackErr) {
              debugPrint(
                'Rollback error deleting dish $createdDishId for household $householdId: $rollbackErr',
              );
            }
          }
        }
      }

      // Re-fetch all complete dishes for this household
      return await fetchDishes(householdId);
    } catch (e) {
      debugPrint('Error seeding default dishes for household $householdId: $e');
      return await fetchDishes(householdId);
    }
  }

  Future<List<Dish>> fetchDishes(String householdId) async {
    if (!SupabaseConfig.isConfigured || householdId.isEmpty) {
      return _getOrInitMockDishes(householdId);
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

      return list;
    } catch (e, stackTrace) {
      debugPrint(
        'CRITICAL: Error fetching dishes for household "$householdId": $e\n$stackTrace',
      );
      rethrow;
    }
  }

  List<Dish> _getOrInitMockDishes(String householdId) {
    if (_householdMockDishes.containsKey(householdId)) {
      return List<Dish>.from(_householdMockDishes[householdId]!);
    }

    final foodMap = <String, String>{};
    final foods = FoodService.defaultFoods;
    for (final f in foods) {
      FoodService.addToSeedLookup(
        foodMap,
        id: '${f.id}_$householdId',
        name: f.name,
        note: f.note,
      );
    }
    final foodsById = {
      for (final f in foods)
        '${f.id}_$householdId': Food(
          id: '${f.id}_$householdId',
          householdId: householdId,
          name: f.name,
          note: f.note,
          iconKey: f.iconKey,
          defaultUnit: f.defaultUnit,
          createdAt: DateTime.now(),
        ),
    };

    final seeded = _createDefaultDishesForHousehold(
      householdId,
      foodMap,
      foodsById: foodsById,
    );
    _householdMockDishes[householdId] = seeded;
    return seeded;
  }

  Future<Dish> createDish({
    required String householdId,
    required String name,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      final dishId = 'dish_${DateTime.now().millisecondsSinceEpoch}';
      final dishItems = items.map((i) {
        final fId = i['food_id'] as String?;
        return DishItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_${i['food_id']}',
          dishId: dishId,
          foodId: fId,
          customName:
              i['custom_name'] ??
              (fId == null ? (i['food_name'] ?? i['name']) : null),
        );
      }).toList();

      final newDish = Dish(
        id: dishId,
        householdId: householdId,
        name: name.trim(),
        isFavorite: false,
        createdAt: DateTime.now(),
        items: dishItems,
      );

      final list = _householdMockDishes.putIfAbsent(householdId, () => []);
      list.add(newDish);
      return newDish;
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
          'custom_name':
              i['custom_name'] ??
              (i['food_id'] == null ? i['food_name'] : null),
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
    String? householdId,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      if (householdId != null &&
          _householdMockDishes.containsKey(householdId)) {
        final list = _householdMockDishes[householdId]!;
        final index = list.indexWhere((d) => d.id == dishId);
        if (index != -1) {
          final old = list[index];
          final dishItems = items.map((i) {
            final fId = i['food_id'] as String?;
            return DishItem(
              id: 'item_${DateTime.now().millisecondsSinceEpoch}_${i['food_id']}',
              dishId: dishId,
              foodId: fId,
              customName:
                  i['custom_name'] ?? (fId == null ? i['food_name'] : null),
            );
          }).toList();

          final updated = old.copyWith(name: name.trim(), items: dishItems);
          list[index] = updated;
          return updated;
        }
      }
      return Dish(
        id: dishId,
        householdId: householdId ?? '',
        name: name,
        createdAt: DateTime.now(),
      );
    }

    // 1. Update dish name
    await _client.from('dishes').update({'name': name.trim()}).eq('id', dishId);

    // 2. Replace dish items: delete old items and insert updated ones
    await _client.from('dish_items').delete().eq('dish_id', dishId);

    if (items.isNotEmpty) {
      final itemsToInsert = items.map((i) {
        return {
          'dish_id': dishId,
          'food_id': i['food_id'],
          'custom_name':
              i['custom_name'] ??
              (i['food_id'] == null ? i['food_name'] : null),
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

  Future<void> deleteDish(String dishId, {String? householdId}) async {
    if (!SupabaseConfig.isConfigured) {
      if (householdId != null &&
          _householdMockDishes.containsKey(householdId)) {
        _householdMockDishes[householdId]!.removeWhere((d) => d.id == dishId);
      }
      return;
    }

    try {
      await _client.from('dishes').delete().eq('id', dishId);
    } catch (e) {
      debugPrint('Error deleting dish: $e');
    }
  }

  Future<void> toggleFavorite(
    String dishId,
    bool isFavorite, {
    String? householdId,
  }) async {
    if (!SupabaseConfig.isConfigured || SupabaseConfig.currentUserId == null) {
      if (householdId != null &&
          _householdMockDishes.containsKey(householdId)) {
        final list = _householdMockDishes[householdId]!;
        final idx = list.indexWhere((d) => d.id == dishId);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(isFavorite: isFavorite);
        }
      }
      return;
    }

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
}
