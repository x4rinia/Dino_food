import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class HouseholdLoadErrorState extends StatelessWidget {
  const HouseholdLoadErrorState({
    super.key,
    required this.onRetry,
    this.onSignOut,
  });

  final VoidCallback onRetry;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/app_icon.jpg',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dino konnte deinen Haushalt gerade nicht laden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Versuch es bitte nochmal.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
            if (onSignOut != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSignOut,
                child: const Text(
                  'Abmelden',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
