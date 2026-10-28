import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/learning_report.dart';
import '../../../shared/services/app_repository.dart';

/// Herói e cor de cada área do progresso.
extension LearningAreaStyle on LearningArea {
  LigaCharacter get character => switch (this) {
    LearningArea.portugues => LigaCharacter.luma,
    LearningArea.matematica => LigaCharacter.nico,
    LearningArea.ciencias || LearningArea.geografia => LigaCharacter.teo,
    LearningArea.historia => LigaCharacter.mila,
    LearningArea.criatividade => LigaCharacter.zuri,
  };

  Color get color => character.color;
}

const _weekdayLetters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

/// Progresso por matéria da aba Conquistas: XP de cada área, pontos fortes,
/// o que praticar e o XP dos últimos 7 dias.
class SubjectProgressSection extends StatefulWidget {
  const SubjectProgressSection({super.key});

  @override
  State<SubjectProgressSection> createState() => _SubjectProgressSectionState();
}

class _SubjectProgressSectionState extends State<SubjectProgressSection> {
  late final Future<SubjectProgress> _future = AppRepository.instance
      .loadLearningLog()
      .then(SubjectProgress.fromLog);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SubjectProgress>(
      future: _future,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              'Progresso por matéria',
              icon: Icons.bar_chart_rounded,
            ),
            if (snapshot.hasError)
              const LigaPanel(child: Text('Não consegui carregar agora.'))
            else if (progress == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              _AreasPanel(progress: progress),
              const SizedBox(height: 14),
              _FocusPanel(progress: progress),
              const SizedBox(height: 14),
              _WeekPanel(progress: progress),
            ],
          ],
        );
      },
    );
  }
}

class _AreasPanel extends StatelessWidget {
  const _AreasPanel({required this.progress});

  final SubjectProgress progress;

  @override
  Widget build(BuildContext context) {
    final top = progress.areas.first.xp;
    return LigaPanel(
      key: const Key('subjectProgressAreas'),
      child: Column(
        children: [
          for (final area in progress.areas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  LigaPortrait(character: area.area.character, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                area.area.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${area.xp} XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: LigaColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LigaProgressBar(
                          value: top == 0 ? 0 : area.xp / top,
                          color: area.area.color,
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.progress});

  final SubjectProgress progress;

  @override
  Widget build(BuildContext context) {
    Widget chips(List<LearningArea> areas, String empty) {
      if (areas.isEmpty) {
        return Text(empty, style: Theme.of(context).textTheme.bodyMedium);
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final area in areas)
            LigaPill(icon: Icons.circle, label: area.label, color: area.color),
        ],
      );
    }

    return LigaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pontos fortes',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          chips(progress.strengths, 'Jogue algumas missões para descobrir!'),
          const SizedBox(height: 14),
          const Text(
            'Para praticar',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          chips(progress.toPractice, 'Tudo em dia. Continue assim!'),
        ],
      ),
    );
  }
}

class _WeekPanel extends StatelessWidget {
  const _WeekPanel({required this.progress});

  final SubjectProgress progress;

  @override
  Widget build(BuildContext context) {
    final days = progress.lastDays.entries.toList();
    final top = days.fold(0, (m, e) => e.value > m ? e.value : m);
    return LigaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimos 7 dias: ${progress.weekXp} XP',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: top == 0 ? 4 : 4 + 66 * day.value / top,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: day.value > 0
                                ? LigaColors.achievementYellow
                                : LigaColors.disabled,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: LigaColors.ink, width: 2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _weekdayLetters[day.key.weekday - 1],
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: LigaColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
