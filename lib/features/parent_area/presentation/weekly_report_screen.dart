import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/learning_report.dart';
import '../../../shared/services/app_repository.dart';
import '../../progress/presentation/subject_progress_section.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Relatório semanal da Área dos responsáveis: se a criança praticou, onde
/// foi bem, o que vale treinar e uma sugestão simples de apoio em casa.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  late final Future<WeeklyReport> _future = AppRepository.instance
      .loadLearningLog()
      .then(
        (log) => WeeklyReport.fromLog(
          log,
          childName: AppRepository.instance.childProfile.nickname,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório da semana')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: FutureBuilder<WeeklyReport>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final error = snapshot.error;
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: LigaErrorCard(
                    message: error is AppRepositoryException
                        ? error.message
                        : 'Não consegui montar o relatório agora.',
                  ),
                );
              }
              final report = snapshot.data;
              if (report == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _ReportView(report: report);
            },
          ),
        ),
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${_date(report.start)} a ${_date(report.end)}',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        LigaPanel(
          key: const Key('weeklyReportSummary'),
          child: Text(report.summary, style: textTheme.bodyLarge),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LigaPill(
              icon: Icons.timer_rounded,
              label: report.minutes == 0
                  ? 'Sem uso na semana'
                  : 'Cerca de ${report.minutes} min de estudo',
              color: LigaColors.primaryBlue,
            ),
            LigaPill(
              icon: Icons.check_circle_rounded,
              label:
                  '${report.activities} '
                  '${report.activities == 1 ? 'atividade' : 'atividades'}',
              color: LigaColors.progressGreen,
            ),
            LigaPill(
              icon: Icons.flag_rounded,
              label:
                  '${report.missions} '
                  '${report.missions == 1 ? 'missão' : 'missões'} do dia',
              color: LigaColors.sunsetOrange,
            ),
            LigaPill(
              icon: Icons.calendar_today_rounded,
              label:
                  '${report.activeDays} '
                  '${report.activeDays == 1 ? 'dia' : 'dias'} de uso',
              color: LigaColors.adventurePurple,
            ),
          ],
        ),
        if (report.highlights.isNotEmpty) ...[
          const SectionTitle('Destaques', icon: Icons.star_rounded),
          LigaPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final highlight in report.highlights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: LigaColors.achievementYellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(highlight, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (report.areas.isNotEmpty) ...[
          const SectionTitle('Áreas praticadas', icon: Icons.school_rounded),
          LigaPanel(
            child: Column(
              children: [
                for (final area in report.areas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 14, color: area.area.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            area.area.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${area.activities} '
                          '${area.activities == 1 ? 'atividade' : 'atividades'}'
                          ' · ${area.xp} XP',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (report.practiceArea != null) ...[
          const SectionTitle(
            'Vale treinar',
            icon: Icons.fitness_center_rounded,
          ),
          LigaPanel(
            borderColor: report.practiceArea!.color,
            child: Text(
              report.practiceArea!.label,
              style: textTheme.titleMedium,
            ),
          ),
        ],
        const SectionTitle(
          'Sugestão para você',
          icon: Icons.volunteer_activism_rounded,
        ),
        LigaPanel(
          key: const Key('weeklyReportSuggestion'),
          borderColor: LigaColors.cyanGlow,
          child: Text(report.suggestion, style: textTheme.bodyLarge),
        ),
        const SizedBox(height: 14),
        Text(
          'O tempo de estudo é estimado pelos horários das atividades.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
