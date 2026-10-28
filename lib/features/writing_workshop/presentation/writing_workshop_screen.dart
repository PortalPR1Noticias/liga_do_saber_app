import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/design_system/liga_report_button.dart';
import '../../../shared/design_system/liga_voice.dart';
import '../../../shared/models/writing_feedback.dart';
import '../../../shared/models/minigame.dart';
import '../../../shared/services/app_repository.dart';
import '../../minigames/presentation/minigame_style.dart';

/// Oficina de Texto: planejar, escrever, receber o feedback da Luma (IA) e
/// reescrever. A reescrita vale XP pela evolução, não só pelo acerto.
class WritingWorkshopScreen extends StatefulWidget {
  const WritingWorkshopScreen({super.key});

  static const routeName = '/writing';

  static const themes = [
    'Um dia na Liga do Saber',
    'O animal mais curioso que conheço',
    'Se eu pudesse inventar uma máquina',
    'Uma aventura no parque',
    'Meu lugar favorito',
    'O dia em que choveu doce',
  ];

  @override
  State<WritingWorkshopScreen> createState() => _WritingWorkshopScreenState();
}

class _WritingWorkshopScreenState extends State<WritingWorkshopScreen> {
  String _theme = WritingWorkshopScreen.themes.first;
  final _start = TextEditingController();
  final _middle = TextEditingController();
  final _end = TextEditingController();
  final _text = TextEditingController();
  final _rewrite = TextEditingController();

  WritingFeedback? _feedback;
  RewriteFeedback? _rewriteFeedback;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_start, _middle, _end, _text, _rewrite]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on AppRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendFirstVersion() async {
    if (_text.text.trim().isEmpty) {
      setState(() => _error = 'Escreva o seu texto antes de enviar.');
      return;
    }
    await _run(() async {
      final feedback = await AppRepository.instance.requestWritingFeedback(
        theme: _theme,
        plan: WritingPlan(
          start: _start.text.trim(),
          middle: _middle.text.trim(),
          end: _end.text.trim(),
        ),
        text: _text.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _feedback = feedback;
        _rewrite.text = _text.text.trim();
      });
    });
  }

  Future<void> _sendRewrite() => _run(() async {
    final result = await AppRepository.instance.submitRewrite(
      productionId: _feedback!.productionId,
      text: _rewrite.text.trim(),
    );
    if (mounted) setState(() => _rewriteFeedback = result);
  });

  void _restart() {
    for (final c in [_start, _middle, _end, _text, _rewrite]) {
      c.clear();
    }
    setState(() {
      _feedback = null;
      _rewriteFeedback = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    final rewriteFeedback = _rewriteFeedback;
    final canRewrite = feedback != null && feedback.appropriate;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oficina de Texto'),
        actions: [
          LigaReportAiButton(
            module: 'texto',
            reference: () => _feedback?.productionId,
          ),
        ],
      ),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Oficina de Texto',
                  subtitle:
                      'Luma ajuda a planejar, escrever, revisar e reescrever.',
                  color: LigaColors.actionCoral,
                  character: LigaCharacter.luma,
                ),
              ),
              const SizedBox(height: 20),
              if (feedback == null || !feedback.appropriate) ...[
                _Step(
                  number: 1,
                  title: 'Escolha o tema',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final theme in WritingWorkshopScreen.themes)
                        ChoiceChip(
                          label: Text(theme),
                          selected: _theme == theme,
                          onSelected: (_) => setState(() => _theme = theme),
                        ),
                    ],
                  ),
                ),
                _Step(
                  number: 2,
                  title: 'Planeje as ideias',
                  child: Column(
                    children: [
                      _Field(controller: _start, label: 'Começo: como começa?'),
                      _Field(
                        controller: _middle,
                        label: 'Meio: o que acontece?',
                      ),
                      _Field(controller: _end, label: 'Final: como termina?'),
                    ],
                  ),
                ),
                _Step(
                  number: 3,
                  title: 'Escreva a versão 1',
                  child: _Field(
                    controller: _text,
                    label: 'Seu texto',
                    minLines: 6,
                  ),
                ),
              ],
              if (feedback != null) ...[
                PopIn(child: _FeedbackCard(feedback: feedback)),
                const SizedBox(height: 14),
                if (feedback.progress != null) ...[
                  PopIn(child: LigaRewardCard(progress: feedback.progress!)),
                  const SizedBox(height: 14),
                ],
              ],
              if (canRewrite && rewriteFeedback == null)
                _Step(
                  number: 4,
                  title: 'Reescreva melhor',
                  child: _Field(
                    controller: _rewrite,
                    label: 'Seu texto melhorado',
                    minLines: 6,
                  ),
                ),
              if (rewriteFeedback != null) ...[
                PopIn(child: _RewriteCard(feedback: rewriteFeedback)),
                const SizedBox(height: 14),
                if (rewriteFeedback.progress != null) ...[
                  PopIn(
                    child: LigaRewardCard(progress: rewriteFeedback.progress!),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
              if (_loading) ...[
                const LigaThinkingCard(text: 'A Luma está lendo seu texto...'),
                const SizedBox(height: 14),
              ],
              if (_error != null) ...[
                PopIn(child: LigaErrorCard(message: _error!)),
                const SizedBox(height: 14),
              ],
              if (!canRewrite)
                LigaActionButton(
                  label: 'Receber feedback da Luma',
                  icon: Icons.auto_awesome_rounded,
                  color: LigaColors.actionCoral,
                  onPressed: _loading ? null : _sendFirstVersion,
                )
              else if (rewriteFeedback == null)
                LigaActionButton(
                  label: 'Enviar reescrita',
                  icon: Icons.edit_note_rounded,
                  color: LigaColors.actionCoral,
                  onPressed: _loading ? null : _sendRewrite,
                )
              else
                LigaActionButton(
                  label: 'Escrever um texto novo',
                  icon: Icons.add_rounded,
                  onPressed: _restart,
                ),
              const MinigameShortcuts(subject: MinigameSubject.portugues),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.child});

  final int number;
  final String title;
  final Widget child;

  static const _colors = [
    LigaColors.actionCoral,
    LigaColors.sunsetOrange,
    LigaColors.adventurePurple,
    LigaColors.progressGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[(number - 1) % _colors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LigaPanel(
        borderColor: color.withValues(alpha: 0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color,
                    border: Border.all(color: LigaColors.ink, width: 3),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: LigaTheme.displayFont,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      shadows: ligaOutline(1.4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 2 : 14,
        maxLength: minLines == 1 ? 300 : 3000,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, counterText: ''),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var s = 0; s < 3; s++)
          Icon(
            Icons.star_rounded,
            size: 22,
            color: s < count
                ? LigaColors.achievementYellow
                : LigaColors.disabled,
          ),
      ],
    );
  }
}

class _CriteriaList extends StatelessWidget {
  const _CriteriaList(this.criteria);

  final List<WritingCriterion> criteria;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final c in criteria)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.label, style: textTheme.titleMedium),
                    ),
                    _Stars(c.stars),
                  ],
                ),
                if (c.comment.isNotEmpty)
                  Text(c.comment, style: textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({
    required this.title,
    required this.items,
    required this.icon,
  });

  final String title;
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: LigaColors.actionCoral),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: textTheme.bodyLarge)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final WritingFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      borderColor: LigaColors.actionCoral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LigaMascot(character: LigaCharacter.luma, size: 56),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Feedback da Luma',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LigaHeroVoice(
            character: LigaCharacter.luma,
            label: 'Ouvir a Luma',
            lines: [
              ...feedback.strengths,
              ...feedback.suggestions,
              feedback.message,
            ],
          ),
          _CriteriaList(feedback.criteria),
          _Bullets(
            title: 'Pontos fortes',
            items: feedback.strengths,
            icon: Icons.thumb_up_alt_rounded,
          ),
          _Bullets(
            title: 'Para a reescrita',
            items: feedback.suggestions,
            icon: Icons.tips_and_updates_rounded,
          ),
          if (feedback.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            LigaSpeechBubble(text: feedback.message),
          ],
        ],
      ),
    );
  }
}

class _RewriteCard extends StatelessWidget {
  const _RewriteCard({required this.feedback});

  final RewriteFeedback feedback;

  static const _evolution = [
    'Ainda dá para melhorar',
    'Melhorou um pouco',
    'Melhorou bem',
    'Melhorou muito!',
  ];

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      borderColor: LigaColors.progressGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LigaPill(
            icon: Icons.trending_up_rounded,
            label: _evolution[feedback.evolution.clamp(0, 3)],
            color: LigaColors.progressGreen,
          ),
          const SizedBox(height: 12),
          LigaHeroVoice(
            character: LigaCharacter.luma,
            label: 'Ouvir a Luma',
            lines: [
              ...feedback.improvements,
              feedback.nextStep,
              feedback.message,
            ],
          ),
          _CriteriaList(feedback.criteria),
          _Bullets(
            title: 'O que melhorou',
            items: feedback.improvements,
            icon: Icons.check_circle_rounded,
          ),
          _Bullets(
            title: 'Próximo passo',
            items: [if (feedback.nextStep.isNotEmpty) feedback.nextStep],
            icon: Icons.flag_rounded,
          ),
          if (feedback.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            LigaSpeechBubble(text: feedback.message),
          ],
        ],
      ),
    );
  }
}
