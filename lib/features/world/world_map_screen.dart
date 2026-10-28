import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design_system/liga_avatars.dart';
import '../../shared/design_system/liga_game.dart';
import '../../shared/design_system/liga_mascots.dart';
import '../../shared/design_system/liga_widgets.dart';
import '../../shared/services/app_repository.dart';
import 'boss/boss_battle_screen.dart';
import 'world_islands.dart';

/// Mundo da Liga: uma ilha por herói, cada uma com uma trilha de fases que
/// termina num chefão. A fase seguinte só abre quando a criança vence a
/// atual (uma atividade que valeu XP).
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  Map<String, int>? _counts;
  Map<String, int> _bosses = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _counts ??= const {};
        _error = error is AppRepositoryException
            ? error.message
            : 'Não consegui carregar o seu progresso agora.';
      });
    }
  }

  Future<void> _fightBoss(LigaIsland island) async {
    await BossBattleScreen.open(context, island);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final avatar = LigaAvatar.byId(
      AppRepository.instance.childProfile.avatarId,
    );
    return LigaNightBackground(
      glow: LigaColors.primaryBlue,
      child: SafeArea(
        bottom: false,
        child: counts == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                children: [
                  const LigaGameText('Mundo da Liga', size: 30),
                  const SizedBox(height: 4),
                  const Text(
                    'Cada desafio vencido abre a próxima fase. '
                    'Escolha uma ilha e avance!',
                    style: TextStyle(
                      color: LigaNight.textSoft,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    LigaPanel(child: Text(_error!)),
                  ],
                  for (var i = 0; i < LigaIsland.all.length; i++) ...[
                    const SizedBox(height: 18),
                    PopIn(
                      delay: Duration(milliseconds: 90 * i),
                      child: _IslandCard(
                        island: LigaIsland.all[i],
                        counts: counts,
                        bossStars: _bosses[LigaIsland.all[i].id],
                        player: avatar.character,
                        onBoss: () => _fightBoss(LigaIsland.all[i]),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({
    required this.island,
    required this.counts,
    required this.bossStars,
    required this.player,
    required this.onBoss,
  });

  final LigaIsland island;
  final Map<String, int> counts;

  /// Estrelas do chefão vencido, ou null se ainda não foi vencido.
  final int? bossStars;
  final LigaCharacter player;
  final VoidCallback onBoss;

  @override
  Widget build(BuildContext context) {
    final character = island.character;
    final cleared = island.clearedPhases(counts) + (bossStars != null ? 1 : 0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LigaColors.shade(character.color, 0.32),
          border: Border.all(color: LigaColors.ink, width: 3.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    character.scene,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.3),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x000A0F2E), Color(0xD90A0F2E)],
                        stops: [0.3, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LigaGameText(island.name, size: 23, maxLines: 1),
                              const SizedBox(height: 2),
                              Text(
                                island.challenge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LigaHudChip(
                          icon: Icons.flag_rounded,
                          label: '$cleared/${LigaIsland.phases}',
                          color: character.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Trail(
              island: island,
              counts: counts,
              bossStars: bossStars,
              player: player,
              onBoss: onBoss,
            ),
          ],
        ),
      ),
    );
  }
}

/// Trilha em curva com as fases da ilha, de cima para baixo.
class _Trail extends StatelessWidget {
  const _Trail({
    required this.island,
    required this.counts,
    required this.bossStars,
    required this.player,
    required this.onBoss,
  });

  final LigaIsland island;
  final Map<String, int> counts;
  final int? bossStars;
  final LigaCharacter player;
  final VoidCallback onBoss;

  static const _step = 84.0;
  static const _top = 56.0;

  /// Posição horizontal da fase, de 0 a 1, ondulando pela largura.
  static double _x(int index) => 0.5 + 0.3 * math.sin(index * 1.1);

  void _open(BuildContext context, int phase) {
    final current = island.currentPhase(counts);
    if (phase == LigaIsland.phases) {
      if (island.bossReady(counts)) {
        onBoss();
      } else {
        _say(
          context,
          'O ${island.boss} espera no fim da trilha. '
          'Vença as fases antes dele!',
        );
      }
      return;
    }
    if (phase > current) {
      _say(context, 'Vença a fase $current para abrir esta.');
      return;
    }
    Navigator.of(context).pushNamed(island.routeFor(phase));
  }

  void _say(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final current = island.currentPhase(counts);
    final height = _top + _step * (LigaIsland.phases - 1) + 64;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          Offset at(int index) =>
              Offset(width * _x(index), _top + _step * index);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter([
                    for (var i = 0; i < LigaIsland.phases; i++) at(i),
                  ], cleared: island.clearedPhases(counts)),
                ),
              ),
              for (var i = 0; i < LigaIsland.phases; i++)
                _place(
                  at(i),
                  _PhaseNode(
                    key: ValueKey('fase-${island.character.id}-${i + 1}'),
                    phase: i + 1,
                    state: i + 1 == LigaIsland.phases
                        ? (bossStars != null
                              ? _PhaseState.bossBeaten
                              : island.bossReady(counts)
                              ? _PhaseState.boss
                              : _PhaseState.bossLocked)
                        : i + 1 < current
                        ? _PhaseState.done
                        : i + 1 == current
                        ? _PhaseState.current
                        : _PhaseState.locked,
                    color: island.character.color,
                    bossIcon: island.bossIcon,
                    stars: bossStars ?? 0,
                    onTap: () => _open(context, i + 1),
                  ),
                ),
              if (bossStars == null)
                Positioned(
                  left: at(current - 1).dx - 22,
                  top: at(current - 1).dy - 78,
                  child: IgnorePointer(child: _PlayerPin(character: player)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _place(Offset center, Widget child) {
    const box = 76.0;
    return Positioned(
      left: center.dx - box / 2,
      top: center.dy - box / 2,
      width: box,
      height: box,
      child: Center(child: child),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, {required this.cleared});

  final List<Offset> points;
  final int cleared;

  Path _through(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _through(points);
    canvas.drawPath(
      path,
      Paint()
        ..color = LigaColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    // Trecho já percorrido em dourado.
    if (cleared > 0) {
      canvas.drawPath(
        _through(points.sublist(0, cleared + 1)),
        Paint()
          ..color = LigaColors.achievementYellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.cleared != cleared || old.points != points;
}

enum _PhaseState { done, current, locked, boss, bossLocked, bossBeaten }

class _PhaseNode extends StatelessWidget {
  const _PhaseNode({
    super.key,
    required this.phase,
    required this.state,
    required this.color,
    required this.bossIcon,
    required this.stars,
    required this.onTap,
  });

  final int phase;
  final _PhaseState state;
  final Color color;
  final IconData bossIcon;

  /// Estrelas do chefão vencido.
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final node = switch (state) {
      _PhaseState.done => _disc(
        size: 50,
        top: const Color(0xFFFFE680),
        bottom: LigaColors.achievementYellow,
        child: const Icon(Icons.check_rounded, color: LigaColors.ink, size: 30),
      ),
      _PhaseState.current => LigaLoop(
        duration: const Duration(milliseconds: 1300),
        builder: (context, t, child) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LigaColors.cyanGlow.withValues(alpha: 0.8 * (1 - t)),
                spreadRadius: 16 * t,
              ),
            ],
          ),
          child: child,
        ),
        child: _disc(
          size: 62,
          top: const Color(0xFF7DFCD9),
          bottom: LigaColors.cyanGlow,
          child: Text('$phase', style: _number(LigaColors.ink, 26)),
        ),
      ),
      _PhaseState.locked => _disc(
        size: 46,
        top: const Color(0xFF7A82AE),
        bottom: const Color(0xFF5B6390),
        child: const Icon(
          Icons.lock_rounded,
          color: Color(0xFFC9CFEE),
          size: 22,
        ),
      ),
      _PhaseState.boss => LigaLoop(
        duration: const Duration(milliseconds: 1100),
        builder: (context, t, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4757).withValues(alpha: 0.8 * (1 - t)),
                spreadRadius: 14 * t,
              ),
            ],
          ),
          child: child,
        ),
        child: _bossBox(
          colors: const [Color(0xFFFF8A9F), Color(0xFFFF4757)],
          icon: bossIcon,
          label: 'LUTAR!',
        ),
      ),
      _PhaseState.bossLocked => _bossBox(
        colors: const [Color(0xFF8A6A7A), Color(0xFF6A4B5C)],
        icon: Icons.lock_rounded,
        label: 'CHEFÃO',
      ),
      _PhaseState.bossBeaten => _bossBox(
        colors: const [Color(0xFFFFE680), LigaColors.achievementYellow],
        icon: Icons.emoji_events_rounded,
        label: '★' * stars + '☆' * (3 - stars),
        dark: true,
      ),
    };
    return Semantics(
      button: true,
      label: switch (state) {
        _PhaseState.boss => 'Chefão: lutar',
        _PhaseState.bossLocked => 'Chefão bloqueado',
        _PhaseState.bossBeaten => 'Chefão vencido, $stars estrelas',
        _ => 'Fase $phase',
      },
      child: LigaPressable(onTap: onTap, child: node),
    );
  }

  static TextStyle _number(Color color, double size) => TextStyle(
    fontFamily: LigaTheme.displayFont,
    fontWeight: FontWeight.w800,
    fontSize: size,
    height: 1,
    color: color,
    shadows: color == Colors.white ? ligaOutline(1.2) : null,
  );

  Widget _bossBox({
    required List<Color> colors,
    required IconData icon,
    required String label,
    bool dark = false,
  }) {
    final ink = dark ? LigaColors.ink : Colors.white;
    return Container(
      width: 72,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LigaColors.ink, width: 3.5),
        boxShadow: const [
          BoxShadow(color: LigaColors.ink, offset: Offset(0, 5)),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: ink,
            size: 26,
            shadows: dark ? null : ligaOutline(1.2),
          ),
          Text(label, style: _number(ink, 12)),
        ],
      ),
    );
  }

  Widget _disc({
    required double size,
    required Color top,
    required Color bottom,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: LigaColors.ink, width: 3.5),
        boxShadow: const [
          BoxShadow(color: LigaColors.ink, offset: Offset(0, 5)),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: child,
    );
  }
}

/// O herói da criança pulando em cima da fase atual.
class _PlayerPin extends StatelessWidget {
  const _PlayerPin({required this.character});

  final LigaCharacter character;

  @override
  Widget build(BuildContext context) {
    return LigaBob(
      distance: 9,
      duration: const Duration(milliseconds: 600),
      child: LigaPortrait(character: character, size: 44),
    );
  }
}
