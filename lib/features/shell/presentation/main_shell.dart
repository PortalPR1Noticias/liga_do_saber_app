import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/league_progress.dart';
import '../../../shared/services/app_repository.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../math_arena/presentation/math_arena_screen.dart';
import '../../mila_archive/presentation/mila_archive_screen.dart';
import '../../minigames/presentation/minigames_hub_screen.dart';
import '../../parent_area/presentation/parent_area_screen.dart';
import '../../photo_solver/presentation/photo_solver_flow_screen.dart';
import '../../practice_exam/presentation/revanche_screen.dart';
import '../../reading_detective/presentation/reading_detective_screen.dart';
import '../../teo_trail/presentation/teo_trail_screen.dart';
import '../../writing_workshop/presentation/writing_workshop_screen.dart';
import '../../zuri_atelier/presentation/zuri_atelier_screen.dart';

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
      body: LigaBackground(
        child: SafeArea(
          // Recria a página quando o XP, o nível ou o avatar mudam.
          child: ListenableBuilder(
            listenable: AppRepository.instance,
            builder: (context, _) => KeyedSubtree(
              key: ValueKey(AppRepository.instance.childProfile),
              child: _pages[_currentIndex],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: LigaColors.ink, width: 3.5)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: LigaColors.primaryBlue,
                ),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(
                  Icons.map_rounded,
                  color: LigaColors.progressGreen,
                ),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(
                  Icons.flag_rounded,
                  color: LigaColors.actionCoral,
                ),
                label: 'Missões',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(
                  Icons.emoji_events_rounded,
                  color: LigaColors.sunsetOrange,
                ),
                label: 'Conquistas',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: LigaColors.adventurePurple,
                ),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapScreen extends StatelessWidget {
  const _MapScreen();

  @override
  Widget build(BuildContext context) {
    return _ShellPage(
      title: 'Mapa da Liga',
      subtitle: 'Escolha um portal e comece a aventura!',
      character: LigaCharacter.nico,
      children: [
        _PortalTrail(
          portals: [
            _Portal(
              'Biblioteca Viva',
              'Leitura com a Luma',
              Icons.menu_book_rounded,
              LigaColors.actionCoral,
              LigaCharacter.luma,
              stars: 3,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(ReadingDetectiveScreen.routeName),
            ),
            _Portal(
              'Oficina de Texto',
              'Redação com a Luma',
              Icons.edit_rounded,
              LigaColors.actionCoral,
              LigaCharacter.luma,
              stars: 2,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(WritingWorkshopScreen.routeName),
            ),
            _Portal(
              'Ilha dos Números',
              'Matemática com o Nico',
              Icons.calculate_rounded,
              LigaColors.primaryBlue,
              LigaCharacter.nico,
              stars: 1,
              onTap: () =>
                  Navigator.of(context).pushNamed(MathArenaScreen.routeName),
            ),
            _Portal(
              'Arquivo da Mila',
              'História com a Mila',
              Icons.manage_search_rounded,
              LigaColors.adventurePurple,
              LigaCharacter.mila,
              onTap: () =>
                  Navigator.of(context).pushNamed(MilaArchiveScreen.routeName),
            ),
            _Portal(
              'Trilha do Teo',
              'Ciências e Geografia',
              Icons.terrain_rounded,
              LigaColors.progressGreen,
              LigaCharacter.teo,
              onTap: () =>
                  Navigator.of(context).pushNamed(TeoTrailScreen.routeName),
            ),
            _Portal(
              'Oficina do Zuri',
              'Projetos e ideias',
              Icons.lightbulb_rounded,
              LigaColors.sunsetOrange,
              LigaCharacter.zuri,
              onTap: () =>
                  Navigator.of(context).pushNamed(ZuriAtelierScreen.routeName),
            ),
          ],
        ),
      ],
    );
  }
}

class _Portal {
  const _Portal(
    this.title,
    this.subject,
    this.icon,
    this.color,
    this.character, {
    this.stars = 0,
    required this.onTap,
  });

  final String title;
  final String subject;
  final IconData icon;
  final Color color;
  final LigaCharacter character;
  final int stars;
  final VoidCallback onTap;
}

/// Trilha em zigue-zague ligando os portais, como num mapa de jogo.
class _PortalTrail extends StatelessWidget {
  const _PortalTrail({required this.portals});

  final List<_Portal> portals;

  static const _rowHeight = 186.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight * portals.length,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TrailPainter(portals.length, _rowHeight),
            ),
          ),
          for (var i = 0; i < portals.length; i++)
            Positioned(
              top: i * _rowHeight,
              left: 0,
              right: 0,
              height: _rowHeight,
              child: Align(
                alignment: Alignment(i.isEven ? -0.75 : 0.75, 0),
                child: PopIn(
                  delay: Duration(milliseconds: 120 * i),
                  child: _PortalNode(portal: portals[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.count, this.rowHeight);

  final int count;
  final double rowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    // Mesmo cálculo do Align(±0.75) dos portais, que têm 170 de largura.
    final sideX = (size.width - 170) * 0.125 + 85;
    final points = [
      for (var i = 0; i < count; i++)
        Offset(
          i.isEven ? sideX : size.width - sideX,
          i * rowHeight + rowHeight * 0.3,
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      path.cubicTo(
        a.dx,
        (a.dy + b.dy) / 2,
        b.dx,
        (a.dy + b.dy) / 2,
        b.dx,
        b.dy,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );

    final dash = Paint()
      ..color = LigaColors.achievementYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 22) {
        canvas.drawPath(metric.extractPath(d, d + 10), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.rowHeight != rowHeight;
}

class _PortalNode extends StatelessWidget {
  const _PortalNode({required this.portal});

  final _Portal portal;

  @override
  Widget build(BuildContext context) {
    final color = portal.color;
    return LigaPressable(
      onTap: portal.onTap,
      child: SizedBox(
        width: 170,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  LigaPortrait(character: portal.character, size: 96),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: color,
                        border: Border.all(color: LigaColors.ink, width: 3),
                      ),
                      child: Icon(portal.icon, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var s = 0; s < 3; s++)
                  Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: s < portal.stars
                        ? LigaColors.achievementYellow
                        : LigaColors.disabled,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LigaColors.ink, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    portal.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LigaColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    portal.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LigaColors.inkSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          label: 'Área dos responsáveis',
          icon: Icons.lock_rounded,
          color: LigaColors.adventurePurple,
          onPressed: () => ParentAreaScreen.open(context),
        ),
        LigaActionButton(
          label: 'Sair da conta',
          icon: Icons.logout_rounded,
          color: LigaColors.actionCoral,
          onPressed: () async {
            await AppRepository.instance.signOut();
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(OnboardingScreen.routeName, (_) => false);
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
