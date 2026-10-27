import 'package:flutter/material.dart';

import '../../auth/presentation/auth_screen.dart';
import 'title_screen.dart';

/// Entrada para quem ainda não tem conta (ou acabou de sair dela).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return LigaTitleScreen(
      footer: 'Para começar, um responsável cria a conta',
      onPlay: () => Navigator.of(context).pushNamed(AuthScreen.routeName),
    );
  }
}
