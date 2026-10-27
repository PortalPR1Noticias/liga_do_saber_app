import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'liga_mascots.dart';

/// Céu azul com pinos de Lego/Roblox, blocos e estrelinhas que flutuam.
class LigaBackground extends StatefulWidget {
  const LigaBackground({super.key, required this.child});

  final Widget child;

  @override
  State<LigaBackground> createState() => _LigaBackgroundState();
}

class _LigaBackgroundState extends State<LigaBackground>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LigaMotion.of(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [LigaColors.skyTop, Color(0xFF9BD8FF), LigaColors.skyBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _SkyPainter(_controller)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Fundo de "baseplate": pinos (studs) bem leves, blocos coloridos
/// flutuando e estrelinhas.
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _blocks = [
    (0.07, 0.14, 30.0, 0.3, LigaColors.achievementYellow),
    (0.93, 0.09, 40.0, -0.25, LigaColors.actionCoral),
    (0.90, 0.50, 24.0, 0.5, LigaColors.cyanGlow),
    (0.04, 0.60, 34.0, -0.4, LigaColors.adventurePurple),
    (0.74, 0.92, 44.0, 0.2, LigaColors.progressGreen),
    (0.16, 0.95, 22.0, 0.6, LigaColors.sunsetOrange),
  ];

  static const _stars = [
    (0.24, 0.06, 7.0),
    (0.78, 0.30, 6.0),
    (0.13, 0.38, 5.0),
    (0.96, 0.74, 7.0),
    (0.42, 0.84, 5.0),
    (0.60, 0.03, 5.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value * 2 * math.pi;

    // Pinos de Lego/Roblox em grade.
    const gap = 34.0;
    final stud = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final studShadow = Paint()..color = LigaColors.ink.withValues(alpha: 0.05);
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y + 1.5), 7, studShadow);
        canvas.drawCircle(Offset(x, y), 7, stud);
      }
    }

    final outline = Paint()
      ..color = LigaColors.ink.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 0; i < _blocks.length; i++) {
      final (x, y, side, angle, color) = _blocks[i];
      final drift = math.sin(phase + i) * 6;
      canvas.save();
      canvas.translate(size.width * x, size.height * y + drift);
      canvas.rotate(angle + math.sin(phase + i) * 0.08);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Radius.circular(side * 0.18),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.55));
      canvas.drawRRect(rect, outline);
      // Pino no topo do bloco.
      canvas.drawCircle(
        Offset.zero,
        side * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
      canvas.restore();
    }

    for (var i = 0; i < _stars.length; i++) {
      final (x, y, r) = _stars[i];
      final twinkle = 0.55 + 0.4 * (1 + math.sin(phase * 2 + i * 1.7)) / 2;
      canvas.drawPath(
        ligaStarPath(Offset(size.width * x, size.height * y), r),
        Paint()..color = Colors.white.withValues(alpha: twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) => false;
}

/// Cartão branco em bloco, com contorno grosso e sombra dura embaixo.
class LigaPanel extends StatelessWidget {
  const LigaPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.color = LigaColors.cardWhite,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Cor da sombra dura embaixo do cartão (o contorno é sempre azul-marinho).
  final Color? borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final accent = borderColor?.withValues(alpha: 1);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LigaColors.ink, width: 3),
        boxShadow: [
          BoxShadow(
            color: accent == null ? LigaColors.ink : LigaColors.shade(accent),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Encolhe um pouquinho ao toque, como um botão de brinquedo.
class LigaPressable extends StatefulWidget {
  const LigaPressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<LigaPressable> createState() => _LigaPressableState();
}

class _LigaPressableState extends State<LigaPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Botão grande em bloco, com contorno grosso, brilho no topo e borda
/// inferior que afunda ao apertar (estilo botão de jogo Roblox).
class LigaActionButton extends StatefulWidget {
  const LigaActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = LigaColors.progressGreen,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  State<LigaActionButton> createState() => _LigaActionButtonState();
}

class _LigaActionButtonState extends State<LigaActionButton> {
  static const _depth = 6.0;
  static final _outline = ligaOutline(1.8);
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final face = _enabled ? widget.color : LigaColors.disabled;
    final edge = LigaColors.shade(face);
    final sink = _pressed ? _depth : 0.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: SizedBox(
          width: double.infinity,
          height: 62,
          child: Stack(
            children: [
              Positioned.fill(
                top: _depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: edge,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LigaColors.ink, width: 3),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                left: 0,
                right: 0,
                top: sink,
                bottom: _depth - sink,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LigaColors.ink, width: 3),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.5, 0.5, 1],
                      colors: [
                        Color.lerp(face, Colors.white, 0.3)!,
                        Color.lerp(face, Colors.white, 0.15)!,
                        face,
                        face,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 26,
                          shadows: _outline,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: LigaTheme.displayFont,
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              shadows: _outline,
                            ),
                          ),
                        ),
                      ],
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

/// Quadradinho colorido com ícone, usado como "selo" das áreas.
class LigaIconBubble extends StatelessWidget {
  const LigaIconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: LigaColors.ink, width: 2.5),
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
        boxShadow: const [
          BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.55,
        shadows: ligaOutline(1.4),
      ),
    );
  }
}

/// Barra de progresso grossa, com brilho, no estilo de jogo.
class LigaProgressBar extends StatelessWidget {
  const LigaProgressBar({
    super.key,
    required this.value,
    this.color = LigaColors.progressGreen,
    this.height = 16,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      height: height + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LigaColors.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped == 0 ? 0 : math.max(clamped, 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          padding: EdgeInsets.fromLTRB(
            height * 0.3,
            height * 0.15,
            height * 0.3,
            height * 0.55,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta arredondada com ícone (XP, sequência de dias, nível).
class LigaPill extends StatelessWidget {
  const LigaPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.solid = false,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Mantido por compatibilidade: a etiqueta agora é sempre cheia.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    // Fundo branco pede texto escuro; nas outras cores o texto é branco
    // com contorno, como os contadores de moedas dos jogos.
    final onWhite = color == Colors.white;
    final textColor = onWhite ? LigaColors.ink : Colors.white;
    final shadows = onWhite ? null : ligaOutline(1.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LigaColors.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18, shadows: shadows),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: LigaTheme.displayFont,
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.25,
                letterSpacing: onWhite ? 0 : 0.5,
                shadows: shadows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: LigaPanel(
        borderColor: color.withValues(alpha: 0.55),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LigaIconBubble(icon: icon, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  LigaIconBubble(
                    icon: Icons.play_arrow_rounded,
                    color: LigaColors.progressGreen,
                    size: 38,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: LigaProgressBar(value: progress, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontFamily: LigaTheme.displayFont,
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    shadows: ligaOutline(1.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color ?? LigaColors.achievementYellow,
              size: 28,
              shadows: ligaOutline(1.8),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 0.8,
                shadows: ligaOutline(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Balão de fala de um mascote.
class LigaSpeechBubble extends StatelessWidget {
  const LigaSpeechBubble({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    const edge = LigaColors.ink;
    return CustomPaint(
      painter: _BubbleTailPainter(edge),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: edge, width: 3),
          boxShadow: [
            BoxShadow(
              color: color?.withValues(alpha: 1) ?? edge,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: LigaColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter(this.edge);

  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final tail = Path()
      ..moveTo(13, y - 10)
      ..lineTo(0, y + 2)
      ..lineTo(13, y + 8)
      ..close();
    canvas.drawPath(tail, Paint()..color = edge);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      oldDelegate.edge != edge;
}

/// Logo oficial da Liga do Saber.
class LigaLogo extends StatelessWidget {
  const LigaLogo({super.key, this.height = 140});

  static const imageKey = ValueKey('liga-logo');

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/logo.png',
      key: imageKey,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Liga do Saber',
    );
  }
}

/// Cabeçalho das áreas de estudo: a cena do personagem com o título por cima.
class LigaFeatureHeader extends StatelessWidget {
  const LigaFeatureHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.character,
  });

  final String title;
  final String subtitle;
  final Color color;
  final LigaCharacter character;

  @override
  Widget build(BuildContext context) {
    return LigaSceneCard(
      character: character,
      color: color,
      height: 210,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LigaPill(
            icon: Icons.person_pin_circle_rounded,
            label: 'com ${character.displayName}',
            color: color,
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              shadows: ligaOutline(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão com a cena ilustrada de um personagem ao fundo e um degradê na
/// cor da área embaixo, para o texto ficar legível.
class LigaSceneCard extends StatelessWidget {
  const LigaSceneCard({
    super.key,
    required this.character,
    required this.color,
    required this.child,
    this.height = 200,
  });

  final LigaCharacter character;
  final Color color;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final deep = LigaColors.shade(color, 0.22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LigaColors.ink, width: 3.5),
        boxShadow: const [
          BoxShadow(color: LigaColors.ink, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.5),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                character.scene,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.4),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.2, 1],
                    colors: [
                      deep.withValues(alpha: 0),
                      deep.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
            // Cresce se o texto precisar (fonte grande do sistema), mas
            // nunca fica menor que [height], para a cena aparecer.
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: height),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Faz o conteúdo surgir com um "pulinho" ao abrir a tela.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 420);

  late final _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _duration).inMilliseconds,
      1,
      curve: Curves.easeOutBack,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (LigaMotion.of(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Aviso padrão para recursos que ainda não foram implementados no protótipo.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Disponível em breve na Liga do Saber.')),
    );
}
