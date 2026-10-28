import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_game.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/league_progress.dart';
import '../../../shared/services/app_repository.dart';
import '../../minigames/presentation/minigames_hub_screen.dart';
import '../../photo_solver/presentation/photo_solver_flow_screen.dart';
import '../../practice_exam/presentation/revanche_screen.dart';
import '../../world/boss/boss_battle_screen.dart';
import '../../world/world_islands.dart';

/// A Base do jogador: o herói escolhido em destaque, o HUD com nível e
/// sequência, o baú das missões do dia e o botão JOGAR, que leva direto para
/// a próxima fase do Mundo da Liga.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenTab});

  /// Troca a aba do jogo (1 = Mundo, 2 = Missões, 3 = Conquistas).
  final ValueChanged<int>? onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DailyMission>? _missions;
  Map<String, int> _counts = const {};
  Map<String, int> _bosses = const {};

  @override
  void initState() {
    super.initState();
    final repository = AppRepository.instance;
    repository
        .loadDailyMissions()
        .then((missions) {
          if (mounted) setState(() => _missions = missions);
        })
        .catchError((_) {});
    _loadWorld();
  }

  Future<void> _loadWorld() async {
    final repository = AppRepository.instance;
    try {
      final results = await Future.wait([
        repository.loadActivityCounts(),
        repository.loadBossWins(),
      ]);
      if (!mounted) return;
      setState(() {
        _counts = results[0];
        _bosses = results[1];
      });
    } catch (_) {}
  }

  /// O chefão da ilha está esperando: fases vencidas e ele ainda de pé.
  bool _bossWaiting(LigaIsland island) =>
      island.bossReady(_counts) && !_bosses.containsKey(island.id);

  Future<void> _play() async {
    final island = LigaIsland.next(_counts, _bosses);
    if (_bossWaiting(island)) {
      await BossBattleScreen.open(context, island);
      await _loadWorld();
      return;
    }
    await Navigator.of(
      context,
    ).pushNamed(island.routeFor(island.currentPhase(_counts)));
    await _loadWorld();
  }

  String _playSubtitle(LigaIsland island) {
    if (_bossWaiting(island)) return 'Chefão: ${island.boss}';
    if (_bosses.containsKey(island.id)) return '${island.name} · Treino livre';
    return '${island.name} · Fase ${island.currentPhase(_counts)}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppRepository.instance.childProfile;
    final avatar = LigaAvatar.byId(profile.avatarId);
    final island = LigaIsland.next(_counts, _bosses);
    final missions = _missions;
    final missionsLeft = missions?.where((m) => !m.done).length ?? 0;

    return LigaNightBackground(
      glow: avatar.color,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 28,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _Hud(
                      avatarId: profile.avatarId,
                      nickname: profile.nickname,
                      level: profile.level,
                      levelProgress: profile.levelProgress,
                      levelXp: profile.levelXp,
                      levelXpGoal: profile.levelXpGoal,
                      streakDays: profile.streakDays,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            _SideTile(
                              label: 'Missões',
                              icon: Icons.flag_rounded,
                              color: LigaColors.actionCoral,
                              badge: missionsLeft,
                              onTap: () => widget.onOpenTab?.call(2),
                            ),
                            const SizedBox(height: 14),
                            _SideTile(
                              label: 'Troféus',
                              icon: Icons.emoji_events_rounded,
                              color: LigaColors.adventurePurple,
                              onTap: () => widget.onOpenTab?.call(3),
                            ),
                            const SizedBox(height: 14),
                            _SideTile(
                              label: 'Revanche',
                              icon: Icons.replay_rounded,
                              color: LigaColors.progressGreen,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RevancheScreen.routeName),
                            ),
                          ],
                        ),
                        Expanded(child: _Hero(avatar: avatar)),
                        Column(
                          children: [
                            _SideTile(
                              label: 'Jogos',
                              icon: Icons.sports_esports_rounded,
                              color: LigaColors.sunsetOrange,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(MinigamesHubScreen.routeName),
                            ),
                            const SizedBox(height: 14),
                            _SideTile(
                              label: 'Foto + IA',
                              icon: Icons.camera_alt_rounded,
                              color: LigaColors.primaryBlue,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(PhotoSolverFlowScreen.routeName),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DailyChest(
                      done: missions == null
                          ? 0
                          : missions.length - missionsLeft,
                      total: missions?.length ?? 0,
                      onTap: () => widget.onOpenTab?.call(2),
                    ),
                    const SizedBox(height: 14),
                    _IslandStrip(
                      counts: _counts,
                      bosses: _bosses,
                      onTap: () => widget.onOpenTab?.call(1),
                    ),
                    const Spacer(),
                    const SizedBox(height: 18),
                    LigaPlayButton(
                      label: 'JOGAR',
                      subtitle: _playSubtitle(island),
                      color: LigaColors.progressGreen,
                      textColor: Colors.white,
                      onPressed: _play,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.avatarId,
    required this.nickname,
    required this.level,
    required this.levelProgress,
    required this.levelXp,
    required this.levelXpGoal,
    required this.streakDays,
  });

  final String avatarId;
  final String nickname;
  final int level;
  final double levelProgress;
  final int levelXp;
  final int levelXpGoal;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              LigaAvatarBadge(avatarId: avatarId, radius: 24),
              Positioned(
                left: -6,
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: LigaColors.adventurePurple,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LigaColors.ink, width: 2),
                  ),
                  child: Text(
                    '$level',
                    style: TextStyle(
                      fontFamily: LigaTheme.displayFont,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 15,
                      shadows: ligaOutline(1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: LigaTheme.displayFont,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.1,
                  shadows: ligaOutline(1.2),
                ),
              ),
              const SizedBox(height: 4),
              _XpBar(value: levelProgress),
              const SizedBox(height: 2),
              Text(
                'Nível $level · $levelXp/$levelXpGoal XP',
                style: const TextStyle(
                  color: LigaNight.textSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        LigaHudChip(
          icon: Icons.local_fire_department_rounded,
          label: '$streakDays',
          color: LigaColors.sunsetOrange,
        ),
        const SizedBox(width: 8),
        const LigaSoundButton(),
      ],
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0x73000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LigaColors.ink, width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.02, 1.0),
            heightFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF3A0), LigaColors.achievementYellow],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O herói da criança no centro da Base, em cima de um pedestal brilhante.
class _Hero extends StatelessWidget {
  const _Hero({required this.avatar});

  final LigaAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final character = avatar.character;
    return Column(
      children: [
        LigaBob(
          tilt: 0.04,
          duration: const Duration(milliseconds: 1500),
          child: LigaPortrait(character: character, size: 164),
        ),
        Container(
          width: 150,
          height: 22,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.elliptical(75, 11)),
            color: character.color.withValues(alpha: 0.7),
            border: Border.all(color: LigaColors.ink, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: character.color.withValues(alpha: 0.8),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        LigaGameText(character.displayName, size: 26),
        Text(
          character.title,
          style: TextStyle(
            color: Color.lerp(character.color, Colors.white, 0.35),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Atalho quadrado nas laterais da Base, com contador opcional.
class _SideTile extends StatelessWidget {
  const _SideTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 62,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LigaColors.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: LigaColors.ink, offset: Offset(0, 4)),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.5, 0.5, 1],
                  colors: [
                    Color.lerp(color, Colors.white, 0.3)!,
                    Color.lerp(color, Colors.white, 0.15)!,
                    color,
                    color,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                    shadows: ligaOutline(1.4),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      shadows: ligaOutline(1),
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  height: 24,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LigaColors.ink, width: 2.5),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Baú das missões do dia: enche conforme a criança cumpre as missões, e
/// cada missão cumprida dá XP de bônus.
class _DailyChest extends StatelessWidget {
  const _DailyChest({
    required this.done,
    required this.total,
    required this.onTap,
  });

  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && done >= total;
    return LigaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: LigaNight.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LigaColors.ink, width: 3),
        ),
        child: Row(
          children: [
            LigaChestIcon(open: complete, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LigaGameText(
                    complete ? 'Baú do dia completo!' : 'Baú do dia',
                    size: 17,
                  ),
                  const SizedBox(height: 4),
                  LigaProgressBar(
                    value: total == 0 ? 0 : done / total,
                    color: LigaColors.achievementYellow,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    complete
                        ? 'Todas as missões de hoje feitas. Volte amanhã!'
                        : '$done de $total missões · cada uma dá XP extra',
                    style: const TextStyle(
                      color: LigaNight.textSoft,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

/// As cinco ilhas com as fases vencidas em cada uma: o que a criança já
/// treinou de cada matéria.
class _IslandStrip extends StatelessWidget {
  const _IslandStrip({
    required this.counts,
    required this.bosses,
    required this.onTap,
  });

  final Map<String, int> counts;
  final Map<String, int> bosses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: LigaNight.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LigaColors.ink, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LigaGameText('Suas ilhas', size: 17),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final island in LigaIsland.all)
                  Column(
                    children: [
                      LigaPortrait(character: island.character, size: 46),
                      const SizedBox(height: 4),
                      Text(
                        '${island.progress(counts, bosses)}/${LigaIsland.phases}',
                        style: TextStyle(
                          color: Color.lerp(
                            island.character.color,
                            Colors.white,
                            0.35,
                          ),
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
