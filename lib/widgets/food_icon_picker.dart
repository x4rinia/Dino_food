import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/food_icon.dart';

class FoodIconPicker extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const FoodIconPicker({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Symbol (optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 102,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: FoodIconCatalog.options.length,
            itemBuilder: (context, index) {
              final option = FoodIconCatalog.options[index];
              final isSelected = option.key == selectedKey;
              return Semantics(
                label: option.semanticLabel,
                selected: isSelected,
                button: true,
                child: InkWell(
                  key: ValueKey('food-icon-${option.key}'),
                  onTap: () => onSelected(option.key),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primarySoft
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
