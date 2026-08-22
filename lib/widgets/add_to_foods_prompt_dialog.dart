import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/food_icon.dart';
import 'food_icon_picker.dart';

enum AddToFoodsAction { onlyShoppingList, addToFoods, cancel }

class AddToFoodsDecision {
  final AddToFoodsAction action;
  final String? note;
  final String? iconKey;

  const AddToFoodsDecision({required this.action, this.note, this.iconKey});

  bool get isOnlyShoppingList => action == AddToFoodsAction.onlyShoppingList;
  bool get isAddToFoods => action == AddToFoodsAction.addToFoods;
  bool get isCanceled => action == AddToFoodsAction.cancel;
}

class AddToFoodsPromptDialog extends StatefulWidget {
  final String foodName;

  const AddToFoodsPromptDialog({super.key, required this.foodName});

  static Future<AddToFoodsDecision?> show(
    BuildContext context,
    String foodName,
  ) {
    return showDialog<AddToFoodsDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddToFoodsPromptDialog(foodName: foodName),
    );
  }

  @override
  State<AddToFoodsPromptDialog> createState() => _AddToFoodsPromptDialogState();
}

class _AddToFoodsPromptDialogState extends State<AddToFoodsPromptDialog> {
  final _noteController = TextEditingController();
  String _selectedIconKey = FoodIconCatalog.fallbackKey;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
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
                    child: const Text('🥦', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Zu Lebensmitteln hinzufügen?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: '„'),
                    TextSpan(
                      text: widget.foodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const TextSpan(
                      text: '“ gibt es noch nicht in deinen Lebensmitteln.\n\nMöchtest du es auch zur Lebensmittel-Liste hinzufügen?',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Notiz (optional)',
                  hintText: 'z. B. Basmati',
                  prefixIcon: Icon(
                    Icons.notes_outlined,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FoodIconPicker(
                selectedKey: _selectedIconKey,
                onSelected: (key) => setState(() => _selectedIconKey = key),
              ),
              const SizedBox(height: 22),

              // Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Option A: Add to permanent foods list
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Lebensmittel hinzufügen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(
                        AddToFoodsDecision(
                          action: AddToFoodsAction.addToFoods,
                          note: _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim(),
                          iconKey: _selectedIconKey,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option B: Only shopping list (pure free-text)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(
                        const AddToFoodsDecision(
                          action: AddToFoodsAction.onlyShoppingList,
                        ),
                      );
                    },
                    child: const Text(
                      'Nur Einkaufsliste',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Option C: Cancel
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        const AddToFoodsDecision(
                          action: AddToFoodsAction.cancel,
                        ),
                      );
                    },
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
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
