import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/shopping_item.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/food_provider.dart';
import '../../widgets/dino_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/load_error_state.dart';
import 'add_edit_item_dialog.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  Widget build(BuildContext context) {
    final shoppingProvider = Provider.of<ShoppingProvider>(context);
    final activeHousehold = context.select(
      (HouseholdProvider provider) => provider.currentHousehold,
    );
    final activeItems = shoppingProvider.activeItems;
    final checkedItems = shoppingProvider.checkedItems;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Einkaufsliste 🛒'),
            if (activeHousehold != null)
              Text(
                'Haushalt: ${activeHousehold.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        ),
        actions: [
          if (checkedItems.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.cleaning_services_outlined,
                color: AppTheme.primaryGreen,
              ),
              tooltip: 'Erledigte in den Vorrat übernehmen',
              onPressed: () {
                _showClearCheckedDialog(context, shoppingProvider);
              },
            ),
        ],
      ),
      body: shoppingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shoppingProvider.errorMessage != null
          ? LoadErrorState(
              message: shoppingProvider.errorMessage!,
              onRetry: shoppingProvider.retryLoad,
            )
          : shoppingProvider.allItems.isEmpty
          ? EmptyState(
              emoji: '🦖',
              title: 'Deine Einkaufsliste ist leer',
              message: 'Füge Artikel hinzu oder wähle Zutaten aus deinen Lieblingsgerichten!',
              actionLabel: 'Artikel hinzufügen',
              onAction: () => _openAddItemDialog(context),
            )
          : RefreshIndicator(
              onRefresh: () async {
                if (activeHousehold != null) {
                  shoppingProvider.bindToHousehold(activeHousehold.id);
                }
              },
              child: CustomScrollView(
                slivers: [
                  const SliverPadding(padding: EdgeInsets.only(top: 12)),
                  if (activeItems.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              'Zu Kaufen (${activeItems.length})',
                              AppTheme.textDark,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: activeItems.length,
                        itemBuilder: (context, index) => _buildItemTile(
                          context,
                          activeItems[index],
                          shoppingProvider,
                          isChecked: false,
                        ),
                      ),
                    ),
                  ],
                  if (checkedItems.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(
                              'Erledigt (${checkedItems.length})',
                              AppTheme.textMuted,
                            ),
                            TextButton.icon(
                              onPressed: () => _showClearCheckedDialog(
                                context,
                                shoppingProvider,
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              icon: const Text(
                                '📦',
                                style: TextStyle(fontSize: 12),
                              ),
                              label: const Text(
                                'In Vorrat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: checkedItems.length,
                        itemBuilder: (context, index) => _buildItemTile(
                          context,
                          checkedItems[index],
                          shoppingProvider,
                          isChecked: true,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
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
            onPressed: () => _openAddItemDialog(context),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Artikel hinzufügen',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    ShoppingItem item,
    ShoppingProvider provider, {
    required bool isChecked,
  }) {
    final note = item.note?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppTheme.errorRed,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) {
          provider.deleteItem(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.displayName} gelöscht'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: DinoCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: isChecked
              ? AppTheme.checkedGray.withValues(alpha: 0.5)
              : Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              Transform.scale(
                scale: 1.15,
                child: Checkbox(
                  value: isChecked,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) {
                    if (val != null) {
                      provider.toggleItem(item.id, val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Item details (Tap to Edit)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddEditItemDialog(itemToEdit: item),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isChecked
                              ? AppTheme.textMuted
                              : AppTheme.textDark,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),

                      // The optional note remains underneath the name.
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isChecked
                                ? Colors.grey.shade400
                                : AppTheme.textMuted,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Shopping quantity stays compact and separate from the note.
              if (item.quantity != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isChecked
                            ? AppTheme.textMuted
                            : AppTheme.textDark,
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // Edit / More button
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  _showItemOptions(context, item, provider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddItemDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddEditItemDialog());
  }

  void _showItemOptions(
    BuildContext context,
    ShoppingItem item,
    ShoppingProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
              title: const Text('Artikel bearbeiten'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => AddEditItemDialog(itemToEdit: item),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorRed),
              title: const Text(
                'Artikel löschen',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteItem(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCheckedDialog(
    BuildContext context,
    ShoppingProvider provider,
  ) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('In den Vorrat übernehmen?'),
        content: const Text(
          'Möchtest du alle abgehakten Artikel in deinen Vorrat übertragen und von der Einkaufsliste entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final initialChecked = provider.checkedCount;
              final transferredCount = await provider.clearCheckedItems(
                stockProvider: stockProvider,
                foodProvider: foodProvider,
              );
              if (context.mounted) {
                if (transferredCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        transferredCount == 1
                            ? '1 Artikel wurde zum Vorrat hinzugefügt 📦'
                            : '$transferredCount Artikel wurden zum Vorrat hinzugefügt 📦',
                      ),
                      backgroundColor: AppTheme.primaryGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else if (initialChecked > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Artikel konnte nicht in den Vorrat übernommen werden.\nEr bleibt auf der Einkaufsliste.',
                      ),
                      backgroundColor: AppTheme.errorRed,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
  }
}
