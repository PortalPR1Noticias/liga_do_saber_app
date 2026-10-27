import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design_system/liga_avatars.dart';
import '../../shared/design_system/liga_game.dart';
import '../../shared/design_system/liga_mascots.dart';
import '../../shared/design_system/liga_widgets.dart';
import '../../shared/services/app_repository.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    AppRepository.instance
        .loadActivityCounts()
        .then((counts) {
          if (mounted) setState(() => _counts = counts);
        })
        .catchError((Object error) {
          if (!mounted) return;
          setState(() {
            _counts = const {};
            _error = error is AppRepositoryException
                ? error.message
                : 'Não consegui carregar o seu progresso agora.';
          });
        });
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
                        player: avatar.character,
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
    required this.player,
  });

  final LigaIsland island;
  final Map<String, int> counts;
  final LigaCharacter player;

  @override
  Widget build(BuildContext context) {
    final character = island.character;
    final cleared = island.clearedPhases(counts);
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
            _Trail(island: island, counts: counts, player: player),
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
    required this.player,
  });

  final LigaIsland island;
  final Map<String, int> counts;
  final LigaCharacter player;

  static const _step = 84.0;
  static const _top = 56.0;

  /// Posição horizontal da fase, de 0 a 1, ondulando pela largura.
  static double _x(int index) => 0.5 + 0.3 * math.sin(index * 1.1);

  void _open(BuildContext context, int phase) {
    final current = island.currentPhase(counts);
    if (phase == LigaIsland.phases) {
      _say(
        context,
        island.isComplete(counts)
            ? 'O chefão chega na próxima atualização. Continue treinando as fases!'
            : 'O chefão espera no fim da trilha. Vença as fases antes dele!',
      );
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
                        ? _PhaseState.boss
                        : i + 1 < current
                        ? _PhaseState.done
                        : i + 1 == current
                        ? _PhaseState.current
                        : _PhaseState.locked,
                    color: island.character.color,
                    onTap: () => _open(context, i + 1),
                  ),
                ),
              if (current < LigaIsland.phases)
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

enum _PhaseState { done, current, locked, boss }

class _PhaseNode extends StatelessWidget {
  const _PhaseNode({
    super.key,
    required this.phase,
    required this.state,
    required this.color,
    required this.onTap,
  });

  final int phase;
  final _PhaseState state;
  final Color color;
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
      _PhaseState.boss => Container(
        width: 72,
        height: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LigaColors.ink, width: 3.5),
          boxShadow: const [
            BoxShadow(color: LigaColors.ink, offset: Offset(0, 5)),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF8A9F), Color(0xFFFF4757)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.whatshot_rounded,
              color: Colors.white,
              size: 26,
              shadows: ligaOutline(1.2),
            ),
            Text('CHEFÃO', style: _number(Colors.white, 12)),
          ],
        ),
      ),
    };
    return Semantics(
      button: true,
      label: state == _PhaseState.boss ? 'Chefão' : 'Fase $phase',
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
