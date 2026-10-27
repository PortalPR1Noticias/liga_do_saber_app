import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/reading_detective/presentation/reading_detective_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_victory.dart';
import 'package:liga_do_saber_app/shared/models/ai_report.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

void main() {
  late MockAppRepository repository;

  setUp(() {
    repository = MockAppRepository();
    AppRepository.instance = repository;
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVictory.enabled = false;
  });

  testWidgets('a bandeira das telas com IA grava a denúncia', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ReadingDetectiveScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Avisar um problema'));
    await tester.pumpAndSettle();
    expect(find.text('Avisar um problema'), findsWidgets);

    await tester.tap(find.text(AiReportReason.improprio.label));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Texto estranho');
    await tester.tap(find.text('Enviar aviso'));
    await tester.pumpAndSettle();

    expect(repository.aiReports, hasLength(1));
    final report = repository.aiReports.single;
    expect(report.module, 'leitura');
    expect(report.reason, AiReportReason.improprio);
    expect(report.comment, 'Texto estranho');
    expect(
      find.text('Obrigado por avisar! A equipe vai olhar isso.'),
      findsOneWidget,
    );
  });

  testWidgets('sem escolher o motivo, o aviso não sai', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadingDetectiveScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Avisar um problema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar aviso'));
    await tester.pumpAndSettle();
    expect(repository.aiReports, isEmpty);
  });
}
