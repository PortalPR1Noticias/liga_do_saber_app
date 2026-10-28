import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/features/world/boss/boss_battle_screen.dart';
import 'package:liga_do_saber_app/features/world/world_islands.dart';
import 'package:liga_do_saber_app/features/world/world_map_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openBattle(WidgetTester tester, LigaIsland island) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(MaterialApp(home: BossBattleScreen(island: island)));
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('LUTAR!'));
}

/// Vence as 9 fases da Ilha dos Números (contas certas no mock).
Future<void> clearNicoPhases() async {
  for (var i = 0; i < 9; i++) {
    await AppRepository.instance.answerMathChallenge('desafio-1', 1);
  }
}

void main() {
  final nico = LigaIsland.all.firstWhere((i) => i.id == 'nico');
  final luma = LigaIsland.all.firstWhere((i) => i.id == 'luma');

  setUp(() {
    AppRepository.instance = MockAppRepository();
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  test('the boss only opens after the nine phases', () async {
    expect(
      nico.bossReady(await AppRepository.instance.loadActivityCounts()),
      isFalse,
    );
    await clearNicoPhases();
    final counts = await AppRepository.instance.loadActivityCounts();
    expect(nico.bossReady(counts), isTrue);
    expect(nico.progress(counts, const {}), 9);
    expect(nico.progress(counts, const {'nico': 2}), 10);
  });

  testWidgets('Nico boss falls when every attack is blocked', (tester) async {
    await openBattle(tester, nico);
    for (var round = 0; round < 5; round++) {
      await tapVisible(tester, find.byKey(ValueKey('ataque-$round-1')));
    }
    expect(find.text('VOLTAR AO MAPA'), findsOneWidget);
    expect(find.text('+50 XP de bônus'), findsOneWidget);
    expect(await AppRepository.instance.loadBossWins(), {'nico': 3});
  });

  testWidgets('a wrong answer costs a heart and shows the hero hint', (
    tester,
  ) async {
    await openBattle(tester, nico);
    await tapVisible(tester, find.byKey(const ValueKey('ataque-0-0')));
    expect(find.text('Pense na tabuada do 3.'), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('ataque-0-2')));
    await tapVisible(tester, find.byKey(const ValueKey('ataque-0-3')));
    expect(find.text('TENTAR DE NOVO'), findsOneWidget);
    expect(await AppRepository.instance.loadBossWins(), isEmpty);
  });

  testWidgets('Luma boss is graded in the final blow', (tester) async {
    await openBattle(tester, luma);
    for (final (round, choice) in [(0, 0), (1, 1), (2, 1)]) {
      await tapVisible(tester, find.byKey(ValueKey('ataque-$round-$choice')));
    }
    expect(find.text('VOLTAR AO MAPA'), findsOneWidget);
    expect(await AppRepository.instance.loadBossWins(), {'luma': 3});
  });

  testWidgets('Luma boss stays up with too many misses and explains them', (
    tester,
  ) async {
    await openBattle(tester, luma);
    for (final (round, choice) in [(0, 1), (1, 0), (2, 1)]) {
      await tapVisible(tester, find.byKey(ValueKey('ataque-$round-$choice')));
    }
    expect(
      find.text('Sombra do Esquecimento venceu desta vez'),
      findsOneWidget,
    );
    expect(find.text('Para revisar'), findsOneWidget);
    expect(await AppRepository.instance.loadBossWins(), isEmpty);
  });

  testWidgets('the map opens the boss once its phases are won', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WorldMapScreen())),
    );
    await tester.pumpAndSettle();
    final boss = find.byKey(const ValueKey('fase-nico-10'));
    await tapVisible(tester, boss);
    expect(find.byType(BossBattleScreen), findsNothing);
    expect(find.textContaining('Golem dos Números espera'), findsOneWidget);

    await clearNicoPhases();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WorldMapScreen())),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, boss);
    expect(find.byType(BossBattleScreen), findsOneWidget);
  });
}
