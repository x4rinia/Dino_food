import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dish_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/stock_provider.dart';
import '../dishes/dishes_screen.dart';
import '../foods/foods_screen.dart';
import '../household/household_screen.dart';
import '../shopping_list/shopping_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ShoppingListScreen(),
    FoodsScreen(),
    DishesScreen(),
    HouseholdScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAppData();
    });
  }

  void _initAppData() async {
    final householdProvider = Provider.of<HouseholdProvider>(context, listen: false);
    final shoppingProvider = Provider.of<ShoppingProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final dishProvider = Provider.of<DishProvider>(context, listen: false);

    final current = householdProvider.currentHousehold;
    if (current != null) {
      shoppingProvider.bindToHousehold(current.id);
      stockProvider.bindToHousehold(current.id);
      foodProvider.bindToHousehold(current.id);
      dishProvider.loadDishes(current.id);
    } else {
      await foodProvider.loadFoods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Liste',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Lebensmittel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_outlined),
              activeIcon: Icon(Icons.restaurant),
              label: 'Gerichte',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Haushalt',
            ),
          ],
        ),
      ),
    );
  }
}
