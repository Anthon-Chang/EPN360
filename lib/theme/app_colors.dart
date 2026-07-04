import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color epnBlue = Color(0xFF1A4B7C);
  static const Color epnRed = Color(0xFFA62B2B);
  static const Color epnGold = Color(0xFFC5A059);
  static const Color epnBgLight = Color(0xFFF8F9FA);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.epnBlue,
    primary: AppColors.epnBlue,
    secondary: AppColors.epnGold,
    error: AppColors.epnRed,
    surface: AppColors.epnBgLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.epnBgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.epnBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.epnBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.epnGold,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.epnBlue, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.epnBlue,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
