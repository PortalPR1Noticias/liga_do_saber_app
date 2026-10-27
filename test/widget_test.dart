import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/liga_do_saber_app.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/auth/presentation/auth_screen.dart';
import 'package:liga_do_saber_app/features/math_arena/presentation/math_arena_screen.dart';
import 'package:liga_do_saber_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:liga_do_saber_app/features/photo_solver/presentation/photo_solver_flow_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_widgets.dart';
import 'package:liga_do_saber_app/shared/models/photo_explanation.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

/// Foto falsa: um PNG de 1 pixel.
final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC',
);

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

/// Rola até o widget (as telas têm mascotes e podem passar da tela) e toca.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  // Os testes nunca falam com o Supabase: cada um começa com um repositório
  // em memória limpo. As animações contínuas ficam desligadas para que
  // `pumpAndSettle` consiga terminar.
  setUp(() {
    AppRepository.instance = MockAppRepository();
    LigaMotion.ambient = false;
  });

  testWidgets('Liga do Saber starts at the splash screen', (tester) async {
    await tester.pumpWidget(const LigaDoSaberApp());

    expect(find.byKey(LigaLogo.imageKey), findsOneWidget);
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
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    await tester.enterText(find.byType(TextFormField).at(1), 'sem-arroba');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await scrollAndTap(tester, find.text('Continuar'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha precisa ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('photo solver explains the photo step by step', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoSolverFlowScreen(pickPhoto: (_) async => _tinyPng),
      ),
    );

    expect(find.text('Entenda a missão'), findsNothing);
    await scrollAndTap(tester, find.text('Tirar foto'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Dividindo figurinhas'), findsOneWidget);
    await scrollTo(tester, find.text('Entenda a missão'));
    expect(find.text('Cada amigo fica com 8 figurinhas.'), findsNothing);
    await scrollAndTap(tester, find.text('Mostrar resposta'));
    await tester.pump();
    expect(find.text('Cada amigo fica com 8 figurinhas.'), findsOneWidget);
  });

  testWidgets('photo solver shows the error from the server', (tester) async {
    usePhoneScreen(tester);
    AppRepository.instance = _FailingPhotoRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoSolverFlowScreen(pickPhoto: (_) async => _tinyPng),
      ),
    );

    await scrollAndTap(tester, find.text('Escolher da galeria'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.text('Você já mandou muitas fotos hoje.'));
    expect(find.text('Você já mandou muitas fotos hoje.'), findsOneWidget);
  });

  testWidgets('math arena reveals step by step', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MathArenaScreen()));

    await scrollAndTap(tester, find.text('Ver passo a passo'));
    await tester.pump();
    await scrollTo(
      tester,
      find.textContaining('Então cada amigo fica com 8 figurinhas.'),
    );
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

    await scrollAndTap(tester, find.text('Criar conta do responsável'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Giovany');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'responsavel@ligadosaber.app',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await scrollAndTap(tester, find.byKey(const Key('parentalConsent')));
    await scrollAndTap(tester, find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bia');
    await scrollAndTap(tester, find.text('Escolher avatar'));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('Criador'));
    await scrollAndTap(tester, find.text('Entrar para a Liga'));
    await tester.pumpAndSettle();

    expect(find.text('Bia'), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-criadora')), findsOneWidget);
  });

  testWidgets('auth error from the server is shown to the user', (
    tester,
  ) async {
    usePhoneScreen(tester);
    AppRepository.instance = _FailingRepository();
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    await tester.tap(find.widgetWithText(SegmentedButton<bool>, 'Entrar'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'responsavel@ligadosaber.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha-errada');
    await scrollAndTap(tester, find.widgetWithText(LigaActionButton, 'Entrar'));
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

class _FailingPhotoRepository extends MockAppRepository {
  @override
  Future<PhotoExplanation> explainPhoto(Uint8List imageBytes) async {
    throw const AppRepositoryException('Você já mandou muitas fotos hoje.');
  }
}
