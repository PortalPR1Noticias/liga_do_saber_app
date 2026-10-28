import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/liga_do_saber_app.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/auth/presentation/auth_screen.dart';
import 'package:liga_do_saber_app/features/auth/presentation/child_login_screen.dart';
import 'package:liga_do_saber_app/features/parent_area/presentation/child_login_setup_screen.dart';
import 'package:liga_do_saber_app/features/parent_area/presentation/parent_home_screen.dart';
import 'package:liga_do_saber_app/features/performance/presentation/performance_view.dart';
import 'package:liga_do_saber_app/features/teacher/presentation/teacher_home_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_widgets.dart';
import 'package:liga_do_saber_app/shared/models/account_role.dart';
import 'package:liga_do_saber_app/shared/models/performance_report.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Responsável com a Bia já cadastrada.
Future<MockAppRepository> parentWithChild() async {
  final repository = MockAppRepository();
  await repository.signUp(
    name: 'Giovany',
    email: 'pai@familia.com',
    password: '123456',
    acceptedTermsVersion: 'teste',
  );
  await repository.saveChildProfile(
    nickname: 'Bia',
    schoolYear: 5,
    focusAreas: const ['Leitura'],
  );
  return repository;
}

void main() {
  setUp(() {
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  test('performance report sorts areas by how well the child does', () {
    final report = MockAppRepository.sampleReport(
      MockAppRepository().childProfile,
    );
    expect(
      report.areas.firstWhere((a) => a.key == 'matematica').status,
      PerformanceStatus.strong,
    );
    expect(report.needsAttention.map((a) => a.name), ['Português']);
    expect(
      report.areas.firstWhere((a) => a.key == 'historia').status,
      PerformanceStatus.noData,
    );
    expect(report.examAccuracy, 0.75);
  });

  test('performance report reads the JSON of avaliacao_desempenho', () {
    final report = PerformanceReport.fromJson({
      'periodo_dias': 30,
      'nivel': 3,
      'xp_total': 400,
      'sequencia_dias': 2,
      'dias_ativos': 5,
      'dias_ativos_semana': 1,
      'xp_semana': 60,
      'areas': [
        {
          'area': 'foto',
          'nome': 'Foto da tarefa',
          'concluidas': 2,
          'concluidas_semana': 0,
          'abertas': 2,
          'xp': 40,
        },
        {
          'area': 'portugues',
          'nome': 'Português',
          'concluidas': 1,
          'concluidas_semana': 1,
          'abertas': 2,
          'xp': 10,
        },
      ],
      'provas': [],
    });
    expect(report.areas.first.status, PerformanceStatus.usage);
    // Duas atividades ainda não bastam para avaliar.
    expect(report.areas.last.status, PerformanceStatus.starting);
    expect(report.rhythm, contains('1 dos últimos 7 dias'));
    expect(report.examAccuracy, isNull);
  });

  test('child username suggestion drops accents and spaces', () {
    expect(ChildLoginSetupScreen.suggestUsername('Ána Júlia'), 'ana.julia');
    expect(ChildLoginSetupScreen.suggestUsername('Zé!'), 'ze');
  });

  testWidgets('login choice opens the child, parent and teacher logins', (
    tester,
  ) async {
    usePhoneScreen(tester);
    AppRepository.instance = MockAppRepository();
    await tester.pumpWidget(const LigaDoSaberApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('JOGAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('loginChild')));
    await tester.pumpAndSettle();
    expect(find.byType(ChildLoginScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('loginTeacher')));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Seu nome'), findsOneWidget);
  });

  testWidgets('child login shows the error for a wrong password', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final repository = await parentWithChild();
    await repository.createChildLogin(username: 'bia', password: 'bia123');
    AppRepository.instance = repository;
    await tester.pumpWidget(const MaterialApp(home: ChildLoginScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'bia');
    await tester.enterText(find.byType(TextFormField).at(1), 'errada1');
    await scrollAndTap(tester, find.widgetWithText(LigaActionButton, 'Entrar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Usuário ou senha incorretos.'), findsOneWidget);
    expect(repository.role, AccountRole.responsible);
  });

  testWidgets('parent shares a child with a teacher, who sees the report', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final repository = await parentWithChild();
    AppRepository.instance = repository;
    await tester.pumpWidget(const MaterialApp(home: ParentHomeScreen()));
    await tester.pumpAndSettle();

    final child = repository.children.single;
    await scrollAndTap(tester, find.byKey(ValueKey('teachers-${child.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('teacherEmail')),
      'Prof.Ana@Escola.br',
    );
    await tester.enterText(
      find.byKey(const Key('teacherChildName')),
      'Beatriz Souza',
    );

    // Sem a autorização marcada, não libera.
    await scrollAndTap(tester, find.text('Liberar professor'));
    await tester.pumpAndSettle();
    expect(
      find.text('Marque a autorização para liberar o professor.'),
      findsOneWidget,
    );
    expect(await repository.loadTeacherLinks(), isEmpty);
    // Espera o aviso sumir para ele não cobrir o botão.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.byKey(const Key('teacherConsent')));
    await scrollAndTap(tester, find.text('Liberar professor'));
    await tester.pumpAndSettle();
    expect(find.text('prof.ana@escola.br'), findsOneWidget);
    expect(find.text('Vê a criança como "Beatriz Souza"'), findsOneWidget);

    // O professor entra e vê a criança com o nome que o responsável deu.
    await repository.signUpTeacher(
      name: 'Ana',
      email: 'prof.ana@escola.br',
      password: '123456',
      acceptedTermsVersion: 'teste',
    );
    await tester.pumpWidget(
      MaterialApp(key: UniqueKey(), home: const TeacherHomeScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Beatriz Souza'), findsOneWidget);
    expect(find.text('Reforço: Português'), findsOneWidget);

    await tester.tap(find.text('Beatriz Souza'));
    await tester.pumpAndSettle();
    expect(find.byType(PerformanceView), findsOneWidget);
    expect(find.text('Mandando bem'), findsOneWidget);
    expect(find.text('Precisa de reforço'), findsOneWidget);
  });

  testWidgets('teacher without students sees how to get them', (tester) async {
    usePhoneScreen(tester);
    final repository = MockAppRepository();
    await repository.signUpTeacher(
      name: 'Ana',
      email: 'ana@escola.br',
      password: '123456',
      acceptedTermsVersion: 'teste',
    );
    AppRepository.instance = repository;
    await tester.pumpWidget(const MaterialApp(home: TeacherHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('teacherEmpty')), findsOneWidget);
  });

  testWidgets('parent sees the performance of the child', (tester) async {
    usePhoneScreen(tester);
    final repository = await parentWithChild();
    AppRepository.instance = repository;
    await tester.pumpWidget(const MaterialApp(home: ParentHomeScreen()));
    await tester.pumpAndSettle();

    final child = repository.children.single;
    await tester.tap(find.byKey(ValueKey('performance-${child.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Desempenho de Bia'), findsOneWidget);
    expect(find.byKey(const Key('performanceRhythm')), findsOneWidget);
    expect(find.byKey(const ValueKey('area-matematica')), findsOneWidget);
  });

  testWidgets('parent adds a second child', (tester) async {
    usePhoneScreen(tester);
    final repository = await parentWithChild();
    AppRepository.instance = repository;
    await tester.pumpWidget(const LigaDoSaberApp());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamedAndRemoveUntil(ParentHomeScreen.routeName, (_) => false);
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.byKey(const Key('addChildButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Leo');
    await scrollAndTap(tester, find.text('Escolher avatar'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Entrar para a Liga'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Fazer depois'));
    await tester.pumpAndSettle();

    expect(repository.children.map((c) => c.nickname), ['Bia', 'Leo']);
    expect(find.text('Leo'), findsOneWidget);
    expect(find.text('Ainda sem login próprio'), findsNWidgets(2));
  });
}
