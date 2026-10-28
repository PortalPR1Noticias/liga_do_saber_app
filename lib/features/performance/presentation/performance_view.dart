import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/performance_report.dart';
import '../../../shared/services/app_repository.dart';

/// Tela da avaliação de desempenho. Sem [report], carrega a da criança
/// escolhida no painel do responsável; o painel do professor já manda o
/// relatório pronto.
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.childName, this.report});

  final String childName;
  final PerformanceReport? report;

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  late Future<PerformanceReport> _report = _load();

  Future<PerformanceReport> _load() {
    final ready = widget.report;
    return ready != null
        ? Future.value(ready)
        : AppRepository.instance.loadPerformance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Desempenho de ${widget.childName}')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: FutureBuilder<PerformanceReport>(
            future: _report,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final error = snapshot.error;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    LigaPanel(
                      child: Text(
                        error is AppRepositoryException
                            ? error.message
                            : 'Não consegui carregar o desempenho.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    LigaActionButton(
                      label: 'Tentar de novo',
                      icon: Icons.refresh_rounded,
                      color: LigaColors.primaryBlue,
                      onPressed: () => setState(() {
                        _report = _load();
                      }),
                    ),
                  ],
                );
              }
              final report = snapshot.data;
              if (report == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [PerformanceView(report: report)],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A avaliação em si: ritmo, cada matéria, pontos fortes, o que reforçar e
/// a Revanche da prova.
class PerformanceView extends StatelessWidget {
  const PerformanceView({super.key, required this.report});

  final PerformanceReport report;

  static Color statusColor(PerformanceStatus status) {
    return switch (status) {
      PerformanceStatus.strong => LigaColors.progressGreen,
      PerformanceStatus.developing => LigaColors.primaryBlue,
      PerformanceStatus.needsPractice => LigaColors.actionCoral,
      PerformanceStatus.starting => LigaColors.sunsetOrange,
      PerformanceStatus.usage => LigaColors.cyanGlow,
      PerformanceStatus.noData => LigaColors.inkSoft,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strengths = report.strengths;
    final attention = report.needsAttention;
    final accuracy = report.examAccuracy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LigaPill(
              icon: Icons.military_tech_rounded,
              label: 'Nível ${report.level}',
              color: LigaColors.adventurePurple,
            ),
            LigaPill(
              icon: Icons.star_rounded,
              label: '${report.totalXp} XP',
              color: LigaColors.achievementYellow,
            ),
            LigaPill(
              icon: Icons.local_fire_department_rounded,
              label: '${report.streakDays} dias seguidos',
              color: LigaColors.sunsetOrange,
            ),
          ],
        ),
        const SizedBox(height: 14),
        LigaPanel(
          key: const Key('performanceRhythm'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ritmo', style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(report.rhythm, style: textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(
                '${report.activeDays} dias de prática e ${report.xpWeek} XP '
                'nesta semana.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (strengths.isNotEmpty || attention.isNotEmpty) ...[
          LigaPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avaliação', style: textTheme.titleLarge),
                if (strengths.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Vai bem em ${_join(strengths)}.',
                    style: textTheme.bodyMedium,
                  ),
                ],
                if (attention.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Precisa de reforço em ${_join(attention)}: muitas '
                    'atividades abertas e poucas concluídas. Vale praticar '
                    'junto e conferir as explicações dos heróis.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        const SectionTitle('Por matéria', icon: Icons.menu_book_rounded),
        for (final area in report.areas) ...[
          _AreaRow(area: area),
          const SizedBox(height: 10),
        ],
        if (report.exams.isNotEmpty) ...[
          const SizedBox(height: 4),
          const SectionTitle(
            'Revanche da prova',
            icon: Icons.assignment_rounded,
          ),
          if (accuracy != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Acertou ${(accuracy * 100).round()}% das questões de treino '
                'das provas reais.',
                style: textTheme.bodyMedium,
              ),
            ),
          for (final exam in report.exams) ...[
            LigaPanel(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.title, style: textTheme.titleMedium),
                        Text(
                          '${exam.rightAnswers} de ${exam.totalQuestions} '
                          'questões${exam.won ? ' · revanche vencida' : ''}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < exam.stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: LigaColors.achievementYellow,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 6),
        Text(
          'Últimos ${report.periodDays} dias. O aproveitamento compara as '
          'atividades concluídas com as que a criança abriu.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  static String _join(List<AreaPerformance> areas) {
    final names = [for (final area in areas) area.name];
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.area});

  final AreaPerformance area;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = area.status;
    final color = PerformanceView.statusColor(status);
    final rate = area.rate;
    final String detail;
    if (status == PerformanceStatus.usage) {
      detail = '${area.opened} fotos de tarefa enviadas.';
    } else if (status == PerformanceStatus.noData) {
      detail = 'Nenhuma atividade no período.';
    } else {
      detail =
          '${area.completed} de ${area.opened} atividades concluídas'
          '${area.completedWeek > 0 ? ' · ${area.completedWeek} nesta semana' : ''}.';
    }
    return LigaPanel(
      key: ValueKey('area-${area.key}'),
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(area.name, style: textTheme.titleMedium),
              if (status != PerformanceStatus.usage)
                LigaPill(
                  icon: Icons.insights_rounded,
                  label: status.label,
                  color: color,
                ),
            ],
          ),
          if (rate != null && status != PerformanceStatus.usage) ...[
            const SizedBox(height: 8),
            LigaProgressBar(value: rate, color: color, height: 10),
          ],
          const SizedBox(height: 6),
          Text(detail, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
