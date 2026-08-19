import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/food.dart';
import '../../models/shopping_item.dart';
import '../../providers/food_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../utils/string_extensions.dart';

class AddEditItemDialog extends StatefulWidget {
  final ShoppingItem? itemToEdit;
  final Food? preselectedFood;

  const AddEditItemDialog({
    super.key,
    this.itemToEdit,
    this.preselectedFood,
  });

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  Food? _selectedFood;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.customName ?? widget.itemToEdit!.displayName;
      _quantityController.text = widget.itemToEdit!.formattedQuantity;
      _noteController.text = widget.itemToEdit!.note ?? '';
      _selectedFood = widget.itemToEdit!.food;
    } else if (widget.preselectedFood != null) {
      _selectedFood = widget.preselectedFood;
      _nameController.text = widget.preselectedFood!.name;
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final shoppingProvider = Provider.of<ShoppingProvider>(context, listen: false);
    final name = _nameController.text.toCapitalized();
    final note = _noteController.text.toCapitalized();

    final rawQty = _quantityController.text.trim().replaceAll(',', '.');
    final quantity = double.tryParse(rawQty) ?? 1.0;

    if (widget.itemToEdit != null) {
      shoppingProvider.updateItem(
        itemId: widget.itemToEdit!.id,
        customName: name,
        quantity: quantity,
        note: note.isNotEmpty ? note : null,
      );
    } else {
      shoppingProvider.addItem(
        foodId: _selectedFood?.id,
        customName: name,
        quantity: quantity,
        note: note.isNotEmpty ? note : null,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final isEditing = widget.itemToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    return option.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                displayStringForOption: (Food option) => option.name,
                onSelected: (Food selection) {
                  setState(() {
                    _selectedFood = selection;
                    _nameController.text = selection.name;
                  });
                },
                fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                  fieldTextEditingController.addListener(() {
                    _nameController.text = fieldTextEditingController.text;
                  });

                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Artikelname *',
                      hintText: 'z. B. Milch oder Katzenfutter',
                      prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppTheme.textMuted),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte Name eingeben';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 14),

              // 2. Quantity (optional number)
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Menge (optional)',
                  hintText: 'z. B. 2 oder 4',
                  prefixIcon: Icon(Icons.format_list_numbered, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Note (optional text)
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Notiz (optional)',
                  hintText: 'z. B. laktosefrei oder Cherrytomaten',
                  prefixIcon: Icon(Icons.note_alt_outlined, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
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
                    child: Text(isEditing ? 'Speichern' : 'Hinzufügen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
