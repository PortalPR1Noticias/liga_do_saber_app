import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/design_system/liga_report_button.dart';
import '../../../shared/models/math_challenge.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';
import '../../../shared/models/minigame.dart';
import '../../minigames/presentation/minigame_style.dart';

/// Arena Matemática: o Nico (IA) cria desafios do ano escolar da criança.
/// Acertar de primeira vale 20 XP; depois de errar, 10; depois de ver o
/// passo a passo, não vale XP.
class MathArenaScreen extends StatefulWidget {
  const MathArenaScreen({super.key});

  static const routeName = '/math';

  @override
  State<MathArenaScreen> createState() => _MathArenaScreenState();
}

class _MathArenaScreenState extends State<MathArenaScreen> {
  MathTopic _topic = MathTopic.operacoes;
  MathChallenge? _challenge;
  final _wrong = <int>{};
  int? _right;
  String _tip = '';
  List<String> _steps = const [];
  ProgressUpdate? _progress;
  bool _loading = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
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

  Future<void> _newChallenge() => _run(() async {
    final challenge = await AppRepository.instance.newMathChallenge(_topic);
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _wrong.clear();
      _right = null;
      _tip = '';
      _steps = const [];
      _progress = null;
    });
  });

  Future<void> _answer(int option) => _run(() async {
    final result = await AppRepository.instance.answerMathChallenge(
      _challenge!.id,
      option,
    );
    if (!mounted) return;
    setState(() {
      if (result.hit) {
        _right = option;
        _steps = result.steps;
        _progress = result.progress;
      } else {
        _wrong.add(option);
        _tip = result.tip;
      }
    });
  });

  Future<void> _showSteps() => _run(() async {
    final solution = await AppRepository.instance.revealMathSolution(
      _challenge!.id,
    );
    if (mounted) setState(() => _steps = solution.steps);
  });

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    final solved = _right != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arena Matemática'),
        actions: [
          LigaReportAiButton(
            module: 'matematica',
            reference: () => _challenge?.id,
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
                  title: 'Arena Matemática',
                  subtitle: 'Desafios rápidos com explicação passo a passo.',
                  color: LigaColors.primaryBlue,
                  character: LigaCharacter.nico,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final topic in MathTopic.values)
                    ChoiceChip(
                      label: Text(topic.label),
                      selected: _topic == topic,
                      onSelected: _loading
                          ? null
                          : (_) => setState(() => _topic = topic),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (challenge != null)
                PopIn(
                  child: LigaPanel(
                    borderColor: LigaColors.primaryBlue.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigaPill(
                          icon: Icons.bolt_rounded,
                          label: 'Desafio do Nico · +${challenge.xp} XP',
                          color: LigaColors.primaryBlue,
                        ),
                        const SizedBox(height: 10),
                        if (challenge.title.isNotEmpty) ...[
                          Text(
                            challenge.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          challenge.statement,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        for (var o = 0; o < challenge.options.length; o++)
                          LigaChoiceButton(
                            label: challenge.options[o],
                            state: _right == o
                                ? LigaChoiceState.right
                                : _wrong.contains(o)
                                ? LigaChoiceState.wrong
                                : LigaChoiceState.idle,
                            onTap: solved || _loading || _wrong.contains(o)
                                ? null
                                : () => _answer(o),
                          ),
                        if (solved || _wrong.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              solved
                                  ? 'Acertou! Mandou bem!'
                                  : 'Quase! ${_tip.isEmpty ? 'Tente de novo ou veja o passo a passo.' : _tip}',
                              style: TextStyle(
                                color: LigaColors.shade(
                                  solved
                                      ? LigaColors.progressGreen
                                      : LigaColors.actionCoral,
                                  0.12,
                                ),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else if (!_loading)
                LigaPanel(
                  borderColor: LigaColors.primaryBlue.withValues(alpha: 0.5),
                  child: Text(
                    'Escolha um tema e o Nico cria um desafio do seu ano. '
                    'Acertar de primeira vale 20 XP!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(text: 'O Nico está pensando...'),
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
              if (challenge != null && _steps.isEmpty)
                LigaActionButton(
                  label: 'Ver passo a passo',
                  icon: Icons.route_rounded,
                  color: LigaColors.primaryBlue,
                  onPressed: _loading ? null : _showSteps,
                ),
              if (_steps.isNotEmpty)
                for (var i = 0; i < _steps.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: 90 * i),
                    child: LigaStepBubble(number: i + 1, text: _steps[i]),
                  ),
              const SizedBox(height: 12),
              LigaActionButton(
                label: challenge == null ? 'Começar desafio' : 'Novo desafio',
                icon: Icons.bolt_rounded,
                onPressed: _loading ? null : _newChallenge,
              ),
              const MinigameShortcuts(
                subject: MinigameSubject.matematica,
                withLightning: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
