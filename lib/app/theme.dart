import 'package:flutter/material.dart';

/// Paleta da Liga, puxada da logo: azul, laranja e verde-água vivos com
/// contorno grosso azul-marinho, no estilo dos jogos de Roblox.
class LigaColors {
  static const primaryBlue = Color(0xFF1E6FE8);
  static const progressGreen = Color(0xFF22C55E);
  static const achievementYellow = Color(0xFFFFC233);
  static const actionCoral = Color(0xFFFF6B8B);
  static const adventurePurple = Color(0xFF9B5DE5);
  static const sunsetOrange = Color(0xFFFF8A1F);
  static const cyanGlow = Color(0xFF14CFA6);

  /// Texto principal (azul-marinho, mais suave que preto).
  static const ink = Color(0xFF0E2152);

  /// Texto secundário.
  static const inkSoft = Color(0xFF34406A);

  static const skyTop = Color(0xFF6CC4FF);
  static const skyBottom = Color(0xFFC4ECFF);
  static const cardWhite = Colors.white;
  static const disabled = Color(0xFFC9D2E3);

  /// Versão mais escura da cor, usada na "borda de baixo" dos botões 3D.
  static Color shade(Color color, [double amount = 0.18]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Contorno de texto (oito sombras sem desfoque), como nos títulos de jogo.
List<Shadow> ligaOutline([double width = 2, Color color = LigaColors.ink]) {
  return [
    for (final (dx, dy) in const [
      (-1.0, -1.0), (0.0, -1.0), (1.0, -1.0), (-1.0, 0.0), //
      (1.0, 0.0), (-1.0, 1.0), (0.0, 1.0), (1.0, 1.0),
    ])
      Shadow(color: color, offset: Offset(dx * width, dy * width)),
    // Sombra dura embaixo, dando volume.
    Shadow(color: color, offset: Offset(0, width * 2)),
  ];
}

/// Liga/desliga as animações contínuas (mascotes flutuando, fundo).
///
/// Os testes desligam para que `pumpAndSettle` termine.
class LigaMotion {
  static bool ambient = true;

  static bool of(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ambient && !reduce;
  }
}

class LigaTheme {
  static const bodyFont = 'Nunito';
  static const displayFont = 'Baloo2';

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LigaColors.primaryBlue,
      brightness: Brightness.light,
      primary: LigaColors.primaryBlue,
      secondary: LigaColors.adventurePurple,
      surface: LigaColors.cardWhite,
      onSurface: LigaColors.ink,
      error: LigaColors.actionCoral,
    );

    final chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(99),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LigaColors.skyTop,
      fontFamily: bodyFont,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: LigaColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: displayFont,
          fontSize: 24,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ).copyWith(shadows: _outline2),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: displayFont,
          fontSize: 36,
          height: 1.05,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: _outline3,
        ),
        headlineMedium: TextStyle(
          fontFamily: displayFont,
          fontSize: 28,
          height: 1.1,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: _outline2,
        ),
        titleLarge: const TextStyle(
          fontFamily: displayFont,
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: LigaColors.ink,
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          height: 1.2,
          fontWeight: FontWeight.w900,
          color: LigaColors.ink,
        ),
        bodyLarge: const TextStyle(
          fontSize: 17,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: LigaColors.ink,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: LigaColors.inkSoft,
        ),
        labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F8FF),
        labelStyle: const TextStyle(
          color: LigaColors.inkSoft,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: LigaColors.primaryBlue,
          fontWeight: FontWeight.w800,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFE11D48),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: _inputBorder(LigaColors.ink, 2.5),
        enabledBorder: _inputBorder(LigaColors.ink, 2.5),
        focusedBorder: _inputBorder(LigaColors.primaryBlue, 3),
        errorBorder: _inputBorder(LigaColors.actionCoral),
        focusedErrorBorder: _inputBorder(LigaColors.actionCoral, 3),
      ),
      chipTheme: ChipThemeData(
        shape: chipShape,
        side: const BorderSide(color: LigaColors.ink, width: 2.5),
        backgroundColor: Colors.white,
        selectedColor: LigaColors.achievementYellow,
        checkmarkColor: LigaColors.ink,
        labelStyle: const TextStyle(
          fontFamily: bodyFont,
          fontWeight: FontWeight.w800,
          color: LigaColors.ink,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w900),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? LigaColors.primaryBlue
                : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : LigaColors.ink,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: LigaColors.ink, width: 2.5),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LigaColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: bodyFont,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: LigaColors.achievementYellow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LigaColors.ink, width: 2.5),
        ),
        height: 74,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 28,
            color: states.contains(WidgetState.selected)
                ? LigaColors.ink
                : LigaColors.inkSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: bodyFont,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? LigaColors.ink
                : LigaColors.inkSoft,
          ),
        ),
      ),
    );
  }

  static final _outline2 = ligaOutline(2);
  static final _outline3 = ligaOutline(2.6);

  static OutlineInputBorder _inputBorder(Color color, [double width = 2]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
