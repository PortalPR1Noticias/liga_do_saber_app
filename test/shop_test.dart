import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/shell/presentation/main_shell.dart';
import 'package:liga_do_saber_app/features/shop/shop_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
import 'package:liga_do_saber_app/shared/models/math_challenge.dart';
import 'package:liga_do_saber_app/shared/models/shop.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Ganha XP acertando [count] contas do Nico (20 XP cada, na primeira).
Future<void> earn(int count) async {
  final repository = AppRepository.instance;
  for (var i = 0; i < count; i++) {
    final challenge = await repository.newMathChallenge(MathTopic.operacoes);
    await repository.answerMathChallenge(challenge.id, 1);
  }
}

void main() {
  setUp(() {
    AppRepository.instance = MockAppRepository();
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  test('season levels come from the XP of the month', () {
    final season = SeasonState(
      id: '2026-10',
      xp: 260,
      endsAt: DateTime.now().add(const Duration(days: 3)),
    );
    expect(season.level, 5);
    expect(season.levelProgress, closeTo(0.2, 0.001));
    expect(season.name, 'Temporada de Outubro');
    expect(
      SeasonState(id: '2026-10', xp: 99999, endsAt: DateTime.now()).level,
      SeasonState.maxLevel,
    );

    final shop = ShopState.fromJson({
      'moedas': 12,
      'itens': ['aura_fogo'],
      'equipados': {'aura': 'aura_fogo', 'slot_novo': 'x'},
      'temporada': {'id': '2026-10', 'xp': 60, 'termina_em': '2026-11-01'},
    });
    expect(shop.coins, 12);
    expect(shop.equippedIn(VisualSlot.aura)?.name, 'Aura de Fogo');
    expect(shop.season.level, 1);
  });

  test('coins come only from XP and pay for visuals once', () async {
    final repository = AppRepository.instance;
    final start = await repository.loadShop();
    expect(start.coins, repository.childProfile.totalXp ~/ ShopState.xpPerCoin);

    final after = await repository.buyVisual('moldura_ouro');
    expect(after.coins, start.coins - 40);
    expect(after.owned, contains('moldura_ouro'));
    // Comprar de novo não cobra outra vez.
    expect((await repository.buyVisual('moldura_ouro')).coins, after.coins);

    // Quem não tem moedas suficientes precisa acertar mais.
    Object? error;
    for (final item in VisualItem.all.where((i) => i.price != null)) {
      try {
        await repository.buyVisual(item.id);
      } on AppRepositoryException catch (e) {
        error = e;
      }
    }
    expect(error, isA<AppRepositoryException>());
    final broke = await repository.loadShop();
    expect(broke.coins, greaterThanOrEqualTo(0));
    await earn(5);
    expect((await repository.loadShop()).coins, greaterThan(broke.coins));

    // Prêmio da temporada não se compra; só se ganha no nível.
    await expectLater(
      repository.buyVisual('aura_lendaria'),
      throwsA(isA<AppRepositoryException>()),
    );
    await expectLater(
      repository.claimSeasonReward('aura_lendaria'),
      throwsA(isA<AppRepositoryException>()),
    );
    await expectLater(
      repository.equipVisual(VisualSlot.moldura, 'aura_lendaria'),
      throwsA(isA<AppRepositoryException>()),
    );
  });

  testWidgets('the shop buys a visual and puts it on the hero', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Cada 10 XP de acertos vira 1 moeda. '
        'Aqui nada é vendido por dinheiro!',
      ),
      findsOneWidget,
    );

    await tapVisible(tester, find.byKey(const ValueKey('slot-titulo')));
    await tapVisible(tester, find.byKey(const ValueKey('item-titulo_curioso')));

    expect(find.text('Novo visual: O Curioso!'), findsOneWidget);
    expect(find.text('USANDO'), findsOneWidget);
    final shop = await AppRepository.instance.loadShop();
    expect(shop.equipped[VisualSlot.titulo], 'titulo_curioso');

    // Tocar de novo tira o visual.
    await tapVisible(tester, find.byKey(const ValueKey('item-titulo_curioso')));
    expect(
      (await AppRepository.instance.loadShop()).equipped,
      isNot(contains(VisualSlot.titulo)),
    );
  });

  testWidgets('season rewards unlock with the level of the month', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await earn(13); // 260 XP + bônus: nível 5 ou mais.
    await tester.pumpWidget(const MaterialApp(home: ShopScreen(season: true)));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey('item-aura_relampago')));
    expect(find.textContaining('nível 10 da temporada'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-titulo_estreante')),
    );
    final shop = await AppRepository.instance.loadShop();
    expect(shop.owned, contains('titulo_estreante'));
    expect(shop.equipped[VisualSlot.titulo], 'titulo_estreante');
  });

  testWidgets('the base shows the coins, the season and the equipped title', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await earn(13);
    await AppRepository.instance.claimSeasonReward('titulo_estreante');
    await AppRepository.instance.equipVisual(
      VisualSlot.titulo,
      'titulo_estreante',
    );
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hud-moedas')), findsOneWidget);
    expect(find.text('Estreante da Temporada'), findsOneWidget);
    expect(find.byKey(const ValueKey('base-temporada')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hud-moedas')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopScreen), findsOneWidget);
  });
}
