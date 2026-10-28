import 'package:flutter/material.dart';

import '../../../shared/services/app_repository.dart';
import '../../auth/presentation/auth_routing.dart';
import 'title_screen.dart';

/// Primeira tela do app. Enquanto a criança vê a entrada, o app confere se
/// já existe uma sessão salva; o JOGAR leva cada perfil para a tela dele ou
/// para a escolha de login.
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
    await openHomeFor(context, outcome, restoredSession: true);
  }

  @override
  Widget build(BuildContext context) {
    return LigaTitleScreen(
      footer: 'Conta criada pelos responsáveis',
      onPlay: _play,
    );
  }
}
