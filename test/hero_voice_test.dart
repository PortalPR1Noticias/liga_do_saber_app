import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_do_saber_app/app/theme.dart';
import 'package:liga_do_saber_app/features/accessibility/accessibility_screen.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_accessibility.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_mascots.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_sound.dart';
import 'package:liga_do_saber_app/shared/design_system/liga_voice.dart';
import 'package:liga_do_saber_app/shared/services/app_repository.dart';
import 'package:liga_do_saber_app/shared/services/mock_app_repository.dart';

void main() {
  late MockAppRepository repository;

  setUp(() {
    repository = MockAppRepository();
    AppRepository.instance = repository;
    LigaMotion.ambient = false;
    LigaSound.enabled = false;
    LigaVoice.enabled = false;
    LigaVoice.current.value = null;
    LigaAccessibility.settings.value = const LigaAccessibilitySettings();
  });

  Widget voice({List<String> lines = const ['Some 1/2 com 1/4', 'Dá 3/4!']}) {
    return MaterialApp(
      home: Scaffold(
        body: LigaHeroVoice(character: LigaCharacter.nico, lines: lines),
      ),
    );
  }

  test('joins the lines into one speech and cuts long ones', () {
    expect(
      LigaVoice.speakable(['Primeiro passo', '', 'Segundo!  ', 'Fim.']),
      'Primeiro passo. Segundo! Fim.',
    );
    final long = LigaVoice.speakable(List.filled(80, 'Uma frase curta'));
    expect(long.length, lessThanOrEqualTo(LigaVoice.maxChars));
    expect(long, endsWith('.'));
  });

  testWidgets('hero speaks the explanation and keeps the text', (tester) async {
    await tester.pumpWidget(voice());
    expect(find.text('Ouvir o Nico explicar'), findsOneWidget);
    expect(find.text('Voz criada por IA'), findsOneWidget);

    await tester.tap(find.byKey(const Key('heroVoice')));
    await tester.pumpAndSettle();
    expect(find.text('Nico está falando...'), findsOneWidget);
    expect(repository.heroVoiceRequests, 1);

    // Tocar de novo para; ouvir outra vez usa o áudio guardado.
    await tester.tap(find.byKey(const Key('heroVoice')));
    await tester.pumpAndSettle();
    expect(find.text('Ouvir o Nico explicar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('heroVoice')));
    await tester.pumpAndSettle();
    expect(find.text('Nico está falando...'), findsOneWidget);
    expect(repository.heroVoiceRequests, 1);

    // Sair da tela para a voz.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(LigaVoice.current.value, isNull);
  });

  testWidgets('auto read plays the explanation by itself', (tester) async {
    LigaAccessibility.settings.value = const LigaAccessibilitySettings(
      autoRead: true,
    );
    await tester.pumpWidget(voice(lines: ['Outra explicação']));
    await tester.pumpAndSettle();
    expect(find.text('Nico está falando...'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  });

  testWidgets('accessibility screen changes the text size of the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    late double scaled;
    await tester.pumpWidget(
      MaterialApp(
        builder: LigaAccessibility.apply,
        home: Builder(
          builder: (context) {
            scaled = MediaQuery.textScalerOf(context).scale(10);
            return const AccessibilityScreen();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scaled, 10);

    await tester.tap(find.text('Muito grande'));
    await tester.pumpAndSettle();
    expect(LigaAccessibility.settings.value.textSize, LigaTextSize.muitoGrande);
    expect(scaled, closeTo(13, 0.001));

    for (final key in ['a11yReduceMotion', 'a11yAutoRead']) {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }
    expect(LigaAccessibility.settings.value.reduceMotion, isTrue);
    expect(LigaAccessibility.settings.value.autoRead, isTrue);
  });
}
