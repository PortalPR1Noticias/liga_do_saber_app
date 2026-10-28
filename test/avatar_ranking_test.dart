import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/avatar/avatar_editor_screen.dart';
import 'package:liga_do_saber_app/features/avatar/profile_editor_screen.dart';
import 'package:liga_do_saber_app/features/parent_area/presentation/parent_home_screen.dart';
import 'package:liga_do_saber_app/features/ranking/ranking_screen.dart';
import 'package:liga_do_saber_app/features/shell/presentation/main_shell.dart';
import 'package:liga_do_saber_app/features/shop/shop_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_avatar_3d.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
import 'package:liga_do_saber_app/shared/models/avatar.dart';
import 'package:liga_do_saber_app/shared/models/ranking.dart';
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

AvatarLook lookWith(Map<String, String> parts) =>
    AvatarLook.fromJson({...AvatarLook.initial.toJson(), ...parts});

void main() {
  setUp(() {
    AppRepository.instance = MockAppRepository();
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  group('modelo do avatar', () {
    test('o visual vai e volta do JSON e ignora peças desconhecidas', () {
      final look = lookWith({'cabelo': 'cabelo_black', 'chapeu': 'coroa'});
      expect(AvatarLook.fromJson(look.toJson()), look);

      final broken = AvatarLook.fromJson({
        'pele': 'pele_99',
        'camisa': 'cabelo_curto',
        'chapeu': 'nao_existe',
      });
      expect(broken[AvatarCategory.pele]!.id, 'pele_3');
      expect(broken[AvatarCategory.camisa]!.id, 'camiseta_azul');
      expect(broken[AvatarCategory.chapeu], isNull);
      expect(AvatarLook.fromJson(null), AvatarLook.initial);
    });

    test('pele, cabelo, olhos e boca são livres desde o nível 1', () {
      for (final category in const [
        AvatarCategory.pele,
        AvatarCategory.cabelo,
        AvatarCategory.olhos,
        AvatarCategory.corOlhos,
        AvatarCategory.boca,
      ]) {
        for (final part in AvatarPart.of(category)) {
          expect(
            part.isUnlocked(level: 1, owned: const {}),
            isTrue,
            reason: part.id,
          );
        }
      }
      final cape = AvatarPart.byId('capa_heroi')!;
      expect(cape.isUnlocked(level: 7, owned: const {}), isFalse);
      expect(cape.isUnlocked(level: 8, owned: const {}), isTrue);
      final jetpack = AvatarPart.byId('jetpack')!;
      expect(jetpack.isUnlocked(level: 99, owned: const {}), isFalse);
      expect(jetpack.isUnlocked(level: 1, owned: const {'jetpack'}), isTrue);
    });

    test('o sorteio usa só peças liberadas', () {
      for (var i = 0; i < 30; i++) {
        final look = AvatarLook.random(level: 1, owned: const {});
        for (final id in look.parts.values) {
          expect(
            AvatarPart.byId(id)!.isUnlocked(level: 1, owned: const {}),
            isTrue,
          );
        }
      }
    });

    test('o nome da Liga só aceita as listas', () {
      expect(LeagueName.isValid('Coruja Veloz 7'), isTrue);
      expect(LeagueName.isValid('Coruja Veloz 07'), isFalse);
      expect(LeagueName.isValid('Coruja Veloz 100'), isFalse);
      expect(LeagueName.isValid('Joana Silva 7'), isFalse);
      expect(LeagueName.isValid('Coruja Veloz'), isFalse);
      for (var i = 0; i < 50; i++) {
        expect(LeagueName.isValid(LeagueName.random()), isTrue);
      }
    });

    test('a migration 0015 tem as mesmas peças, níveis e preços do app', () {
      final sql = File(
        'supabase/migrations/0015_avatar_perfil_ranking.sql',
      ).readAsStringSync();
      for (final part in AvatarPart.all) {
        final level = part.fromShop ? 'null' : '${part.minLevel}';
        expect(
          sql,
          contains("('${part.id}', '${part.category.key}', $level)"),
          reason: part.id,
        );
        if (part.fromShop) {
          expect(
            sql,
            contains(
              "('${part.id}', 'roupa', ${part.price ?? 'null'}, "
              "${part.seasonLevel ?? 'null'})",
            ),
            reason: part.id,
          );
        }
      }
      for (final word in [...LeagueName.animals, ...LeagueName.qualities]) {
        expect(sql, contains("'$word'"), reason: word);
      }
    });

    test('as roupas da Loja entram no catálogo de visuais', () {
      final neon = VisualItem.byId('tenis_neon')!;
      expect(neon.slot, VisualSlot.roupa);
      expect(neon.price, 60);
      expect(neon.avatarPart?.category, AvatarCategory.tenis);
      expect(VisualItem.byId('coroa')!.seasonLevel, 18);
    });

    test('o ranking lê o JSON de ranking_liga', () {
      final ranking = Ranking.fromJson(RankingPeriod.semana, {
        'participa': false,
        'participantes': 1,
        'top': [
          {
            'posicao': 1,
            'nome_liga': 'Tigre Valente 21',
            'avatar_visual': {'cabelo': 'cabelo_black'},
            'nivel': 6,
            'xp': 60,
            'eu': false,
          },
        ],
        'eu': {
          'posicao': 2,
          'nome_liga': 'Coruja Veloz 7',
          'avatar_visual': null,
          'nivel': 3,
          'xp': 30,
          'eu': true,
        },
      });
      expect(ranking.top.single.leagueName, 'Tigre Valente 21');
      expect(
        ranking.top.single.look[AvatarCategory.cabelo]!.id,
        'cabelo_black',
      );
      expect(ranking.me!.position, 2);
      expect(ranking.me!.look, AvatarLook.initial);
      expect(ranking.participating, isFalse);
    });
  });

  testWidgets('o avatar desenha todas as peças sem erro, de todos os lados', (
    tester,
  ) async {
    final looks = [
      for (final part in AvatarPart.all) AvatarLook.initial.withPart(part),
    ];
    for (final yaw in const [0.0, 1.6, 3.1, -1.6]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Wrap(
            children: [
              for (final look in looks) ...[
                CustomPaint(
                  size: const Size(40, 50),
                  painter: AvatarPainter(look, yaw: yaw),
                ),
                CustomPaint(
                  size: const Size(30, 30),
                  painter: AvatarPainter(look, yaw: yaw, bust: true),
                ),
              ],
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a criança monta o avatar e salva', (tester) async {
    usePhoneScreen(tester);
    final repository = AppRepository.instance;
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AvatarEditorScreen.routeName: (_) => const AvatarEditorScreen(),
        },
        home: const MainShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-Perfil')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('perfilAvatar')), findsOneWidget);
    expect(find.text('No ranking: Raposa Genial 8'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('editarAvatar')));
    expect(find.byType(AvatarEditorScreen), findsOneWidget);

    // Tom de pele, cabelo e cor do cabelo.
    await tapVisible(tester, find.byKey(const ValueKey('peca-pele_6')));
    await tapVisible(tester, find.byKey(const ValueKey('aba-avatar-cabelo')));
    await tapVisible(tester, find.byKey(const ValueKey('peca-cabelo_trancas')));
    await tapVisible(tester, find.byKey(const ValueKey('peca-cor_ruivo')));

    // Peça da Loja ainda não comprada: compra com as moedas do XP.
    await tapVisible(tester, find.byKey(const ValueKey('aba-avatar-tenis')));
    await tapVisible(tester, find.byKey(const ValueKey('peca-tenis_neon')));
    expect(find.text('Comprar Tênis Neon?'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('confirmarCompra')));
    expect((await repository.loadShop()).owned, contains('tenis_neon'));

    // Espera o aviso da compra sumir de cima do botão.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('salvarAvatar')));
    expect(find.byType(AvatarEditorScreen), findsNothing);
    final look = repository.childProfile.look;
    expect(look[AvatarCategory.pele]!.id, 'pele_6');
    expect(look[AvatarCategory.cabelo]!.id, 'cabelo_trancas');
    expect(look[AvatarCategory.corCabelo]!.id, 'cor_ruivo');
    expect(look[AvatarCategory.tenis]!.id, 'tenis_neon');
  });

  testWidgets('roupa de nível alto fica trancada até a criança subir', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final repository = AppRepository.instance as MockAppRepository;
    // Perfil novo começa no nível 1.
    repository.selectChild(null);
    await repository.saveChildProfile(
      nickname: 'Leo',
      schoolYear: 3,
      focusAreas: const [],
    );
    expect(repository.childProfile.level, 1);

    await tester.pumpWidget(const MaterialApp(home: AvatarEditorScreen()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('aba-avatar-costas')));
    await tapVisible(tester, find.byKey(const ValueKey('peca-capa_heroi')));
    expect(find.textContaining('nível 8 para liberar'), findsOneWidget);

    Object? error;
    try {
      await repository.saveAvatarLook(
        AvatarLook.initial.withPart(AvatarPart.byId('capa_heroi')!),
      );
    } on AppRepositoryException catch (e) {
      error = e;
    }
    expect(error, isNotNull);
  });

  testWidgets('a criança muda o apelido e o nome do ranking', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ProfileEditorScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Raposa Genial 8'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('apelidoField')), 'Alexia');
    await tapVisible(tester, find.byKey(const ValueKey('heroi-guardia')));
    await tapVisible(tester, find.byTooltip('Aumentar número'));
    expect(find.text('Raposa Genial 9'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('salvarPerfil')));

    final profile = AppRepository.instance.childProfile;
    expect(profile.nickname, 'Alexia');
    expect(profile.avatarId, 'guardia');
    expect(profile.leagueName, 'Raposa Genial 9');
  });

  testWidgets('ranking: sem liberação a criança só vê a própria posição', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: RankingScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rankingPrivado')), findsOneWidget);
    expect(find.text('Coruja Veloz 7'), findsOneWidget);
    // Ela não está no top, mas vê a posição dela embaixo.
    await tester.scrollUntilVisible(
      find.byKey(const Key('minhaPosicao')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Raposa Genial 8'), findsOneWidget);
    expect(find.text('Você · Nível 11'), findsOneWidget);

    for (final period in RankingPeriod.values) {
      await tapVisible(tester, find.byKey(ValueKey('periodo-${period.key}')));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('o responsável libera a criança no ranking', (tester) async {
    usePhoneScreen(tester);
    final repository = AppRepository.instance as MockAppRepository;
    await repository.signIn(email: 'a@b.c', password: '123456');
    final child = repository.children.single;
    expect(child.inRanking, isFalse);

    await tester.pumpWidget(const MaterialApp(home: ParentHomeScreen()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(ValueKey('ranking-${child.id}')));
    expect(repository.children.single.inRanking, isTrue);

    repository.selectChild(child.id);
    final ranking = await repository.loadRanking(RankingPeriod.geral);
    expect(ranking.participating, isTrue);
    expect(ranking.top.where((e) => e.isMe), hasLength(1));
    // No ranking aparece o nome da Liga, nunca o apelido.
    expect(ranking.top.map((e) => e.leagueName), isNot(contains('Alex G')));
  });

  testWidgets('a Loja vende roupas do avatar e veste na hora', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('slot-roupa')));
    await tapVisible(tester, find.byKey(const ValueKey('item-fone_gamer')));

    final repository = AppRepository.instance;
    expect((await repository.loadShop()).owned, contains('fone_gamer'));
    expect(repository.childProfile.look.wears('fone_gamer'), isTrue);
    expect(find.text('USANDO'), findsOneWidget);

    // Tocar de novo tira o fone (chapéu é opcional).
    await tapVisible(tester, find.byKey(const ValueKey('item-fone_gamer')));
    expect(repository.childProfile.look.wears('fone_gamer'), isFalse);
  });
}
