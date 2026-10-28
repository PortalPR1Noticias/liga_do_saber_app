import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/services/app_repository.dart';
import '../../auth/presentation/child_login_screen.dart';
import '../../auth/presentation/login_choice_screen.dart';
import '../../child_profile/presentation/child_profile_screen.dart';
import '../../performance/presentation/performance_view.dart';
import '../../practice_exam/presentation/parent_exams_screen.dart';
import 'child_login_setup_screen.dart';
import 'parent_area_screen.dart';
import 'teacher_links_screen.dart';
import 'weekly_report_screen.dart';

/// Painel do responsável: as crianças da conta, o desempenho de cada uma, o
/// login delas, os professores liberados e as provas para treinar.
class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  static const routeName = '/responsavel';

  Future<void> _addChild(BuildContext context) async {
    AppRepository.instance.selectChild(null);
    await Navigator.of(context).pushNamed(ChildProfileScreen.routeName);
  }

  Future<void> _signOut(BuildContext context) async {
    await AppRepository.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginChoiceScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppRepository.instance;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Painel do responsável')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: repository,
            builder: (context, _) {
              final children = repository.children;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Olá, ${repository.responsible.name}!',
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Acompanhe as crianças e crie o login delas. No login da '
                    'criança, o app mostra só os jogos.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  for (final child in children) ...[
                    _ChildCard(child: child),
                    const SizedBox(height: 14),
                  ],
                  LigaActionButton(
                    key: const Key('addChildButton'),
                    label: 'Adicionar criança',
                    icon: Icons.person_add_alt_1_rounded,
                    color: LigaColors.progressGreen,
                    onPressed: () => _addChild(context),
                  ),
                  const SizedBox(height: 12),
                  LigaActionButton(
                    label: 'Autorizações, dados e privacidade',
                    icon: Icons.shield_rounded,
                    color: LigaColors.adventurePurple,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ParentAreaScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LigaActionButton(
                    label: 'Sair da conta',
                    icon: Icons.logout_rounded,
                    color: LigaColors.actionCoral,
                    onPressed: () => _signOut(context),
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

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});

  final ChildProfile child;

  /// Escolhe a criança no repositório antes de abrir a tela dela.
  void _open(BuildContext context, WidgetBuilder builder) {
    AppRepository.instance.selectChild(child.id);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  Future<void> _handOver(BuildContext context) async {
    final username = child.username;
    if (username == null) {
      _open(context, (_) => const ChildLoginSetupScreen());
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Passar para ${child.nickname}?'),
        content: Text(
          'Você sai da sua conta neste aparelho e ${child.nickname} entra com '
          'o usuário $username e a senha dele(a). Para voltar ao painel, '
          'saia da conta da criança e entre como responsável.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Passar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppRepository.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context)
      ..pushNamedAndRemoveUntil(LoginChoiceScreen.routeName, (_) => false)
      ..pushNamed(ChildLoginScreen.routeName, arguments: username);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final username = child.username;
    return LigaPanel(
      key: ValueKey('child-${child.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LigaAvatarBadge(avatarId: child.avatarId, radius: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.nickname, style: textTheme.titleLarge),
                    Text(
                      'Nível ${child.level} · ${child.schoolYear}º ano',
                      style: textTheme.bodyMedium,
                    ),
                    Text(
                      username == null
                          ? 'Ainda sem login próprio'
                          : 'Login: $username',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: ValueKey('performance-${child.id}'),
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Desempenho'),
                onPressed: () => _open(
                  context,
                  (_) => PerformanceScreen(childName: child.nickname),
                ),
              ),
              FilledButton.tonalIcon(
                key: ValueKey('weeklyReport-${child.id}'),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Relatório da semana'),
                onPressed: () =>
                    _open(context, (_) => const WeeklyReportScreen()),
              ),
              FilledButton.tonalIcon(
                key: ValueKey('childLogin-${child.id}'),
                icon: const Icon(Icons.key_rounded),
                label: Text(username == null ? 'Criar login' : 'Login'),
                onPressed: () =>
                    _open(context, (_) => const ChildLoginSetupScreen()),
              ),
              FilledButton.tonalIcon(
                key: ValueKey('teachers-${child.id}'),
                icon: const Icon(Icons.school_rounded),
                label: const Text('Professores'),
                onPressed: () =>
                    _open(context, (_) => const TeacherLinksScreen()),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.assignment_rounded),
                label: const Text('Provas para treinar'),
                onPressed: () =>
                    _open(context, (_) => const ParentExamsScreen()),
              ),
              FilledButton.icon(
                key: ValueKey('handOver-${child.id}'),
                icon: const Icon(Icons.sports_esports_rounded),
                label: const Text('Passar para a criança'),
                onPressed: () => _handOver(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
