import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/practice_exam/presentation/parent_exams_screen.dart';
import 'package:liga_do_saber_app/features/practice_exam/presentation/revanche_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_widgets.dart';
import 'package:liga_do_saber_app/shared/models/practice_exam.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

/// Foto falsa: um PNG de 1 pixel.
final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC',
);

void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppRepository.instance = MockAppRepository();
    LigaMotion.ambient = false;
  });

  testWidgets('parent needs the AI consent to send an exam', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(
      MaterialApp(home: ParentExamsScreen(pickPhoto: (_) async => _tinyPng)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('practiceNoConsent')), findsOneWidget);
    await tester.tap(find.byKey(const Key('practiceCamera')));
    await tester.pumpAndSettle();
    expect(find.text('Fotos (1 de 4)'), findsOneWidget);

    await _scrollTo(tester, find.byKey(const Key('practiceSend')));
    final send = tester.widget<LigaActionButton>(
      find.byKey(const Key('practiceSend')),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('parent sends an exam and sees the summary', (tester) async {
    _usePhoneScreen(tester);
    await AppRepository.instance.setAiConsent(true);
    await tester.pumpWidget(
      MaterialApp(home: ParentExamsScreen(pickPhoto: (_) async => _tinyPng)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma prova enviada ainda.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('practiceGallery')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practiceGallery')));
    await tester.pumpAndSettle();
    expect(find.text('Fotos (2 de 4)'), findsOneWidget);

    await _scrollAndTap(tester, find.text('Criar treino'));
    await _scrollTo(tester, find.text('Treino pronto: Prova de frações'));
    expect(find.text('Fotos (0 de 4)'), findsOneWidget);
    await _scrollTo(tester, find.textContaining('0 de 3 questões'));
  });

  testWidgets('child sees an empty revanche without exams', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: RevancheScreen()));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('revancheEmpty')));
  });

  testWidgets('child wins the revanche by getting every question right', (
    tester,
  ) async {
    _usePhoneScreen(tester);
    final repository = AppRepository.instance;
    await repository.setAiConsent(true);
    await repository.uploadPracticeExam(
      photos: [_tinyPng],
      kind: PracticeExamKind.prova,
    );
    await tester.pumpWidget(const MaterialApp(home: RevancheScreen()));
    await tester.pumpAndSettle();

    await _scrollAndTap(tester, find.text('Prova de frações'));

    // 1ª questão: a que a criança errou na prova. Acertou de primeira: 10 XP.
    expect(find.text('Revanche!'), findsOneWidget);
    await _scrollAndTap(tester, find.text('2/4'));
    await _scrollTo(tester, find.text('Acertou! Veja o raciocínio:'));
    await _scrollTo(tester, find.text('+10 XP'));
    await _scrollAndTap(tester, find.text('Próxima questão'));

    // 2ª questão: dois erros, o Nico explica e ela volta no fim da fila.
    expect(find.textContaining('3/4 ou 1/4'), findsOneWidget);
    await _scrollAndTap(tester, find.text('1/4'));
    await _scrollTo(tester, find.textContaining('Quase!'));
    await _scrollAndTap(tester, find.text('São iguais'));
    await _scrollTo(tester, find.text('Nico explica:'));
    await _scrollAndTap(tester, find.text('Entendi! Essa volta no fim'));

    // 3ª questão, de primeira.
    await _scrollAndTap(tester, find.text('1/3'));
    await _scrollAndTap(tester, find.text('Próxima questão'));

    // A 2ª volta. Acertar agora não vale XP da questão, mas vence a prova
    // (+30 de bônus). Dois acertos de primeira em três: 2 estrelas.
    expect(find.textContaining('3/4 ou 1/4'), findsOneWidget);
    await _scrollAndTap(tester, find.text('3/4'));
    await _scrollTo(tester, find.byKey(const Key('revancheWon')));
    expect(find.text('3 de 3 acertadas'), findsOneWidget);
    final stars = await repository.loadPracticeExams();
    expect(stars.single.won, isTrue);
    expect(stars.single.stars, 2);
  });
}
