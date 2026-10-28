import 'package:flutter/material.dart';

import '../../../shared/services/app_repository.dart';
import '../../child_profile/presentation/child_profile_screen.dart';
import '../../parent_area/presentation/parent_area_screen.dart';
import '../../parent_area/presentation/parent_home_screen.dart';
import '../../shell/presentation/main_shell.dart';
import '../../teacher/presentation/teacher_home_screen.dart';
import 'login_choice_screen.dart';

/// Leva cada perfil para a sua tela inicial: a criança para os jogos, o
/// responsável para o painel dele e o professor para o painel da turma.
///
/// Com [restoredSession], a sessão do responsável estava salva no aparelho:
/// antes do painel vem a pergunta de adulto, para a criança não entrar nele
/// sozinha.
Future<void> openHomeFor(
  BuildContext context,
  AuthOutcome outcome, {
  bool restoredSession = false,
}) async {
  final navigator = Navigator.of(context);
  switch (outcome) {
    case AuthOutcome.readyWithProfile:
      navigator.pushNamedAndRemoveUntil(MainShell.routeName, (_) => false);
    case AuthOutcome.readyAsParent:
      if (restoredSession && !await showParentGate(context)) return;
      navigator.pushNamedAndRemoveUntil(
        ParentHomeScreen.routeName,
        (_) => false,
      );
    case AuthOutcome.readyAsTeacher:
      navigator.pushNamedAndRemoveUntil(
        TeacherHomeScreen.routeName,
        (_) => false,
      );
    case AuthOutcome.needsChildProfile:
      if (restoredSession && !await showParentGate(context)) return;
      AppRepository.instance.selectChild(null);
      navigator.pushNamed(ChildProfileScreen.routeName);
    case AuthOutcome.needsEmailConfirmation || AuthOutcome.signedOut:
      navigator.pushNamed(LoginChoiceScreen.routeName);
  }
}
