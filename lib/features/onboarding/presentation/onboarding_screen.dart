import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../auth/presentation/auth_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LigaBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 44,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const PopIn(child: Center(child: LigaLogo(height: 120))),
                      const SizedBox(height: 14),
                      const PopIn(
                        delay: Duration(milliseconds: 60),
                        child: Center(child: LigaCrew(size: 60)),
                      ),
                      const SizedBox(height: 16),
                      PopIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Entre para a Liga do Saber',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PopIn(
                        delay: const Duration(milliseconds: 180),
                        child: Text(
                          'Nico, Luma, Teo, Mila e Zuri te esperam para missões de matemática, português, ciências, história e projetos. Cada desafio vale XP e medalhas!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const PopIn(
                        delay: Duration(milliseconds: 260),
                        child: _OnboardingPoint(
                          icon: Icons.calculate_rounded,
                          color: LigaColors.primaryBlue,
                          text:
                              'Resolva desafios de lógica e contas com o Nico.',
                        ),
                      ),
                      const PopIn(
                        delay: Duration(milliseconds: 340),
                        child: _OnboardingPoint(
                          icon: Icons.edit_rounded,
                          color: LigaColors.actionCoral,
                          text: 'Leia e escreva melhor com a Luma.',
                        ),
                      ),
                      const PopIn(
                        delay: Duration(milliseconds: 420),
                        child: _OnboardingPoint(
                          icon: Icons.travel_explore_rounded,
                          color: LigaColors.adventurePurple,
                          text:
                              'Investigue a História com a Mila e explore a natureza com o Teo.',
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 8),
                      PopIn(
                        delay: const Duration(milliseconds: 500),
                        child: LigaActionButton(
                          label: 'Criar conta do responsável',
                          icon: Icons.rocket_launch_rounded,
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AuthScreen.routeName);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LigaPanel(
        padding: const EdgeInsets.all(12),
        borderColor: color.withValues(alpha: 0.5),
        child: Row(
          children: [
            LigaIconBubble(icon: icon, color: color, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
