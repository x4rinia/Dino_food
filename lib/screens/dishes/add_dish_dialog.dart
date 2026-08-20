import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/dish.dart';
import '../../models/food.dart';
import '../../providers/dish_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../utils/string_extensions.dart';
import '../../widgets/add_to_catalog_dialog.dart';

class AddDishDialog extends StatefulWidget {
  final Dish? dishToEdit;

  const AddDishDialog({super.key, this.dishToEdit});

  @override
  State<AddDishDialog> createState() => _AddDishDialogState();
}

class _AddDishDialogState extends State<AddDishDialog> {
  final _nameController = TextEditingController();
  final List<Map<String, dynamic>> _selectedIngredients = [];

  Food? _tempSelectedFood;
  TextEditingController? _autocompleteTextController;
  final _tempQuantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    if (widget.dishToEdit != null) {
      _nameController.text = widget.dishToEdit!.name;
      for (final item in widget.dishToEdit!.items) {
        _selectedIngredients.add({
          'food_id': item.foodId,
          'food_name': item.displayName,
          'custom_name': item.customName,
          'quantity': item.quantity,
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tempQuantityController.dispose();
    super.dispose();
  }

  void _addIngredient() async {
    final rawName = _autocompleteTextController?.text.trim() ?? '';
    final name = rawName.isNotEmpty ? rawName.toCapitalized() : (_tempSelectedFood?.name ?? '');
    if (name.isEmpty) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final rawQty = _tempQuantityController.text.trim().replaceAll(',', '.');
    final qty = double.tryParse(rawQty) ?? 1.0;
    final finalQty = qty > 0 ? qty : 1.0;

    // Check if matching catalog food exists
    Food? matchedFood;
    if (_tempSelectedFood != null && _tempSelectedFood!.name.toLowerCase().trim() == name.toLowerCase()) {
      matchedFood = _tempSelectedFood;
    } else {
      matchedFood = foodProvider.foods.where((f) {
        return f.name.toLowerCase().trim() == name.toLowerCase();
      }).firstOrNull;
    }

    if (matchedFood != null) {
      setState(() {
        _selectedIngredients.add({
          'food_id': matchedFood!.id,
          'food_name': matchedFood.name,
          'quantity': finalQty,
        });
        _tempSelectedFood = null;
        _autocompleteTextController?.clear();
        _tempQuantityController.text = '1';
      });
      return;
    }

    // Food is not in catalog -> Ask user with AddToCatalogDialog
    final decision = await AddToCatalogDialog.show(context, name);
    if (!mounted) return;

    if (decision == null || decision.isCanceled) {
      return; // Stay in dialog
    }

    if (decision.shouldAddToCatalog) {
      final newFood = await foodProvider.addCustomFood(
        name: name,
        category: decision.category,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name zum Katalog hinzugefügt! 🥦'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _selectedIngredients.add({
          'food_id': newFood.id,
          'food_name': newFood.name,
          'quantity': finalQty,
        });
        _tempSelectedFood = null;
        _autocompleteTextController?.clear();
        _tempQuantityController.text = '1';
      });
    } else if (decision.shouldUseOnce) {
      setState(() {
        _selectedIngredients.add({
          'food_id': null,
          'food_name': name,
          'custom_name': name,
          'quantity': finalQty,
        });
        _tempSelectedFood = null;
        _autocompleteTextController?.clear();
        _tempQuantityController.text = '1';
      });
    }
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Name des Gerichts eingeben')),
      );
      return;
    }

    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens eine Zutat hinzufügen')),
      );
      return;
    }

    final householdProvider = Provider.of<HouseholdProvider>(context, listen: false);
    final dishProvider = Provider.of<DishProvider>(context, listen: false);
    final householdId = householdProvider.currentHousehold?.id ?? '';

    bool success;
    if (widget.dishToEdit != null) {
      success = await dishProvider.updateDish(
        dishId: widget.dishToEdit!.id,
        name: name,
        items: _selectedIngredients,
      );
    } else {
      success = await dishProvider.createDish(
        householdId: householdId,
        name: name,
        items: _selectedIngredients,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.dishToEdit != null
              ? 'Gericht "$name" erfolgreich aktualisiert!'
              : 'Gericht "$name" erfolgreich erstellt!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final isEditing = widget.dishToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(isEditing ? '✏️' : '🍲', style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Gericht bearbeiten' : 'Neues Gericht anlegen',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dish Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name des Gerichts *',
                hintText: 'z. B. Spaghetti Bolognese',
                prefixIcon: Icon(Icons.restaurant_menu, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients Header
            const Text(
              'Zutaten zusammenstellen:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),

            // Add Ingredient Area: Lebensmittel + Anzahl
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Autocomplete<Food>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Food>.empty();
                      }
                      return foodProvider.foods.where((Food option) {
                        return option.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (Food option) => option.name,
                    onSelected: (Food selection) {
                      setState(() {
                        _tempSelectedFood = selection;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      _autocompleteTextController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Zutat suchen (z. B. Tomaten)...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                        onSubmitted: (_) => _addIngredient(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity input
                      Expanded(
                        child: TextField(
                          controller: _tempQuantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Anzahl',
                            hintText: 'z. B. 4',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addIngredient(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: ((_autocompleteTextController?.text.trim().isNotEmpty ?? false) || _tempSelectedFood != null)
                            ? _addIngredient
                            : null,
                        child: const Text('Zutat hinzufügen'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // List of added ingredients
            Expanded(
              child: _selectedIngredients.isEmpty
                  ? Center(
                      child: Text(
                        'Noch keine Zutaten hinzugefügt.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedIngredients.length,
                      itemBuilder: (context, index) {
                        final ing = _selectedIngredients[index];
                        final dynamic qty = ing['quantity'];
                        final String qtyStr = (qty is num)
                            ? (qty == qty.roundToDouble()
                                ? qty.toInt().toString()
                                : qty.toString().replaceAll('.', ','))
                            : (qty?.toString() ?? '1');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Text('•', style: TextStyle(fontSize: 18, color: AppTheme.primaryGreen)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ing['food_name'] ?? 'Zutat',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppTheme.errorRed),
                                onPressed: () {
                                  setState(() {
                                    _selectedIngredients.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Speichern' : 'Gericht anlegen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
