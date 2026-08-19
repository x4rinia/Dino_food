import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/dish.dart';
import '../../providers/dish_provider.dart';
import '../../providers/household_provider.dart';
import '../../widgets/dino_card.dart';
import '../../widgets/empty_state.dart';
import 'add_dish_dialog.dart';
import 'dish_preview_dialog.dart';

class DishesScreen extends StatefulWidget {
  const DishesScreen({super.key});

  @override
  State<DishesScreen> createState() => _DishesScreenState();
}

class _DishesScreenState extends State<DishesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final household = Provider.of<HouseholdProvider>(context, listen: false).currentHousehold;
      if (household != null) {
        Provider.of<DishProvider>(context, listen: false).loadDishes(household.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final householdProvider = Provider.of<HouseholdProvider>(context);
    final dishProvider = Provider.of<DishProvider>(context);
    final household = householdProvider.currentHousehold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerichte 🍲'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted),
            onPressed: () {
              if (household != null) {
                dishProvider.loadDishes(household.id);
              }
            },
          ),
        ],
      ),
      body: dishProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dishProvider.dishes.isEmpty
              ? EmptyState(
                  emoji: '🍝',
                  title: 'Noch keine Gerichte angelegt',
                  message:
                      'Erstelle gespeicherte Zusammenstellungen deiner Lieblingsgerichte (z. B. Spaghetti Bolognese) und setze alle Zutaten mit einem Klick auf die Einkaufsliste!',
                  actionLabel: 'Gericht hinzufügen',
                  onAction: () => _openAddDishDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: dishProvider.dishes.length,
                  itemBuilder: (context, index) {
                    final dish = dishProvider.dishes[index];
                    return _buildDishCard(context, dish, dishProvider);
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _openAddDishDialog(context),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Gericht hinzufügen',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDishCard(
    BuildContext context,
    Dish dish,
    DishProvider dishProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DinoCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon, Name, Favorite Heart & Delete button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🍲', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dish.items.length} Zutaten',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                // Favorite Heart Button (Max 5 favorites check)
                IconButton(
                  icon: Icon(
                    dish.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: dish.isFavorite ? AppTheme.errorRed : AppTheme.textMuted,
                    size: 24,
                  ),
                  tooltip: dish.isFavorite ? 'Aus Favoriten entfernen' : 'Als Favorit markieren',
                  onPressed: () async {
                    final success = await dishProvider.toggleFavorite(dish.id);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Du kannst maximal 5 Lieblingsgerichte auswählen.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

                // Delete Dish Button with confirmation
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                  tooltip: 'Gericht löschen',
                  onPressed: () => _confirmDeleteDish(context, dish, dishProvider),
                ),
              ],
            ),

            // Ingredients List
            if (dish.items.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dish.items.map((item) {
                    final qtyStr = item.formattedQuantity;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              item.displayName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textDark),
                            ),
                          ),
                          if (qtyStr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                qtyStr,
                                style: const TextStyle(fontSize: 12, color: AppTheme.primaryDark, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons: "Bearbeiten" and "Zur Einkaufsliste hinzufügen"
            Row(
              children: [
                // Edit Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryGreen),
                  label: const Text('Bearbeiten', style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddDishDialog(dishToEdit: dish),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Add to Shopping List Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Auf Einkaufsliste',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => DishPreviewDialog(dish: dish),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDish(
    BuildContext context,
    Dish dish,
    DishProvider dishProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gericht wirklich löschen?'),
        content: Text('Möchtest du "${dish.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () {
              Navigator.pop(ctx);
              dishProvider.deleteDish(dish.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gericht "${dish.name}" gelöscht.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _openAddDishDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddDishDialog(),
    );
  }
}
