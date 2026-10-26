import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/services/mock_app_repository.dart';
import '../../home/presentation/home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const routeName = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    HomeScreen(),
    _MapScreen(),
    _MissionsScreen(),
    _ProgressScreen(),
    _ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LigaBackground(child: SafeArea(child: _pages[_currentIndex])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: LigaColors.deepBlue,
        indicatorColor: LigaColors.primaryBlue.withValues(alpha: 0.28),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Missões',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Progresso',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _MapScreen extends StatelessWidget {
  const _MapScreen();

  @override
  Widget build(BuildContext context) {
    return const _ShellPage(
      title: 'Mapa da Liga',
      subtitle: 'Portais de aprendizagem por área.',
      children: [
        _WorldTile(
          'Biblioteca Viva',
          'Interpretação e leitura',
          Icons.menu_book,
          LigaColors.progressGreen,
        ),
        _WorldTile(
          'Oficina de Texto',
          'Criar, revisar e reescrever',
          Icons.edit_note,
          LigaColors.actionCoral,
        ),
        _WorldTile(
          'Ilha dos Números',
          'Cálculo e raciocínio',
          Icons.calculate,
          LigaColors.primaryBlue,
        ),
        _WorldTile(
          'Arquivo da Mila',
          'História e pistas visuais',
          Icons.manage_search,
          LigaColors.adventurePurple,
        ),
      ],
    );
  }
}

class _MissionsScreen extends StatelessWidget {
  const _MissionsScreen();

  @override
  Widget build(BuildContext context) {
    return const _ShellPage(
      title: 'Missões',
      subtitle: 'Tarefas curtas para treinar sem virar apostila.',
      children: [
        _MissionRow(
          'Descobrir a ideia principal',
          '+25 XP',
          Icons.travel_explore,
        ),
        _MissionRow('Reescrever um parágrafo', '+35 XP', Icons.edit),
        _MissionRow('Resolver desafio de frações', '+20 XP', Icons.functions),
        _MissionRow('Enviar foto da tarefa', '+15 XP', Icons.camera_alt),
      ],
    );
  }
}

class _ProgressScreen extends StatelessWidget {
  const _ProgressScreen();

  @override
  Widget build(BuildContext context) {
    final profile = MockAppRepository.instance.childProfile;

    return _ShellPage(
      title: 'Progresso',
      subtitle: 'Evolução individual, sem ranking público.',
      children: [
        LigaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.nickname} | Nível ${profile.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: profile.levelProgress,
                minHeight: 10,
              ),
              const SizedBox(height: 10),
              Text(
                '${profile.totalXp % ChildProfile.levelXpGoal} / '
                '${ChildProfile.levelXpGoal} XP',
                style: const TextStyle(color: Color(0xFFD8E2FF)),
              ),
            ],
          ),
        ),
        const _MissionRow(
          'Badge: Detetive da Leitura',
          '5 casos concluídos',
          Icons.military_tech,
        ),
        const _MissionRow(
          'Ponto forte',
          'Interpretação explícita',
          Icons.check_circle,
        ),
        const _MissionRow(
          'Praticar mais',
          'Pontuação em textos',
          Icons.tips_and_updates,
        ),
      ],
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final profile = MockAppRepository.instance.childProfile;

    return _ShellPage(
      title: 'Perfil',
      subtitle: 'Protótipo de perfil infantil e acesso responsável.',
      children: [
        LigaPanel(
          child: Row(
            children: [
              LigaAvatarBadge(avatarId: profile.avatarId),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Mestre Junior | ${profile.streakDays} dias de sequência',
                      style: const TextStyle(color: Color(0xFFD8E2FF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        LigaActionButton(
          label: 'Área dos responsáveis',
          icon: Icons.lock_outline,
          color: LigaColors.adventurePurple,
          onPressed: () => showComingSoon(context),
        ),
      ],
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(bottom: 14), child: child),
        ),
      ],
    );
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile(this.title, this.subtitle, this.icon, this.color);

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MissionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      progress: 0.48,
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: LigaColors.cyanGlow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
