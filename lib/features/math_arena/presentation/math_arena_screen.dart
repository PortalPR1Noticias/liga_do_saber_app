import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';

class MathArenaScreen extends StatefulWidget {
  const MathArenaScreen({super.key});

  static const routeName = '/math';

  @override
  State<MathArenaScreen> createState() => _MathArenaScreenState();
}

class _MathArenaScreenState extends State<MathArenaScreen> {
  bool _showSteps = false;

  static const _steps = [
    'São 24 figurinhas para dividir igualmente entre 3 amigos.',
    'Dividir é repartir em partes iguais: 24 ÷ 3.',
    'Pense na tabuada do 3: 3 × 8 = 24.',
    'Então cada amigo fica com 8 figurinhas.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arena Matemática')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.calculate,
                color: LigaColors.primaryBlue,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Arena Matemática',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Desafios rápidos com explicação passo a passo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              const LigaPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desafio de Nico',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Se 24 figurinhas forem divididas entre 3 amigos, quantas ficam para cada um?',
                      style: TextStyle(color: Color(0xFFD8E2FF), height: 1.35),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Resposta simulada: 8',
                      style: TextStyle(
                        color: LigaColors.progressGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              LigaActionButton(
                label: 'Ver passo a passo',
                icon: Icons.route,
                color: LigaColors.primaryBlue,
                onPressed: () => setState(() => _showSteps = !_showSteps),
              ),
              if (_showSteps) ...[
                const SizedBox(height: 14),
                LigaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '${i + 1}. ${_steps[i]}',
                            style: const TextStyle(
                              color: Color(0xFFD8E2FF),
                              height: 1.35,
                            ),
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
