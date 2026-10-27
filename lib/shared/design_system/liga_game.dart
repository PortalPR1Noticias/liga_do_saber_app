import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'liga_sound.dart';

/// Repete uma animação enquanto as animações contínuas estão ligadas
/// ([LigaMotion]); com elas desligadas, desenha parado em `t = 0`.
class LigaLoop extends StatefulWidget {
  const LigaLoop({
    super.key,
    required this.duration,
    required this.builder,
    this.reverse = false,
    this.child,
  });

  final Duration duration;
  final bool reverse;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<LigaLoop> createState() => _LigaLoopState();
}

class _LigaLoopState extends State<LigaLoop>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LigaMotion.of(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: widget.reverse);
    } else {
      _controller
        ..stop()
        ..value = 0;
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
      animation: _controller,
      builder: (context, child) =>
          widget.builder(context, _controller.value, child),
      child: widget.child,
    );
  }
}

/// Cores das telas de jogo (entrada, Base e Mundo), que são noturnas.
class LigaNight {
  static const top = Color(0xFF2B3AA8);
  static const middle = Color(0xFF1A2275);
  static const bottom = Color(0xFF0E1446);
  static const deep = Color(0xFF0A0F2E);

  /// Fundo translúcido dos painéis do HUD.
  static const glass = Color(0xCC060A28);
  static const textSoft = Color(0xFFA9B4E6);
}

/// Fundo da Base: noite azul, chão de pinos em perspectiva e brilhos que
/// sobem devagar.
class LigaNightBackground extends StatelessWidget {
  const LigaNightBackground({super.key, required this.child, this.glow});

  final Widget child;

  /// Cor do brilho atrás do herói.
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [LigaNight.top, LigaNight.middle, LigaNight.bottom],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: LigaLoop(
                duration: const Duration(seconds: 6),
                builder: (context, t, _) => CustomPaint(
                  painter: _NightPainter(t, glow ?? LigaColors.cyanGlow),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _NightPainter extends CustomPainter {
  _NightPainter(this.t, this.glow);

  final double t;
  final Color glow;

  static const _sparks = [
    (0.12, 0.0), (0.3, 0.35), (0.52, 0.7), (0.71, 0.15), (0.88, 0.5), //
    (0.2, 0.85), (0.62, 0.42), (0.42, 0.1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Brilho atrás do herói.
    final center = Offset(size.width / 2, size.height * 0.36);
    canvas.drawCircle(
      center,
      size.width * 0.62,
      Paint()
        ..shader =
            RadialGradient(
              colors: [glow.withValues(alpha: 0.42), glow.withValues(alpha: 0)],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.62),
            ),
    );

    // Chão de pinos, mais juntos ao fundo, como uma baseplate em perspectiva.
    final floorTop = size.height * 0.58;
    final stud = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var row = 0; row < 14; row++) {
      final p = row / 13;
      final y = floorTop + (size.height - floorTop) * p * p;
      final spacing = 10 + 26 * p;
      final r = 1.5 + 3.5 * p;
      for (var x = -spacing / 2; x < size.width + spacing; x += spacing) {
        canvas.drawCircle(
          Offset(x + (row.isEven ? spacing / 2 : 0), y),
          r,
          stud,
        );
      }
    }

    // Brilhos subindo.
    for (final (x, phase) in _sparks) {
      final local = (t + phase) % 1;
      final y = size.height * (0.95 - 0.8 * local);
      final alpha = math.sin(local * math.pi);
      canvas.drawCircle(
        Offset(size.width * x, y),
        2.6,
        Paint()
          ..color = const Color(0xFFFFF2B0).withValues(alpha: alpha * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_NightPainter old) => old.t != t || old.glow != glow;
}

/// Texto de título de jogo: fonte grossa, branco com contorno azul-marinho.
class LigaGameText extends StatelessWidget {
  const LigaGameText(
    this.text, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final double size;
  final Color color;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: LigaTheme.displayFont,
        fontWeight: FontWeight.w800,
        fontSize: size,
        height: 1.05,
        color: color,
        shadows: ligaOutline(size / 14),
      ),
    );
  }
}

/// Peça do HUD: ícone e valor numa cápsula escura.
class LigaHudChip extends StatelessWidget {
  const LigaHudChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
      decoration: BoxDecoration(
        color: LigaNight.glass,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: LigaColors.ink, width: 2.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: LigaColors.ink, width: 2),
            ),
            child: Icon(icon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão de ligar e desligar o som.
class LigaSoundButton extends StatelessWidget {
  const LigaSoundButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: LigaSound.muted,
      builder: (context, muted, _) => Semantics(
        button: true,
        label: muted ? 'Ligar o som' : 'Desligar o som',
        child: GestureDetector(
          onTap: LigaSound.toggle,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LigaNight.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LigaColors.ink, width: 2.5),
            ),
            child: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// O botão principal do jogo: grande, em bloco, pulsando com brilho.
class LigaPlayButton extends StatefulWidget {
  const LigaPlayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.color = LigaColors.achievementYellow,
    this.textColor = LigaColors.ink,
    this.height = 74,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double height;

  @override
  State<LigaPlayButton> createState() => _LigaPlayButtonState();
}

class _LigaPlayButtonState extends State<LigaPlayButton> {
  static const _depth = 7.0;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _tap() {
    LigaSound.play(LigaSfx.jogar);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final face = _enabled ? widget.color : LigaColors.disabled;
    final sink = _pressed ? _depth : 0.0;
    final light = widget.textColor == Colors.white;

    final button = SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            top: _depth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LigaColors.shade(face, 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LigaColors.ink, width: 3.5),
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LigaColors.ink, width: 3.5),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.48, 0.52, 1],
                  colors: [
                    Color.lerp(face, Colors.white, 0.45)!,
                    Color.lerp(face, Colors.white, 0.2)!,
                    face,
                    LigaColors.shade(face, 0.06),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: LigaTheme.displayFont,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.subtitle == null ? 32 : 28,
                      height: 1,
                      letterSpacing: 1.5,
                      color: widget.textColor,
                      shadows: light
                          ? ligaOutline(2)
                          : const [
                              Shadow(
                                color: Colors.white70,
                                offset: Offset(0, 2),
                              ),
                            ],
                    ),
                  ),
                  if (widget.subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          shadows: light ? ligaOutline(1) : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled ? _tap : null,
        child: LigaLoop(
          duration: const Duration(milliseconds: 900),
          reverse: true,
          builder: (context, t, child) {
            final pulse = Curves.easeInOut.transform(t);
            return Transform.scale(
              scale: 1 + 0.035 * pulse,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: face.withValues(alpha: 0.55 * pulse),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: button,
        ),
      ),
    );
  }
}

/// Flutua o filho para cima e para baixo, como um personagem parado no lobby.
class LigaBob extends StatelessWidget {
  const LigaBob({
    super.key,
    required this.child,
    this.distance = 8,
    this.duration = const Duration(milliseconds: 1400),
    this.tilt = 0,
  });

  final Widget child;
  final double distance;
  final Duration duration;

  /// Inclinação máxima em radianos.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return LigaLoop(
      duration: duration,
      reverse: true,
      builder: (context, t, child) {
        final e = Curves.easeInOut.transform(t);
        return Transform.translate(
          offset: Offset(0, -distance * e),
          child: Transform.rotate(angle: tilt * (e - 0.5), child: child),
        );
      },
      child: child,
    );
  }
}

/// Baú de madeira desenhado em blocos; balança quando ainda está fechado.
class LigaChestIcon extends StatelessWidget {
  const LigaChestIcon({super.key, this.open = false, this.size = 48});

  final bool open;
  final double size;

  @override
  Widget build(BuildContext context) {
    final chest = SizedBox(
      width: size,
      height: size * 0.82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size * 0.5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(size * 0.14),
                  top: Radius.circular(size * 0.05),
                ),
                border: Border.all(color: LigaColors.ink, width: size * 0.06),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA85D1C), Color(0xFF6E3A0E)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -size * 0.03,
            right: -size * 0.03,
            top: open ? -size * 0.12 : size * 0.06,
            height: size * 0.34,
            child: Transform.rotate(
              angle: open ? -0.25 : 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(size * 0.2),
                    bottom: Radius.circular(size * 0.05),
                  ),
                  border: Border.all(color: LigaColors.ink, width: size * 0.06),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE3A04F), Color(0xFFA85D1C)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: size * 0.4,
            width: size * 0.2,
            top: size * 0.3,
            height: size * 0.24,
            child: Container(
              decoration: BoxDecoration(
                color: LigaColors.achievementYellow,
                borderRadius: BorderRadius.circular(size * 0.04),
                border: Border.all(color: LigaColors.ink, width: size * 0.05),
              ),
            ),
          ),
        ],
      ),
    );
    if (open) return chest;
    return LigaLoop(
      duration: const Duration(milliseconds: 1800),
      builder: (context, t, child) {
        // Parado na maior parte do tempo; dá uma chacoalhada no fim.
        final k = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
        return Transform.rotate(
          angle: 0.16 * math.sin(k * math.pi * 4) * (1 - k),
          child: child,
        );
      },
      child: chest,
    );
  }
}
