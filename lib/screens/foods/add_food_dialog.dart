import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/food_provider.dart';
import '../../utils/string_extensions.dart';

class AddFoodDialog extends StatefulWidget {
  final String? initialName;

  const AddFoodDialog({super.key, this.initialName});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String _selectedCategory = 'Gemüse';
  bool _isSaving = false;

  final List<String> _categories = FoodProvider.standardCategories
      .where((cat) => cat != 'Alle')
      .toList();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final name = _nameController.text.trim().toCapitalized();

    setState(() => _isSaving = true);

    try {
      final newFood = await foodProvider.addCustomFood(
        name: name,
        category: _selectedCategory,
        defaultUnit: '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name zu den Lebensmitteln hinzugefügt! 🥕'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(newFood);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final raw = e.toString().replaceFirst('Exception: ', '');
        final msg = raw.contains('duplicate') || raw.contains('23505')
            ? 'Dieses Lebensmittel gibt es bereits.'
            : raw;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Speichern'),
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
