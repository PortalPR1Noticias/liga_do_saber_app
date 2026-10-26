import 'package:flutter/material.dart';

class LigaColors {
  static const primaryBlue = Color(0xFF2563EB);
  static const progressGreen = Color(0xFF22C55E);
  static const achievementYellow = Color(0xFFFACC15);
  static const actionCoral = Color(0xFFFB7185);
  static const adventurePurple = Color(0xFF8B5CF6);
  static const softWhite = Color(0xFFF8FAFC);
  static const textGraphite = Color(0xFF1F2937);
  static const deepBlue = Color(0xFF071B3A);
  static const deepPurple = Color(0xFF1E124D);
  static const cardDark = Color(0xFF111B3D);
  static const cyanGlow = Color(0xFF38BDF8);
}

class LigaTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LigaColors.primaryBlue,
      brightness: Brightness.light,
      primary: LigaColors.primaryBlue,
      secondary: LigaColors.adventurePurple,
      surface: LigaColors.softWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LigaColors.deepBlue,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1.05,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.08,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: Colors.white),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.3,
          color: Color(0xFFD8E2FF),
        ),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }
}
