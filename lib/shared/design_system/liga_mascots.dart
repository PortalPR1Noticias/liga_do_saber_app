import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Personagens oficiais da Liga (artes em assets/mascots e assets/backgrounds).
enum LigaCharacter {
  /// Luma: assistente da Oficina de Texto.
  luma('luma', 'Luma', LigaColors.actionCoral),

  /// Nico: o craque da Arena Matemática.
  nico('nico', 'Nico', LigaColors.primaryBlue),

  /// Mila: a detetive da leitura e dona do Arquivo da Mila.
  mila('mila', 'Mila', LigaColors.adventurePurple),

  /// Zuri: o criativo dos projetos e ideias.
  zuri('zuri', 'Zuri', LigaColors.sunsetOrange),

  /// Explorador das trilhas e da natureza.
  explorador('explorador', 'Explorador', LigaColors.progressGreen);

  const LigaCharacter(this.id, this.displayName, this.color);

  final String id;
  final String displayName;
  final Color color;

  /// Rosto e tronco, recortado em quadrado.
  String get portrait => 'assets/mascots/${id}_retrato.jpg';

  /// Cena completa, em formato paisagem.
  String get scene => 'assets/backgrounds/${id}_cena.jpg';
}

/// Retrato redondo do personagem que flutua de leve.
class LigaMascot extends StatefulWidget {
  const LigaMascot({
    super.key,
    required this.character,
    this.size = 96,
    this.delay = Duration.zero,
  });

  final LigaCharacter character;
  final double size;

  /// Defasagem da flutuação, para vários personagens não subirem juntos.
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.size * 0.05 * t),
          child: child,
        );
      },
      child: LigaPortrait(character: widget.character, size: widget.size),
    );
  }
}

/// Retrato redondo, com anel na cor do personagem.
class LigaPortrait extends StatelessWidget {
  const LigaPortrait({
    super.key,
    required this.character,
    this.size = 96,
    this.locked = false,
  });

  final LigaCharacter character;
  final double size;

  /// Mostra o retrato em cinza, para conteúdos ainda trancados.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final ring = locked ? LigaColors.disabled : character.color;
    Widget image = Image.asset(
      character.portrait,
      fit: BoxFit.cover,
      semanticLabel: character.displayName,
    );
    if (locked) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, 20, //
          0.33, 0.33, 0.33, 0, 20, //
          0.33, 0.33, 0.33, 0, 20, //
          0, 0, 0, 1, 0, //
        ]),
        child: image,
      );
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: ring, width: size * 0.05),
        boxShadow: [
          BoxShadow(
            color: LigaColors.shade(ring),
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipOval(child: image),
    );
  }
}

/// A turma toda lado a lado, com os retratos um pouco sobrepostos.
class LigaCrew extends StatelessWidget {
  const LigaCrew({super.key, this.size = 72});

  final double size;

  static const _order = [
    LigaCharacter.luma,
    LigaCharacter.zuri,
    LigaCharacter.nico,
    LigaCharacter.mila,
    LigaCharacter.explorador,
  ];

  @override
  Widget build(BuildContext context) {
    final step = size * 0.72;
    return SizedBox(
      width: step * (_order.length - 1) + size,
      height: size * 1.12,
      child: Stack(
        children: [
          for (var i = 0; i < _order.length; i++)
            Positioned(
              left: step * i,
              // O do meio fica mais alto, formando um arco.
              top: (i - 2).abs() * size * 0.06,
              child: LigaMascot(
                character: _order[i],
                size: size,
                delay: Duration(milliseconds: 300 * i),
              ),
            ),
        ],
      ),
    );
  }
}

/// Caminho de uma estrela de cinco pontas, para enfeites e recompensas.
Path ligaStarPath(Offset center, double radius) {
  final innerRadius = radius * 0.45;
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
