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
      Icons.psychology_alt,
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
      LigaColors.achievementYellow,
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
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatar.color.withValues(alpha: 0.22),
      child: Icon(avatar.icon, color: avatar.color, size: radius * 1.05),
    );
  }
}
