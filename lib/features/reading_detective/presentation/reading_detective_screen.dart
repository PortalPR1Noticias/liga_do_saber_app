import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/design_system/liga_report_button.dart';
import '../../../shared/models/reading_case.dart';
import '../../../shared/models/minigame.dart';
import '../../../shared/services/app_repository.dart';
import '../../minigames/presentation/minigame_style.dart';

/// Detetive da Leitura: a Luma (IA) cria um texto curto com três perguntas
/// de interpretação; a criança responde e vê a pista de cada resposta.
class ReadingDetectiveScreen extends StatefulWidget {
  const ReadingDetectiveScreen({super.key});

  static const routeName = '/reading';

  @override
  State<ReadingDetectiveScreen> createState() => _ReadingDetectiveScreenState();
}

class _ReadingDetectiveScreenState extends State<ReadingDetectiveScreen> {
  ReadingCase? _case;
  List<int?> _answers = const [];
  ReadingCaseResult? _result;
  bool _loading = false;
  String? _loadingText;
  String? _error;
  int _caseNumber = 0;

  Future<void> _run(String loadingText, Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _loadingText = loadingText;
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

  Future<void> _openCase() =>
      _run('A Luma está escrevendo o caso...', () async {
        final newCase = await AppRepository.instance.newReadingCase();
        if (!mounted) return;
        setState(() {
          _case = newCase;
          _answers = List<int?>.filled(newCase.questions.length, null);
          _result = null;
          _caseNumber++;
        });
      });

  Future<void> _submit() => _run('Conferindo as pistas...', () async {
    final result = await AppRepository.instance.answerReadingCase(_case!.id, [
      for (final a in _answers) a ?? -1,
    ]);
    if (mounted) setState(() => _result = result);
  });

  @override
  Widget build(BuildContext context) {
    final currentCase = _case;
    final result = _result;
    final allAnswered = _answers.isNotEmpty && !_answers.contains(null);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detetive da Leitura'),
        actions: [
          LigaReportAiButton(module: 'leitura', reference: () => _case?.id),
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
                  title: 'Detetive da Leitura',
                  subtitle: 'Cada pergunta precisa de uma pista no texto.',
                  color: LigaColors.actionCoral,
                  character: LigaCharacter.luma,
                ),
              ),
              const SizedBox(height: 20),
              if (currentCase == null && !_loading)
                PopIn(
                  delay: const Duration(milliseconds: 120),
                  child: LigaPanel(
                    borderColor: LigaColors.actionCoral.withValues(alpha: 0.5),
                    child: Text(
                      'A Luma escreve um caso novo só para você: leia o '
                      'texto, encontre as pistas e responda às perguntas. '
                      'Cada acerto vale 10 XP!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              if (currentCase != null) ...[
                PopIn(
                  child: _CaseText(number: _caseNumber, data: currentCase),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < currentCase.questions.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: 80 * i),
                    child: _QuestionCard(
                      number: i + 1,
                      question: currentCase.questions[i],
                      chosen: _answers[i],
                      feedback: result?.answers.elementAtOrNull(i),
                      onChoose: result != null || _loading
                          ? null
                          : (option) => setState(() => _answers[i] = option),
                    ),
                  ),
              ],
              if (_loading) ...[
                const SizedBox(height: 4),
                LigaThinkingCard(text: _loadingText ?? ''),
                const SizedBox(height: 14),
              ],
              if (_error != null) ...[
                PopIn(child: LigaErrorCard(message: _error!)),
                const SizedBox(height: 14),
              ],
              if (result != null) ...[
                LigaSpeechBubble(
                  text: result.hits == result.total
                      ? 'Caso resolvido! Você achou todas as pistas!'
                      : 'Você acertou ${result.hits} de ${result.total}. '
                            'Veja as pistas e tente o próximo caso!',
                ),
                const SizedBox(height: 14),
                if (result.progress != null) ...[
                  PopIn(child: LigaRewardCard(progress: result.progress!)),
                  const SizedBox(height: 14),
                ],
              ],
              if (currentCase != null && result == null && !_loading)
                LigaActionButton(
                  label: 'Enviar respostas',
                  icon: Icons.task_alt_rounded,
                  color: LigaColors.actionCoral,
                  onPressed: allAnswered ? _submit : null,
                ),
              if (currentCase == null || result != null || _error != null) ...[
                const SizedBox(height: 12),
                LigaActionButton(
                  label: currentCase == null ? 'Abrir um caso' : 'Novo caso',
                  icon: Icons.folder_open_rounded,
                  onPressed: _loading ? null : _openCase,
                ),
              ],
              const MinigameShortcuts(subject: MinigameSubject.portugues),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseText extends StatelessWidget {
  const _CaseText({required this.number, required this.data});

  final int number;
  final ReadingCase data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LigaPanel(
      borderColor: LigaColors.actionCoral.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LigaPill(
            icon: Icons.folder_open_rounded,
            label: 'Caso nº $number',
            color: LigaColors.actionCoral,
          ),
          const SizedBox(height: 10),
          Text(data.title, style: textTheme.titleLarge),
          if (data.intro.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data.intro,
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(data.text, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.chosen,
    required this.feedback,
    required this.onChoose,
  });

  final int number;
  final ReadingQuestion question;
  final int? chosen;
  final ReadingAnswerFeedback? feedback;
  final ValueChanged<int>? onChoose;

  LigaChoiceState _stateOf(int option) {
    final f = feedback;
    if (f == null) {
      return option == chosen ? LigaChoiceState.selected : LigaChoiceState.idle;
    }
    if (option == f.correct) return LigaChoiceState.right;
    if (option == f.chosen) return LigaChoiceState.wrong;
    return LigaChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final f = feedback;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LigaPanel(
        borderColor: LigaColors.adventurePurple.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LigaPill(
              icon: Icons.search_rounded,
              label: 'Pergunta $number · ${question.skillLabel}',
              color: LigaColors.adventurePurple,
            ),
            const SizedBox(height: 10),
            Text(question.question, style: textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var o = 0; o < question.options.length; o++)
              LigaChoiceButton(
                label: question.options[o],
                state: _stateOf(o),
                color: LigaColors.adventurePurple,
                onTap: onChoose == null ? null : () => onChoose!(o),
              ),
            if (f != null) ...[
              const SizedBox(height: 4),
              Text(
                f.hit ? 'Acertou!' : 'Quase! Olhe a pista:',
                style: textTheme.titleMedium?.copyWith(
                  color: LigaColors.shade(
                    f.hit ? LigaColors.progressGreen : LigaColors.actionCoral,
                    0.12,
                  ),
                ),
              ),
              if (f.clue.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('🔎 "${f.clue}"', style: textTheme.bodyLarge),
              ],
              if (f.explanation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(f.explanation, style: textTheme.bodyMedium),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
