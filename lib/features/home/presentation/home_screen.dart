import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/services/app_repository.dart';
import '../../math_arena/presentation/math_arena_screen.dart';
import '../../photo_solver/presentation/photo_solver_flow_screen.dart';
import '../../reading_detective/presentation/reading_detective_screen.dart';
import '../../writing_workshop/presentation/writing_workshop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AppRepository.instance.childProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        PopIn(
          child: _Header(
            nickname: profile.nickname,
            avatarId: profile.avatarId,
            level: profile.level,
            levelProgress: profile.levelProgress,
            levelXp: profile.totalXp % ChildProfile.levelXpGoal,
            streakDays: profile.streakDays,
          ),
        ),
        const SizedBox(height: 20),
        PopIn(
          delay: const Duration(milliseconds: 90),
          child: _DailyMission(
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ReadingDetectiveScreen.routeName),
          ),
        ),
        const SizedBox(height: 20),
        PopIn(
          delay: const Duration(milliseconds: 160),
          child: LigaActionButton(
            label: 'Enviar foto da atividade',
            icon: Icons.camera_alt_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(PhotoSolverFlowScreen.routeName),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Áreas em destaque', icon: Icons.star_rounded),
        PopIn(
          delay: const Duration(milliseconds: 220),
          child: MissionCard(
            title: 'Oficina de Texto',
            subtitle: 'Planeje, escreva, receba feedback e reescreva melhor.',
            icon: Icons.edit_rounded,
            color: LigaColors.actionCoral,
            progress: 0.65,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(WritingWorkshopScreen.routeName),
          ),
        ),
        const SizedBox(height: 14),
        PopIn(
          delay: const Duration(milliseconds: 280),
          child: MissionCard(
            title: 'Detetive da Leitura',
            subtitle: 'Encontre pistas, interprete e conclua o caso.',
            icon: Icons.search_rounded,
            color: LigaColors.adventurePurple,
            progress: 0.78,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ReadingDetectiveScreen.routeName),
          ),
        ),
        const SizedBox(height: 14),
        PopIn(
          delay: const Duration(milliseconds: 340),
          child: MissionCard(
            title: 'Arena Matemática',
            subtitle: 'Treinos rápidos de cálculo e raciocínio.',
            icon: Icons.calculate_rounded,
            color: LigaColors.primaryBlue,
            progress: 0.42,
            onTap: () =>
                Navigator.of(context).pushNamed(MathArenaScreen.routeName),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.nickname,
    required this.avatarId,
    required this.level,
    required this.levelProgress,
    required this.levelXp,
    required this.streakDays,
  });

  final String nickname;
  final String avatarId;
  final int level;
  final double levelProgress;
  final int levelXp;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      child: Column(
        children: [
          Row(
            children: [
              LigaAvatarBadge(avatarId: avatarId, radius: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olá,', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      nickname,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StreakFlame(days: streakDays),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              LigaPill(
                icon: Icons.military_tech_rounded,
                label: 'Nível $level',
                color: LigaColors.adventurePurple,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LigaProgressBar(
                  value: levelProgress,
                  color: LigaColors.achievementYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$levelXp / ${ChildProfile.levelXpGoal} XP',
              style: const TextStyle(
                color: LigaColors.inkSoft,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakFlame extends StatelessWidget {
  const _StreakFlame({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LigaColors.sunsetOrange, width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: LigaColors.sunsetOrange,
            size: 28,
          ),
          Text(
            '$days dias',
            style: const TextStyle(
              color: LigaColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Destaque da missão do dia, com a Mila convidando a criança.
class _DailyMission extends StatelessWidget {
  const _DailyMission({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB37CFF), LigaColors.adventurePurple],
          ),
          boxShadow: [
            BoxShadow(
              color: LigaColors.shade(LigaColors.adventurePurple),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LigaPill(
                    icon: Icons.bolt_rounded,
                    label: 'Missão do dia · +50 XP',
                    color: LigaColors.achievementYellow,
                    solid: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'O Mistério da Biblioteca Viva',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Investigue pistas no texto e desbloqueie o próximo caso.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const LigaMascot(character: LigaCharacter.mila, size: 96),
          ],
        ),
      ),
    );
  }
}
