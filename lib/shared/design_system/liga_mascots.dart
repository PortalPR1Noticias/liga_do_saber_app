import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Personagens da Liga, desenhados em código enquanto não temos as artes finais.
enum LigaCharacter {
  /// Luma: assistente da Oficina de Texto, com uma estrela na antena.
  luma(LigaColors.actionCoral, 'Luma'),

  /// Nico: o craque da Arena Matemática, de óculos redondos.
  nico(LigaColors.primaryBlue, 'Nico'),

  /// Mila: a detetive da Biblioteca Viva, de chapéu e lupa.
  mila(LigaColors.adventurePurple, 'Mila');

  const LigaCharacter(this.color, this.displayName);

  final Color color;
  final String displayName;
}

/// Mascote que flutua de leve, para dar vida às telas.
class LigaMascot extends StatefulWidget {
  const LigaMascot({
    super.key,
    required this.character,
    this.size = 96,
    this.delay = Duration.zero,
  });

  final LigaCharacter character;
  final double size;

  /// Defasagem da flutuação, para vários mascotes não subirem juntos.
  final Duration delay;

  @override
  State<LigaMascot> createState() => _LigaMascotState();
}

class _LigaMascotState extends State<LigaMascot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LigaMotion.of(context)) {
      if (!_controller.isAnimating) {
        final total = _controller.duration!.inMilliseconds;
        _controller.value = (widget.delay.inMilliseconds % total) / total;
        _controller.repeat(reverse: true);
      }
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
    return Semantics(
      label: widget.character.displayName,
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: Offset(0, -widget.size * 0.05 * t),
            child: child,
          );
        },
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(painter: _MascotPainter(widget.character)),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter(this.character);

  final LigaCharacter character;

  @override
  void paint(Canvas canvas, Size size) {
    // Desenha numa grade de 100 x 100 e escala para o tamanho pedido.
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final color = character.color;
    final dark = LigaColors.shade(color, 0.16);
    final light = Color.lerp(color, Colors.white, 0.55)!;

    // Sombra no chão.
    canvas.drawOval(
      const Rect.fromLTWH(24, 90, 52, 7),
      Paint()..color = LigaColors.ink.withValues(alpha: 0.12),
    );

    if (character == LigaCharacter.luma) _paintLumaAntenna(canvas);
    if (character == LigaCharacter.mila) _paintMilaGlass(canvas);

    // Pezinhos.
    final feet = Paint()..color = dark;
    canvas.drawOval(const Rect.fromLTWH(30, 82, 16, 10), feet);
    canvas.drawOval(const Rect.fromLTWH(54, 82, 16, 10), feet);

    // Corpo.
    const body = Rect.fromLTWH(16, 22, 68, 66);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(34)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.15)!, dark],
        ).createShader(body),
    );

    // Barriga.
    canvas.drawOval(
      const Rect.fromLTWH(32, 58, 36, 26),
      Paint()..color = light.withValues(alpha: 0.75),
    );
    if (character == LigaCharacter.nico) _paintPlus(canvas, dark);

    // Bracinhos.
    final arm = Paint()..color = dark;
    canvas.drawOval(const Rect.fromLTWH(9, 54, 13, 18), arm);
    canvas.drawOval(const Rect.fromLTWH(78, 54, 13, 18), arm);

    // Olhos.
    for (final x in [38.0, 62.0]) {
      canvas.drawCircle(Offset(x, 46), 10, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(x + 1.5, 47.5),
        5.6,
        Paint()..color = LigaColors.ink,
      );
      canvas.drawCircle(
        Offset(x + 3.5, 45),
        2.1,
        Paint()..color = Colors.white,
      );
    }
    if (character == LigaCharacter.nico) _paintGlasses(canvas);

    // Bochechas.
    final cheek = Paint()
      ..color = const Color(0xFFFF8FB1).withValues(alpha: 0.75);
    canvas.drawOval(const Rect.fromLTWH(22, 56, 11, 7), cheek);
    canvas.drawOval(const Rect.fromLTWH(67, 56, 11, 7), cheek);

    // Sorriso.
    final smile = Path()
      ..moveTo(42, 60)
      ..quadraticBezierTo(50, 69, 58, 60)
      ..close();
    canvas.drawPath(smile, Paint()..color = LigaColors.ink);
    canvas.drawOval(
      const Rect.fromLTWH(46.5, 62.5, 7, 3.5),
      Paint()..color = const Color(0xFFFF6B8B),
    );

    if (character == LigaCharacter.mila) _paintMilaHat(canvas);

    canvas.restore();
  }

  void _paintLumaAntenna(Canvas canvas) {
    canvas.drawLine(
      const Offset(50, 24),
      const Offset(50, 10),
      Paint()
        ..color = LigaColors.shade(character.color, 0.16)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      _starPath(const Offset(50, 9), 9, 4),
      Paint()..color = LigaColors.achievementYellow,
    );
  }

  void _paintPlus(Canvas canvas, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(50, 66), const Offset(50, 77), paint);
    canvas.drawLine(const Offset(44.5, 71.5), const Offset(55.5, 71.5), paint);
  }

  void _paintGlasses(Canvas canvas) {
    final frame = Paint()
      ..color = LigaColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(const Offset(38, 46), 12.5, frame);
    canvas.drawCircle(const Offset(62, 46), 12.5, frame);
    canvas.drawLine(const Offset(48, 44), const Offset(52, 44), frame);
  }

  void _paintMilaHat(Canvas canvas) {
    const hat = Color(0xFFB7793E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 25, 64, 9),
        const Radius.circular(5),
      ),
      Paint()..color = LigaColors.shade(hat, 0.1),
    );
    final crown = Path()
      ..moveTo(28, 28)
      ..quadraticBezierTo(30, 8, 50, 8)
      ..quadraticBezierTo(70, 8, 72, 28)
      ..close();
    canvas.drawPath(crown, Paint()..color = hat);
    canvas.drawRect(
      const Rect.fromLTWH(29, 21, 42, 5),
      Paint()..color = LigaColors.achievementYellow,
    );
  }

  void _paintMilaGlass(Canvas canvas) {
    canvas.drawLine(
      const Offset(90, 80),
      const Offset(98, 92),
      Paint()
        ..color = const Color(0xFF8A5A2B)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(86, 72),
      10,
      Paint()..color = const Color(0xFFBDEBFF),
    );
    canvas.drawCircle(
      const Offset(86, 72),
      10,
      Paint()
        ..color = LigaColors.achievementYellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4,
    );
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) =>
      oldDelegate.character != character;
}

/// Luma, Nico e Mila juntos, com o Nico um pouco à frente.
class LigaMascotTrio extends StatelessWidget {
  const LigaMascotTrio({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.6,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            bottom: size * 0.1,
            child: LigaMascot(character: LigaCharacter.luma, size: size * 0.9),
          ),
          Positioned(
            right: 0,
            bottom: size * 0.1,
            child: LigaMascot(
              character: LigaCharacter.mila,
              size: size * 0.9,
              delay: const Duration(milliseconds: 500),
            ),
          ),
          LigaMascot(
            character: LigaCharacter.nico,
            size: size * 1.1,
            delay: const Duration(milliseconds: 900),
          ),
        ],
      ),
    );
  }
}

/// Caminho de uma estrela de cinco pontas.
Path _starPath(Offset center, double radius, double innerRadius) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? radius : innerRadius;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

/// Estrela desenhada, para enfeites e recompensas.
Path ligaStarPath(Offset center, double radius) =>
    _starPath(center, radius, radius * 0.45);
