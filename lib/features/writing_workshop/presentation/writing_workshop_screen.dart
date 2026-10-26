import 'package:flutter/material.dart';

import '../../../app/theme.dart';
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
      icon: Icons.edit_note,
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
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 22),
              ...children,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LigaPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: LigaColors.actionCoral,
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
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
