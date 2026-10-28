import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tamanho do texto escolhido em Acessibilidade. Soma com o do aparelho.
enum LigaTextSize {
  normal('Normal', 1.0),
  grande('Grande', 1.15),
  muitoGrande('Muito grande', 1.3);

  const LigaTextSize(this.label, this.scale);

  final String label;
  final double scale;
}

/// Opções de acessibilidade do app, salvas no aparelho.
@immutable
class LigaAccessibilitySettings {
  const LigaAccessibilitySettings({
    this.textSize = LigaTextSize.normal,
    this.reduceMotion = false,
    this.autoRead = false,
    this.vibration = true,
  });

  final LigaTextSize textSize;

  /// Para as animações contínuas (heróis flutuando, brilhos, pulsos).
  final bool reduceMotion;

  /// O herói lê a explicação sozinho assim que ela aparece.
  final bool autoRead;

  /// Vibração nos acertos, erros e toques.
  final bool vibration;

  LigaAccessibilitySettings copyWith({
    LigaTextSize? textSize,
    bool? reduceMotion,
    bool? autoRead,
    bool? vibration,
  }) {
    return LigaAccessibilitySettings(
      textSize: textSize ?? this.textSize,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      autoRead: autoRead ?? this.autoRead,
      vibration: vibration ?? this.vibration,
    );
  }
}

class LigaAccessibility {
  LigaAccessibility._();

  static final settings = ValueNotifier(const LigaAccessibilitySettings());

  static const _prefix = 'acessibilidade_';

  /// O texto nunca passa disso, nem somando o tamanho do aparelho, para os
  /// botões e cartões não quebrarem.
  static const maxTextScale = 2.0;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      settings.value = LigaAccessibilitySettings(
        textSize:
            LigaTextSize.values.asNameMap()[prefs.getString(
              '${_prefix}texto',
            )] ??
            LigaTextSize.normal,
        reduceMotion: prefs.getBool('${_prefix}menos_movimento') ?? false,
        autoRead: prefs.getBool('${_prefix}leitura_automatica') ?? false,
        vibration: prefs.getBool('${_prefix}vibracao') ?? true,
      );
    } catch (_) {
      // Sem preferências salvas: fica com o padrão.
    }
  }

  static Future<void> update(LigaAccessibilitySettings value) async {
    settings.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefix}texto', value.textSize.name);
      await prefs.setBool('${_prefix}menos_movimento', value.reduceMotion);
      await prefs.setBool('${_prefix}leitura_automatica', value.autoRead);
      await prefs.setBool('${_prefix}vibracao', value.vibration);
    } catch (_) {}
  }

  /// Aplica as opções no app inteiro (usado no `builder` do MaterialApp).
  static Widget apply(BuildContext context, Widget? child) {
    return ValueListenableBuilder<LigaAccessibilitySettings>(
      valueListenable: settings,
      builder: (context, value, _) {
        final media = MediaQuery.of(context);
        final scaler = media.textScaler.clamp(
          maxScaleFactor: maxTextScale / value.textSize.scale,
        );
        return MediaQuery(
          data: media.copyWith(
            textScaler: _CombinedScaler(scaler, value.textSize.scale),
            disableAnimations: media.disableAnimations || value.reduceMotion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Escala do aparelho vezes a escolhida no app.
class _CombinedScaler extends TextScaler {
  const _CombinedScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.scale(14) / 14 * factor;

  @override
  bool operator ==(Object other) =>
      other is _CombinedScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
