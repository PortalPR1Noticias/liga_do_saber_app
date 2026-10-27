import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LigaAvatar {
  const LigaAvatar(this.id, this.name, this.icon, this.color);

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  static const all = [
    LigaAvatar(
      'estrategista',
      'Estrategista',
      Icons.lightbulb_rounded,
      LigaColors.primaryBlue,
    ),
    LigaAvatar(
      'investigadora',
      'Investigadora',
      Icons.travel_explore,
      LigaColors.progressGreen,
    ),
    LigaAvatar(
      'criadora',
      'Criadora',
      Icons.auto_awesome,
      LigaColors.actionCoral,
    ),
    LigaAvatar(
      'explorador',
      'Explorador',
      Icons.terrain,
      LigaColors.sunsetOrange,
    ),
  ];

  static LigaAvatar byId(String id) {
    return all.firstWhere((avatar) => avatar.id == id, orElse: () => all.first);
  }
}

class LigaAvatarBadge extends StatelessWidget {
  const LigaAvatarBadge({super.key, required this.avatarId, this.radius = 34});

  final String avatarId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = LigaAvatar.byId(avatarId);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(avatar.color, Colors.white, 0.3)!, avatar.color],
        ),
        border: Border.all(color: Colors.white, width: radius * 0.1),
        boxShadow: [
          BoxShadow(
            color: LigaColors.shade(avatar.color),
            offset: Offset(0, radius * 0.1),
          ),
        ],
      ),
      child: Icon(avatar.icon, color: Colors.white, size: radius * 1.05),
    );
  }
}
