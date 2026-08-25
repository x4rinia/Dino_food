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

  @override
  Widget build(BuildContext context) {
    return Text(
      '${item.displayName.trim()}$suffix',
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
