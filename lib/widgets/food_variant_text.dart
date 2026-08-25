import 'package:flutter/material.dart';

/// Renders a food variant as `Name (note)` while italicizing only the note.
class FoodVariantText extends StatelessWidget {
  final String name;
  final String? note;
  final String suffix;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const FoodVariantText({
    super.key,
    required this.name,
    this.note,
    this.suffix = '',
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final trimmedNote = note?.trim();

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: trimmedName),
          if (trimmedNote != null && trimmedNote.isNotEmpty) ...[
            const TextSpan(text: ' ('),
            TextSpan(
              text: trimmedNote,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const TextSpan(text: ')'),
          ],
          if (suffix.isNotEmpty) TextSpan(text: suffix),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
