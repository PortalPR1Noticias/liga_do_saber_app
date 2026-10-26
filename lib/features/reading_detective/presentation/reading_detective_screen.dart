import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';

class ReadingDetectiveScreen extends StatelessWidget {
  const ReadingDetectiveScreen({super.key});

  static const routeName = '/reading';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detetive da Leitura')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.travel_explore,
                color: LigaColors.progressGreen,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Detetive da Leitura',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Cada pergunta precisa de uma pista no texto.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              const LigaPanel(
                child: Text(
                  'Caso: O bilhete desaparecido\n\nMila encontrou uma mensagem incompleta na biblioteca. Para descobrir quem deixou o bilhete, você precisa identificar a ideia principal e inferir o motivo da visita.',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
              ),
              const SizedBox(height: 14),
              MissionCard(
                title: 'Pergunta 1',
                subtitle: 'Qual é a pista mais importante do texto?',
                icon: Icons.search,
                color: LigaColors.progressGreen,
                progress: 0.33,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
