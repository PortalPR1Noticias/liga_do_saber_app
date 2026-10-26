import 'package:flutter/material.dart';

import '../../../app/theme.dart';
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      const Icon(
                        Icons.workspace_premium,
                        color: LigaColors.achievementYellow,
                        size: 54,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Entre para a Liga do Saber',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Missões curtas, leitura, produção textual, matemática e IA para transformar atividade escolar em treino guiado.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      const _OnboardingPoint(
                        icon: Icons.camera_alt_outlined,
                        text:
                            'Envie foto da atividade e receba uma explicação.',
                      ),
                      const _OnboardingPoint(
                        icon: Icons.edit_note,
                        text: 'Melhore textos com feedback e reescrita.',
                      ),
                      const _OnboardingPoint(
                        icon: Icons.travel_explore,
                        text:
                            'Resolva casos de interpretação como investigação.',
                      ),
                      const Spacer(),
                      LigaActionButton(
                        label: 'Criar conta do responsável',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AuthScreen.routeName);
                        },
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
  const _OnboardingPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: LigaColors.cyanGlow),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
