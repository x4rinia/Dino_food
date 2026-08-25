import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food.dart';
import '../../models/shopping_item.dart';
import '../../providers/food_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../utils/string_extensions.dart';
import '../../widgets/add_to_foods_prompt_dialog.dart';
import '../foods/add_food_dialog.dart';

class AddEditItemDialog extends StatefulWidget {
  final ShoppingItem? itemToEdit;
  final Food? preselectedFood;
  final int? suggestedQuantity;

  const AddEditItemDialog({
    super.key,
    this.itemToEdit,
    this.preselectedFood,
    this.suggestedQuantity,
  });

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _quantityController = TextEditingController();
  Food? _selectedFood;
  TextEditingController? _autocompleteController;
  bool _resolvedLinkedFood = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.displayName;
      _noteController.text = widget.itemToEdit!.note ?? '';
      _quantityController.text =
          widget.suggestedQuantity?.toString() ??
          widget.itemToEdit!.quantity?.toString() ??
          '';
      _selectedFood = widget.itemToEdit!.food;
    } else if (widget.preselectedFood != null) {
      _selectedFood = widget.preselectedFood;
      _nameController.text = widget.preselectedFood!.name;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedLinkedFood || _selectedFood != null) return;
    _resolvedLinkedFood = true;
    final foodId = widget.itemToEdit?.foodId;
    if (foodId == null) return;
    _selectedFood = context
        .read<FoodProvider>()
        .foods
        .where((food) => food.id == foodId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _quantityController.dispose();
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
        _selectedFood = newFood;
        _nameController.text = newFood.name;
        _autocompleteController?.text = newFood.name;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final shoppingProvider = Provider.of<ShoppingProvider>(
      context,
      listen: false,
    );
    final name = _nameController.text.trim().toCapitalized();
    final note = _noteController.text.trim().toCapitalized();
    final quantityText = _quantityController.text.trim();
    final quantity = quantityText.isEmpty ? null : int.parse(quantityText);

    // 1. Check if the food exists in catalog (case-insensitive)
    Food? matchedFood;
    if (_selectedFood != null &&
        _selectedFood!.name.toLowerCase().trim() == name.toLowerCase()) {
      matchedFood = _selectedFood;
    } else {
      matchedFood = foodProvider.foods.where((f) {
        return f.name.toLowerCase().trim() == name.toLowerCase();
      }).firstOrNull;
    }

    String? finalFoodId = matchedFood?.id;
    String finalCustomName = matchedFood?.name ?? name;

    // 2. If new item and NOT in foods catalog -> Prompt user (Nur Einkaufsliste vs Lebensmittel hinzufügen)
    if (matchedFood == null && widget.itemToEdit == null) {
      final decision = await AddToFoodsPromptDialog.show(context, name);
      if (!mounted) return;

      if (decision == null || decision.isCanceled) {
        return; // Stay in dialog
      }

      if (decision.isAddToFoods) {
        final newFood = await foodProvider.addCustomFood(
          name: name,
          note: decision.note,
          iconKey: decision.iconKey,
        );
        finalFoodId = newFood.id;
        finalCustomName = newFood.name;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name zu den Lebensmitteln hinzugefügt! 🥦'),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (decision.isOnlyShoppingList) {
        // Pure free-text entry on shopping list only
        finalFoodId = null;
        finalCustomName = name;
      }
    }

    bool success = false;
    if (widget.itemToEdit != null) {
      success = await shoppingProvider.updateItem(
        itemId: widget.itemToEdit!.id,
        customName: finalCustomName,
        note: note.isNotEmpty ? note : null,
        quantity: quantity,
        replaceQuantity: true,
      );
    } else {
      success = await shoppingProvider.addItem(
        foodId: finalFoodId,
        food: matchedFood,
        customName: finalCustomName,
        note: note.isNotEmpty ? note : null,
        quantity: quantity,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shoppingProvider.lastMutationError ??
                shoppingProvider.errorMessage ??
                'Fehler beim Speichern des Artikels.',
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final isEditing = widget.itemToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isEditing ? '✏️' : '🛒',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Artikel bearbeiten' : 'Artikel hinzufügen',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Item Name with AutoComplete from Food Catalog
                Autocomplete<Food>(
                  initialValue: TextEditingValue(text: _nameController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Food>.empty();
                    }
                    return foodProvider.foods.where((Food option) {
                      final query = textEditingValue.text.toLowerCase();
                      return option.name.toLowerCase().contains(query) ||
                          (option.note?.toLowerCase().contains(query) ?? false);
                    });
                  },
                  displayStringForOption: (Food option) =>
                      option.note == null || option.note!.trim().isEmpty
                      ? option.name
                      : '${option.name} — ${option.note}',
                  onSelected: (Food selection) {
                    setState(() {
                      _selectedFood = selection;
                      _nameController.text = selection.name;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _autocompleteController = controller;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Lebensmittel *',
                            hintText: 'z. B. Milch oder Tomaten',
                            prefixIcon: Icon(
                              Icons.shopping_basket_outlined,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Bitte Name eingeben';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            _nameController.text = val;
                            _selectedFood = null;
                          },
                        );
                      },
                ),

                // Create new food button if not in list
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
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
                      _nameController.text.trim(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (_selectedFood?.note?.trim().isNotEmpty ?? false) ...[
                  TextFormField(
                    key: ValueKey(
                      'food-note-${_selectedFood!.id}-${_selectedFood!.note}',
                    ),
                    initialValue: _selectedFood!.note!.trim(),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Lebensmittel-Notiz',
                      prefixIcon: Icon(
                        Icons.label_outline,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Note (optional text)
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Einkaufslisten-Notiz (optional)',
                    hintText: 'z. B. Im Angebot nehmen',
                    prefixIcon: Icon(
                      Icons.note_alt_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Anzahl (optional)',
                    hintText: 'z. B. 2',
                    prefixIcon: Icon(Icons.numbers, color: AppTheme.textMuted),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final parsed = int.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      return 'Bitte eine positive ganze Zahl eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Actions
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
                      child: Text(isEditing ? 'Speichern' : 'Hinzufügen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
