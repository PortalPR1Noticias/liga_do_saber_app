import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_game.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';

/// Tela de entrada do jogo: as cenas dos cinco heróis passando em tela cheia,
/// o logo flutuando e o botão JOGAR.
class LigaTitleScreen extends StatelessWidget {
  const LigaTitleScreen({
    super.key,
    required this.onPlay,
    required this.footer,
  });

  final VoidCallback? onPlay;

  /// Linha pequena embaixo do JOGAR.
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LigaNight.deep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SceneCarousel(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.3, 0.62, 0.9],
                colors: [
                  Color(0x330A0F2E),
                  Color(0x000A0F2E),
                  Color(0x990A0F2E),
                  LigaNight.deep,
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h - 24),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: LigaSoundButton(),
                          ),
                          PopIn(
                            child: LigaBob(
                              tilt: 0.03,
                              duration: const Duration(milliseconds: 1600),
                              child: LigaLogo(height: math.min(230, h * 0.32)),
                            ),
                          ),
                          const Spacer(),
                          PopIn(
                            delay: const Duration(milliseconds: 150),
                            child: LigaCrew(size: math.min(58, h * 0.1)),
                          ),
                          SizedBox(height: h * 0.02),
                          const PopIn(
                            delay: Duration(milliseconds: 250),
                            child: LigaGameText(
                              'Aprender vira missão',
                              size: 22,
                              color: LigaColors.achievementYellow,
                            ),
                          ),
                          SizedBox(height: h * 0.03),
                          PopIn(
                            delay: const Duration(milliseconds: 350),
                            child: LigaPlayButton(
                              label: 'JOGAR',
                              onPressed: onPlay,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            footer,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: LigaNight.textSoft,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// As cenas dos heróis em sequência, com zoom lento e troca suave.
class _SceneCarousel extends StatelessWidget {
  const _SceneCarousel();

  static const _order = [
    LigaCharacter.nico,
    LigaCharacter.luma,
    LigaCharacter.teo,
    LigaCharacter.mila,
    LigaCharacter.zuri,
  ];

  /// Parte de cada cena gasta na troca para a próxima.
  static const _fade = 0.18;

  @override
  Widget build(BuildContext context) {
    return LigaLoop(
      duration: Duration(seconds: 4 * _order.length),
      builder: (context, t, _) {
        final slot = t * _order.length;
        final index = slot.floor() % _order.length;
        final local = slot - slot.floor();
        final next = (index + 1) % _order.length;
        final fading = ((local - (1 - _fade)) / _fade).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            _scene(_order[index], local),
            if (fading > 0)
              Opacity(opacity: fading, child: _scene(_order[next], 0)),
          ],
        );
      },
    );
  }

  Widget _scene(LigaCharacter character, double progress) {
    return Transform.scale(
      scale: 1.16 - 0.12 * progress,
      child: Image.asset(
        character.scene,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.2),
        gaplessPlayback: true,
      ),
    );
  }
}
