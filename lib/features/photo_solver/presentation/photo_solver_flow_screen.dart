import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/photo_explanation.dart';
import '../../../shared/services/app_repository.dart';

/// Abre a câmera ou a galeria e devolve os bytes da foto (ou `null` se a
/// criança desistir). Os testes trocam por uma foto falsa.
typedef PhotoPicker = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> pickPhotoWithImagePicker(ImageSource source) async {
  // Foto menor deixa o envio rápido e cabe no limite da IA, mantendo a letra
  // da lição legível.
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  return file?.readAsBytes();
}

class PhotoSolverFlowScreen extends StatefulWidget {
  const PhotoSolverFlowScreen({
    super.key,
    this.pickPhoto = pickPhotoWithImagePicker,
  });

  static const routeName = '/photo';

  final PhotoPicker pickPhoto;

  @override
  State<PhotoSolverFlowScreen> createState() => _PhotoSolverFlowScreenState();
}

class _PhotoSolverFlowScreenState extends State<PhotoSolverFlowScreen> {
  Uint8List? _photo;
  bool _loading = false;
  String? _error;
  PhotoExplanation? _result;
  bool _showAnswer = false;

  Future<void> _takePhoto(ImageSource source) async {
    final Uint8List? photo;
    try {
      photo = await widget.pickPhoto(source);
    } on Exception {
      setState(() {
        _error = source == ImageSource.camera
            ? 'Não consegui abrir a câmera. Confira a permissão do app.'
            : 'Não consegui abrir a galeria. Confira a permissão do app.';
      });
      return;
    }
    if (photo == null || !mounted) return;
    setState(() {
      _photo = photo;
      _loading = true;
      _error = null;
      _result = null;
      _showAnswer = false;
    });
    try {
      final result = await AppRepository.instance.explainPhoto(photo);
      if (!mounted) return;
      setState(() => _result = result);
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
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
                child: _PhotoFrame(photo: _photo, loading: _loading),
              ),
              const SizedBox(height: 18),
              LigaActionButton(
                label: _photo == null ? 'Tirar foto' : 'Tirar outra foto',
                icon: Icons.photo_camera_rounded,
                onPressed: _loading
                    ? null
                    : () => _takePhoto(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              LigaActionButton(
                label: 'Escolher da galeria',
                icon: Icons.photo_library_rounded,
                color: LigaColors.primaryBlue,
                onPressed: _loading
                    ? null
                    : () => _takePhoto(ImageSource.gallery),
              ),
              if (_loading) ...[
                const SizedBox(height: 18),
                const _ThinkingCard(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 18),
                PopIn(
                  child: LigaPanel(
                    borderColor: LigaColors.actionCoral,
                    child: Row(
                      children: [
                        const LigaIconBubble(
                          icon: Icons.error_outline_rounded,
                          color: LigaColors.actionCoral,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (result != null) ...[
                const SizedBox(height: 18),
                ..._buildResult(context, result),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResult(BuildContext context, PhotoExplanation result) {
    final character = LigaCharacter.values.firstWhere(
      (c) => c.id == result.characterId,
      orElse: () => LigaCharacter.zuri,
    );
    final textTheme = Theme.of(context).textTheme;
    return [
      PopIn(
        child: LigaPanel(
          borderColor: character.color,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LigaMascot(character: character, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${character.displayName}, ${character.title}',
                      style: textTheme.labelLarge?.copyWith(
                        color: character.color,
                      ),
                    ),
                    if (result.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(result.title, style: textTheme.titleLarge),
                    ],
                    if (result.statement.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(result.statement, style: textTheme.bodyLarge),
                    ],
                    if (!result.readable &&
                        result.closingMessage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(result.closingMessage, style: textTheme.bodyLarge),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (result.readable) ...[
        const SizedBox(height: 18),
        for (var i = 0; i < result.steps.length; i++)
          PopIn(
            delay: Duration(milliseconds: 90 * i),
            child: _StepBubble(number: i + 1, step: result.steps[i]),
          ),
        if (result.finalAnswer.isNotEmpty) ...[
          const SizedBox(height: 6),
          if (_showAnswer)
            PopIn(
              child: LigaPanel(
                borderColor: LigaColors.progressGreen,
                child: Text(result.finalAnswer, style: textTheme.titleMedium),
              ),
            )
          else
            LigaActionButton(
              label: 'Mostrar resposta',
              icon: Icons.visibility_rounded,
              color: LigaColors.achievementYellow,
              onPressed: () => setState(() => _showAnswer = true),
            ),
        ],
        if (result.tip.isNotEmpty || result.closingMessage.isNotEmpty) ...[
          const SizedBox(height: 18),
          LigaSpeechBubble(
            text: [
              result.tip,
              result.closingMessage,
            ].where((t) => t.isNotEmpty).join('\n\n'),
          ),
        ],
        if (result.xp > 0) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: LigaPill(
              icon: Icons.bolt_rounded,
              label: '+${result.xp} XP',
              color: LigaColors.achievementYellow,
            ),
          ),
        ],
      ],
    ];
  }
}

/// Área da foto: cantoneiras de câmera e, depois de escolher, a própria foto.
class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.photo, required this.loading});

  final Uint8List? photo;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      padding: const EdgeInsets.all(12),
      borderColor: LigaColors.progressGreen.withValues(alpha: 0.6),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFEFFBF3)),
            child: CustomPaint(
              foregroundPainter: _ViewfinderPainter(),
              child: photo != null
                  ? Opacity(
                      opacity: loading ? 0.6 : 1,
                      child: Image.memory(photo!, fit: BoxFit.cover),
                    )
                  : const Center(
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
    );
  }
}

class _ThinkingCard extends StatelessWidget {
  const _ThinkingCard();

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      borderColor: LigaColors.sunsetOrange.withValues(alpha: 0.5),
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'A Liga está lendo sua lição...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBubble extends StatelessWidget {
  const _StepBubble({required this.number, required this.step});

  final int number;
  final ExplanationStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: LigaColors.achievementYellow,
              border: Border.all(color: LigaColors.ink, width: 3),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: LigaColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LigaPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.title.isNotEmpty)
                    Text(step.title, style: textTheme.titleMedium),
                  if (step.title.isNotEmpty) const SizedBox(height: 4),
                  Text(step.explanation, style: textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
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
