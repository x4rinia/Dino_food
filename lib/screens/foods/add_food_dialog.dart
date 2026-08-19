import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/food_provider.dart';

class AddFoodDialog extends StatefulWidget {
  const AddFoodDialog({super.key});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCategory = 'Gemüse';

  final List<String> _categories = [
    'Gemüse',
    'Obst',
    'Kartoffeln',
    'Fleisch',
    'Wurst',
    'Fisch',
    'Milchprodukte',
    'Käse',
    'Eier',
    'Brot & Backwaren',
    'Nudeln & Reis',
    'Konserven & Gläser',
    'Tiefkühl',
    'Gewürze',
    'Saucen',
    'Öle & Fette',
    'Frühstück',
    'Backen',
    'Getränke',
    'Snacks',
    'Sonstiges',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    await foodProvider.addCustomFood(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      defaultUnit: '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text.trim()} zum Katalog hinzugefügt!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🥦', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Neues Lebensmittel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Food Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name des Lebensmittels *',
                  hintText: 'z. B. Paprika rot',
                  prefixIcon: Icon(Icons.fastfood_outlined, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Name eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textMuted),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 24),

              // Buttons
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
                    child: const Text('Speichern'),
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
