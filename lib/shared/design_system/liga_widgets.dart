import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'liga_mascots.dart';

/// Céu claro com nuvens, bolhas e estrelinhas que flutuam devagar.
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
          colors: [LigaColors.skyTop, Color(0xFFEAF6FF), LigaColors.skyBottom],
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

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _bubbles = [
    (0.08, 0.16, 38.0, LigaColors.achievementYellow),
    (0.92, 0.10, 54.0, LigaColors.actionCoral),
    (0.88, 0.52, 30.0, LigaColors.cyanGlow),
    (0.05, 0.62, 46.0, LigaColors.adventurePurple),
    (0.70, 0.90, 60.0, LigaColors.progressGreen),
    (0.18, 0.94, 26.0, LigaColors.sunsetOrange),
  ];

  static const _stars = [
    (0.22, 0.07, 7.0),
    (0.78, 0.30, 6.0),
    (0.12, 0.40, 5.0),
    (0.95, 0.75, 7.0),
    (0.40, 0.82, 5.0),
    (0.60, 0.04, 5.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value * 2 * math.pi;

    _paintCloud(canvas, Offset(size.width * 0.25, size.height * 0.24), 1);
    _paintCloud(canvas, Offset(size.width * 0.80, size.height * 0.68), 0.8);

    for (var i = 0; i < _bubbles.length; i++) {
      final (x, y, r, color) = _bubbles[i];
      final drift = math.sin(phase + i) * 6;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y + drift),
        r,
        Paint()..color = color.withValues(alpha: 0.16),
      );
    }

    for (var i = 0; i < _stars.length; i++) {
      final (x, y, r) = _stars[i];
      final twinkle = 0.45 + 0.35 * (1 + math.sin(phase * 2 + i * 1.7)) / 2;
      canvas.drawPath(
        ligaStarPath(Offset(size.width * x, size.height * y), r),
        Paint()
          ..color = LigaColors.achievementYellow.withValues(alpha: twinkle),
      );
    }
  }

  void _paintCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(center, 22 * scale, paint);
    canvas.drawCircle(
      center + Offset(-24 * scale, 8 * scale),
      15 * scale,
      paint,
    );
    canvas.drawCircle(
      center + Offset(24 * scale, 8 * scale),
      17 * scale,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, 14 * scale),
          width: 76 * scale,
          height: 18 * scale,
        ),
        Radius.circular(9 * scale),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) => false;
}

/// Cartão branco, bem arredondado, com "sombra de brinquedo" embaixo.
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
  final Color? borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final edge = borderColor ?? const Color(0xFFE3E9F7);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: edge, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? LigaColors.ink).withValues(
              alpha: borderColor == null ? 0.07 : 0.28,
            ),
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: LigaColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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

/// Botão grande e "fofinho", com borda inferior que afunda ao apertar.
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
                    borderRadius: BorderRadius.circular(22),
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
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(face, Colors.white, 0.18)!, face],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
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
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
        boxShadow: [
          BoxShadow(color: LigaColors.shade(color), offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
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
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped == 0 ? 0 : math.max(clamped, 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
          padding: EdgeInsets.fromLTRB(
            height * 0.5,
            height * 0.2,
            height * 0.5,
            height * 0.55,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
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

  /// Fundo cheio, para usar sobre cartões coloridos.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: solid ? LigaColors.ink : LigaColors.shade(color, 0.08),
            size: 18,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: solid ? LigaColors.ink : LigaColors.shade(color, 0.22),
                fontWeight: FontWeight.w900,
                fontSize: 14,
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
                  Icon(Icons.play_circle_fill_rounded, color: color, size: 34),
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
                    color: LigaColors.shade(color, 0.12),
                    fontWeight: FontWeight.w900,
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
            Icon(icon, color: color ?? LigaColors.sunsetOrange, size: 26),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
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
    final edge = color ?? const Color(0xFFE3E9F7);
    return CustomPaint(
      painter: _BubbleTailPainter(edge),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: edge, width: 2.5),
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
      ..moveTo(12, y - 9)
      ..lineTo(0, y + 2)
      ..lineTo(12, y + 7)
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
            color: Colors.white,
            solid: true,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: LigaColors.shade(color), offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
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
