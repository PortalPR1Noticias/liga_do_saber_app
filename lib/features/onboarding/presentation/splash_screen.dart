import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
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
        const PopIn(child: LigaLogo(height: 220)),
        const SizedBox(height: 18),
        const PopIn(
          delay: Duration(milliseconds: 150),
          child: LigaCrew(size: 58),
        ),
        const SizedBox(height: 18),
        PopIn(
          delay: const Duration(milliseconds: 280),
          child: const LigaPill(
            icon: Icons.rocket_launch_rounded,
            label: 'Aprender vira missão',
            color: LigaColors.sunsetOrange,
          ),
        ),
      ],
    );
  }
}
