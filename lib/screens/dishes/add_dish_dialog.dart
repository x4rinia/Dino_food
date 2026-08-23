import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/dish.dart';
import '../../models/food.dart';
import '../../providers/dish_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../widgets/food_variant_text.dart';
import '../foods/add_food_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.dishToEdit != null) {
      _nameController.text = widget.dishToEdit!.name;
      for (final item in widget.dishToEdit!.items) {
        _selectedIngredients.add({
          'food_id': item.foodId,
          'food_name': item.displayName,
          'food_note': item.food?.note,
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openCreateNewFood(
    BuildContext context, [
    String? initialName,
  ]) async {
    final newFood = await showDialog<Food>(
      context: context,
      builder: (_) => AddFoodDialog(initialName: initialName),
    );

    if (newFood != null && mounted) {
      setState(() {
        _tempSelectedFood = newFood;
        _autocompleteTextController?.text = newFood.name;
      });
    }
  }

  void _addIngredient() {
    final rawName = _autocompleteTextController?.text.trim() ?? '';
    final name = rawName.isNotEmpty ? rawName : (_tempSelectedFood?.name ?? '');
    if (name.isEmpty) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    // Check if matching catalog food exists
    Food? matchedFood;
    if (_tempSelectedFood != null) {
      matchedFood = _tempSelectedFood;
    } else {
      matchedFood = foodProvider.foods.where((f) {
        return f.name.toLowerCase().trim() == name.toLowerCase();
      }).firstOrNull;
    }

    if (matchedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Bitte wähle ein Lebensmittel aus der Liste oder lege es neu an.',
          ),
          backgroundColor: AppTheme.accentOrange,
          action: SnackBarAction(
            label: 'Neu anlegen',
            textColor: Colors.white,
            onPressed: () => _openCreateNewFood(context, name),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedIngredients.add({
        'food_id': matchedFood!.id,
        'food_name': matchedFood.name,
        'food_note': matchedFood.note,
      });
      _tempSelectedFood = null;
      _autocompleteTextController?.clear();
    });
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

    final householdProvider = Provider.of<HouseholdProvider>(
      context,
      listen: false,
    );
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
          content: Text(
            widget.dishToEdit != null
                ? 'Gericht "$name" erfolgreich aktualisiert!'
                : 'Gericht "$name" erfolgreich erstellt!',
          ),
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
                  child: Text(
                    isEditing ? '✏️' : '🍲',
                    style: const TextStyle(fontSize: 22),
                  ),
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
                prefixIcon: Icon(
                  Icons.restaurant_menu,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients Header
            const Text(
              'Zutaten zusammenstellen:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),

            // Add ingredient area
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
                        final query = textEditingValue.text.toLowerCase();
                        return option.name.toLowerCase().contains(query) ||
                            (option.note?.toLowerCase().contains(query) ??
                                false);
                      });
                    },
                    displayStringForOption: (Food option) =>
                        option.displayLabel,
                    onSelected: (Food selection) {
                      setState(() {
                        _tempSelectedFood = selection;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmitted) {
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
                              setState(() => _tempSelectedFood = null);
                            },
                            onSubmitted: (_) => _addIngredient(),
                          );
                        },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      label: const Text(
                        '+ Neues Lebensmittel anlegen',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      onPressed: () => _openCreateNewFood(
                        context,
                        _autocompleteTextController?.text.trim(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        onPressed:
                            ((_autocompleteTextController?.text
                                        .trim()
                                        .isNotEmpty ??
                                    false) ||
                                _tempSelectedFood != null)
                            ? _addIngredient
                            : null,
                        label: const Text('Zutat hinzufügen'),
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
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedIngredients.length,
                      itemBuilder: (context, index) {
                        final ing = _selectedIngredients[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FoodVariantText(
                                  name: ing['food_name'] as String? ?? 'Zutat',
                                  note: ing['food_note'] as String?,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppTheme.errorRed,
                                ),
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
                  child: const Text(
                    'Abbrechen',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
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
