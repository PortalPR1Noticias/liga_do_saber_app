import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/progress_update.dart';
import 'liga_sound.dart';
import 'liga_victory.dart';
import 'liga_widgets.dart';

/// Ícone de uma medalha ou missão pelo nome guardado no banco.
IconData ligaIconFor(String? name) {
  return switch (name) {
    'rocket' => Icons.rocket_launch_rounded,
    'search' => Icons.search_rounded,
    'edit' => Icons.edit_rounded,
    'calculate' => Icons.calculate_rounded,
    'fire' => Icons.local_fire_department_rounded,
    'camera' => Icons.camera_alt_rounded,
    'explore' => Icons.explore_rounded,
    'lightbulb' => Icons.lightbulb_rounded,
    'hub' => Icons.hub_rounded,
    'history_edu' => Icons.history_edu_rounded,
    _ => Icons.emoji_events_rounded,
  };
}

/// Cor de uma medalha ou missão pelo nome do ícone.
Color ligaColorFor(String? name) {
  return switch (name) {
    'rocket' => LigaColors.cyanGlow,
    'search' => LigaColors.adventurePurple,
    'edit' => LigaColors.actionCoral,
    'calculate' => LigaColors.primaryBlue,
    'fire' => LigaColors.sunsetOrange,
    'camera' => LigaColors.progressGreen,
    'explore' => LigaColors.progressGreen,
    'lightbulb' => LigaColors.sunsetOrange,
    'hub' => LigaColors.sunsetOrange,
    'history_edu' => LigaColors.adventurePurple,
    _ => LigaColors.achievementYellow,
  };
}

/// Cartão de recompensa depois de uma atividade: XP ganho, missão do dia
/// concluída, nível novo e medalhas novas. Na primeira vez que aparece, abre
/// a tela de vitória por cima ([LigaVictory]).
class LigaRewardCard extends StatefulWidget {
  const LigaRewardCard({super.key, required this.progress});

  final ProgressUpdate progress;

  @override
  State<LigaRewardCard> createState() => _LigaRewardCardState();
}

class _LigaRewardCardState extends State<LigaRewardCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) LigaVictory.maybeShow(context, widget.progress);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final textTheme = Theme.of(context).textTheme;
    return LigaPanel(
      borderColor: LigaColors.achievementYellow,
      color: const Color(0xFFFFF7DD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LigaIconBubble(
                icon: Icons.bolt_rounded,
                color: LigaColors.achievementYellow,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '+${progress.xpGained} XP',
                  style: TextStyle(
                    fontFamily: LigaTheme.displayFont,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: ligaOutline(1.8),
                  ),
                ),
              ),
              LigaPill(
                icon: Icons.local_fire_department_rounded,
                label: '${progress.streakDays}',
                color: LigaColors.sunsetOrange,
              ),
            ],
          ),
          if (progress.missionTitle != null) ...[
            const SizedBox(height: 10),
            Text(
              'Missão do dia concluída: ${progress.missionTitle} '
              '(+${progress.missionXp} XP de bônus)',
              style: textTheme.titleMedium,
            ),
          ],
          if (progress.leveledUp) ...[
            const SizedBox(height: 10),
            LigaPill(
              icon: Icons.military_tech_rounded,
              label: 'Subiu para o nível ${progress.level}!',
              color: LigaColors.adventurePurple,
            ),
          ],
          for (final badge in progress.newBadges) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                LigaIconBubble(
                  icon: ligaIconFor(badge.icon),
                  color: ligaColorFor(badge.icon),
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Medalha nova: ${badge.name}',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Pensando..." enquanto a IA trabalha.
class LigaThinkingCard extends StatelessWidget {
  const LigaThinkingCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      borderColor: LigaColors.sunsetOrange.withValues(alpha: 0.5),
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

/// Mensagem de erro vinda do servidor.
class LigaErrorCard extends StatelessWidget {
  const LigaErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      borderColor: LigaColors.actionCoral,
      child: Row(
        children: [
          const LigaIconBubble(
            icon: Icons.error_outline_rounded,
            color: LigaColors.actionCoral,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

enum LigaChoiceState { idle, selected, right, wrong }

/// Opção de resposta em bloco (Detetive da Leitura e Arena Matemática).
/// Toca o som de acerto ou de erro quando a resposta é conferida.
class LigaChoiceButton extends StatefulWidget {
  const LigaChoiceButton({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
    this.color = LigaColors.primaryBlue,
  });

  final String label;
  final LigaChoiceState state;
  final VoidCallback? onTap;

  /// Cor quando selecionada.
  final Color color;

  @override
  State<LigaChoiceButton> createState() => _LigaChoiceButtonState();
}

class _LigaChoiceButtonState extends State<LigaChoiceButton> {
  /// Só a opção que a criança tocou faz barulho quando é conferida (a
  /// resposta mostrada no "ver solução" fica em silêncio).
  bool _tapped = false;

  @override
  void didUpdateWidget(LigaChoiceButton old) {
    super.didUpdateWidget(old);
    if (old.state == widget.state || !_tapped) return;
    if (widget.state == LigaChoiceState.right) {
      LigaSound.play(LigaSfx.acerto);
    } else if (widget.state == LigaChoiceState.wrong) {
      LigaSound.play(LigaSfx.erro);
    }
  }

  void _tap() {
    _tapped = true;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final color = widget.color;
    final label = widget.label;
    final onTap = widget.onTap == null ? null : _tap;
    final fill = switch (state) {
      LigaChoiceState.idle => Colors.white,
      LigaChoiceState.selected => color,
      LigaChoiceState.right => LigaColors.progressGreen,
      LigaChoiceState.wrong => LigaColors.actionCoral,
    };
    final onFill = state != LigaChoiceState.idle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LigaPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LigaColors.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: LigaColors.ink, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: onFill ? Colors.white : LigaColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    shadows: onFill ? ligaOutline(1.2) : null,
                  ),
                ),
              ),
              if (state == LigaChoiceState.right)
                const Icon(Icons.check_circle_rounded, color: Colors.white),
              if (state == LigaChoiceState.wrong)
                const Icon(Icons.cancel_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Passo numerado de uma explicação.
class LigaStepBubble extends StatelessWidget {
  const LigaStepBubble({
    super.key,
    required this.number,
    required this.text,
    this.title = '',
  });

  final int number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: LigaColors.achievementYellow,
              border: Border.all(color: LigaColors.ink, width: 3),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: LigaColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LigaPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty) ...[
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                  ],
                  Text(text, style: textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
