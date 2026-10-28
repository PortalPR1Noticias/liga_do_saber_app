import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/minigames/presentation/crossword_screen.dart';
import 'package:liga_do_saber_app/features/parent_area/presentation/weekly_report_screen.dart';
import 'package:liga_do_saber_app/features/progress/presentation/subject_progress_section.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
import 'package:liga_do_saber_app/shared/models/learning_report.dart';
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

LearningEvent win(LearningArea area, DateTime at, {int xp = 20}) =>
    LearningEvent(origin: 'minijogo', xp: xp, at: at, area: area);

List<LearningAttempt> tries(LearningArea area, DateTime at, int n) => [
  for (var i = 0; i < n; i++)
    LearningAttempt(
      area: area,
      at: at.add(Duration(minutes: i)),
    ),
];

void main() {
  setUp(() {
    AppRepository.instance = MockAppRepository();
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  test('crossword letters ignore accents, spaces and case', () {
    expect(crosswordLetters('Fração'), 'FRACAO');
    expect(crosswordLetters(' ár vo-re '), 'ARVORE');
  });

  test('weekly report shows what went well and what to practice', () {
    final now = DateTime(2026, 10, 28, 18);
    final monday = DateTime(2026, 10, 26, 15);
    final lastWeek = DateTime(2026, 10, 19, 15);
    final log = LearningLog(
      events: [
        for (var i = 0; i < 4; i++)
          win(LearningArea.matematica, monday.add(Duration(minutes: 5 * i))),
        win(LearningArea.portugues, now.subtract(const Duration(hours: 2))),
        LearningEvent(origin: 'missao', xp: 15, at: monday),
        win(LearningArea.matematica, lastWeek),
      ],
      attempts: [
        ...tries(LearningArea.matematica, monday, 4),
        ...tries(
          LearningArea.portugues,
          now.subtract(const Duration(hours: 2)),
          4,
        ),
      ],
    );

    final report = WeeklyReport.fromLog(log, childName: 'Sofia', now: now);

    expect(report.start, DateTime(2026, 10, 22));
    expect(report.activities, 5);
    expect(report.previousActivities, 1);
    expect(report.missions, 1);
    expect(report.xp, 5 * 20 + 15);
    expect(report.activeDays, 2);
    expect(
      report.summary,
      'Nesta semana, Sofia praticou mais Matemática. Foi bem em Matemática, '
      'mas ainda precisa treinar Português.',
    );
    expect(report.practiceArea, LearningArea.portugues);
    expect(report.suggestion, LearningArea.portugues.parentTip);
    expect(
      report.highlights,
      contains('Fez mais atividades que na semana anterior (5 contra 1).'),
    );
    // Duas sessões: 15 min + 3 na segunda-feira e 3 + 3 hoje.
    expect(report.minutes, 18 + 6);
  });

  test('weekly report without activity suggests a short daily habit', () {
    final report = WeeklyReport.fromLog(
      const LearningLog(),
      childName: 'Caio',
      now: DateTime(2026, 10, 28),
    );
    expect(report.activities, 0);
    expect(report.summary, contains('Caio ainda não jogou'));
    expect(report.suggestion, contains('10 a 15 minutos'));
    expect(report.minutes, 0);
  });

  test('subject progress ranks areas and finds strengths', () {
    final now = DateTime(2026, 10, 28, 12);
    final log = LearningLog(
      events: [
        for (var i = 0; i < 3; i++) win(LearningArea.historia, now),
        win(LearningArea.ciencias, now.subtract(const Duration(days: 2))),
      ],
      attempts: [
        ...tries(LearningArea.historia, now, 3),
        ...tries(LearningArea.ciencias, now, 4),
      ],
    );
    final progress = SubjectProgress.fromLog(log, now: now);
    expect(progress.areas.first.area, LearningArea.historia);
    expect(progress.areas.first.xp, 60);
    expect(progress.strengths, [LearningArea.historia]);
    expect(progress.toPractice, [LearningArea.ciencias]);
    expect(progress.weekXp, 80);
    expect(progress.lastDays.values.last, 60);
  });

  testWidgets('crossword: wrong answers give a hint, all words give XP', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: CrosswordScreen()));

    await scrollAndTap(tester, find.text('Começar cruzadas'));
    expect(find.text('0 de 3 · +20 XP'), findsOneWidget);

    Future<void> answer(String text) async {
      await scrollTo(tester, find.byKey(const Key('crosswordAnswer')));
      await tester.enterText(find.byKey(const Key('crosswordAnswer')), text);
      await scrollAndTap(tester, find.byKey(const Key('crosswordCheck')));
    }

    // Tamanho errado é avisado sem gastar tentativa.
    await answer('CORRER');
    await scrollTo(tester, find.textContaining('A palavra tem 5 letras'));

    await answer('verbo');
    await scrollTo(tester, find.text('Isso! VERBO está certa.'));

    // A próxima pista aberta é a 3 Horizontal (FRASE).
    await answer('TEXTO');
    await scrollTo(
      tester,
      find.text('Ainda não. Leia a pista de novo com calma.'),
    );
    await answer('LINHA');
    await scrollTo(tester, find.text('Quase! Dica: Começa com F...'));
    await answer('frase');

    // Tocar numa casa escolhe a palavra dela: RIMA desce da coluna 2.
    await scrollAndTap(tester, find.byKey(const Key('crosswordCell-2-2')));
    await answer('rima');

    await scrollTo(
      tester,
      find.text('Cruzadas completas! Todas as palavras no lugar!'),
    );
    // Precisou de dica: 10 XP + 15 da missão do dia.
    await scrollTo(tester, find.text('+25 XP'));
    expect(find.text('+25 XP'), findsOneWidget);

    // O jogo entra no progresso por matéria (Português).
    final log = await AppRepository.instance.loadLearningLog();
    expect(log.events.where((e) => e.area == LearningArea.portugues).length, 1);
  });

  testWidgets('weekly report screen shows summary and suggestion', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final repo = AppRepository.instance as MockAppRepository;
    final now = DateTime.now();
    repo.learningEvents.addAll([
      for (var i = 0; i < 3; i++)
        win(LearningArea.matematica, now.subtract(Duration(minutes: i))),
    ]);
    repo.learningAttempts.addAll(tries(LearningArea.matematica, now, 3));

    await tester.pumpWidget(const MaterialApp(home: WeeklyReportScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weeklyReportSummary')), findsOneWidget);
    expect(find.textContaining('praticou mais Matemática'), findsOneWidget);
    expect(find.text('3 atividades'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('weeklyReportSuggestion')));
  });

  testWidgets('subject progress section lists every area', (tester) async {
    usePhoneScreen(tester);
    final repo = AppRepository.instance as MockAppRepository;
    repo.learningEvents.add(win(LearningArea.geografia, DateTime.now()));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: SubjectProgressSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progresso por matéria'), findsOneWidget);
    for (final area in LearningArea.values) {
      expect(find.text(area.label), findsWidgets);
    }
    expect(find.text('Últimos 7 dias: 20 XP'), findsOneWidget);
  });
}
