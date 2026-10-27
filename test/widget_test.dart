import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/liga_do_saber_app.dart';
import 'package:liga_do_saber_app/features/auth/presentation/auth_screen.dart';
import 'package:liga_do_saber_app/features/math_arena/presentation/math_arena_screen.dart';
import 'package:liga_do_saber_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:liga_do_saber_app/features/photo_solver/presentation/photo_solver_flow_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_widgets.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

void main() {
  // Os testes nunca falam com o Supabase: cada um começa com um repositório
  // em memória limpo.
  setUp(() => AppRepository.instance = MockAppRepository());

  testWidgets('Liga do Saber starts at the splash screen', (tester) async {
    await tester.pumpWidget(const LigaDoSaberApp());

    expect(find.text('LIGA DO SABER'), findsOneWidget);
    expect(find.text('Aprender vira missão'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Entre para a Liga do Saber'), findsOneWidget);
  });

  testWidgets('onboarding fits on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('Criar conta do responsável'), findsOneWidget);
  });

  testWidgets('auth form validates e-mail and password', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    await tester.enterText(find.byType(TextFormField).at(1), 'sem-arroba');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha precisa ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('photo solver shows result only after analysis', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: PhotoSolverFlowScreen()));

    expect(find.text('Resultado simulado'), findsNothing);
    await tester.tap(find.text('Simular análise da IA'));
    await tester.pump();
    expect(find.text('Resultado simulado'), findsOneWidget);
  });

  testWidgets('math arena reveals step by step', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MathArenaScreen()));

    await tester.tap(find.text('Ver passo a passo'));
    await tester.pump();
    expect(
      find.textContaining('Então cada amigo fica com 8 figurinhas.'),
      findsOneWidget,
    );
  });

  testWidgets('full sign-up flow reaches the home with chosen data', (
    tester,
  ) async {
    usePhoneScreen(tester);

    await tester.pumpWidget(const LigaDoSaberApp());
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar conta do responsável'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Giovany');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'responsavel@ligadosaber.app',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bia');
    await tester.tap(find.text('Escolher avatar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criadora'));
    await tester.tap(find.text('Entrar para a Liga'));
    await tester.pumpAndSettle();

    expect(find.text('Bia'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);
  });

  testWidgets('auth error from the server is shown to the user', (
    tester,
  ) async {
    AppRepository.instance = _FailingRepository();
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    await tester.tap(find.widgetWithText(SegmentedButton<bool>, 'Entrar'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'responsavel@ligadosaber.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha-errada');
    await tester.tap(find.widgetWithText(LigaActionButton, 'Entrar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });
}

class _FailingRepository extends MockAppRepository {
  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    throw const AppRepositoryException('E-mail ou senha incorretos.');
  }
}
