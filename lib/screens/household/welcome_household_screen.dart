import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dish_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/stock_provider.dart';
import 'create_or_join_household_dialog.dart';

class WelcomeHouseholdScreen extends StatelessWidget {
  const WelcomeHouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final householdProvider = Provider.of<HouseholdProvider>(context);
    final shoppingProvider = Provider.of<ShoppingProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final dishProvider = Provider.of<DishProvider>(context, listen: false);

    final displayName = authProvider.profile?.displayName ??
        authProvider.currentUser?.email?.split('@').first ??
        'Dino-Freund';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dino_food 🦕'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textMuted),
            tooltip: 'Abmelden',
            onPressed: () {
              authProvider.signOut();
              householdProvider.reset();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dino Avatar
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryLight.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Willkommen bei Dino_food,\n$displayName! 👋',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Du bist aktuell noch keinem Haushalt zugeordnet. Erstelle einen neuen Haushalt oder tritt einem bestehenden per Einladungscode bei.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                // Button: Haushalt erstellen
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => const CreateOrJoinHouseholdDialog(isJoining: false),
                      );
                      if (result == true && householdProvider.currentHousehold != null) {
                        final active = householdProvider.currentHousehold!;
                        shoppingProvider.bindToHousehold(active.id);
                        stockProvider.bindToHousehold(active.id);
                        foodProvider.bindToHousehold(active.id);
                        dishProvider.loadDishes(active.id);
                      }
                    },
                    icon: const Icon(Icons.add_home_outlined),
                    label: const Text(
                      'Haushalt erstellen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Or Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'oder',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 14),

                // Button: Einladungscode eingeben
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => const CreateOrJoinHouseholdDialog(isJoining: true),
                      );
                      if (result == true && householdProvider.currentHousehold != null) {
                        final active = householdProvider.currentHousehold!;
                        shoppingProvider.bindToHousehold(active.id);
                        stockProvider.bindToHousehold(active.id);
                        foodProvider.bindToHousehold(active.id);
                        dishProvider.loadDishes(active.id);
                      }
                    },
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text(
                      'Einladungscode eingeben',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Refresh / Status Check Button
                Center(
                  child: TextButton.icon(
                    onPressed: () => householdProvider.loadHouseholds(force: true),
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.textMuted),
                    label: const Text(
                      'Status aktualisieren',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
