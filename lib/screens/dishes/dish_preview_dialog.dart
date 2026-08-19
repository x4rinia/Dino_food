import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/dish.dart';
import '../../models/dish_item.dart';
import '../../providers/dish_provider.dart';
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

    // Check open (unchecked) items to avoid duplicates
    final openItems = shoppingProvider.activeItems;

    final List<DishItem> itemsToAdd = [];
    final List<DishItem> inStockItems = [];
    final List<DishItem> alreadyOnListItems = [];

    for (final item in dish.items) {
      final isInStock = item.foodId != null && stockProvider.isInStock(item.foodId!);
      final isAlreadyOnList = openItems.any((openItem) {
        if (item.foodId != null && openItem.foodId != null && openItem.foodId == item.foodId) {
          return true;
        }
        final itemName = item.displayName.toLowerCase().trim();
        final openName = openItem.displayName.toLowerCase().trim();
        return itemName == openName;
      });

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
                          await dishProvider.addItemsToShoppingList(
                            householdId: householdId,
                            items: itemsToAdd,
                          );

                          // Refresh shopping items stream
                          shoppingProvider.bindToHousehold(householdId);

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
