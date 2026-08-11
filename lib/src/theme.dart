import 'package:flutter/material.dart';

abstract final class SeatColors {
  static const background = Color(0xFFF7F2E9),
      secondaryBackground = Color(0xFFEEE7DB),
      surface = Color(0xFFFFFCF7),
      primaryText = Color(0xFF24211F),
      secondaryText = Color(0xFF68615B),
      accent = Color(0xFFB65F43),
      success = Color(0xFF47725B),
      warning = Color(0xFF9A651F),
      destructive = Color(0xFFA33D35),
      divider = Color(0xFFD9D1C6);
}

ThemeData seatTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: SeatColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: SeatColors.accent,
    brightness: Brightness.light,
    surface: SeatColors.surface,
    error: SeatColors.destructive,
  ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: SeatColors.primaryText,
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: SeatColors.primaryText,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: SeatColors.primaryText,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: SeatColors.primaryText,
    ),
    bodyLarge: TextStyle(fontSize: 17, color: SeatColors.primaryText),
    bodyMedium: TextStyle(fontSize: 15, color: SeatColors.secondaryText),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SeatColors.background,
    foregroundColor: SeatColors.primaryText,
    elevation: 0,
  ),
  cardTheme: const CardThemeData(
    color: SeatColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: SeatColors.accent,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SeatColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SeatColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SeatColors.divider),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: SeatColors.surface,
    indicatorColor: SeatColors.accent.withValues(alpha: .12),
    height: 74,
  ),
);
