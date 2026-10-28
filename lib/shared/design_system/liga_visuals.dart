import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/shop.dart';
import 'liga_avatars.dart';
import 'liga_game.dart';

/// Ícone da moeda da Liga (moedas vêm só de XP, nunca de dinheiro).
class LigaCoinIcon extends StatelessWidget {
  const LigaCoinIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: LigaColors.ink, width: size * 0.1),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE680), Color(0xFFFFB800)],
        ),
      ),
      child: Text(
        'L',
        style: TextStyle(
          fontFamily: LigaTheme.displayFont,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.55,
          height: 1,
          color: const Color(0xFF8A5A00),
        ),
      ),
    );
  }
}

/// Saldo de moedas, para o HUD e a loja.
class LigaCoinCounter extends StatelessWidget {
  const LigaCoinCounter({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.fromLTRB(5, 0, 12, 0),
      decoration: BoxDecoration(
        color: LigaNight.glass,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: LigaColors.ink, width: 2.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LigaCoinIcon(size: 26),
          const SizedBox(width: 6),
          LigaGameText('$coins', size: 18),
        ],
      ),
    );
  }
}

/// Avatar com a moldura equipada (ou sem moldura).
class LigaFramedAvatar extends StatelessWidget {
  const LigaFramedAvatar({
    super.key,
    required this.avatarId,
    required this.radius,
    this.frame,
  });

  final String avatarId;
  final double radius;
  final VisualItem? frame;

  @override
  Widget build(BuildContext context) {
    final badge = LigaAvatarBadge(avatarId: avatarId, radius: radius);
    final frame = this.frame;
    if (frame == null) return badge;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius * 0.48 + 3),
        border: Border.all(color: LigaColors.ink, width: 1.5),
        gradient: _gradient(frame.colors),
      ),
      child: badge,
    );
  }
}

/// Brilho da aura atrás do herói, pulsando devagar.
class LigaAura extends StatelessWidget {
  const LigaAura({
    super.key,
    required this.aura,
    required this.size,
    required this.child,
  });

  final VisualItem? aura;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final aura = this.aura;
    if (aura == null) return child;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // O brilho passa da borda sem mudar o tamanho do herói na tela.
        Positioned.fill(
          child: IgnorePointer(
            child: OverflowBox(
              maxWidth: size * 1.5,
              maxHeight: size * 1.5,
              child: LigaLoop(
                duration: const Duration(milliseconds: 2200),
                reverse: true,
                builder: (context, t, _) => Container(
                  width: size * (1.4 + 0.1 * t),
                  height: size * (1.4 + 0.1 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        for (final color in aura.colors.reversed)
                          color.withValues(alpha: 0.75 + 0.25 * t),
                        aura.colors.first.withValues(alpha: 0),
                      ],
                      stops: [
                        for (var i = 0; i < aura.colors.length; i++)
                          0.5 + 0.3 * i / aura.colors.length,
                        1,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// O chão do herói na Base: a cor do herói ou o pedestal equipado.
class LigaPedestal extends StatelessWidget {
  const LigaPedestal({
    super.key,
    required this.pedestal,
    required this.fallback,
    this.width = 150,
  });

  final VisualItem? pedestal;
  final Color fallback;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors =
        pedestal?.colors ??
        [fallback.withValues(alpha: 0.7), fallback.withValues(alpha: 0.7)];
    final height = width * 0.15;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.elliptical(width / 2, height / 2),
        ),
        gradient: _gradient(colors),
        border: Border.all(color: LigaColors.ink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.8),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Miniatura do visual nos cartões da loja e da temporada.
class LigaVisualPreview extends StatelessWidget {
  const LigaVisualPreview({
    super.key,
    required this.item,
    required this.avatarId,
    this.size = 72,
  });

  final VisualItem item;
  final String avatarId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = size * 0.3;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: switch (item.slot) {
          VisualSlot.moldura => LigaFramedAvatar(
            avatarId: avatarId,
            radius: avatarRadius,
            frame: item,
          ),
          VisualSlot.aura => LigaAura(
            aura: item,
            size: size * 0.8,
            child: LigaAvatarBadge(avatarId: avatarId, radius: avatarRadius),
          ),
          VisualSlot.pedestal => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LigaAvatarBadge(avatarId: avatarId, radius: avatarRadius * 0.85),
              const SizedBox(height: 4),
              LigaPedestal(
                pedestal: item,
                fallback: item.colors.last,
                width: size * 0.85,
              ),
            ],
          ),
          VisualSlot.titulo => Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              color: LigaColors.ink,
              shape: BoxShape.circle,
              border: Border.all(color: item.colors.first, width: 3),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: item.colors.first,
              size: size * 0.42,
            ),
          ),
        },
      ),
    );
  }
}

/// O título equipado, numa plaquinha embaixo do nome do herói.
class LigaTitleTag extends StatelessWidget {
  const LigaTitleTag({super.key, required this.item, this.fontSize = 13});

  final VisualItem item;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LigaColors.ink.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.colors.first, width: 1.5),
      ),
      child: Text(
        item.name,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: item.colors.first,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

Gradient _gradient(List<Color> colors) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: colors.length == 1 ? [colors.first, colors.first] : colors,
);
