import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food_icon.dart';
import '../../providers/food_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/dino_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/load_error_state.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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

    // Filter by name or note.
    final query = _searchQuery.trim().toLowerCase();
    final filteredFoods = inStockFoods.where((food) {
      return query.isEmpty ||
          food.name.toLowerCase().contains(query) ||
          (food.note?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mein Vorrat 📦')),
      body: stockProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stockProvider.errorMessage != null
          ? LoadErrorState(
              message: stockProvider.errorMessage!,
              onRetry: stockProvider.retryLoad,
            )
          : inStockFoods.isEmpty
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppTheme.primarySoft.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppTheme.primaryGreen,
                      ),
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
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textMuted,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
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
                                const Text(
                                  '🔍',
                                  style: TextStyle(fontSize: 40),
                                ),
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
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                  ),
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: DinoCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
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
                                      child: Text(
                                        FoodIconCatalog.emojiFor(food.iconKey),
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Food info: name and optional note
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

                                    // Stock Toggle Button (identical to FoodsScreen)
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
                                          color: AppTheme.primaryGreen,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Zuhause',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
}
