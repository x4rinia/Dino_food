import 'package:flutter/material.dart';

class DinoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Border? border;

  const DinoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }

    return card;
  }
}
