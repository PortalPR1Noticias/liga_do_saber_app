import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_game.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_sound.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/league_progress.dart';
import '../../../shared/services/app_repository.dart';
import '../../auth/presentation/login_choice_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../math_arena/presentation/math_arena_screen.dart';
import '../../mila_archive/presentation/mila_archive_screen.dart';
import '../../minigames/presentation/minigames_hub_screen.dart';
import '../../photo_solver/presentation/photo_solver_flow_screen.dart';
import '../../practice_exam/presentation/revanche_screen.dart';
import '../../reading_detective/presentation/reading_detective_screen.dart';
import '../../teo_trail/presentation/teo_trail_screen.dart';
import '../../writing_workshop/presentation/writing_workshop_screen.dart';
import '../../world/world_map_screen.dart';
import '../../zuri_atelier/presentation/zuri_atelier_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const routeName = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _tabs = [
    (Icons.home_rounded, 'Base', LigaColors.cyanGlow),
    (Icons.public_rounded, 'Mundo', LigaColors.progressGreen),
    (Icons.flag_rounded, 'Missões', LigaColors.actionCoral),
    (Icons.emoji_events_rounded, 'Conquistas', LigaColors.achievementYellow),
    (Icons.person_rounded, 'Perfil', LigaColors.adventurePurple),
  ];

  void _openTab(int index) => setState(() => _currentIndex = index);

  Widget _page() {
    return switch (_currentIndex) {
      0 => HomeScreen(onOpenTab: _openTab),
      1 => const WorldMapScreen(),
      2 => const _MissionsScreen(),
      3 => const _ProgressScreen(),
      _ => const _ProfileScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // A Base e o Mundo são telas de jogo, com fundo próprio de ponta a
    // ponta; as outras abas ficam no céu da Liga.
    final gameScreen = _currentIndex <= 1;
    return Scaffold(
      backgroundColor: LigaNight.deep,
      body: ListenableBuilder(
        listenable: AppRepository.instance,
        // Recria a página quando o XP, o nível ou o avatar mudam.
        builder: (context, _) {
          final page = KeyedSubtree(
            key: ValueKey((AppRepository.instance.childProfile, _currentIndex)),
            child: _page(),
          );
          return gameScreen
              ? page
              : LigaBackground(child: SafeArea(child: page));
        },
      ),
      bottomNavigationBar: _GameNavBar(
        tabs: _tabs,
        selected: _currentIndex,
        onSelect: _openTab,
      ),
    );
  }
}

/// Barra de abas no estilo dos jogos: blocos escuros com ícone grande, e a
/// aba escolhida sobe e acende na cor dela.
class _GameNavBar extends StatelessWidget {
  const _GameNavBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<(IconData, String, Color)> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: LigaNight.deep,
        border: Border(top: BorderSide(color: LigaColors.ink, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    child: GestureDetector(
                      key: ValueKey('tab-${tabs[i].$2}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != selected) LigaSound.play(LigaSfx.toque);
                        onSelect(i);
                      },
                      child: _NavItem(
                        icon: tabs[i].$1,
                        label: tabs[i].$2,
                        color: tabs[i].$3,
                        active: i == selected,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          width: active ? 52 : 44,
          height: active ? 42 : 36,
          transform: Matrix4.translationValues(0, active ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: active ? color : const Color(0xFF1A2275),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LigaColors.ink, width: 2.5),
            boxShadow: active
                ? const [BoxShadow(color: LigaColors.ink, offset: Offset(0, 4))]
                : null,
          ),
          child: Icon(
            icon,
            size: active ? 26 : 22,
            color: active ? Colors.white : LigaNight.textSoft,
            shadows: active ? ligaOutline(1.2) : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            color: active ? Colors.white : LigaNight.textSoft,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Carrega dados da Liga ao abrir a aba. A aba é recriada quando o perfil
/// muda (veja o ListenableBuilder do MainShell), então recarrega sozinha.
abstract class _LiveState<W extends StatefulWidget, T> extends State<W> {
  late final Future<T> _future = load();

  Future<T> load();

  Widget buildWith(BuildContext context, T? data, String? error);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) => buildWith(
        context,
        snapshot.data,
        snapshot.error is AppRepositoryException
            ? (snapshot.error as AppRepositoryException).message
            : snapshot.hasError
            ? 'Não consegui carregar agora.'
            : null,
      ),
    );
  }
}

class _MissionsScreen extends StatefulWidget {
  const _MissionsScreen();

  @override
  State<_MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState
    extends _LiveState<_MissionsScreen, List<DailyMission>> {
  @override
  Future<List<DailyMission>> load() =>
      AppRepository.instance.loadDailyMissions();

  void _open(DailyMission mission) {
    final route = switch (mission.type) {
      'leitura' => ReadingDetectiveScreen.routeName,
      'texto' || 'texto_reescrita' => WritingWorkshopScreen.routeName,
      'matematica' => MathArenaScreen.routeName,
      'expedicao' => TeoTrailScreen.routeName,
      'atelie' || 'projeto' => ZuriAtelierScreen.routeName,
      'arquivo' => MilaArchiveScreen.routeName,
      'minijogo' => MinigamesHubScreen.routeName,
      'foto' => PhotoSolverFlowScreen.routeName,
      'revanche' || 'revanche_vencida' => RevancheScreen.routeName,
      _ => null,
    };
    if (route != null) Navigator.of(context).pushNamed(route);
  }

  @override
  Widget buildWith(
    BuildContext context,
    List<DailyMission>? missions,
    String? error,
  ) {
    final done = missions?.where((m) => m.done).length ?? 0;
    return _ShellPage(
      title: 'Missões',
      subtitle: 'Desafios rapidinhos que valem XP. Bora?',
      character: LigaCharacter.luma,
      children: [
        if (error != null)
          LigaPanel(child: Text(error))
        else if (missions == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          LigaPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoje: $done de ${missions.length} missões',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LigaProgressBar(
                  value: missions.isEmpty ? 0 : done / missions.length,
                  color: LigaColors.progressGreen,
                ),
              ],
            ),
          ),
          for (final mission in missions)
            LigaPressable(
              onTap: () => _open(mission),
              child: _MissionRow(
                mission.title,
                mission.done ? 'Feita!' : '+${mission.xp} XP',
                mission.done ? Icons.check_rounded : ligaIconFor(mission.icon),
                mission.done
                    ? LigaColors.progressGreen
                    : ligaColorFor(mission.icon),
              ),
            ),
        ],
      ],
    );
  }
}

class _ProgressScreen extends StatefulWidget {
  const _ProgressScreen();

  @override
  State<_ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState
    extends _LiveState<_ProgressScreen, List<Achievement>> {
  @override
  Future<List<Achievement>> load() => AppRepository.instance.loadAchievements();

  @override
  Widget buildWith(
    BuildContext context,
    List<Achievement>? achievements,
    String? error,
  ) {
    final profile = AppRepository.instance.childProfile;

    return _ShellPage(
      title: 'Conquistas',
      subtitle: 'Sua evolução, no seu ritmo. Sem ranking!',
      character: LigaCharacter.mila,
      children: [
        LigaPanel(
          child: Row(
            children: [
              SizedBox.square(
                dimension: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: profile.levelProgress,
                      strokeWidth: 11,
                      strokeCap: StrokeCap.round,
                      backgroundColor: LigaColors.achievementYellow.withValues(
                        alpha: 0.2,
                      ),
                      color: LigaColors.achievementYellow,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'NÍVEL',
                            style: TextStyle(
                              color: LigaColors.inkSoft,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${profile.level}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.levelXp} / ${profile.levelXpGoal} XP',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    LigaPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${profile.streakDays} dias seguidos',
                      color: LigaColors.sunsetOrange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Medalhas', icon: Icons.emoji_events_rounded),
        if (error != null)
          LigaPanel(child: Text(error))
        else if (achievements == null)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final achievement in achievements)
                _Badge(
                  achievement.name,
                  ligaIconFor(achievement.icon),
                  ligaColorFor(achievement.icon),
                  earned: achievement.earned,
                ),
            ],
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.title, this.icon, this.color, {this.earned = true});

  final String title;
  final IconData icon;
  final Color color;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final tint = earned ? color : LigaColors.disabled;
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.5, 0.5, 1],
                colors: [
                  Color.lerp(tint, Colors.white, 0.3)!,
                  Color.lerp(tint, Colors.white, 0.15)!,
                  tint,
                  tint,
                ],
              ),
              border: Border.all(color: LigaColors.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: LigaColors.ink, offset: Offset(0, 4)),
              ],
            ),
            child: Icon(
              earned ? icon : Icons.lock_rounded,
              color: Colors.white,
              size: 34,
              shadows: ligaOutline(1.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: earned ? LigaColors.ink : LigaColors.inkSoft,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final profile = AppRepository.instance.childProfile;

    return _ShellPage(
      title: 'Perfil',
      subtitle: 'Seu cantinho na Liga.',
      children: [
        LigaPanel(
          child: Column(
            children: [
              LigaAvatarBadge(avatarId: profile.avatarId, radius: 48),
              const SizedBox(height: 12),
              Text(
                profile.nickname,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  LigaPill(
                    icon: Icons.military_tech_rounded,
                    label: 'Nível ${profile.level}',
                    color: LigaColors.adventurePurple,
                  ),
                  LigaPill(
                    icon: Icons.local_fire_department_rounded,
                    label: '${profile.streakDays} dias',
                    color: LigaColors.sunsetOrange,
                  ),
                  LigaPill(
                    icon: Icons.school_rounded,
                    label: '${profile.schoolYear}º ano',
                    color: LigaColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
        LigaActionButton(
          label: 'Sair da conta',
          icon: Icons.logout_rounded,
          color: LigaColors.actionCoral,
          onPressed: () async {
            await AppRepository.instance.signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              LoginChoiceScreen.routeName,
              (_) => false,
            );
          },
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
    this.character,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final LigaCharacter? character;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (character != null) LigaMascot(character: character!, size: 76),
          ],
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PopIn(
              delay: Duration(milliseconds: 70 * i),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow(this.title, this.subtitle, this.icon, this.color);

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isXp = subtitle.startsWith('+');
    return LigaPanel(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.45),
      child: Row(
        children: [
          LigaIconBubble(icon: icon, color: color, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (!isXp) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (isXp)
            LigaPill(
              icon: Icons.star_rounded,
              label: subtitle,
              color: LigaColors.achievementYellow,
            ),
        ],
      ),
    );
  }
}
