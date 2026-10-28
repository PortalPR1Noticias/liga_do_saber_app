import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import 'auth_screen.dart';
import 'child_login_screen.dart';

/// Quem vai entrar: a criança (login criado pelo responsável), o
/// responsável ou o professor.
class LoginChoiceScreen extends StatelessWidget {
  const LoginChoiceScreen({super.key});

  static const routeName = '/entrar';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar na Liga')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PopIn(
                child: Row(
                  children: [
                    const LigaMascot(character: LigaCharacter.zuri, size: 84),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LigaSpeechBubble(
                        text: 'Quem vai entrar agora?',
                        color: LigaColors.sunsetOrange.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              LigaActionButton(
                key: const Key('loginChild'),
                label: 'Sou criança',
                icon: Icons.sports_esports_rounded,
                color: LigaColors.progressGreen,
                onPressed: () =>
                    Navigator.of(context).pushNamed(ChildLoginScreen.routeName),
              ),
              const SizedBox(height: 6),
              Text(
                'Entre com o usuário e a senha que o seu responsável criou.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                key: const Key('loginParent'),
                label: 'Sou responsável',
                icon: Icons.family_restroom_rounded,
                color: LigaColors.primaryBlue,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AuthScreen.routeName),
              ),
              const SizedBox(height: 6),
              Text(
                'Crie a conta da família, os perfis e os logins das crianças '
                'e acompanhe o desempenho.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                key: const Key('loginTeacher'),
                label: 'Sou professor',
                icon: Icons.school_rounded,
                color: LigaColors.adventurePurple,
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AuthScreen.teacherRouteName),
              ),
              const SizedBox(height: 6),
              Text(
                'Acompanhe os alunos que as famílias liberarem para o seu '
                'e-mail.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
