import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';

class WritingWorkshopScreen extends StatelessWidget {
  const WritingWorkshopScreen({super.key});

  static const routeName = '/writing';

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Oficina de Texto',
      subtitle: 'Luma ajuda a planejar, escrever, revisar e reescrever.',
      color: LigaColors.actionCoral,
      character: LigaCharacter.luma,
      children: const [
        _StepTile('1', 'Planejar ideias', 'Tema, começo, meio e final.'),
        _StepTile('2', 'Escrever versão 1', 'Texto curto com foco em clareza.'),
        _StepTile(
          '3',
          'Receber feedback',
          'Clareza, organização, pontuação e criatividade.',
        ),
        _StepTile(
          '4',
          'Reescrever melhor',
          'XP por evolução, não só por acerto.',
        ),
      ],
    );
  }
}

class _FeatureScaffold extends StatelessWidget {
  const _FeatureScaffold({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.character,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Color color;
  final LigaCharacter character;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              PopIn(
                child: LigaFeatureHeader(
                  title: title,
                  subtitle: subtitle,
                  color: color,
                  character: character,
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < children.length; i++)
                PopIn(
                  delay: Duration(milliseconds: 100 + 80 * i),
                  child: children[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile(this.number, this.title, this.subtitle);

  final String number;
  final String title;
  final String subtitle;

  static const _colors = [
    LigaColors.actionCoral,
    LigaColors.sunsetOrange,
    LigaColors.adventurePurple,
    LigaColors.progressGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[(int.parse(number) - 1) % _colors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LigaPanel(
        padding: const EdgeInsets.all(14),
        borderColor: color.withValues(alpha: 0.45),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: LigaColors.shade(color),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: LigaTheme.displayFont,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
