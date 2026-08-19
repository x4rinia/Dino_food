import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/dish_provider.dart';
import 'providers/food_provider.dart';
import 'providers/household_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/stock_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/set_new_password_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/household/welcome_household_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(const DinoFoodApp());
}

class DinoFoodApp extends StatelessWidget {
  const DinoFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HouseholdProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => DishProvider()),
      ],
      child: MaterialApp(
        title: 'Dino_food',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final householdProvider = Provider.of<HouseholdProvider>(context);
    final shoppingProvider = Provider.of<ShoppingProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final dishProvider = Provider.of<DishProvider>(context, listen: false);

    // 1. Initializing Auth -> Splash / Loading screen
    if (authProvider.isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/app_icon.jpg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // 2. Unconfigured Supabase -> Demo mode
    if (!SupabaseConfig.isConfigured) {
      return const MainNavigationScreen();
    }

    // 2.5 Password Recovery -> Set New Password Screen
    if (authProvider.isRecoveringPassword) {
      return const SetNewPasswordScreen();
    }

    // 3. Not Logged In -> Login Screen
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // 4. Logged In -> State-based household handling
    if (householdProvider.state == HouseholdState.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        householdProvider.loadHouseholds().then((_) {
          final current = householdProvider.currentHousehold;
          if (current != null) {
            shoppingProvider.bindToHousehold(current.id);
            stockProvider.bindToHousehold(current.id);
            dishProvider.loadDishes(current.id);
          }
        });
      });

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/app_icon.jpg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Lade Haushalt...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (householdProvider.state == HouseholdState.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/app_icon.jpg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Lade Haushalt...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (householdProvider.state == HouseholdState.error) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                const Text(
                  'Fehler beim Laden des Haushalts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  householdProvider.errorMessage ?? 'Unbekannter Verbindungsfehler.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    householdProvider.loadHouseholds(force: true).then((_) {
                      final current = householdProvider.currentHousehold;
                      if (current != null) {
                        shoppingProvider.bindToHousehold(current.id);
                        stockProvider.bindToHousehold(current.id);
                        dishProvider.loadDishes(current.id);
                      }
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    authProvider.signOut();
                    householdProvider.reset();
                  },
                  child: const Text('Abmelden', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 5. User has no household -> Show Welcome / Setup Screen
    if (!householdProvider.hasHousehold) {
      return const WelcomeHouseholdScreen();
    }

    // 6. User is logged in and has a household -> Main Screen
    return const MainNavigationScreen();
  }
}
