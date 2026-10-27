import 'package:flutter/material.dart';

import 'liga_mascots.dart';

/// Herói que a criança escolhe para representá-la na Liga.
class LigaAvatar {
  const LigaAvatar(this.id, this.name, this.icon, this.character);

  final String id;
  final String name;
  final IconData icon;
  final LigaCharacter character;

  Color get color => character.color;

  static const all = [
    LigaAvatar(
      'estrategista',
      'Estrategista',
      Icons.lightbulb_rounded,
      LigaCharacter.nico,
    ),
    LigaAvatar(
      'investigadora',
      'Investigadora',
      Icons.search_rounded,
      LigaCharacter.mila,
    ),
    LigaAvatar('criadora', 'Criadora', Icons.auto_awesome, LigaCharacter.luma),
    LigaAvatar(
      'explorador',
      'Explorador',
      Icons.terrain_rounded,
      LigaCharacter.explorador,
    ),
  ];

  static LigaAvatar byId(String id) {
    return all.firstWhere((avatar) => avatar.id == id, orElse: () => all.first);
  }
}

/// Retrato do herói escolhido, com o selo da classe no canto.
class LigaAvatarBadge extends StatelessWidget {
  const LigaAvatarBadge({super.key, required this.avatarId, this.radius = 34});

  final String avatarId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = LigaAvatar.byId(avatarId);
    final seal = radius * 0.62;
    return SizedBox(
      key: ValueKey('avatar-${avatar.id}'),
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          LigaPortrait(character: avatar.character, size: radius * 2),
          Positioned(
            right: -seal * 0.15,
            bottom: -seal * 0.1,
            child: Container(
              width: seal,
              height: seal,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatar.color,
                border: Border.all(color: Colors.white, width: seal * 0.1),
              ),
              child: Icon(avatar.icon, color: Colors.white, size: seal * 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
