import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/expedition.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';

/// Trilha do Teo: o Teo (IA) cria investigações de Ciências e Geografia do
/// ano escolar da criança. Acertar de primeira vale 20 XP; depois de errar,
/// 10; depois de revelar a descoberta, não vale XP.
class TeoTrailScreen extends StatefulWidget {
  const TeoTrailScreen({super.key});

  static const routeName = '/teo';

  @override
  State<TeoTrailScreen> createState() => _TeoTrailScreenState();
}

class _TeoTrailScreenState extends State<TeoTrailScreen> {
  ExpeditionSubject _subject = ExpeditionSubject.ciencias;
  Expedition? _expedition;
  final _wrong = <int>{};
  int? _right;
  String _tip = '';
  ExpeditionDiscovery? _discovery;
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

  Future<void> _newExpedition() => _run(() async {
    final expedition = await AppRepository.instance.newExpedition(_subject);
    if (!mounted) return;
    setState(() {
      _expedition = expedition;
      _wrong.clear();
      _right = null;
      _tip = '';
      _discovery = null;
      _progress = null;
    });
  });

  Future<void> _answer(int option) => _run(() async {
    final result = await AppRepository.instance.answerExpedition(
      _expedition!.id,
      option,
    );
    if (!mounted) return;
    setState(() {
      if (result.hit) {
        _right = option;
        _discovery = result.discovery;
        _progress = result.progress;
      } else {
        _wrong.add(option);
        _tip = result.tip;
      }
    });
  });

  Future<void> _reveal() => _run(() async {
    final discovery = await AppRepository.instance.revealExpedition(
      _expedition!.id,
    );
    if (mounted) setState(() => _discovery = discovery);
  });

  @override
  Widget build(BuildContext context) {
    final expedition = _expedition;
    final discovery = _discovery;
    final solved = _right != null;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Trilha do Teo')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Trilha do Teo',
                  subtitle: 'Investigue mistérios de Ciências e Geografia.',
                  color: LigaColors.progressGreen,
                  character: LigaCharacter.teo,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final subject in ExpeditionSubject.values)
                    ChoiceChip(
                      label: Text(subject.label),
                      selected: _subject == subject,
                      onSelected: _loading
                          ? null
                          : (_) => setState(() => _subject = subject),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (expedition != null) ...[
                PopIn(
                  child: LigaSceneCard(
                    character: LigaCharacter.teo,
                    color: LigaColors.progressGreen,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigaPill(
                          icon: Icons.explore_rounded,
                          label:
                              '${expedition.subject.label} · +${expedition.xp} XP',
                          color: LigaColors.achievementYellow,
                          solid: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          expedition.title,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expedition.scene,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PopIn(
                  child: LigaPanel(
                    borderColor: LigaColors.progressGreen.withValues(
                      alpha: 0.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (expedition.clues.isNotEmpty) ...[
                          Text('Pistas do Teo', style: textTheme.titleMedium),
                          const SizedBox(height: 6),
                          for (final clue in expedition.clues)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: LigaColors.progressGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      clue,
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                        ],
                        Text(expedition.question, style: textTheme.bodyLarge),
                        const SizedBox(height: 16),
                        for (var o = 0; o < expedition.options.length; o++)
                          LigaChoiceButton(
                            label: expedition.options[o],
                            state: _right == o || discovery?.correct == o
                                ? LigaChoiceState.right
                                : _wrong.contains(o)
                                ? LigaChoiceState.wrong
                                : LigaChoiceState.idle,
                            onTap:
                                solved ||
                                    discovery != null ||
                                    _loading ||
                                    _wrong.contains(o)
                                ? null
                                : () => _answer(o),
                          ),
                        if (solved || _wrong.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              solved
                                  ? 'Mistério desvendado! Que explorador!'
                                  : 'Quase! ${_tip.isEmpty ? 'Olhe as pistas de novo ou revele a descoberta.' : _tip}',
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
                ),
              ] else if (!_loading)
                LigaPanel(
                  borderColor: LigaColors.progressGreen.withValues(alpha: 0.5),
                  child: Text(
                    'Escolha Ciências ou Geografia e o Teo leva você para '
                    'uma expedição do seu ano. Desvendar de primeira vale '
                    '20 XP!',
                    style: textTheme.bodyLarge,
                  ),
                ),
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(text: 'O Teo está explorando...'),
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
              if (expedition != null && discovery == null)
                LigaActionButton(
                  label: 'Revelar a descoberta',
                  icon: Icons.travel_explore_rounded,
                  color: LigaColors.progressGreen,
                  onPressed: _loading ? null : _reveal,
                ),
              if (discovery != null) ...[
                for (var i = 0; i < discovery.steps.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: 90 * i),
                    child: LigaStepBubble(
                      number: i + 1,
                      text: discovery.steps[i],
                    ),
                  ),
                if (discovery.funFact.isNotEmpty)
                  PopIn(
                    delay: Duration(milliseconds: 90 * discovery.steps.length),
                    child: LigaPanel(
                      borderColor: LigaColors.achievementYellow,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: LigaColors.sunsetOrange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Você sabia? ${discovery.funFact}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              LigaActionButton(
                label: expedition == null
                    ? 'Começar expedição'
                    : 'Nova expedição',
                icon: Icons.explore_rounded,
                onPressed: _loading ? null : _newExpedition,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
