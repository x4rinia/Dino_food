import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/dino_card.dart';
import '../../widgets/empty_state.dart';
import '../shopping_list/add_edit_item_dialog.dart';
import 'add_food_dialog.dart';
import 'edit_food_dialog.dart';
import 'stock_screen.dart';

class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String? hhId;
      try {
        hhId = Provider.of<HouseholdProvider>(
          context,
          listen: false,
        ).currentHousehold?.id;
      } catch (_) {}
      final fp = Provider.of<FoodProvider>(context, listen: false);
      if (hhId != null) {
        fp.bindToHousehold(hhId);
      } else {
        fp.loadFoods();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);
    final shoppingProvider = Provider.of<ShoppingProvider>(
      context,
      listen: false,
    );
    final visibleStockCount = stockProvider.countForFoodIds(
      foodProvider.foods.map((food) => food.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lebensmittel & Vorrat 🥕'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primarySoft,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockScreen()),
                );
              },
              icon: const Text('📦', style: TextStyle(fontSize: 16)),
              label: Text(
                'Vorrat ($visibleStockCount)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.primarySoft.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Text('📦', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visibleStockCount == 0
                        ? 'Tippe bei Artikeln auf „Vorrat?“, um sie als Zuhause zu markieren.'
                        : '$visibleStockCount Artikel im Vorrat',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Lebensmittel suchen...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          foodProvider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (val) => foodProvider.setSearchQuery(val),
            ),
          ),

          const SizedBox(height: 4),

          // Food List with Stock Toggle
          Expanded(
            child: foodProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : foodProvider.filteredFoods.isEmpty
                ? EmptyState(
                    emoji: '🔍',
                    title: 'Keine Lebensmittel gefunden',
                    message:
                        'Füge "${foodProvider.searchQuery}" als neues eigenes Lebensmittel hinzu!',
                    actionLabel: 'Lebensmittel hinzufügen',
                    onAction: () => _openAddFoodDialog(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: foodProvider.filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = foodProvider.filteredFoods[index];
                      final isInStock = stockProvider.isInStock(food.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: DinoCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isInStock
                                      ? AppTheme.primarySoft
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '🥕',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    if (food.note != null &&
                                        food.note!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        food.note!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Stock Toggle Button
                              InkWell(
                                onTap: () {
                                  stockProvider.toggleStock(food.id);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isInStock
                                        ? AppTheme.primaryGreen
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isInStock
                                          ? AppTheme.primaryGreen
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isInStock
                                            ? Icons.check_circle
                                            : Icons.home_outlined,
                                        size: 15,
                                        color: isInStock
                                            ? Colors.white
                                            : AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isInStock ? 'Zuhause' : 'Vorrat?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isInStock
                                              ? Colors.white
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Quick Add to shopping list
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primarySoft,
                                  foregroundColor: AppTheme.primaryDark,
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                ),
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 18,
                                ),
                                tooltip: 'Auf Einkaufsliste setzen',
                                onPressed: () {
                                  _quickAddFoodToShopping(
                                    context,
                                    food,
                                    shoppingProvider,
                                  );
                                },
                              ),

                              // More menu: Edit / Delete
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: AppTheme.textMuted,
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openEditFoodDialog(context, food);
                                  } else if (value == 'delete') {
                                    _confirmDeleteFood(
                                      context,
                                      food,
                                      foodProvider,
                                    );
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Bearbeiten',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: AppTheme.errorRed,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Löschen',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _openAddFoodDialog(context),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Lebensmittel hinzufügen',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddFoodDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddFoodDialog());
  }

  void _openEditFoodDialog(BuildContext context, Food food) {
    showDialog(
      context: context,
      builder: (_) => EditFoodDialog(food: food),
    );
  }

  void _confirmDeleteFood(
    BuildContext context,
    Food food,
    FoodProvider foodProvider,
  ) async {
    final inUse = await foodProvider.isFoodInUse(food.id);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lebensmittel löschen?'),
        content: Text(
          inUse
              ? '„${food.name}“ wirklich vollständig aus der Lebensmittel-Liste löschen?\n\nHinweis: Dieses Lebensmittel wird derzeit noch in anderen Bereichen verwendet. Die zugehörigen Verknüpfungen werden beim Löschen bereinigt.'
              : '„${food.name}“ wirklich vollständig aus der Lebensmittel-Liste löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await foodProvider.deleteFood(food.id, foodName: food.name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('„${food.name}“ vollständig gelöscht.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: AppTheme.errorRed,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _quickAddFoodToShopping(
    BuildContext context,
    Food food,
    ShoppingProvider shoppingProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AddEditItemDialog(preselectedFood: food),
    );
  }
}
