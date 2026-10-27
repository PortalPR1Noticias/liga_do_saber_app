import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Foto + IA',
                  subtitle:
                      'Tire uma foto da lição e a gente explica juntinho.',
                  color: LigaColors.progressGreen,
                  character: LigaCharacter.zuri,
                ),
              ),
              const SizedBox(height: 20),
              PopIn(
                delay: const Duration(milliseconds: 120),
                child: LigaPanel(
                  padding: const EdgeInsets.all(12),
                  borderColor: LigaColors.progressGreen.withValues(alpha: 0.6),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFBF3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomPaint(
                        painter: _ViewfinderPainter(),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LigaIconBubble(
                                icon: Icons.photo_camera_rounded,
                                color: LigaColors.progressGreen,
                                size: 76,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Enquadre a atividade aqui',
                                style: TextStyle(
                                  color: LigaColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LigaActionButton(
                label: 'Simular análise da IA',
                icon: Icons.auto_awesome_rounded,
                onPressed: () => setState(() => _showResult = true),
              ),
              if (_showResult) ...[
                const SizedBox(height: 18),
                PopIn(
                  child: LigaPanel(
                    borderColor: LigaColors.sunsetOrange.withValues(alpha: 0.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LigaMascot(
                          character: LigaCharacter.zuri,
                          size: 64,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resultado simulado',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Identifiquei uma questão de Matemática. A resposta está parcialmente correta. Vamos revisar a operação antes de concluir.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

/// Cantoneiras de câmera nos quatro cantos da área da foto.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const inset = 16.0;
    const arm = 30.0;
    final paint = Paint()
      ..color = LigaColors.progressGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final corners = [
      (const Offset(inset, inset), 1.0, 1.0),
      (Offset(size.width - inset, inset), -1.0, 1.0),
      (Offset(inset, size.height - inset), 1.0, -1.0),
      (Offset(size.width - inset, size.height - inset), -1.0, -1.0),
    ];
    for (final (corner, dx, dy) in corners) {
      canvas.drawLine(corner, corner + Offset(arm * dx, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, arm * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}
