import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design_system/liga_accessibility.dart';
import '../../shared/design_system/liga_mascots.dart';
import '../../shared/design_system/liga_sound.dart';
import '../../shared/design_system/liga_widgets.dart';

/// Opções de acessibilidade, abertas pela Base e pela área dos responsáveis.
/// Ficam salvas no aparelho e valem para todas as crianças dele.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  static const routeName = '/acessibilidade';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Acessibilidade')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ValueListenableBuilder<LigaAccessibilitySettings>(
            valueListenable: LigaAccessibility.settings,
            builder: (context, settings, _) {
              void set(LigaAccessibilitySettings value) =>
                  LigaAccessibility.update(value);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  LigaPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tamanho do texto', style: textTheme.titleLarge),
                        const SizedBox(height: 10),
                        SegmentedButton<LigaTextSize>(
                          key: const Key('a11yTextSize'),
                          showSelectedIcon: false,
                          segments: [
                            for (final size in LigaTextSize.values)
                              ButtonSegment(
                                value: size,
                                label: Text(size.label),
                              ),
                          ],
                          selected: {settings.textSize},
                          onSelectionChanged: (value) =>
                              set(settings.copyWith(textSize: value.first)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const LigaPortrait(
                              character: LigaCharacter.luma,
                              size: 48,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Assim fica o texto das explicações.',
                                style: textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LigaPanel(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          SwitchListTile(
                            key: const Key('a11yAutoRead'),
                            secondary: const Icon(Icons.record_voice_over),
                            title: const Text('Heróis leem em voz alta'),
                            subtitle: const Text(
                              'A explicação toca sozinha quando aparece. '
                              'O texto continua na tela.',
                            ),
                            value: settings.autoRead,
                            onChanged: (value) =>
                                set(settings.copyWith(autoRead: value)),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: LigaSound.muted,
                            builder: (context, muted, _) => SwitchListTile(
                              key: const Key('a11ySound'),
                              secondary: const Icon(Icons.music_note_rounded),
                              title: const Text('Efeitos sonoros'),
                              value: !muted,
                              onChanged: (_) => LigaSound.toggle(),
                            ),
                          ),
                          SwitchListTile(
                            key: const Key('a11yVibration'),
                            secondary: const Icon(Icons.vibration_rounded),
                            title: const Text('Vibração'),
                            value: settings.vibration,
                            onChanged: (value) =>
                                set(settings.copyWith(vibration: value)),
                          ),
                          SwitchListTile(
                            key: const Key('a11yReduceMotion'),
                            secondary: const Icon(Icons.motion_photos_off),
                            title: const Text('Menos movimento'),
                            subtitle: const Text(
                              'Para as animações dos heróis e dos botões.',
                            ),
                            value: settings.reduceMotion,
                            onChanged: (value) =>
                                set(settings.copyWith(reduceMotion: value)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LigaPanel(
                    borderColor: LigaColors.primaryBlue,
                    child: Text(
                      'O app também segue o tamanho de letra, o leitor de '
                      'tela (TalkBack) e a opção de remover animações do '
                      'aparelho.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
