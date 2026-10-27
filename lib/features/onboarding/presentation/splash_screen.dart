import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import '../../shell/presentation/main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    final (outcome, _) = await (
      _restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ).wait;
    if (!mounted) return;
    // Quem já entrou antes e tem perfil volta direto para a Liga.
    final nextRoute = outcome == AuthOutcome.readyWithProfile
        ? MainShell.routeName
        : OnboardingScreen.routeName;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  static Future<AuthOutcome> _restoreSession() async {
    try {
      return await AppRepository.instance.restoreSession();
    } on AppRepositoryException {
      return AuthOutcome.signedOut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LigaBackground(child: Center(child: _SplashMark())),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [LigaColors.primaryBlue, LigaColors.adventurePurple],
            ),
            border: Border.all(color: LigaColors.cyanGlow, width: 2),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: LigaColors.achievementYellow,
            size: 56,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'LIGA DO SABER',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Aprender vira missão',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
