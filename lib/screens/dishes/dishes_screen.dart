import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/dish.dart';
import '../../models/dish_item.dart';
import '../../models/food.dart';
import '../../models/food_icon.dart';
import '../../providers/dish_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/stock_provider.dart';
import '../../utils/recipe_ingredient_matcher.dart';
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
  final TextEditingController _hungerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final household = Provider.of<HouseholdProvider>(
        context,
        listen: false,
      ).currentHousehold;
      if (household != null) {
        Provider.of<DishProvider>(
          context,
          listen: false,
        ).loadDishes(household.id);
        Provider.of<FoodProvider>(
          context,
          listen: false,
        ).bindToHousehold(household.id);
        Provider.of<StockProvider>(
          context,
          listen: false,
        ).bindToHousehold(household.id);
      }
    });
  }

  @override
  void dispose() {
    _hungerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdProvider = Provider.of<HouseholdProvider>(context);
    final dishProvider = Provider.of<DishProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);
    final household = householdProvider.currentHousehold;

    final foodMap = RecipeIngredientMatcher.indexFoods(foodProvider.foods);

    final selectedHunger = dishProvider.selectedHungerFood;
    List<HungerDishMatch>? rankedMatches;

    if (selectedHunger != null) {
      rankedMatches = dishProvider.getRankedDishesForHunger(
        hungerFood: selectedHunger,
        inStockFoodIds: stockProvider.inStockFoodIds,
        foodIdsByName: foodMap,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerichte 🍲'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted),
            tooltip: 'Neu laden',
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
          : Column(
              children: [
                // --- "Worauf hast du Hunger? 🦕" Bar ---
                _buildHungerSearchBar(context, dishProvider, foodProvider),

                // --- Dish List ---
                Expanded(
                  child: selectedHunger != null
                      ? _buildHungerResultsView(
                          context,
                          dishProvider,
                          stockProvider,
                          rankedMatches!,
                          selectedHunger,
                          foodMap,
                        )
                      : _buildStandardDishesView(
                          context,
                          dishProvider,
                          stockProvider,
                          foodMap,
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

  // --- Hunger-Suche Header & Quick Chips ---
  Widget _buildHungerSearchBar(
    BuildContext context,
    DishProvider dishProvider,
    FoodProvider foodProvider,
  ) {
    final selected = dishProvider.selectedHungerFood;

    // Common popular quick ingredients
    final quickIngredients = [
      'Hackfleisch',
      'Kartoffeln',
      'Nudeln',
      'Reis',
      'Tomaten',
      'Hähnchenbrust',
      'Eier',
      'Sahne',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Worauf hast du Hunger?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              if (selected != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppTheme.errorRed,
                  ),
                  onPressed: () => dishProvider.clearHungerSearch(),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text(
                    'Alle Gerichte',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Active filter or Quick ingredient selector chips
          if (selected != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDark,
                        ),
                        children: [
                          const TextSpan(text: 'Hauptzutat: '),
                          TextSpan(
                            text: selected.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _openFoodSearchModal(
                      context,
                      foodProvider,
                      dishProvider,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Ändern',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Button to search all foods in household
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ActionChip(
                      avatar: const Icon(
                        Icons.search,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      label: const Text('Zutat suchen...'),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                      backgroundColor: AppTheme.primarySoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                      onPressed: () => _openFoodSearchModal(
                        context,
                        foodProvider,
                        dishProvider,
                      ),
                    ),
                  ),

                  // Quick chips
                  ...quickIngredients.map((name) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ActionChip(
                        label: Text(name),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                        backgroundColor: AppTheme.backgroundLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: () {
                          // Find food matching this name or create temporary reference
                          final food = foodProvider.foods.firstWhere(
                            (f) =>
                                f.name.trim().toLowerCase() ==
                                name.trim().toLowerCase(),
                            orElse: () => Food(
                              id: 'quick_$name',
                              name: name,
                              createdAt: DateTime.now(),
                            ),
                          );
                          dishProvider.setHungerFood(food);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Modal to Search Any Food in Household ---
  void _openFoodSearchModal(
    BuildContext context,
    FoodProvider foodProvider,
    DishProvider dishProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _hungerSearchController.text.trim().toLowerCase();
            final matches = foodProvider.foods.where((f) {
              return query.isEmpty || f.name.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🍲', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Worauf hast du Hunger?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hungerSearchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Zutat suchen (z. B. Hackfleisch)...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textMuted,
                      ),
                      suffixIcon: _hungerSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setModalState(() {
                                  _hungerSearchController.clear();
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: matches.isEmpty
                        ? const Center(
                            child: Text(
                              'Keine Zutat gefunden.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: matches.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final food = matches[index];
                              return ListTile(
                                leading: Text(
                                  FoodIconCatalog.emojiFor(food.iconKey),
                                  style: TextStyle(fontSize: 18),
                                ),
                                title: Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle:
                                    food.note != null &&
                                        food.note!.trim().isNotEmpty
                                    ? Text(
                                        food.note!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      )
                                    : null,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                onTap: () {
                                  _hungerSearchController.clear();
                                  Navigator.pop(ctx);
                                  dishProvider.setHungerFood(food);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Hunger-Suche Results View ---
  Widget _buildHungerResultsView(
    BuildContext context,
    DishProvider dishProvider,
    StockProvider stockProvider,
    List<HungerDishMatch> matches,
    Food hungerFood,
    FoodIdsByNormalizedName foodMap,
  ) {
    if (matches.isEmpty) {
      return EmptyState(
        emoji: '🔍',
        title: 'Keine Gerichte mit „${hungerFood.name}“',
        message: 'Erstelle ein neues Gericht mit dieser Zutat oder wähle eine andere Zutat aus.',
        actionLabel: 'Alle Gerichte ansehen',
        onAction: () => dishProvider.clearHungerSearch(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildHungerDishCard(
          context,
          match,
          dishProvider,
          stockProvider,
          hungerFood,
          foodMap,
        );
      },
    );
  }

  // --- Card for Hunger-Suche Match ---
  Widget _buildHungerDishCard(
    BuildContext context,
    HungerDishMatch match,
    DishProvider dishProvider,
    StockProvider stockProvider,
    Food hungerFood,
    FoodIdsByNormalizedName foodMap,
  ) {
    final dish = match.dish;
    final inStockFoodIds = stockProvider.inStockFoodIds;
    final normalizedSearch = RecipeIngredientMatcher.normalizeName(
      hungerFood.name,
    );

    // Determine badge color based on stock percentage
    Color scoreBgColor = const Color(0xFFF3F4F6);
    Color scoreTextColor = AppTheme.textDark;
    if (match.score >= 0.75) {
      scoreBgColor = const Color(0xFFDCFCE7);
      scoreTextColor = const Color(0xFF166534);
    } else if (match.score >= 0.4) {
      scoreBgColor = const Color(0xFFFEF3C7);
      scoreTextColor = const Color(0xFF92400E);
    }

    // Separate ingredients into: Searched main ingredient, and other ingredients
    DishItem? mainItem;
    final otherItems = <DishItem>[];

    for (final item in dish.items) {
      final isMain =
          (item.foodId != null && item.foodId == hungerFood.id) ||
          (item.food?.id != null && item.food!.id == hungerFood.id) ||
          (RecipeIngredientMatcher.normalizeName(item.displayName) ==
              normalizedSearch);

      if (isMain && mainItem == null) {
        mainItem = item;
      } else {
        otherItems.add(item);
      }
    }

    final isCookable =
        match.totalCount > 0 && match.inStockCount == match.totalCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DinoCard(
        padding: const EdgeInsets.all(16),
        border: isCookable
            ? Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                width: 1.5,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, Favorite, Delete, and Stock Score Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCookable
                        ? const Color(0xFFFEF2F2)
                        : AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCookable ? '🔥' : '🍲',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dish.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (isCookable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: const Text(
                                '🔥 Kochbar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Vorrats-Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scoreBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: scoreTextColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${match.inStockCount} von ${match.totalCount} Zutaten vorhanden (${match.scorePercentageText})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scoreTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Heart Button
                IconButton(
                  icon: Icon(
                    dish.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: dish.isFavorite
                        ? AppTheme.errorRed
                        : AppTheme.textMuted,
                    size: 24,
                  ),
                  tooltip: dish.isFavorite
                      ? 'Aus Favoriten entfernen'
                      : 'Als Favorit markieren',
                  onPressed: () async {
                    final success = await dishProvider.toggleFavorite(dish.id);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Du kannst maximal 5 Lieblingsgerichte auswählen.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

                // Delete Dish Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  tooltip: 'Gericht löschen',
                  onPressed: () =>
                      _confirmDeleteDish(context, dish, dishProvider),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // --- Ingredients List with ★, ✓, ○ Icons ---
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
                children: [
                  // 1. Gesuchte Hauptzutat (★)
                  if (mainItem != null) ...[
                    _buildIngredientRow(
                      iconText: '★',
                      iconColor: match.isMainInStock
                          ? const Color(0xFF166534)
                          : const Color(0xFFD97706),
                      nameText: match.isMainInStock
                          ? '${mainItem.displayLabel} · vorhanden'
                          : '${mainItem.displayLabel} · fehlt',
                      isBold: true,
                      textColor: match.isMainInStock
                          ? const Color(0xFF166534)
                          : const Color(0xFFB45309),
                      isMain: true,
                    ),
                    if (otherItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Divider(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                  ],

                  // 2. Weitere Zutaten (✓ oder ○)
                  ...otherItems.map((item) {
                    final isInStock = RecipeIngredientMatcher.isInStock(
                      item: item,
                      inStockFoodIds: inStockFoodIds,
                      foodIdsByName: foodMap,
                    );

                    return _buildIngredientRow(
                      iconText: isInStock ? '✓' : '○',
                      iconColor: isInStock
                          ? AppTheme.primaryGreen
                          : AppTheme.textMuted,
                      nameText: item.displayLabel,
                      isBold: isInStock,
                      textColor: isInStock
                          ? AppTheme.textDark
                          : AppTheme.textMuted,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons: "Bearbeiten" and "Auf Einkaufsliste"
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                  label: const Text(
                    'Bearbeiten',
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddDishDialog(dishToEdit: dish),
                    );
                  },
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Auf Einkaufsliste',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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

  // --- Helper for Single Ingredient Line ---
  Widget _buildIngredientRow({
    required String iconText,
    required Color iconColor,
    required String nameText,
    required bool isBold,
    required Color textColor,
    bool isMain = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 20,
            alignment: Alignment.center,
            child: Text(
              iconText,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w900,
                fontSize: isMain ? 15 : 14,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nameText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Standard View (When no Hunger Search is active) ---
  Widget _buildStandardDishesView(
    BuildContext context,
    DishProvider dishProvider,
    StockProvider stockProvider,
    FoodIdsByNormalizedName foodMap,
  ) {
    if (dishProvider.errorMessage != null && dishProvider.dishes.isEmpty) {
      final householdProvider = Provider.of<HouseholdProvider>(
        context,
        listen: false,
      );
      return EmptyState(
        emoji: '⚠️',
        title: 'Fehler beim Laden',
        message:
            'Die Gerichte konnten nicht geladen werden: ${dishProvider.errorMessage}',
        actionLabel: 'Erneut versuchen',
        onAction: () {
          final hhId = householdProvider.currentHousehold?.id;
          if (hhId != null) dishProvider.loadDishes(hhId);
        },
      );
    }

    if (dishProvider.dishes.isEmpty) {
      return const EmptyState(
        emoji: '🍝',
        title: 'Noch keine Gerichte angelegt',
        message: 'Erstelle gespeicherte Zusammenstellungen deiner Lieblingsgerichte (z. B. Spaghetti Bolognese) und setze alle Zutaten mit einem Klick auf die Einkaufsliste!',
      );
    }

    final inStockFoodIds = stockProvider.inStockFoodIds;
    final cookableDishes = <Dish>[];
    final otherDishes = <Dish>[];

    for (final dish in dishProvider.dishes) {
      var inStockCount = 0;
      for (final item in dish.items) {
        if (RecipeIngredientMatcher.isInStock(
          item: item,
          inStockFoodIds: inStockFoodIds,
          foodIdsByName: foodMap,
        )) {
          inStockCount++;
        }
      }
      if (dish.items.isNotEmpty && inStockCount == dish.items.length) {
        cookableDishes.add(dish);
      } else {
        otherDishes.add(dish);
      }
    }

    // If no dishes are cookable, show the simple standard list
    if (cookableDishes.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: dishProvider.dishes.length,
        itemBuilder: (context, index) {
          final dish = dishProvider.dishes[index];
          return _buildStandardDishCard(
            context,
            dish,
            dishProvider,
            stockProvider,
            foodMap,
          );
        },
      );
    }

    // When at least one dish is cookable: partition with headers (NO duplicates)
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Section Header: 🔥 Kochbar
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                'Kochbar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '${cookableDishes.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cookable Dish Cards
        ...cookableDishes.map(
          (dish) => _buildStandardDishCard(
            context,
            dish,
            dishProvider,
            stockProvider,
            foodMap,
          ),
        ),

        // Section Header for other dishes (if any)
        if (otherDishes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
            child: Text(
              'Alle anderen Gerichte (${otherDishes.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          ...otherDishes.map(
            (dish) => _buildStandardDishCard(
              context,
              dish,
              dishProvider,
              stockProvider,
              foodMap,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStandardDishCard(
    BuildContext context,
    Dish dish,
    DishProvider dishProvider,
    StockProvider stockProvider,
    FoodIdsByNormalizedName foodMap,
  ) {
    final inStockFoodIds = stockProvider.inStockFoodIds;

    var inStockCount = 0;
    for (final item in dish.items) {
      if (RecipeIngredientMatcher.isInStock(
        item: item,
        inStockFoodIds: inStockFoodIds,
        foodIdsByName: foodMap,
      )) {
        inStockCount++;
      }
    }

    final isCookable =
        dish.items.isNotEmpty && inStockCount == dish.items.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DinoCard(
        padding: const EdgeInsets.all(16),
        border: isCookable
            ? Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                width: 1.5,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon, Name, Favorite Heart & Delete button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCookable
                        ? const Color(0xFFFEF2F2)
                        : AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCookable ? '🔥' : '🍲',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dish.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (isCookable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: const Text(
                                '🔥 Kochbar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCookable
                            ? '${dish.items.length} von ${dish.items.length} Zutaten vorhanden'
                            : '${dish.items.length} Zutaten · $inStockCount im Vorrat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCookable
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isCookable
                              ? const Color(0xFFDC2626)
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Heart Button
                IconButton(
                  icon: Icon(
                    dish.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: dish.isFavorite
                        ? AppTheme.errorRed
                        : AppTheme.textMuted,
                    size: 24,
                  ),
                  tooltip: dish.isFavorite
                      ? 'Aus Favoriten entfernen'
                      : 'Als Favorit markieren',
                  onPressed: () async {
                    final success = await dishProvider.toggleFavorite(dish.id);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Du kannst maximal 5 Lieblingsgerichte auswählen.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

                // Delete Dish Button with confirmation
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  tooltip: 'Gericht löschen',
                  onPressed: () =>
                      _confirmDeleteDish(context, dish, dishProvider),
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
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dish.items.map((item) {
                    final isInStock = RecipeIngredientMatcher.isInStock(
                      item: item,
                      inStockFoodIds: inStockFoodIds,
                      foodIdsByName: foodMap,
                    );

                    return _buildIngredientRow(
                      iconText: isInStock ? '✓' : '○',
                      iconColor: isInStock
                          ? AppTheme.primaryGreen
                          : AppTheme.textMuted,
                      nameText: item.displayLabel,
                      isBold: isInStock,
                      textColor: isInStock
                          ? AppTheme.textDark
                          : AppTheme.textMuted,
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons: "Bearbeiten" and "Zur Einkaufsliste hinzufügen"
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                  label: const Text(
                    'Bearbeiten',
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddDishDialog(dishToEdit: dish),
                    );
                  },
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Auf Einkaufsliste',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: AppTheme.textMuted),
            ),
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
    showDialog(context: context, builder: (_) => const AddDishDialog());
  }
}
