import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food.dart';
import '../../models/food_icon.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/dino_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/load_error_state.dart';
import '../shopping_list/add_edit_item_dialog.dart';
import 'add_food_dialog.dart';
import 'edit_food_dialog.dart';

enum FoodSortMode {
  inStockFirst,
  notInStockFirst,
  alphabetical,
}

class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  final _searchController = TextEditingController();
  String _lastSearchQuery = '';
  FoodSortMode _sortMode = FoodSortMode.alphabetical;

  void _handleTabTap(
    FoodSortMode mode,
    FoodProvider foodProvider,
    StockProvider stockProvider,
  ) async {
    if (_sortMode == mode) {
      // Re-tapping active tab triggers refresh
      await foodProvider.loadFoods(force: true);
    } else {
      setState(() {
        _sortMode = mode;
      });
    }
  }

  Widget _buildSortTab({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: AppTheme.primaryGreen,
                  width: 1.5,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 1.5,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sortMode = FoodSortMode.alphabetical;
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

    final filteredFoods = foodProvider.filteredFoods;
    final visibleStockCount = stockProvider.countForFoodIds(
      foodProvider.foods.map((food) => food.id),
    );

    // Filter and sort displayed foods according to selected tab mode:
    final List<Food> displayedFoods;
    switch (_sortMode) {
      case FoodSortMode.inStockFirst:
        // "Vorrat" tab -> display ONLY items in stock
        displayedFoods = filteredFoods
            .where((food) => stockProvider.isInStock(food.id))
            .toList();
        break;

      case FoodSortMode.notInStockFirst:
        // "Nicht im Vorrat" tab -> display ONLY items not in stock
        displayedFoods = filteredFoods
            .where((food) => !stockProvider.isInStock(food.id))
            .toList();
        break;

      case FoodSortMode.alphabetical:
        // "Alle" tab -> display all items
        displayedFoods = List<Food>.from(filteredFoods);
        break;
    }

    // Always sort displayed items alphabetically A-Z
    displayedFoods.sort((a, b) => FoodProvider.compareFoodNames(a.name, b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lebensmitteldatenbank 🍽️'),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            color: AppTheme.primarySoft.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Text('📦', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sortMode == FoodSortMode.inStockFirst
                        ? (displayedFoods.isEmpty
                            ? 'Keine Lebensmittel im Vorrat.'
                            : '${displayedFoods.length} ${displayedFoods.length == 1 ? 'Artikel' : 'Artikel'} im Vorrat')
                        : _sortMode == FoodSortMode.notInStockFirst
                            ? (displayedFoods.isEmpty
                                ? 'Alle Lebensmittel sind aktuell im Vorrat!'
                                : '${displayedFoods.length} ${displayedFoods.length == 1 ? 'Artikel' : 'Artikel'} nicht im Vorrat')
                            : 'Alle ${filteredFoods.length} Lebensmittel (A–Z sortiert)',
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Lebensmittel suchen...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textMuted,
                ),
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

          // 3 Segmented Sort Tabs (Alle / Vorrat / Nicht im Vorrat)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSortTab(
                      label: 'Alle',
                      subtitle: 'A–Z',
                      isSelected: _sortMode == FoodSortMode.alphabetical,
                      onTap: () => _handleTabTap(
                        FoodSortMode.alphabetical,
                        foodProvider,
                        stockProvider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildSortTab(
                      label: 'Vorrat',
                      subtitle: '($visibleStockCount)',
                      isSelected: _sortMode == FoodSortMode.inStockFirst,
                      onTap: () => _handleTabTap(
                        FoodSortMode.inStockFirst,
                        foodProvider,
                        stockProvider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildSortTab(
                      label: 'Nicht im Vorrat',
                      subtitle: '(${filteredFoods.length - visibleStockCount})',
                      isSelected: _sortMode == FoodSortMode.notInStockFirst,
                      onTap: () => _handleTabTap(
                        FoodSortMode.notInStockFirst,
                        foodProvider,
                        stockProvider,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Food List with RefreshIndicator
          Expanded(
            child: foodProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : foodProvider.errorMessage != null
                ? LoadErrorState(
                    message: foodProvider.errorMessage!,
                    onRetry: () => foodProvider.loadFoods(force: true),
                  )
                : displayedFoods.isEmpty
                ? EmptyState(
                    emoji: _sortMode == FoodSortMode.inStockFirst
                        ? '📦'
                        : _sortMode == FoodSortMode.notInStockFirst
                            ? '🎉'
                            : '🔍',
                    title: _sortMode == FoodSortMode.inStockFirst
                        ? 'Keine Lebensmittel im Vorrat'
                        : _sortMode == FoodSortMode.notInStockFirst
                            ? 'Alles im Vorrat!'
                            : 'Keine Lebensmittel gefunden',
                    message: _sortMode == FoodSortMode.inStockFirst
                        ? 'Markiere Artikel im Vorrat-Tab als Zuhause, um sie hier anzuzeigen.'
                        : _sortMode == FoodSortMode.notInStockFirst
                            ? 'Alle Lebensmittel befinden sich aktuell im Vorrat.'
                            : 'Füge "${foodProvider.searchQuery}" als neues eigenes Lebensmittel hinzu!',
                    actionLabel: _sortMode == FoodSortMode.alphabetical
                        ? 'Lebensmittel hinzufügen'
                        : null,
                    onAction: _sortMode == FoodSortMode.alphabetical
                        ? () => _openAddFoodDialog(context)
                        : null,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await foodProvider.loadFoods(force: true);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                      itemCount: displayedFoods.length,
                      itemBuilder: (context, index) {
                      final food = displayedFoods[index];
                      final isInStock = stockProvider.isInStock(food.id);

                      return Padding(
                        key: ValueKey(food.id),
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
                                child: Text(
                                  FoodIconCatalog.emojiFor(food.iconKey),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                onTap: () => stockProvider.toggleStock(food.id),
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
                                        isInStock ? 'Vorrat' : 'Vorrat?',
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

  Future<void> _quickAddFoodToShopping(
    BuildContext context,
    Food food,
    ShoppingProvider shoppingProvider,
  ) async {
    var saved = false;
    final existingItem = shoppingProvider.itemForFood(food.id);
    if (existingItem == null) {
      saved =
          await showDialog<bool>(
            context: context,
            builder: (_) => AddEditItemDialog(preselectedFood: food),
          ) ??
          false;
    } else {
      final nextQuantity = (existingItem.quantity ?? 1) + 1;
      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${food.name} ist bereits in der Einkaufsliste.'),
          duration: const Duration(seconds: 2),
        ),
      );
      saved =
          await showDialog<bool>(
            context: context,
            builder: (_) => AddEditItemDialog(
              itemToEdit: existingItem,
              suggestedQuantity: nextQuantity,
            ),
          ) ??
          false;
    }

    if (!saved || !context.mounted) return;

    // Intentionally scoped to this food-list quick-add flow. Stock removal and
    // ordinary shopping-item edits/deletes must never trigger this prompt.
    final stockProvider = context.read<StockProvider>();
    if (!stockProvider.isInStock(food.id)) return;

    final removeFromStock = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lebensmittel im Vorrat'),
        content: Text(
          '${food.displayLabel} ist aktuell im Vorrat. '
          'Aus dem Vorrat entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Nein'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ja'),
          ),
        ],
      ),
    );

    if (removeFromStock != true || !context.mounted) return;
    final removed = await stockProvider.removeFromStock(food.id);
    if (!removed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Das Lebensmittel konnte nicht aus dem Vorrat entfernt werden.',
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}
