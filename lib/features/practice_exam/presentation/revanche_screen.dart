import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/design_system/liga_report_button.dart';
import '../../../shared/models/practice_exam.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';

LigaCharacter _heroFor(String id) {
  return LigaCharacter.values.firstWhere(
    (c) => c.id == id,
    orElse: () => LigaCharacter.zuri,
  );
}

/// Revanche da prova: as provas e tarefas que o responsável enviou viram
/// missões. Quem acerta todas as questões vence a revanche.
class RevancheScreen extends StatefulWidget {
  const RevancheScreen({super.key});

  static const routeName = '/revanche';

  @override
  State<RevancheScreen> createState() => _RevancheScreenState();
}

class _RevancheScreenState extends State<RevancheScreen> {
  List<PracticeExamSummary>? _exams;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final exams = await AppRepository.instance.loadPracticeExams();
      if (mounted) setState(() => _exams = exams);
    } on AppRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _play(PracticeExamSummary exam) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RevancheBattleScreen(exam: exam)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final exams = _exams;
    final open = exams?.where((e) => !e.won).toList() ?? const [];
    final won = exams?.where((e) => e.won).toList() ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Revanche da prova')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Revanche da prova',
                  subtitle: 'Treine o que caiu na escola e vire o jogo!',
                  color: LigaColors.sunsetOrange,
                  character: LigaCharacter.zuri,
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                LigaErrorCard(message: _error!)
              else if (exams == null)
                const Center(child: CircularProgressIndicator())
              else if (exams.isEmpty)
                LigaPanel(
                  key: const Key('revancheEmpty'),
                  child: Row(
                    children: [
                      const LigaPortrait(
                        character: LigaCharacter.zuri,
                        size: 64,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ainda não tem prova para treinar. Peça para um '
                          'adulto fotografar uma prova ou tarefa na Área dos '
                          'responsáveis!',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (open.isNotEmpty)
                  const SectionTitle(
                    'Revanches abertas',
                    icon: Icons.sports_martial_arts_rounded,
                  ),
                for (final exam in open) ...[
                  _ExamMissionCard(exam: exam, onTap: () => _play(exam)),
                  const SizedBox(height: 12),
                ],
                if (won.isNotEmpty)
                  const SectionTitle(
                    'Revanches vencidas',
                    icon: Icons.emoji_events_rounded,
                  ),
                for (final exam in won) ...[
                  _ExamMissionCard(exam: exam, onTap: () => _play(exam)),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamMissionCard extends StatelessWidget {
  const _ExamMissionCard({required this.exam, required this.onTap});

  final PracticeExamSummary exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hero = _heroFor(exam.characterId);
    final textTheme = Theme.of(context).textTheme;
    return LigaPressable(
      onTap: onTap,
      child: LigaPanel(
        borderColor: hero.color,
        child: Row(
          children: [
            LigaPortrait(character: hero, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.title, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    exam.topics.isEmpty
                        ? exam.kind.label
                        : exam.topics.take(3).join(' · '),
                    style: textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (exam.won)
                    _Stars(count: exam.stars, size: 24)
                  else ...[
                    LigaProgressBar(
                      value: exam.progress,
                      color: hero.color,
                      height: 12,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exam.solvedQuestions}/${exam.totalQuestions} questões',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded, size: 40),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.count, this.size = 36});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i < count
                ? LigaColors.achievementYellow
                : LigaColors.disabled,
            shadows: ligaOutline(1.4),
          ),
      ],
    );
  }
}

/// Uma questão por vez. Errar uma vez mostra a dica; errar de novo faz o
/// herói explicar, e a questão volta no fim da fila (sem XP) até a criança
/// acertar. Só vence quem acerta todas.
class RevancheBattleScreen extends StatefulWidget {
  const RevancheBattleScreen({super.key, required this.exam});

  final PracticeExamSummary exam;

  @override
  State<RevancheBattleScreen> createState() => _RevancheBattleScreenState();
}

class _RevancheBattleScreenState extends State<RevancheBattleScreen> {
  /// Questões que faltam acertar, na ordem em que vão aparecer.
  final _queue = <PracticeQuestion>[];
  int _total = 0;
  int _solved = 0;
  bool _won = false;
  int _stars = 0;

  final _wrong = <int>{};
  int? _right;
  String _tip = '';
  List<String> _explanation = const [];
  bool _explained = false;
  ProgressUpdate? _progress;
  bool _loading = true;
  String? _error;

  LigaCharacter get _hero => _heroFor(widget.exam.characterId);

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final round = await AppRepository.instance.openPracticeExam(
        widget.exam.id,
      );
      if (!mounted) return;
      setState(() {
        _total = round.questions.length;
        _solved = round.questions.where((q) => q.solved).length;
        _won = round.won;
        _stars = widget.exam.stars;
        // As que já foram explicadas ficam por último.
        _queue
          ..addAll(round.questions.where((q) => !q.solved && !q.explained))
          ..addAll(round.questions.where((q) => !q.solved && q.explained));
      });
    } on AppRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _answer(int option) async {
    final question = _queue.first;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AppRepository.instance.answerPracticeQuestion(
        widget.exam.id,
        question.id,
        option,
      );
      if (!mounted) return;
      setState(() {
        _solved = result.solvedQuestions;
        if (result.progress != null) _progress = result.progress;
        if (result.hit) {
          _right = option;
          _explanation = result.explanation;
          if (result.won) {
            _won = true;
            _stars = result.stars;
          }
        } else {
          _wrong.add(option);
          _tip = result.tip;
          if (result.explained) {
            _explained = true;
            _right = result.correct;
            _explanation = result.explanation;
          }
        }
      });
    } on AppRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    setState(() {
      final current = _queue.removeAt(0);
      // Depois da explicação, a questão volta no fim da fila.
      if (_explained) {
        _queue.add(
          PracticeQuestion(
            id: current.id,
            topic: current.topic,
            statement: current.statement,
            options: current.options,
            fromExam: current.fromExam,
            missedInExam: current.missedInExam,
            attempts: current.attempts + 2,
            explained: true,
          ),
        );
      }
      _wrong.clear();
      _right = null;
      _tip = '';
      _explanation = const [];
      _explained = false;
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hero = _hero;
    final textTheme = Theme.of(context).textTheme;
    final question = _queue.isEmpty ? null : _queue.first;
    final hit = _right != null && !_explained;
    final answered = hit || _explained;
    final finished = _won && (question == null || hit);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title),
        actions: [
          LigaReportAiButton(
            module: 'revanche',
            reference: () => widget.exam.id,
          ),
        ],
      ),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  LigaPortrait(character: hero, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigaProgressBar(
                          value: _total == 0 ? 0 : _solved / _total,
                          color: hero.color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_solved de $_total acertadas',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            shadows: ligaOutline(1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (finished)
                PopIn(
                  child: LigaPanel(
                    key: const Key('revancheWon'),
                    borderColor: LigaColors.achievementYellow,
                    color: const Color(0xFFFFF7DD),
                    child: Column(
                      children: [
                        Text(
                          'Revanche vencida!',
                          style: textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        _Stars(count: _stars),
                        const SizedBox(height: 8),
                        Text(
                          'Você acertou todas as questões. Agora esse '
                          'conteúdo é seu!',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else if (question != null)
                PopIn(
                  key: ValueKey('${question.id}-${question.explained}'),
                  child: LigaPanel(
                    borderColor: hero.color,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (question.topic.isNotEmpty)
                              LigaPill(
                                icon: Icons.bookmark_rounded,
                                label: question.topic,
                                color: hero.color,
                              ),
                            if (question.missedInExam)
                              const LigaPill(
                                icon: Icons.replay_rounded,
                                label: 'Revanche!',
                                color: LigaColors.actionCoral,
                              )
                            else if (question.fromExam)
                              const LigaPill(
                                icon: Icons.description_rounded,
                                label: 'Caiu na prova',
                                color: LigaColors.primaryBlue,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(question.statement, style: textTheme.bodyLarge),
                        const SizedBox(height: 14),
                        for (var o = 0; o < question.options.length; o++)
                          LigaChoiceButton(
                            label: question.options[o],
                            state: _right == o
                                ? LigaChoiceState.right
                                : _wrong.contains(o)
                                ? LigaChoiceState.wrong
                                : LigaChoiceState.idle,
                            onTap: answered || _loading || _wrong.contains(o)
                                ? null
                                : () => _answer(o),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_tip.isNotEmpty && !answered) ...[
                const SizedBox(height: 14),
                PopIn(
                  child: Row(
                    children: [
                      LigaPortrait(character: hero, size: 48),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LigaSpeechBubble(
                          text: 'Quase! $_tip',
                          color: hero.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (answered && _explanation.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  hit
                      ? 'Acertou! Veja o raciocínio:'
                      : '${hero.displayName} explica:',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    shadows: ligaOutline(1.4),
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _explanation.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: 90 * i),
                    child: LigaStepBubble(number: i + 1, text: _explanation[i]),
                  ),
              ],
              if (_loading && question != null) ...[
                const SizedBox(height: 14),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaErrorCard(message: _error!)),
              ],
              if (_progress != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaRewardCard(progress: _progress!)),
              ],
              const SizedBox(height: 18),
              if (finished)
                LigaActionButton(
                  label: 'Voltar às revanches',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                )
              else if (answered)
                LigaActionButton(
                  label: _explained
                      ? 'Entendi! Essa volta no fim'
                      : 'Próxima questão',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
