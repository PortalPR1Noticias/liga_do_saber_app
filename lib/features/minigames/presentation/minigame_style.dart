import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/minigame.dart';
import 'lightning_challenge_screen.dart';
import 'order_puzzle_screen.dart';
import 'word_search_screen.dart';

/// Personagem e cor de cada matéria nos Jogos da Liga.
extension MinigameSubjectStyle on MinigameSubject {
  LigaCharacter get character => switch (this) {
    MinigameSubject.portugues => LigaCharacter.luma,
    MinigameSubject.matematica => LigaCharacter.nico,
    MinigameSubject.ciencias || MinigameSubject.geografia => LigaCharacter.teo,
  };

  Color get color => switch (this) {
    MinigameSubject.portugues => LigaColors.actionCoral,
    MinigameSubject.matematica => LigaColors.primaryBlue,
    MinigameSubject.ciencias ||
    MinigameSubject.geografia => LigaColors.progressGreen,
  };
}

/// Fileira de chips para escolher a matéria do jogo.
class MinigameSubjectPicker extends StatelessWidget {
  const MinigameSubjectPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final MinigameSubject value;
  final ValueChanged<MinigameSubject> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final subject in MinigameSubject.values)
          ChoiceChip(
            label: Text(subject.label),
            selected: value == subject,
            onSelected: enabled ? (_) => onChanged(subject) : null,
          ),
      ],
    );
  }
}

/// Atalho para os Jogos da Liga dentro de um módulo: o mesmo conteúdo, em
/// formato de jogo.
class MinigameShortcuts extends StatelessWidget {
  const MinigameShortcuts({
    super.key,
    required this.subject,
    this.withLightning = false,
  });

  final MinigameSubject subject;

  /// Mostra também o Desafio Relâmpago (para a Arena Matemática).
  final bool withLightning;

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        SectionTitle(
          'Treine jogando',
          icon: Icons.sports_esports_rounded,
          color: subject.color,
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (withLightning)
              _ShortcutChip(
                label: 'Desafio Relâmpago',
                icon: Icons.bolt_rounded,
                color: LigaColors.sunsetOrange,
                onTap: () => open(const LightningChallengeScreen()),
              ),
            _ShortcutChip(
              label: 'Caça-palavras',
              icon: Icons.grid_on_rounded,
              color: subject.color,
              onTap: () => open(WordSearchScreen(subject: subject)),
            ),
            _ShortcutChip(
              label: 'Quebra-cabeça',
              icon: Icons.extension_rounded,
              color: subject.color,
              onTap: () => open(OrderPuzzleScreen(subject: subject)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LigaColors.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: LigaColors.ink, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                shadows: ligaOutline(1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
