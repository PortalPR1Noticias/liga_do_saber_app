import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_widgets.dart';
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
      padding: const EdgeInsets.all(20),
      children: [
        _Header(
          nickname: profile.nickname,
          avatarId: profile.avatarId,
          level: profile.level,
          levelProgress: profile.levelProgress,
          streakDays: profile.streakDays,
        ),
        const SizedBox(height: 22),
        LigaActionButton(
          label: 'Enviar foto da atividade',
          icon: Icons.camera_alt,
          onPressed: () =>
              Navigator.of(context).pushNamed(PhotoSolverFlowScreen.routeName),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Continuar missão'),
        LigaPanel(
          borderColor: LigaColors.cyanGlow.withValues(alpha: 0.5),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: LigaColors.achievementYellow,
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O Mistério da Biblioteca Viva',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Investigue pistas no texto e desbloqueie o próximo caso.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Áreas em destaque'),
        MissionCard(
          title: 'Oficina de Texto',
          subtitle: 'Planeje, escreva, receba feedback e reescreva melhor.',
          icon: Icons.edit_note,
          color: LigaColors.actionCoral,
          progress: 0.65,
          onTap: () =>
              Navigator.of(context).pushNamed(WritingWorkshopScreen.routeName),
        ),
        const SizedBox(height: 14),
        MissionCard(
          title: 'Detetive da Leitura',
          subtitle: 'Encontre pistas, interprete e conclua o caso.',
          icon: Icons.travel_explore,
          color: LigaColors.progressGreen,
          progress: 0.78,
          onTap: () =>
              Navigator.of(context).pushNamed(ReadingDetectiveScreen.routeName),
        ),
        const SizedBox(height: 14),
        MissionCard(
          title: 'Arena Matemática',
          subtitle: 'Treinos rápidos de cálculo e raciocínio.',
          icon: Icons.calculate,
          color: LigaColors.primaryBlue,
          progress: 0.42,
          onTap: () =>
              Navigator.of(context).pushNamed(MathArenaScreen.routeName),
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
    required this.streakDays,
  });

  final String nickname;
  final String avatarId;
  final int level;
  final double levelProgress;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      child: Row(
        children: [
          LigaAvatarBadge(avatarId: avatarId),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Nível $level | Mestre Junior',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: levelProgress.clamp(0.08, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0x332563EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      LigaColors.cyanGlow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: LigaColors.actionCoral,
              ),
              Text(
                '$streakDays',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
