import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/child_login_screen.dart';
import '../features/auth/presentation/login_choice_screen.dart';
import '../features/child_profile/presentation/child_profile_screen.dart';
import '../features/child_profile/presentation/choose_avatar_screen.dart';
import '../features/math_arena/presentation/math_arena_screen.dart';
import '../features/mila_archive/presentation/mila_archive_screen.dart';
import '../features/minigames/presentation/minigames_hub_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/parent_area/presentation/child_login_setup_screen.dart';
import '../features/parent_area/presentation/parent_home_screen.dart';
import '../features/photo_solver/presentation/photo_solver_flow_screen.dart';
import '../features/practice_exam/presentation/revanche_screen.dart';
import '../features/reading_detective/presentation/reading_detective_screen.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/teacher/presentation/teacher_home_screen.dart';
import '../features/teo_trail/presentation/teo_trail_screen.dart';
import '../features/writing_workshop/presentation/writing_workshop_screen.dart';
import '../features/zuri_atelier/presentation/zuri_atelier_screen.dart';
import '../features/avatar/avatar_editor_screen.dart';
import '../features/avatar/profile_editor_screen.dart';
import '../features/ranking/ranking_screen.dart';
import '../features/shop/shop_screen.dart';
import 'theme.dart';

class LigaDoSaberApp extends StatelessWidget {
  const LigaDoSaberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liga do Saber',
      debugShowCheckedModeBanner: false,
      theme: LigaTheme.light(),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        LoginChoiceScreen.routeName: (_) => const LoginChoiceScreen(),
        AuthScreen.routeName: (_) => const AuthScreen(),
        AuthScreen.teacherRouteName: (_) => const AuthScreen(forTeacher: true),
        ChildLoginScreen.routeName: (_) => const ChildLoginScreen(),
        ParentHomeScreen.routeName: (_) => const ParentHomeScreen(),
        ChildLoginSetupScreen.routeName: (_) => const ChildLoginSetupScreen(),
        TeacherHomeScreen.routeName: (_) => const TeacherHomeScreen(),
        ChildProfileScreen.routeName: (_) => const ChildProfileScreen(),
        ChooseAvatarScreen.routeName: (_) => const ChooseAvatarScreen(),
        MainShell.routeName: (_) => const MainShell(),
        MinigamesHubScreen.routeName: (_) => const MinigamesHubScreen(),
        PhotoSolverFlowScreen.routeName: (_) => const PhotoSolverFlowScreen(),
        WritingWorkshopScreen.routeName: (_) => const WritingWorkshopScreen(),
        ReadingDetectiveScreen.routeName: (_) => const ReadingDetectiveScreen(),
        MathArenaScreen.routeName: (_) => const MathArenaScreen(),
        TeoTrailScreen.routeName: (_) => const TeoTrailScreen(),
        ZuriAtelierScreen.routeName: (_) => const ZuriAtelierScreen(),
        MilaArchiveScreen.routeName: (_) => const MilaArchiveScreen(),
        RevancheScreen.routeName: (_) => const RevancheScreen(),
        ShopScreen.routeName: (_) => const ShopScreen(),
        AvatarEditorScreen.routeName: (_) => const AvatarEditorScreen(),
        ProfileEditorScreen.routeName: (_) => const ProfileEditorScreen(),
        RankingScreen.routeName: (_) => const RankingScreen(),
      },
    );
  }
}
