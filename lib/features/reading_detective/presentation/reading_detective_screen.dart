import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Detetive da Leitura',
                  subtitle: 'Cada pergunta precisa de uma pista no texto.',
                  color: LigaColors.actionCoral,
                  character: LigaCharacter.luma,
                ),
              ),
              const SizedBox(height: 20),
              PopIn(
                delay: const Duration(milliseconds: 120),
                child: LigaPanel(
                  borderColor: LigaColors.actionCoral.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LigaPill(
                        icon: Icons.folder_open_rounded,
                        label: 'Caso nº 1',
                        color: LigaColors.actionCoral,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'O bilhete desaparecido',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Luma encontrou uma mensagem incompleta na biblioteca. Para descobrir quem deixou o bilhete, você precisa identificar a ideia principal e inferir o motivo da visita.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PopIn(
                delay: const Duration(milliseconds: 200),
                child: MissionCard(
                  title: 'Pergunta 1',
                  subtitle: 'Qual é a pista mais importante do texto?',
                  icon: Icons.search_rounded,
                  color: LigaColors.actionCoral,
                  progress: 0.33,
                  onTap: () => showComingSoon(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
