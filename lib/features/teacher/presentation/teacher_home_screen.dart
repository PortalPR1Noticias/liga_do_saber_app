import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/performance_report.dart';
import '../../../shared/services/app_repository.dart';
import '../../auth/presentation/login_choice_screen.dart';
import '../../legal/presentation/legal_document_screen.dart';
import '../../performance/presentation/performance_view.dart';

/// Painel do professor: as crianças que os responsáveis liberaram para o
/// e-mail dele, com o nome que a família escolheu e o desempenho de cada uma.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  static const routeName = '/professor';

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late Future<List<TeacherStudent>> _students = AppRepository.instance
      .loadTeacherPanel();

  void _reload() {
    setState(() {
      _students = AppRepository.instance.loadTeacherPanel();
    });
  }

  Future<void> _signOut() async {
    await AppRepository.instance.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginChoiceScreen.routeName, (_) => false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir sua conta?'),
        content: const Text(
          'Sua conta de professor é apagada. As famílias continuam com os '
          'dados das crianças.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LigaColors.actionCoral,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppRepository.instance.deleteAccount();
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginChoiceScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final teacher = AppRepository.instance.teacher;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do professor'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Olá, ${teacher.name}!', style: textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Aqui aparecem os alunos que as famílias liberaram para '
                '${teacher.email}.',
                style: textTheme.bodyMedium,
              ),
              if (!teacher.emailConfirmed) ...[
                const SizedBox(height: 12),
                LigaPanel(
                  borderColor: LigaColors.sunsetOrange,
                  child: Text(
                    'Confirme o seu e-mail pelo link que enviamos para ver os '
                    'alunos. Depois, saia e entre de novo.',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FutureBuilder<List<TeacherStudent>>(
                future: _students,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return LigaPanel(
                      child: Text(
                        error is AppRepositoryException
                            ? error.message
                            : 'Não consegui carregar os alunos.',
                      ),
                    );
                  }
                  final students = snapshot.data;
                  if (students == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (students.isEmpty) {
                    return LigaPanel(
                      key: const Key('teacherEmpty'),
                      child: Text(
                        'Nenhum aluno por enquanto. Peça aos responsáveis para '
                        'abrirem o painel deles na Liga, tocarem em '
                        'Professores e liberarem o e-mail ${teacher.email}.',
                        style: textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final student in students)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StudentCard(student: student),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              for (final document in LegalDocument.values) ...[
                TextButton(
                  onPressed: () => LegalDocumentScreen.open(context, document),
                  child: Text(document.title),
                ),
              ],
              const SizedBox(height: 8),
              LigaActionButton(
                label: 'Sair da conta',
                icon: Icons.logout_rounded,
                color: LigaColors.actionCoral,
                onPressed: _signOut,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _deleteAccount,
                child: const Text('Excluir minha conta de professor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final TeacherStudent student;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final report = student.report;
    final attention = report.needsAttention;
    return LigaPressable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PerformanceScreen(childName: student.name, report: report),
        ),
      ),
      child: LigaPanel(
        key: ValueKey('student-${student.linkId}'),
        child: Row(
          children: [
            LigaAvatarBadge(avatarId: student.avatarId, radius: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: textTheme.titleLarge),
                  Text(
                    '${student.schoolYear}º ano · nível ${report.level} · '
                    '${report.activeDaysWeek} dias de prática na semana',
                    style: textTheme.bodyMedium,
                  ),
                  if (attention.isNotEmpty)
                    Text(
                      'Reforço: ${attention.map((a) => a.name).join(', ')}',
                      style: textTheme.bodySmall?.copyWith(
                        color: LigaColors.actionCoral,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: LigaColors.ink),
          ],
        ),
      ),
    );
  }
}
