import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../providers/food_provider.dart';

/// Result type when the AddToCatalogDialog closes:
/// - category string if user clicked "Ja, hinzufügen"
/// - empty string '' if user clicked "Nein, nur einmalig verwenden"
/// - null if user canceled
class AddToCatalogDialog extends StatefulWidget {
  final String foodName;

  const AddToCatalogDialog({
    super.key,
    required this.foodName,
  });

  /// Helper static method to show this dialog and return the decision
  /// Returns:
  /// - `AddToCatalogResult.addToCatalog(category)`
  /// - `AddToCatalogResult.useOnce()`
  /// - `AddToCatalogResult.cancel()`
  static Future<AddToCatalogDecision?> show(BuildContext context, String foodName) {
    return showDialog<AddToCatalogDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddToCatalogDialog(foodName: foodName),
    );
  }

  @override
  State<AddToCatalogDialog> createState() => _AddToCatalogDialogState();
}

enum AddToCatalogAction {
  addToCatalog,
  useOnce,
  cancel,
}

class AddToCatalogDecision {
  final AddToCatalogAction action;
  final String category;

  const AddToCatalogDecision({
    required this.action,
    this.category = 'Gemüse',
  });

  bool get shouldAddToCatalog => action == AddToCatalogAction.addToCatalog;
  bool get shouldUseOnce => action == AddToCatalogAction.useOnce;
  bool get isCanceled => action == AddToCatalogAction.cancel;
}

class _AddToCatalogDialogState extends State<AddToCatalogDialog> {
  String _selectedCategory = 'Gemüse';

  final List<String> _categories = FoodProvider.standardCategories
      .where((cat) => cat != 'Alle')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
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
                    'Zum Katalog hinzufügen?',
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
                style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4),
                children: [
                  const TextSpan(text: '„'),
                  TextSpan(
                    text: widget.foodName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ),
                  const TextSpan(
                    text: '“ ist noch nicht im Lebensmittel-Katalog vorhanden.\n\nMöchtest du es dauerhaft zum Katalog hinzufügen?',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Category selector
            DropdownButtonFormField<String>(
              key: const ValueKey('category_dropdown'),
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategorie (für den Katalog)',
                prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textMuted, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 24),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Option 1: Yes, add to catalog
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    'Ja, zum Katalog hinzufügen',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(AddToCatalogDecision(
                      action: AddToCatalogAction.addToCatalog,
                      category: _selectedCategory,
                    ));
                  },
                ),
                const SizedBox(height: 8),

                // Option 2: No, use only once
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textDark,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(const AddToCatalogDecision(
                      action: AddToCatalogAction.useOnce,
                    ));
                  },
                  child: const Text(
                    'Nein, nur einmalig verwenden',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),

                // Option 3: Cancel
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(const AddToCatalogDecision(
                      action: AddToCatalogAction.cancel,
                    ));
                  },
                  child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
