import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
import 'package:liga_do_saber_app/features/minigames/presentation/lightning_challenge_screen.dart';
import 'package:liga_do_saber_app/features/minigames/presentation/minigames_hub_screen.dart';
import 'package:liga_do_saber_app/features/minigames/presentation/order_puzzle_screen.dart';
import 'package:liga_do_saber_app/features/minigames/presentation/widgets/word_search_board.dart';
import 'package:liga_do_saber_app/features/minigames/presentation/word_search_screen.dart';
import 'package:liga_do_saber_app/shared/models/minigame.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapCell(WidgetTester tester, int row, int col) async {
  final cell = find.byKey(ValueKey('letra-$row-$col'));
  await scrollTo(tester, cell);
  await tester.tap(cell);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppRepository.instance = MockAppRepository();
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  test('word search line only accepts straight lines', () {
    expect(
      WordSearchBoard.line(const GridCell(0, 0), const GridCell(2, 2)),
      const [GridCell(0, 0), GridCell(1, 1), GridCell(2, 2)],
    );
    expect(
      WordSearchBoard.line(const GridCell(3, 1), const GridCell(3, 0)),
      const [GridCell(3, 1), GridCell(3, 0)],
    );
    expect(
      WordSearchBoard.line(const GridCell(0, 0), const GridCell(1, 2)),
      isEmpty,
    );
  });

  testWidgets('word search finds every word and gives XP', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: WordSearchScreen()));

    await scrollAndTap(tester, find.text('Começar caça-palavras'));
    expect(find.text('0 de 3 · +20 XP'), findsOneWidget);

    // Uma seleção errada não conta.
    await tapCell(tester, 1, 0);
    await tapCell(tester, 1, 3);
    await scrollTo(tester, find.textContaining('Essa não é uma das palavras'));

    await tapCell(tester, 0, 0);
    await tapCell(tester, 0, 4);
    await scrollTo(tester, find.text('VERBO'));

    await tapCell(tester, 4, 6);
    await tapCell(tester, 1, 6);
    await tapCell(tester, 6, 2);
    await tapCell(tester, 6, 6);

    await scrollTo(tester, find.text('Achou todas! Caça-palavras completo!'));
    // 20 XP do jogo + 15 da missão do dia.
    await scrollTo(tester, find.text('+35 XP'));
    expect(find.text('+35 XP'), findsOneWidget);
  });

  testWidgets('order puzzle locks right pieces and rewards the solution', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: OrderPuzzleScreen()));

    await scrollAndTap(tester, find.text('Começar quebra-cabeça'));
    await scrollAndTap(tester, find.text('Conferir'));
    await scrollTo(tester, find.textContaining('0 de 4 no lugar'));

    Future<void> swap(String a, String b) async {
      await scrollAndTap(tester, find.text(a));
      await scrollAndTap(tester, find.text(b));
    }

    await swap('A Luma', 'de aventuras');
    await swap('de aventuras', 'leu um livro');
    await swap('na biblioteca.', 'de aventuras');

    await scrollAndTap(tester, find.text('Conferir'));
    await scrollTo(tester, find.text('Montou! Tudo no lugar!'));
    // Montou na segunda conferida: 10 XP + 15 da missão do dia.
    await scrollTo(tester, find.text('+25 XP'));
    expect(find.text('+25 XP'), findsOneWidget);
  });

  testWidgets('lightning challenge counts the hits', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(home: LightningChallengeScreen()),
    );

    await scrollAndTap(tester, find.text('Começar'));
    expect(find.text('2 × 3 = ?'), findsOneWidget);

    Future<void> answer(int value) async {
      for (final digit in '$value'.split('')) {
        await scrollAndTap(tester, find.byKey(ValueKey('tecla-$digit')));
      }
      await scrollAndTap(tester, find.byKey(const ValueKey('tecla-ok')));
    }

    await answer(7); // errada
    for (var n = 3; n <= 9; n++) {
      await answer(n * 3);
    }

    await scrollTo(tester, find.text('Você acertou 7 de 8 contas.'));
    // 5 + 2 por acerto = 19 XP, mais 15 da missão do dia.
    await scrollTo(tester, find.text('+34 XP'));
    expect(find.text('+34 XP'), findsOneWidget);
  });

  testWidgets('games hub opens each game with the chosen subject', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: MinigamesHubScreen()));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('Matemática'));
    await scrollAndTap(tester, find.text('Quebra-cabeça'));
    expect(find.byType(OrderPuzzleScreen), findsOneWidget);
    final screen = tester.widget<OrderPuzzleScreen>(
      find.byType(OrderPuzzleScreen),
    );
    expect(screen.subject, MinigameSubject.matematica);
  });
}
