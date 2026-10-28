import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/theme.dart';
import '../services/app_repository.dart';
import 'liga_accessibility.dart';
import 'liga_mascots.dart';

/// Voz dos heróis: as explicações viram áudio com a voz de cada herói
/// (Edge Function `voz-heroi`, text-to-speech da OpenAI). O texto continua
/// na tela; o áudio só é gerado quando a criança toca em "Ouvir".
class LigaVoice {
  LigaVoice._();

  /// Os testes desligam o tocador: lá não há plugin de áudio.
  static bool enabled = true;

  /// A Edge Function aceita até 1200 caracteres por áudio.
  static const maxChars = 1200;

  /// Qual fala está carregando ou tocando agora (só uma por vez).
  static final current = ValueNotifier<LigaVoiceState?>(null);

  /// Áudios já gerados nesta sessão: ouvir de novo não paga outra vez.
  static final _cache = <String, Uint8List>{};
  static const _cacheSize = 30;

  static AudioPlayer? _player;

  /// Junta os trechos numa fala só, com pausa entre eles, e corta no fim de
  /// uma frase se passar do limite.
  static String speakable(List<String> lines) {
    final parts = <String>[];
    for (final line in lines) {
      final text = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) continue;
      parts.add(RegExp(r'[.!?:;…]$').hasMatch(text) ? text : '$text.');
    }
    var speech = parts.join(' ');
    if (speech.length <= maxChars) return speech;
    speech = speech.substring(0, maxChars);
    final end = speech.lastIndexOf(RegExp(r'[.!?]\s'));
    return end > maxChars ~/ 2 ? speech.substring(0, end + 1) : speech;
  }

  /// Toca a fala do herói. Tocar a mesma fala de novo para.
  static Future<void> speak(LigaCharacter hero, String text) async {
    final key = '${hero.id}|$text';
    if (current.value?.key == key) {
      await stop();
      return;
    }
    await stop();
    current.value = LigaVoiceState(key, playing: false);
    try {
      final audio =
          _cache[key] ??
          await AppRepository.instance.heroVoice(
            characterId: hero.id,
            text: text,
          );
      _remember(key, audio);
      if (current.value?.key != key) return;
      current.value = LigaVoiceState(key, playing: true);
      if (!enabled) return;
      await _play(audio);
    } on AppRepositoryException catch (error) {
      if (current.value?.key == key) {
        current.value = LigaVoiceState(
          key,
          playing: false,
          error: error.message,
        );
      }
    } catch (_) {
      if (current.value?.key == key) {
        current.value = LigaVoiceState(
          key,
          playing: false,
          error: 'Não consegui tocar o áudio. Leia na tela!',
        );
      }
    }
  }

  static Future<void> stop() async {
    current.value = null;
    if (!enabled) return;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  /// Para a fala se ela for de uma tela que fechou.
  static void stopIf(String key) {
    if (current.value?.key == key) stop();
  }

  static void _remember(String key, Uint8List audio) {
    _cache.remove(key);
    _cache[key] = audio;
    if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
  }

  static Future<void> _play(Uint8List audio) async {
    final player = _player ??= AudioPlayer()
      ..onPlayerComplete.listen((_) => current.value = null);
    // No Android e na web o áudio toca direto da memória; nos outros
    // sistemas o plugin precisa de um arquivo.
    if (kIsWeb || Platform.isAndroid) {
      await player.play(BytesSource(audio, mimeType: 'audio/mpeg'));
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/liga_voz.mp3');
    await file.writeAsBytes(audio, flush: true);
    await player.play(DeviceFileSource(file.path, mimeType: 'audio/mpeg'));
  }
}

@immutable
class LigaVoiceState {
  const LigaVoiceState(this.key, {required this.playing, this.error});

  final String key;
  final bool playing;
  final String? error;
}

/// Retrato do herói com o botão "Ouvir". Enquanto fala, o retrato pulsa e
/// aparecem ondas de som.
class LigaHeroVoice extends StatefulWidget {
  const LigaHeroVoice({
    super.key,
    required this.character,
    required this.lines,
    this.label,
  });

  final LigaCharacter character;

  /// O que o herói lê, na ordem em que aparece na tela.
  final List<String> lines;

  /// Texto do botão. Padrão: "Ouvir o Nico explicar".
  final String? label;

  @override
  State<LigaHeroVoice> createState() => _LigaHeroVoiceState();
}

class _LigaHeroVoiceState extends State<LigaHeroVoice>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  String get _text => LigaVoice.speakable(widget.lines);
  String get _key => '${widget.character.id}|$_text';

  @override
  void initState() {
    super.initState();
    LigaVoice.current.addListener(_onVoice);
    // "Heróis leem em voz alta" (Acessibilidade): toca sozinho, se nada
    // estiver falando.
    if (LigaAccessibility.settings.value.autoRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && LigaVoice.current.value == null && _text.isNotEmpty) {
          LigaVoice.speak(widget.character, _text);
        }
      });
    }
  }

  @override
  void dispose() {
    LigaVoice.current.removeListener(_onVoice);
    LigaVoice.stopIf(_key);
    _pulse.dispose();
    super.dispose();
  }

  void _onVoice() {
    final state = LigaVoice.current.value;
    final speaking = state?.key == _key && state!.playing;
    if (speaking && LigaMotion.of(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.character;
    final text = _text;
    if (text.isEmpty) return const SizedBox.shrink();
    final state = LigaVoice.current.value;
    final mine = state?.key == _key ? state : null;
    final loading = mine != null && !mine.playing && mine.error == null;
    final playing = mine?.playing ?? false;
    final article = hero == LigaCharacter.luma || hero == LigaCharacter.mila
        ? 'a'
        : 'o';
    final label = widget.label ?? 'Ouvir $article ${hero.displayName} explicar';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: playing ? 'Parar a voz' : label,
        child: GestureDetector(
          key: const Key('heroVoice'),
          onTap: () => LigaVoice.speak(hero, text),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LigaColors.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: LigaColors.ink, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => Transform.scale(
                    scale: 1 + 0.06 * Curves.easeInOut.transform(_pulse.value),
                    child: child,
                  ),
                  child: LigaPortrait(character: hero, size: 56),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playing ? '${hero.displayName} está falando...' : label,
                        style: TextStyle(
                          color: LigaColors.shade(hero.color, 0.15),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mine?.error ?? 'Voz criada por IA',
                        style: const TextStyle(
                          color: LigaColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hero.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: LigaColors.ink, width: 3),
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          playing
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
