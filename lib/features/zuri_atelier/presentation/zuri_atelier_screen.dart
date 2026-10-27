import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/atelier.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';
import 'atelier_games.dart';

/// Ateliê do Zuri: minijogos de organizar ideias para o contraturno
/// (caça-palavras, monte o mapa mental e quebra-cabeça do projeto) criados
/// pela IA. Resolver de primeira vale 20 XP; depois de errar, 10; depois de
/// ver a solução, nada. Em "Meu projeto", a criança escreve o tema do
/// trabalho dela e o Zuri monta o mapa mental e as etapas (15 XP).
class ZuriAtelierScreen extends StatefulWidget {
  const ZuriAtelierScreen({super.key});

  static const routeName = '/zuri';

  @override
  State<ZuriAtelierScreen> createState() => _ZuriAtelierScreenState();
}

class _ZuriAtelierScreenState extends State<ZuriAtelierScreen> {
  static const _color = LigaColors.sunsetOrange;

  bool _projectMode = false;
  AtelierGameType _type = AtelierGameType.cacaPalavras;
  AtelierGame? _game;
  bool _solved = false;
  bool _missed = false;
  AtelierSolution? _solution;
  final _theme = TextEditingController();
  ProjectPlan? _plan;
  ProgressUpdate? _progress;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

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

  void _switchTo(bool projectMode) {
    setState(() {
      _projectMode = projectMode;
      _error = null;
      _progress = null;
    });
  }

  Future<void> _newGame() => _run(() async {
    final game = await AppRepository.instance.newAtelierGame(_type);
    if (!mounted) return;
    setState(() {
      _game = game;
      _solved = false;
      _missed = false;
      _solution = null;
      _progress = null;
    });
  });

  Future<AtelierCheckResult?> _check(List<Object> move) async {
    AtelierCheckResult? result;
    await _run(() async {
      result = await AppRepository.instance.checkAtelierGame(_game!.id, move);
      if (!mounted) return;
      setState(() {
        _solved = result!.solved;
        _missed = !result!.solved;
        if (result!.solved) {
          _solution = result!.solution;
          _progress = result!.progress;
        }
      });
    });
    return result;
  }

  Future<void> _reveal() => _run(() async {
    final solution = await AppRepository.instance.revealAtelierGame(_game!.id);
    if (mounted) setState(() => _solution = solution);
  });

  Future<void> _planProject() async {
    final theme = _theme.text.trim();
    if (theme.length < 3) {
      setState(() => _error = 'Conte qual é o tema do seu projeto.');
      return;
    }
    FocusScope.of(context).unfocus();
    await _run(() async {
      final plan = await AppRepository.instance.planProject(theme);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _progress = plan.progress;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ateliê do Zuri')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Ateliê do Zuri',
                  subtitle: 'Jogos de ideias, mapas mentais e projetos.',
                  color: _color,
                  character: LigaCharacter.zuri,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.extension_rounded, size: 18),
                    label: const Text('Jogos'),
                    selected: !_projectMode,
                    onSelected: _loading ? null : (_) => _switchTo(false),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.hub_rounded, size: 18),
                    label: const Text('Meu projeto'),
                    selected: _projectMode,
                    onSelected: _loading ? null : (_) => _switchTo(true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_projectMode)
                ..._projectSection(context)
              else
                ..._gameSection(context),
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(text: 'O Zuri está criando...'),
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
              if (_projectMode) ...[
                if (_plan != null) ..._planView(context, _plan!),
                const SizedBox(height: 12),
                LigaActionButton(
                  label: _plan == null
                      ? 'Montar meu mapa mental'
                      : 'Montar outro projeto',
                  icon: Icons.hub_rounded,
                  onPressed: _loading ? null : _planProject,
                ),
              ] else ...[
                if (_game != null && _solution == null)
                  LigaActionButton(
                    label: 'Ver a solução do Zuri',
                    icon: Icons.tips_and_updates_rounded,
                    color: _color,
                    onPressed: _loading ? null : _reveal,
                  ),
                if (_solution != null) ..._explanation(context, _solution!),
                const SizedBox(height: 12),
                LigaActionButton(
                  label: _game == null ? 'Começar jogo' : 'Novo jogo',
                  icon: Icons.videogame_asset_rounded,
                  onPressed: _loading ? null : _newGame,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _gameSection(BuildContext context) {
    final game = _game;
    final textTheme = Theme.of(context).textTheme;
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in AtelierGameType.values)
            ChoiceChip(
              label: Text(type.label),
              selected: _type == type,
              onSelected: _loading ? null : (_) => setState(() => _type = type),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (game != null) ...[
        PopIn(
          child: LigaSceneCard(
            character: LigaCharacter.zuri,
            color: _color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LigaPill(
                  icon: Icons.videogame_asset_rounded,
                  label: '${game.type.label} · +${game.xp} XP',
                  color: LigaColors.achievementYellow,
                ),
                const SizedBox(height: 8),
                Text(
                  game.title,
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  game.intro,
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
        LigaPanel(
          borderColor: _color.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (game.type) {
                AtelierGameType.cacaPalavras => WordSearchGame(
                  key: ValueKey(game.id),
                  game: game,
                  onCheck: _check,
                  solution: _solution,
                  enabled: !_loading,
                ),
                AtelierGameType.mapaMental => MindMapGame(
                  key: ValueKey(game.id),
                  game: game,
                  onCheck: _check,
                  solution: _solution,
                  enabled: !_loading,
                ),
                AtelierGameType.ordemProjeto => ProjectOrderGame(
                  key: ValueKey(game.id),
                  game: game,
                  onCheck: _check,
                  solution: _solution,
                  enabled: !_loading,
                ),
              },
              if (_solved || _missed)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _solved
                        ? 'Ideia genial! Você é um criador!'
                        : 'Quase! As peças vermelhas voltaram. Tente de novo.',
                    style: TextStyle(
                      color: LigaColors.shade(
                        _solved
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
      ] else if (!_loading)
        LigaPanel(
          borderColor: _color.withValues(alpha: 0.5),
          child: Text(
            'Escolha um jogo e o Zuri cria um desafio do seu ano. '
            'Resolver de primeira vale 20 XP!',
            style: textTheme.bodyLarge,
          ),
        ),
    ];
  }

  List<Widget> _explanation(BuildContext context, AtelierSolution solution) {
    return [
      for (var i = 0; i < solution.explanation.length; i++)
        PopIn(
          delay: Duration(milliseconds: 90 * i),
          child: LigaStepBubble(number: i + 1, text: solution.explanation[i]),
        ),
    ];
  }

  List<Widget> _projectSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return [
      LigaPanel(
        borderColor: _color.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qual é o tema do seu projeto ou trabalho da escola? O Zuri '
              'monta um mapa mental e as etapas para você começar. Não '
              'escreva seu nome nem o da escola.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _theme,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tema do projeto',
                hintText: 'Ex.: reciclagem na escola',
                counterText: '',
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _planView(BuildContext context, ProjectPlan plan) {
    final textTheme = Theme.of(context).textTheme;
    return [
      PopIn(
        child: LigaSceneCard(
          character: LigaCharacter.zuri,
          color: _color,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LigaPill(
                icon: Icons.hub_rounded,
                label: 'Mapa mental',
                color: LigaColors.achievementYellow,
              ),
              const SizedBox(height: 8),
              Text(
                plan.title,
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Centro: ${plan.centralIdea}',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      for (var b = 0; b < plan.branches.length; b++)
        PopIn(
          delay: Duration(milliseconds: 80 * b),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LigaPanel(
              borderColor: _color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.call_split_rounded, color: _color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.branches[b].title,
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final idea in plan.branches[b].ideas)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      child: Text('• $idea', style: textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
        ),
      for (var i = 0; i < plan.steps.length; i++)
        LigaStepBubble(number: i + 1, title: 'Etapa', text: plan.steps[i]),
      if (plan.creativeChallenge.isNotEmpty)
        LigaPanel(
          borderColor: LigaColors.achievementYellow,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Toque criativo: ${plan.creativeChallenge}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
