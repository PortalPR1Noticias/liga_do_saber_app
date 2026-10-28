import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
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
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  testWidgets('parent needs the AI consent to send an exam', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ParentExamsScreen(
          pickPhoto: (_) async => _tinyPng,
          pickGallery: (limit) async => [_tinyPng],
          pickPdf: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('practiceNoConsent')), findsOneWidget);
    await tester.tap(find.byKey(const Key('practiceCamera')));
    await tester.pumpAndSettle();
    expect(find.text('Fotos (1 de 10)'), findsOneWidget);

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
      MaterialApp(
        home: ParentExamsScreen(
          pickPhoto: (_) async => _tinyPng,
          pickGallery: (limit) async => [_tinyPng],
          pickPdf: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Nenhuma prova enviada ainda.'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('practiceGallery')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practiceGallery')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practiceGallery')));
    await tester.pumpAndSettle();
    expect(find.text('Fotos (2 de 10)'), findsOneWidget);

    await _scrollAndTap(tester, find.text('Criar treino'));
    await _scrollTo(tester, find.text('Treino pronto: Prova de frações'));
    expect(find.text('Fotos (0 de 10)'), findsOneWidget);
    await _scrollTo(tester, find.textContaining('0 de 3 questões'));
  });

  testWidgets('parent picks many photos at once, up to 10', (tester) async {
    _usePhoneScreen(tester);
    final limits = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ParentExamsScreen(
          pickPhoto: (_) async => _tinyPng,
          pickGallery: (limit) async {
            limits.add(limit);
            return List.filled(7, _tinyPng);
          },
          pickPdf: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('practiceGallery')));
    await tester.pumpAndSettle();
    expect(find.text('Fotos (7 de 10)'), findsOneWidget);
    await _scrollAndTap(tester, find.byKey(const Key('practiceGallery')));
    expect(limits, [10, 3]);
    expect(find.text('Fotos (10 de 10)'), findsOneWidget);
    expect(find.textContaining('Cabem só 10 fotos'), findsOneWidget);
    final gallery = tester.widget<OutlinedButton>(
      find.byKey(const Key('practiceGallery')),
    );
    expect(gallery.onPressed, isNull);
  });

  testWidgets('parent sends only a PDF', (tester) async {
    _usePhoneScreen(tester);
    await AppRepository.instance.setAiConsent(true);
    var pdf = PracticeExamPdf(
      name: 'nao-e-pdf.pdf',
      bytes: Uint8List.fromList(utf8.encode('oi, tudo bem?')),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ParentExamsScreen(
          pickPhoto: (_) async => null,
          pickGallery: (_) async => const [],
          pickPdf: () async => pdf,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollAndTap(tester, find.byKey(const Key('practicePdf')));
    await _scrollTo(tester, find.text('Esse arquivo não é um PDF.'));
    expect(find.byKey(const Key('practicePdfChip')), findsNothing);

    pdf = PracticeExamPdf(
      name: 'prova-fracoes.pdf',
      bytes: Uint8List.fromList(utf8.encode('%PDF-1.4 prova')),
    );
    await _scrollAndTap(tester, find.byKey(const Key('practicePdf')));
    expect(find.textContaining('prova-fracoes.pdf'), findsOneWidget);
    expect(find.text('Trocar o PDF'), findsOneWidget);

    await _scrollAndTap(tester, find.text('Criar treino'));
    await _scrollTo(tester, find.text('Treino pronto: Prova de frações'));
    expect(find.byKey(const Key('practicePdfChip')), findsNothing);
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
    await tester.scrollUntilVisible(
      find.text('3 de 3 acertadas'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    final stars = await repository.loadPracticeExams();
    expect(stars.single.won, isTrue);
    expect(stars.single.stars, 2);
  });
}
