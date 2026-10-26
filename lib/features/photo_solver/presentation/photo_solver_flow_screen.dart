import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';

class PhotoSolverFlowScreen extends StatefulWidget {
  const PhotoSolverFlowScreen({super.key});

  static const routeName = '/photo';

  @override
  State<PhotoSolverFlowScreen> createState() => _PhotoSolverFlowScreenState();
}

class _PhotoSolverFlowScreenState extends State<PhotoSolverFlowScreen> {
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar atividade')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Foto + IA',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Protótipo do fluxo de captura, análise e feedback pedagógico.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              LigaPanel(
                borderColor: LigaColors.progressGreen.withValues(alpha: 0.6),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LigaColors.progressGreen),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.document_scanner_outlined,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LigaActionButton(
                label: 'Simular análise da IA',
                icon: Icons.psychology_alt,
                onPressed: () => setState(() => _showResult = true),
              ),
              if (_showResult) ...[
                const SizedBox(height: 18),
                const LigaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado simulado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Identifiquei uma questão de Matemática. A resposta está parcialmente correta. Vamos revisar a operação antes de concluir.',
                        style: TextStyle(
                          color: Color(0xFFD8E2FF),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
