import 'package:flutter/material.dart';

import '../../../shared/services/app_repository.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../child_profile/presentation/child_profile_screen.dart';
import '../../shell/presentation/main_shell.dart';
import 'title_screen.dart';

/// Primeira tela do app. Enquanto a criança vê a entrada, o app confere se
/// já existe uma sessão salva; o JOGAR leva para a Liga ou para o cadastro.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Future<AuthOutcome> _outcome = _restoreSession();

  static Future<AuthOutcome> _restoreSession() async {
    try {
      return await AppRepository.instance.restoreSession();
    } on AppRepositoryException {
      return AuthOutcome.signedOut;
    }
  }

  Future<void> _play() async {
    final outcome = await _outcome;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    switch (outcome) {
      case AuthOutcome.readyWithProfile:
        navigator.pushReplacementNamed(MainShell.routeName);
      case AuthOutcome.needsChildProfile:
        navigator.pushNamed(ChildProfileScreen.routeName);
      case AuthOutcome.needsEmailConfirmation || AuthOutcome.signedOut:
        navigator.pushNamed(AuthScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LigaTitleScreen(
      footer: 'Conta criada pelos responsáveis',
      onPlay: _play,
    );
  }
}
