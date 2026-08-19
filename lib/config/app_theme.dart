import 'package:flutter/material.dart';

class AppTheme {
  // Dino_food Palette
  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primarySoft = Color(0xFFD8F3DC);
  static const Color primaryDark = Color(0xFF1B4332);

  static const Color accentOrange = Color(0xFFF4A261);
  static const Color accentYellow = Color(0xFFE9C46A);
  static const Color textDark = Color(0xFF212529);
  static const Color textMuted = Color(0xFF6C757D);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceWhite = Colors.white;
  static const Color checkedGray = Color(0xFFE9ECEF);
  static const Color errorRed = Color(0xFFE63946);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentOrange,
        surface: surfaceWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}
