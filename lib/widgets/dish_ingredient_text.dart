import 'package:flutter/material.dart';

import '../models/dish_item.dart';

/// Renders a dish ingredient by name only, without its food variant note.
class DishIngredientText extends StatelessWidget {
  final DishItem item;
  final String suffix;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const DishIngredientText({
    super.key,
    required this.item,
    this.suffix = '',
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  String get _nameOnly {
    final foodName = item.food?.name.trim();
    if (foodName != null && foodName.isNotEmpty) return foodName;

    final displayName = item.displayName.trim();
    final legacyLabel = RegExp(r'^(.*?)\s*\([^()]*\)\s*$')
        .firstMatch(displayName);
    final nameWithoutLegacyNote = legacyLabel?.group(1)?.trim();
    return nameWithoutLegacyNote == null || nameWithoutLegacyNote.isEmpty
        ? displayName
        : nameWithoutLegacyNote;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_nameOnly$suffix',
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
