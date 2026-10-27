import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Efeitos sonoros do jogo (arquivos em assets/sounds, gerados pela GPLABS).
enum LigaSfx {
  toque('toque.wav'),
  jogar('jogar.wav'),
  acerto('acerto.wav'),
  erro('erro.wav'),
  vitoria('vitoria.wav'),
  bau('bau.wav');

  const LigaSfx(this.file);

  final String file;
}

/// Sons e vibração do jogo. A criança liga e desliga o som pelo botão da
/// Base; a escolha fica salva no aparelho.
class LigaSound {
  LigaSound._();

  /// Os testes desligam: lá não há plugin de áudio.
  static bool enabled = true;

  static const _prefsKey = 'som_ligado';

  /// Som ligado ou desligado pela criança.
  static final muted = ValueNotifier<bool>(false);

  static final _players = <LigaSfx, AudioPlayer>{};

  /// Lê a preferência salva. Chamado uma vez no início do app.
  static Future<void> load() async {
    if (!enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_prefsKey) == false;
    } catch (_) {
      // Sem preferência salva: fica com o som ligado.
    }
  }

  static Future<void> toggle() async {
    muted.value = !muted.value;
    if (!enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, !muted.value);
    } catch (_) {}
  }

  /// Toca o efeito e dá uma vibração curta combinando com ele.
  static void play(LigaSfx sfx) {
    if (!enabled) return;
    switch (sfx) {
      case LigaSfx.acerto || LigaSfx.jogar:
        HapticFeedback.lightImpact();
      case LigaSfx.erro:
        HapticFeedback.heavyImpact();
      case LigaSfx.vitoria || LigaSfx.bau:
        HapticFeedback.mediumImpact();
      case LigaSfx.toque:
        HapticFeedback.selectionClick();
    }
    if (muted.value) return;
    final player = _players.putIfAbsent(sfx, () {
      return AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
    });
    player
        .stop()
        .then((_) => player.play(AssetSource('sounds/${sfx.file}')))
        .catchError((Object _) {});
  }
}
