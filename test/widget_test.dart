import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/liga_do_saber_app.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/auth/presentation/auth_screen.dart';
import 'package:liga_do_saber_app/features/math_arena/presentation/math_arena_screen.dart';
import 'package:liga_do_saber_app/features/mila_archive/presentation/mila_archive_screen.dart';
import 'package:liga_do_saber_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:liga_do_saber_app/features/photo_solver/presentation/photo_solver_flow_screen.dart';
import 'package:liga_do_saber_app/features/reading_detective/presentation/reading_detective_screen.dart';
import 'package:liga_do_saber_app/features/shell/presentation/main_shell.dart';
import 'package:liga_do_saber_app/features/teo_trail/presentation/teo_trail_screen.dart';
import 'package:liga_do_saber_app/features/writing_workshop/presentation/writing_workshop_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_rewards.dart';
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

  testWidgets('math arena gives XP for the right answer', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MathArenaScreen()));

    await scrollAndTap(tester, find.text('Começar desafio'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('24 figurinhas'), findsOneWidget);

    await scrollAndTap(tester, find.text('12'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.textContaining('tabuada do 3'));

    await scrollAndTap(tester, find.text('8'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.text('Acertou! Mandou bem!'));
    // Acertou depois de errar: 10 XP + 20 de bônus da missão do dia.
    await scrollTo(tester, find.text('+30 XP'));
    expect(find.text('+30 XP'), findsOneWidget);
    await scrollTo(
      tester,
      find.textContaining('Então cada amigo fica com 8 figurinhas.'),
    );
  });

  testWidgets('math arena reveals step by step', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MathArenaScreen()));

    await scrollAndTap(tester, find.text('Começar desafio'));
    await tester.pump();
    await tester.pump();
    await scrollAndTap(tester, find.text('Ver passo a passo'));
    await tester.pump();
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

  testWidgets('teo trail gives XP and shows the discovery', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: TeoTrailScreen()));

    await scrollAndTap(tester, find.text('Geografia'));
    await scrollAndTap(tester, find.text('Começar expedição'));
    await tester.pump();
    await tester.pump();
    expect(find.text('O mistério da poça sumida'), findsOneWidget);
    expect(find.textContaining('Geografia · +20 XP'), findsOneWidget);

    await scrollAndTap(tester, find.text('Evaporou com o calor do sol'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.text('Mistério desvendado! Que explorador!'));
    // Acertou de primeira: 20 XP + 20 de bônus da missão do dia.
    await scrollTo(tester, find.text('+40 XP'));
    expect(find.text('+40 XP'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Você sabia?'));
  });

  testWidgets('teo trail reveals the discovery without XP', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: TeoTrailScreen()));

    await scrollAndTap(tester, find.text('Começar expedição'));
    await tester.pump();
    await tester.pump();
    await scrollAndTap(tester, find.text('Virou terra'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.textContaining('calor faz com a água'));

    await scrollAndTap(tester, find.text('Revelar a descoberta'));
    await tester.pump();
    await tester.pump();
    await scrollTo(
      tester,
      find.textContaining('a água da poça evaporou com o calor do sol'),
    );
    expect(find.text('+20 XP'), findsNothing);
  });

  testWidgets('mila word search gives XP when every word is found', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MilaArchiveScreen()));

    await scrollAndTap(tester, find.text('Começar jogo'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Palavras do Império'), findsOneWidget);
    expect(find.text('Palavras: 0 de 4'), findsOneWidget);

    Future<void> mark(int r1, int c1, int r2, int c2) async {
      await scrollAndTap(tester, find.byKey(ValueKey('letra-$r1-$c1')));
      await tester.pump();
      await scrollAndTap(tester, find.byKey(ValueKey('letra-$r2-$c2')));
      await tester.pump();
      await tester.pump();
    }

    await mark(0, 0, 0, 6); // IMPERIO
    await scrollTo(tester, find.textContaining('governado por um imperador'));
    await mark(0, 0, 1, 1); // não é palavra
    await scrollTo(tester, find.textContaining('não é uma das palavras'));
    await mark(2, 4, 2, 1); // CAFE, de trás para frente
    await mark(3, 0, 7, 0); // COROA
    await mark(3, 6, 6, 6); // OURO
    await scrollTo(tester, find.text('Achou todas! Olho de historiadora!'));
    // 20 XP + 20 de bônus da missão do dia.
    await scrollTo(tester, find.text('+40 XP'));
    await scrollTo(tester, find.textContaining('Você sabia?'));
  });

  testWidgets('mila timeline counts the cards in place', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MilaArchiveScreen()));

    await scrollAndTap(tester, find.text('Linha do tempo'));
    await scrollAndTap(tester, find.text('Começar jogo'));
    await tester.pump();
    await tester.pump();

    Future<void> pick(String text) async {
      await scrollAndTap(tester, find.textContaining(text));
      await tester.pump();
    }

    // Ordem errada: correio, TV, telefone, celular.
    await pick('cartas a cavalo');
    await pick('transmissão de TV');
    await pick('primeiros telefones');
    await pick('celulares');
    await scrollAndTap(tester, find.text('Conferir ordem'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.textContaining('2 de 4 fichas no lugar certo'));

    // Ordem certa: correio, telefone, TV, celular (vale 10 XP + bônus).
    await pick('cartas a cavalo');
    await pick('primeiros telefones');
    await pick('transmissão de TV');
    await pick('celulares');
    await scrollAndTap(tester, find.text('Conferir ordem'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.text('Fichas em ordem! Caso resolvido!'));
    await scrollTo(tester, find.text('1877'));
    await scrollTo(tester, find.text('+30 XP'));
  });

  testWidgets('mila document riddle reveals the answer without XP', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MilaArchiveScreen()));

    await scrollAndTap(tester, find.text('Enigma do documento'));
    await scrollAndTap(tester, find.text('Começar jogo'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Foto antiga'), findsOneWidget);

    await scrollAndTap(tester, find.text('Tem um quadro na parede'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.textContaining('quase ninguém usa hoje'));

    await scrollAndTap(tester, find.text('Revelar a solução'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.textContaining('os tinteiros mostram'));
    expect(find.byType(LigaRewardCard), findsNothing);
  });

  testWidgets('mila games stop giving XP after 15 wins in a day', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MilaArchiveScreen()));
    await scrollAndTap(tester, find.text('Enigma do documento'));

    for (var game = 1; game <= 16; game++) {
      await scrollAndTap(
        tester,
        find.text(game == 1 ? 'Começar jogo' : 'Nova partida'),
      );
      await tester.pump();
      await tester.pump();
      await scrollAndTap(
        tester,
        find.text('Há tinteiros para molhar a caneta'),
      );
      await tester.pump();
      await tester.pump();
    }
    await scrollTo(tester, find.textContaining('já ganhou o XP do Arquivo'));
    expect(find.byType(LigaRewardCard), findsNothing);
  });

  testWidgets('reading detective checks the answers and shows clues', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ReadingDetectiveScreen()));

    await scrollAndTap(tester, find.text('Abrir um caso'));
    await tester.pump();
    await tester.pump();
    expect(find.text('O bilhete desaparecido'), findsOneWidget);

    await scrollAndTap(tester, find.text('Um bilhete deixado na biblioteca'));
    await scrollAndTap(tester, find.text('A bibliotecária'));
    await scrollAndTap(tester, find.text('Um foguete'));
    await scrollAndTap(tester, find.text('Enviar respostas'));
    await tester.pump();
    await tester.pump();

    await scrollTo(tester, find.textContaining('Você acertou 2 de 3'));
    // 2 acertos (20 XP) + 25 de bônus da missão do dia.
    await scrollTo(tester, find.text('+45 XP'));
    expect(find.text('+45 XP'), findsOneWidget);
    expect(find.text('Medalha nova: Primeiro Passo'), findsOneWidget);
  });

  testWidgets('writing workshop gives feedback and rewards the rewrite', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: WritingWorkshopScreen()));

    await scrollTo(tester, find.widgetWithText(TextField, 'Seu texto'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Seu texto'),
      'era uma vez um gato que voava',
    );
    await scrollAndTap(tester, find.text('Receber feedback da Luma'));
    await tester.pump();
    await tester.pump();

    await scrollTo(tester, find.text('Feedback da Luma'));
    await scrollTo(tester, find.text('Termine cada frase com ponto final.'));
    await scrollAndTap(tester, find.text('Enviar reescrita'));
    await tester.pump();
    await tester.pump();

    await scrollTo(tester, find.text('Melhorou bem'));
    // 26 XP pela evolução + 35 de bônus da missão do dia.
    await scrollTo(tester, find.text('+61 XP'));
    expect(find.text('+61 XP'), findsOneWidget);
  });

  testWidgets('missions tab shows what is done today', (tester) async {
    usePhoneScreen(tester);
    await AppRepository.instance.answerMathChallenge('desafio-1', 1);
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();
    expect(find.text('Hoje: 1 de 6 missões'), findsOneWidget);
    expect(find.text('Feita!'), findsOneWidget);
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
