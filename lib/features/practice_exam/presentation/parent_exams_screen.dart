import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/practice_exam.dart';
import '../../../shared/services/app_repository.dart';
import '../../photo_solver/presentation/photo_solver_flow_screen.dart';

/// Escolhe várias fotos da galeria de uma vez (até `limit`).
typedef GalleryPicker = Future<List<Uint8List>> Function(int limit);

/// Escolhe um PDF do aparelho.
typedef PdfPicker = Future<PracticeExamPdf?> Function();

Future<List<Uint8List>> pickGalleryWithImagePicker(int limit) async {
  // Mesmo tamanho da Foto + IA: a letra da prova continua legível.
  final files = await ImagePicker().pickMultiImage(
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
    limit: limit < 2 ? null : limit,
  );
  return [for (final file in files.take(limit)) await file.readAsBytes()];
}

Future<PracticeExamPdf?> pickPdfWithFilePicker() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (file == null) return null;
  return PracticeExamPdf(name: file.name, bytes: await file.readAsBytes());
}

/// Área dos responsáveis > Provas e tarefas para treinar. O adulto manda
/// fotos ou o PDF de uma prova ou tarefa que a criança já fez; a IA cria as
/// questões da Revanche da prova (Edge Function `revanche-prova`).
class ParentExamsScreen extends StatefulWidget {
  const ParentExamsScreen({
    super.key,
    this.pickPhoto = pickPhotoWithImagePicker,
    this.pickGallery = pickGalleryWithImagePicker,
    this.pickPdf = pickPdfWithFilePicker,
  });

  /// Uma prova costuma ter mais de uma folha.
  static const maxPhotos = 10;

  /// O servidor aceita PDF de até 6 MB e 10 páginas.
  static const maxPdfBytes = 6 * 1024 * 1024;

  final PhotoPicker pickPhoto;
  final GalleryPicker pickGallery;
  final PdfPicker pickPdf;

  @override
  State<ParentExamsScreen> createState() => _ParentExamsScreenState();
}

class _ParentExamsScreenState extends State<ParentExamsScreen> {
  final _photos = <Uint8List>[];
  PracticeExamPdf? _pdf;
  final _note = TextEditingController();
  PracticeExamKind _kind = PracticeExamKind.prova;
  List<PracticeExamSummary> _exams = const [];
  PracticeExamSummary? _justSent;
  bool _loading = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final exams = await AppRepository.instance.loadPracticeExams();
      if (mounted) setState(() => _exams = exams);
    } on AppRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    final free = ParentExamsScreen.maxPhotos - _photos.length;
    final List<Uint8List> photos;
    try {
      if (source == ImageSource.camera) {
        final photo = await widget.pickPhoto(source);
        photos = [?photo];
      } else {
        photos = await widget.pickGallery(free);
      }
    } on Exception {
      setState(() {
        _error = source == ImageSource.camera
            ? 'Não consegui abrir a câmera. Confira a permissão do app.'
            : 'Não consegui abrir a galeria. Confira a permissão do app.';
      });
      return;
    }
    if (photos.isEmpty || !mounted) return;
    setState(() {
      _photos.addAll(photos.take(free));
      _error = photos.length > free
          ? 'Cabem só ${ParentExamsScreen.maxPhotos} fotos por envio. '
                'Fiquei com as primeiras.'
          : null;
    });
  }

  Future<void> _addPdf() async {
    final PracticeExamPdf? pdf;
    try {
      pdf = await widget.pickPdf();
    } on Exception {
      setState(() {
        _error = 'Não consegui abrir os arquivos. Confira a permissão do app.';
      });
      return;
    }
    if (pdf == null || !mounted) return;
    final isPdf =
        pdf.bytes.length > 4 &&
        String.fromCharCodes(pdf.bytes.sublist(0, 5)) == '%PDF-';
    setState(() {
      if (!isPdf) {
        _error = 'Esse arquivo não é um PDF.';
      } else if (pdf!.bytes.length > ParentExamsScreen.maxPdfBytes) {
        _error =
            'O PDF passou de 6 MB. Mande só as páginas da prova ou '
            'fotografe as folhas.';
      } else {
        _pdf = pdf;
        _error = null;
      }
    });
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
      _justSent = null;
    });
    try {
      final exam = await AppRepository.instance.uploadPracticeExam(
        photos: List.of(_photos),
        pdf: _pdf,
        kind: _kind,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _justSent = exam;
        _exams = [exam, ..._exams];
        _photos.clear();
        _pdf = null;
        _note.clear();
      });
    } on AppRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(PracticeExamSummary exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar o treino?'),
        content: Text(
          'A criança perde as questões de "${exam.title}". '
          'O XP que ela já ganhou continua.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LigaColors.actionCoral,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppRepository.instance.deletePracticeExam(exam.id);
      if (!mounted) return;
      setState(() {
        _exams = [
          for (final e in _exams)
            if (e.id != exam.id) e,
        ];
        if (_justSent?.id == exam.id) _justSent = null;
      });
    } on AppRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final consent = AppRepository.instance.responsible.aiConsent;
    final canAdd = !_sending && _photos.length < ParentExamsScreen.maxPhotos;

    return Scaffold(
      appBar: AppBar(title: const Text('Provas para treinar')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              LigaPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revanche da prova', style: textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Fotografe (até ${ParentExamsScreen.maxPhotos} fotos) ou '
                      'mande o PDF de uma prova ou tarefa que já voltou da '
                      'escola (de preferência corrigida). A IA monta questões de '
                      'treino iguais e parecidas, começando pelas que a '
                      'criança errou, e elas viram uma missão no app.',
                      style: textTheme.bodyMedium,
                    ),
                    if (!consent) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Para enviar, ligue antes a autorização de IA na '
                        'Área dos responsáveis: as fotos e o PDF vão para a '
                        'OpenAI (EUA) só para criar o treino e não ficam '
                        'guardados.',
                        key: const Key('practiceNoConsent'),
                        style: textTheme.bodyMedium?.copyWith(
                          color: LigaColors.shade(LigaColors.actionCoral, 0.1),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LigaPanel(
                borderColor: LigaColors.sunsetOrange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<PracticeExamKind>(
                      segments: [
                        for (final kind in PracticeExamKind.values)
                          ButtonSegment(value: kind, label: Text(kind.label)),
                      ],
                      selected: {_kind},
                      onSelectionChanged: _sending
                          ? null
                          : (value) => setState(() => _kind = value.first),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Fotos (${_photos.length} de '
                      '${ParentExamsScreen.maxPhotos})',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _photos.length; i++)
                          _Thumb(
                            photo: _photos[i],
                            onRemove: _sending
                                ? null
                                : () => setState(() => _photos.removeAt(i)),
                          ),
                      ],
                    ),
                    if (_photos.isNotEmpty) const SizedBox(height: 10),
                    if (_pdf != null) ...[
                      _PdfChip(
                        pdf: _pdf!,
                        onRemove: _sending
                            ? null
                            : () => setState(() => _pdf = null),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('practiceCamera'),
                            onPressed: canAdd
                                ? () => _addPhoto(ImageSource.camera)
                                : null,
                            icon: const Icon(Icons.photo_camera_rounded),
                            label: const Text('Câmera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('practiceGallery'),
                            onPressed: canAdd
                                ? () => _addPhoto(ImageSource.gallery)
                                : null,
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Galeria'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('practicePdf'),
                      onPressed: _sending ? null : _addPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(_pdf == null ? 'Anexar PDF' : 'Trocar o PDF'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Um PDF por envio, de até 10 páginas e 6 MB.',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('practiceNote'),
                      controller: _note,
                      enabled: !_sending,
                      maxLength: 300,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Recado para a IA (opcional)',
                        hintText: 'Ex.: ela teve dificuldade na questão 3',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LigaActionButton(
                key: const Key('practiceSend'),
                label: 'Criar treino',
                icon: Icons.auto_awesome_rounded,
                color: LigaColors.sunsetOrange,
                onPressed:
                    _sending || (_photos.isEmpty && _pdf == null) || !consent
                    ? null
                    : _send,
              ),
              if (_sending) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(
                  text: 'Lendo a prova e montando o treino...',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaErrorCard(message: _error!)),
              ],
              if (_justSent != null) ...[
                const SizedBox(height: 14),
                PopIn(
                  child: LigaPanel(
                    borderColor: LigaColors.progressGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Treino pronto: ${_justSent!.title}',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_justSent!.totalQuestions} questões. A missão '
                          'já aparece para a criança em Missões > Revanche '
                          'da prova.',
                          style: textTheme.bodyMedium,
                        ),
                        if (_justSent!.parentNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _justSent!.parentNote,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const SectionTitle('Já enviadas', icon: Icons.history_rounded),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_exams.isEmpty)
                LigaPanel(
                  child: Text(
                    'Nenhuma prova enviada ainda.',
                    style: textTheme.bodyMedium,
                  ),
                )
              else
                for (final exam in _exams) ...[
                  _SentExamCard(exam: exam, onDelete: () => _delete(exam)),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.onRemove});

  final Uint8List photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LigaColors.ink, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            photo,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.description_rounded, size: 36),
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: IconButton.filled(
            tooltip: 'Remover foto',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: LigaColors.actionCoral,
            ),
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}

class _PdfChip extends StatelessWidget {
  const _PdfChip({required this.pdf, required this.onRemove});

  final PracticeExamPdf pdf;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final size = pdf.bytes.length / (1024 * 1024);
    return Container(
      key: const Key('practicePdfChip'),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LigaColors.ink, width: 3),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: LigaColors.actionCoral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${pdf.name} (${size.toStringAsFixed(1)} MB)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Remover PDF',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SentExamCard extends StatelessWidget {
  const _SentExamCard({required this.exam, required this.onDelete});

  final PracticeExamSummary exam;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = exam.createdAt.toLocal();
    final day =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
    return LigaPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${exam.title} · ${exam.kind.label} de $day',
                  style: textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Apagar',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LigaProgressBar(value: exam.progress, height: 12),
                const SizedBox(height: 6),
                Text(
                  exam.won
                      ? 'Revanche vencida com ${exam.stars} '
                            '${exam.stars == 1 ? 'estrela' : 'estrelas'}.'
                      : '${exam.solvedQuestions} de ${exam.totalQuestions} '
                            'questões acertadas.',
                  style: textTheme.bodyMedium,
                ),
                if (exam.parentNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(exam.parentNote, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
