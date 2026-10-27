import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/services/app_repository.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../math_arena/presentation/math_arena_screen.dart';
import '../../reading_detective/presentation/reading_detective_screen.dart';
import '../../writing_workshop/presentation/writing_workshop_screen.dart';

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
              locked: true,
              onTap: () => showComingSoon(context),
            ),
            _Portal(
              'Trilha do Teo',
              'Ciências e Geografia',
              Icons.terrain_rounded,
              LigaColors.progressGreen,
              LigaCharacter.teo,
              locked: true,
              onTap: () => showComingSoon(context),
            ),
            _Portal(
              'Ateliê do Zuri',
              'Projetos e ideias',
              Icons.lightbulb_rounded,
              LigaColors.sunsetOrange,
              LigaCharacter.zuri,
              locked: true,
              onTap: () => showComingSoon(context),
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
    this.locked = false,
    required this.onTap,
  });

  final String title;
  final String subject;
  final IconData icon;
  final Color color;
  final LigaCharacter character;
  final int stars;
  final bool locked;
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
    final color = portal.locked ? LigaColors.disabled : portal.color;
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
                  LigaPortrait(
                    character: portal.character,
                    size: 96,
                    locked: portal.locked,
                  ),
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
                      child: Icon(
                        portal.locked ? Icons.lock_rounded : portal.icon,
                        color: Colors.white,
                        size: 18,
                      ),
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
                    portal.locked ? 'Em breve' : portal.subject,
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

class _MissionsScreen extends StatelessWidget {
  const _MissionsScreen();

  @override
  Widget build(BuildContext context) {
    return const _ShellPage(
      title: 'Missões',
      subtitle: 'Desafios rapidinhos que valem XP. Bora?',
      character: LigaCharacter.luma,
      children: [
        _MissionRow(
          'Descobrir a ideia principal',
          '+25 XP',
          Icons.search_rounded,
          LigaColors.adventurePurple,
        ),
        _MissionRow(
          'Reescrever um parágrafo',
          '+35 XP',
          Icons.edit_rounded,
          LigaColors.actionCoral,
        ),
        _MissionRow(
          'Resolver desafio de frações',
          '+20 XP',
          Icons.functions_rounded,
          LigaColors.primaryBlue,
        ),
        _MissionRow(
          'Enviar foto da tarefa',
          '+15 XP',
          Icons.camera_alt_rounded,
          LigaColors.progressGreen,
        ),
      ],
    );
  }
}

class _ProgressScreen extends StatelessWidget {
  const _ProgressScreen();

  @override
  Widget build(BuildContext context) {
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
                      '${profile.totalXp % ChildProfile.levelXpGoal} / '
                      '${ChildProfile.levelXpGoal} XP',
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
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _Badge(
              'Detetive da Leitura',
              Icons.search_rounded,
              LigaColors.adventurePurple,
            ),
            _Badge(
              'Escritor Criativo',
              Icons.edit_rounded,
              LigaColors.actionCoral,
            ),
            _Badge(
              'Sequência de Fogo',
              Icons.local_fire_department_rounded,
              LigaColors.sunsetOrange,
            ),
            _Badge(
              'Mestre das Frações',
              Icons.functions_rounded,
              LigaColors.primaryBlue,
              earned: false,
            ),
            _Badge(
              'Explorador do Mapa',
              Icons.map_rounded,
              LigaColors.progressGreen,
              earned: false,
            ),
            _Badge(
              'Cientista Curioso',
              Icons.science_rounded,
              LigaColors.cyanGlow,
              earned: false,
            ),
          ],
        ),
        const _MissionRow(
          'Ponto forte',
          'Interpretação explícita',
          Icons.thumb_up_alt_rounded,
          LigaColors.progressGreen,
        ),
        const _MissionRow(
          'Praticar mais',
          'Pontuação em textos',
          Icons.tips_and_updates_rounded,
          LigaColors.achievementYellow,
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
          onPressed: () => showComingSoon(context),
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
