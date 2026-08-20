import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../models/dish.dart';
import '../../models/dish_item.dart';
import '../../providers/dish_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/stock_provider.dart';

class DishPreviewDialog extends StatelessWidget {
  final Dish dish;

  const DishPreviewDialog({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final shoppingProvider = Provider.of<ShoppingProvider>(context);
    final householdProvider = Provider.of<HouseholdProvider>(context);
    final dishProvider = Provider.of<DishProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodProvider>(context);

    // Check open (unchecked) items to avoid duplicates
    final openItems = shoppingProvider.activeItems;

    final List<DishItem> itemsToAdd = [];
    final List<DishItem> inStockItems = [];
    final List<DishItem> alreadyOnListItems = [];

    for (final item in dish.items) {
      final itemName = item.displayName.toLowerCase().trim();
      final itemCustomName = item.customName?.toLowerCase().trim();

      // Find matching catalog food if available
      final matchingFood = foodProvider.foods.where((f) {
        final fName = f.name.toLowerCase().trim();
        return fName == itemName || (itemCustomName != null && fName == itemCustomName);
      }).firstOrNull;

      final matchedFoodId = item.foodId ?? item.food?.id ?? matchingFood?.id;

      // 1. Check if in stock (Vorrat aktiv)
      bool isInStock = false;
      if (item.foodId != null && stockProvider.isInStock(item.foodId!)) {
        isInStock = true;
      } else if (item.food != null && stockProvider.isInStock(item.food!.id)) {
        isInStock = true;
      } else if (matchedFoodId != null && stockProvider.isInStock(matchedFoodId)) {
        isInStock = true;
      }

      // 2. Check if already on active shopping list
      bool isAlreadyOnList = false;
      if (!isInStock) {
        isAlreadyOnList = openItems.any((openItem) {
          final openFoodId = openItem.foodId ?? openItem.food?.id;
          // Match by food ID
          if (matchedFoodId != null && openFoodId != null && matchedFoodId == openFoodId) {
            return true;
          }
          // Match by display name
          final openName = openItem.displayName.toLowerCase().trim();
          if (openName == itemName) {
            return true;
          }
          // Match by custom name
          final openCustomName = openItem.customName?.toLowerCase().trim();
          if (openCustomName != null && itemCustomName != null && openCustomName == itemCustomName) {
            return true;
          }
          // Match with open food catalog name
          if (openItem.food != null) {
            final openCatalogName = openItem.food!.name.toLowerCase().trim();
            if (openCatalogName == itemName || (itemCustomName != null && openCatalogName == itemCustomName)) {
              return true;
            }
          }
          return false;
        });
      }

      if (isInStock) {
        inStockItems.add(item);
      } else if (isAlreadyOnList) {
        alreadyOnListItems.add(item);
      } else {
        itemsToAdd.add(item);
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🍝', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dish.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Wird hinzugefügt
                    if (itemsToAdd.isNotEmpty) ...[
                      const Text(
                        'Wird hinzugefügt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: itemsToAdd.map((item) {
                            final qtyStr = item.formattedQuantity;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                  if (qtyStr.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        qtyStr,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primaryDark),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Section: Zuhause vorhanden
                    if (inStockItems.isNotEmpty) ...[
                      const Text(
                        'Zuhause vorhanden',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: inStockItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Text('🏠', style: TextStyle(fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.displayName,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ),
                                  const Text(
                                    'Im Vorrat',
                                    style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Section: Bereits auf Einkaufsliste
                    if (alreadyOnListItems.isNotEmpty) ...[
                      const Text(
                        'Bereits auf Einkaufsliste',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: alreadyOnListItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Text('🛒', style: TextStyle(fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.displayName,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    'Bereits auf Liste',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Summary message
                    Text(
                      itemsToAdd.isEmpty
                          ? 'Alle Zutaten sind bereits im Vorrat oder auf der Einkaufsliste!'
                          : '${itemsToAdd.length} Artikel werden hinzugefügt.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: itemsToAdd.isEmpty ? AppTheme.accentOrange : AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: itemsToAdd.isEmpty
                      ? () => Navigator.of(context).pop()
                      : () async {
                          final householdId = householdProvider.currentHousehold?.id ?? '';
                          if (!SupabaseConfig.isConfigured) {
                            for (final item in itemsToAdd) {
                              await shoppingProvider.addItem(
                                foodId: item.foodId ?? item.food?.id,
                                customName: item.food?.name ?? item.customName ?? item.displayName,
                                quantity: item.quantity > 0 ? item.quantity : 1.0,
                              );
                            }
                          } else {
                            await dishProvider.addItemsToShoppingList(
                              householdId: householdId,
                              items: itemsToAdd,
                            );
                            shoppingProvider.bindToHousehold(householdId);
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${itemsToAdd.length} Zutaten zur Einkaufsliste hinzugefügt! 🛒'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        },
                  child: Text(itemsToAdd.isEmpty ? 'Schließen' : 'Zur Einkaufsliste hinzufügen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
