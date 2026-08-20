import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/food_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/dino_card.dart';
import '../../widgets/empty_state.dart';
import '../shopping_list/add_edit_item_dialog.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Alle';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);

    // Get all foods that are currently in stock
    final inStockFoods = foodProvider.foods
        .where((food) => stockProvider.isInStock(food.id))
        .toList();

    // Extract categories present in current stock
    final availableCategories = <String>{'Alle'};
    for (final food in inStockFoods) {
      if (food.category.isNotEmpty) {
        availableCategories.add(food.category);
      }
    }

    // Filter by search query and category
    final query = _searchQuery.trim().toLowerCase();
    final filteredFoods = inStockFoods.where((food) {
      final matchesSearch = query.isEmpty || food.name.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'Alle' || food.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Vorrat 📦'),
      ),
      body: inStockFoods.isEmpty
          ? EmptyState(
              emoji: '📦',
              title: 'Noch nichts im Vorrat 🦕',
              message: 'Markiere Lebensmittel als „Zuhause“, damit sie hier erscheinen.',
              actionLabel: 'Zu den Lebensmitteln',
              onAction: () => Navigator.of(context).pop(),
            )
          : Column(
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.primarySoft.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${inStockFoods.length} ${inStockFoods.length == 1 ? 'Lebensmittel' : 'Lebensmittel'} zuhause im Vorrat',
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
                      hintText: 'Vorrat durchsuchen...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),

                // Categories Filter (if more than 1 category)
                if (availableCategories.length > 2)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: availableCategories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryGreen,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textDark,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                              ),
                            ),
                            showCheckmark: false,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Stock Items List
                Expanded(
                  child: filteredFoods.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🔍', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Keine Artikel gefunden',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Kein Vorratsartikel passt zu deiner Suche.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          itemCount: filteredFoods.length,
                          itemBuilder: (context, index) {
                            final food = filteredFoods[index];
                            final emoji = _getEmojiForCategory(food.category);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: DinoCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    // Emoji Avatar
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primarySoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                                    ),
                                    const SizedBox(width: 12),

                                    // Food Info: Name & Category
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
                                          const SizedBox(height: 2),
                                          Text(
                                            food.category,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quick Add to shopping list
                                    IconButton.filledTonal(
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.primarySoft,
                                        foregroundColor: AppTheme.primaryDark,
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
                                      ),
                                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                                      tooltip: 'Auf Einkaufsliste setzen',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AddEditItemDialog(preselectedFood: food),
                                        );
                                      },
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
    );
  }

  String _getEmojiForCategory(String category) {
    switch (category) {
      case 'Gemüse':
        return '🥦';
      case 'Obst':
        return '🍎';
      case 'Kartoffeln':
        return '🥔';
      case 'Fleisch':
        return '🥩';
      case 'Wurst':
        return '🥓';
      case 'Fisch':
        return '🐟';
      case 'Milchprodukte':
        return '🥛';
      case 'Käse':
        return '🧀';
      case 'Eier':
        return '🥚';
      case 'Brot & Backwaren':
        return '🍞';
      case 'Nudeln & Reis':
        return '🍝';
      case 'Konserven & Gläser':
        return '🥫';
      case 'Tiefkühl':
        return '🧊';
      case 'Gewürze':
        return '🧂';
      case 'Saucen':
        return '🍅';
      case 'Öle & Fette':
        return '🫒';
      case 'Frühstück':
        return '🥣';
      case 'Backen':
        return '🧁';
      case 'Getränke':
        return '🧃';
      case 'Snacks':
        return '🍿';
      default:
        return '🥑';
    }
  }
}
