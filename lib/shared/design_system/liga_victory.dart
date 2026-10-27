import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/child_profile.dart';
import '../models/progress_update.dart';
import 'liga_game.dart';
import 'liga_rewards.dart';
import 'liga_sound.dart';

/// Tela cheia de vitória que aparece quando uma atividade dá XP: baú
/// abrindo, o que a criança ganhou e a barra do nível enchendo.
class LigaVictory {
  LigaVictory._();

  /// Os testes desligam para conferir o cartão de recompensa embaixo.
  static bool enabled = true;

  /// Cada resultado comemora uma vez só, mesmo que o cartão seja recriado.
  static final _shown = Expando<bool>();

  static void maybeShow(BuildContext context, ProgressUpdate progress) {
    if (!enabled || progress.xpGained <= 0 || _shown[progress] == true) return;
    _shown[progress] = true;
    LigaSound.play(LigaSfx.vitoria);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, _, _) => _VictoryView(progress: progress),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

class _VictoryView extends StatefulWidget {
  const _VictoryView({required this.progress});

  final ProgressUpdate progress;

  @override
  State<_VictoryView> createState() => _VictoryViewState();
}

class _VictoryViewState extends State<_VictoryView>
    with SingleTickerProviderStateMixin {
  /// Abre o baú, mostra os prêmios e enche a barra, nessa ordem.
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _chestOpen = false;

  @override
  void initState() {
    super.initState();
    _intro.addListener(() {
      if (!_chestOpen && _intro.value > 0.25) {
        setState(() => _chestOpen = true);
        LigaSound.play(LigaSfx.bau);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isAnimating || _intro.isCompleted) return;
    if (LigaMotion.of(context)) {
      _intro.forward();
    } else {
      _intro.value = 1;
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Valor de 0 a 1 do trecho [begin]–[end] da introdução, com quique.
  double _stage(double begin, double end, [Curve curve = Curves.easeOutBack]) {
    final t = ((_intro.value - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final levelStart = ChildProfile.levelStartXp(p.level);
    final levelGoal = ChildProfile.levelStartXp(p.level + 1) - levelStart;
    final levelXp = p.totalXp - levelStart;
    final before = ((levelXp - p.xpGained) / levelGoal).clamp(0.0, 1.0);
    final after = (levelXp / levelGoal).clamp(0.0, 1.0);

    final loot = <Widget>[
      _Loot(
        icon: Icons.star_rounded,
        value: '+${p.xpGained}',
        label: 'XP',
        color: LigaColors.adventurePurple,
      ),
      if (p.missionTitle != null)
        _Loot(
          icon: Icons.flag_rounded,
          value: '+${p.missionXp}',
          label: 'missão do dia',
          color: LigaColors.actionCoral,
        )
      else
        _Loot(
          icon: Icons.local_fire_department_rounded,
          value: '${p.streakDays}',
          label: p.streakDays == 1 ? 'dia seguido' : 'dias seguidos',
          color: LigaColors.sunsetOrange,
        ),
      if (p.leveledUp)
        _Loot(
          icon: Icons.military_tech_rounded,
          value: '${p.level}',
          label: 'nível novo!',
          color: LigaColors.cyanGlow,
        )
      else
        _Loot(
          icon: Icons.emoji_events_rounded,
          value: '${p.newBadges.length}',
          label: p.newBadges.length == 1 ? 'medalha nova' : 'medalhas novas',
          color: LigaColors.cyanGlow,
        ),
    ];

    return Material(
      color: LigaNight.deep,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 0.9,
                colors: [Color(0xFF3D4FD6), LigaNight.middle, LigaNight.deep],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LigaLoop(
                duration: const Duration(seconds: 16),
                builder: (context, t, _) =>
                    CustomPaint(painter: _RaysPainter(t)),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) => LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 44,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Transform.scale(
                            scale: _stage(0, 0.2),
                            child: const LigaGameText(
                              'VITÓRIA!',
                              size: 54,
                              color: LigaColors.achievementYellow,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Opacity(
                            opacity: _stage(0.1, 0.3, Curves.easeOut),
                            child: const Text(
                              'Resposta certa vale ponto. Continue assim!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _ChestBurst(open: _chestOpen),
                          const Spacer(),
                          Row(
                            children: [
                              for (var i = 0; i < loot.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: Transform.scale(
                                    scale: _stage(
                                      0.3 + 0.08 * i,
                                      0.5 + 0.08 * i,
                                    ),
                                    child: loot[i],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          for (final badge in p.newBadges) ...[
                            const SizedBox(height: 10),
                            Opacity(
                              opacity: _stage(0.55, 0.7, Curves.easeOut),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    ligaIconFor(badge.icon),
                                    color: ligaColorFor(badge.icon),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Medalha nova: ${badge.name}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _LevelBar(
                            level: p.level,
                            value: p.leveledUp
                                ? after
                                : before +
                                      (after - before) *
                                          _stage(0.6, 1, Curves.easeOutCubic),
                            xp: levelXp,
                            goal: levelGoal,
                          ),
                          const SizedBox(height: 22),
                          LigaPlayButton(
                            label: 'CONTINUAR',
                            color: LigaColors.primaryBlue,
                            textColor: Colors.white,
                            height: 64,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChestBurst extends StatelessWidget {
  const _ChestBurst({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: open ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: 220,
              height: 170,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFF7C2),
                    Color(0x99FFC233),
                    Color(0x00FFC233),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
          ),
          AnimatedScale(
            scale: open ? 1.08 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: LigaChestIcon(open: open, size: 120),
          ),
        ],
      ),
    );
  }
}

class _Loot extends StatelessWidget {
  const _Loot({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LigaColors.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: LigaColors.ink, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28, shadows: ligaOutline(1.3)),
          LigaGameText(value, size: 24),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              shadows: ligaOutline(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.level,
    required this.value,
    required this.xp,
    required this.goal,
  });

  final int level;
  final double value;
  final int xp;
  final int goal;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: 13,
    );
    return Column(
      children: [
        Row(
          children: [
            Text('Nível $level', style: label),
            const Spacer(),
            Text('$xp/$goal XP', style: label),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0x73000000),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: LigaColors.ink, width: 3),
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
        ),
      ],
    );
  }
}

/// Raios dourados girando atrás do baú.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.longestSide * 0.8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x55FFD65A), Color(0x00FFD65A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.7));
    const rays = 18;
    for (var i = 0; i < rays; i++) {
      final a = t * 2 * math.pi + i * 2 * math.pi / rays;
      const half = math.pi / rays / 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(a - half),
          center.dy + radius * math.sin(a - half),
        )
        ..lineTo(
          center.dx + radius * math.cos(a + half),
          center.dy + radius * math.sin(a + half),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t;
}
