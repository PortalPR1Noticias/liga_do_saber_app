import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/minigame.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';
import 'minigame_style.dart';
import 'widgets/word_search_board.dart';

/// Caça-palavras: a IA escolhe palavras do tema e escreve uma pista para
/// cada uma; a criança acha a palavra na grade pela pista. Achar todas vale
/// 20 XP.
class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key, this.subject = MinigameSubject.portugues});

  final MinigameSubject subject;

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  late MinigameSubject _subject = widget.subject;
  WordSearchGame? _game;
  final _foundWords = <int, String>{};
  final _foundCells = <GridCell>{};
  bool _missed = false;
  ProgressUpdate? _progress;
  String _notice = '';
  bool _loading = false;
  String? _error;

  bool get _finished =>
      _game != null && _foundWords.length == _game!.clues.length;

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

  Future<void> _newGame() => _run(() async {
    final game = await AppRepository.instance.newWordSearch(_subject);
    if (!mounted) return;
    setState(() {
      _game = game;
      _foundWords.clear();
      _foundCells.clear();
      _missed = false;
      _progress = null;
      _notice = '';
    });
  });

  Future<void> _check(GridCell start, GridCell end) => _run(() async {
    final result = await AppRepository.instance.checkWordSearch(
      _game!.id,
      start,
      end,
    );
    if (!mounted) return;
    setState(() {
      _missed = !result.found;
      if (result.found && result.index != null) {
        _foundWords[result.index!] = result.word;
        _foundCells.addAll(result.cells);
      }
      if (result.progress != null) _progress = result.progress;
      if (result.notice.isNotEmpty) _notice = result.notice;
    });
  });

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final color = _subject.color;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Caça-palavras')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              PopIn(
                child: LigaFeatureHeader(
                  title: 'Caça-palavras',
                  subtitle: 'Leia a pista e ache a palavra escondida.',
                  color: color,
                  character: _subject.character,
                ),
              ),
              const SizedBox(height: 20),
              MinigameSubjectPicker(
                value: _subject,
                enabled: !_loading,
                onChanged: (subject) => setState(() => _subject = subject),
              ),
              const SizedBox(height: 16),
              if (game != null)
                PopIn(
                  child: LigaPanel(
                    padding: const EdgeInsets.all(12),
                    borderColor: color.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigaPill(
                          icon: Icons.grid_on_rounded,
                          label:
                              '${_foundWords.length} de ${game.clues.length} · +${game.xp} XP',
                          color: color,
                        ),
                        const SizedBox(height: 8),
                        if (game.title.isNotEmpty)
                          Text(game.title, style: textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Toque na primeira e na última letra da palavra.',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        WordSearchBoard(
                          rows: game.rows,
                          foundCells: _foundCells,
                          enabled: !_loading && !_finished,
                          color: color,
                          onSelected: _check,
                        ),
                        if (_missed)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'Essa não é uma das palavras. Leia a pista de novo!',
                              style: TextStyle(
                                color: LigaColors.shade(
                                  LigaColors.actionCoral,
                                  0.12,
                                ),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else if (!_loading)
                LigaPanel(
                  borderColor: color.withValues(alpha: 0.5),
                  child: Text(
                    'Escolha a matéria e comece. Achar todas as palavras '
                    'vale 20 XP!',
                    style: textTheme.bodyLarge,
                  ),
                ),
              if (game != null) ...[
                const SizedBox(height: 16),
                const SectionTitle('Pistas', icon: Icons.lightbulb_rounded),
                for (var i = 0; i < game.clues.length; i++)
                  _ClueRow(
                    clue: game.clues[i],
                    word: _foundWords[i],
                    color: color,
                  ),
              ],
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(text: 'Escondendo as palavras...'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaErrorCard(message: _error!)),
              ],
              if (_finished) ...[
                const SizedBox(height: 14),
                Text(
                  'Achou todas! Caça-palavras completo!',
                  style: TextStyle(
                    color: LigaColors.shade(LigaColors.progressGreen, 0.12),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
              if (_progress != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaRewardCard(progress: _progress!)),
              ],
              if (_notice.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(_notice, style: textTheme.bodyLarge),
              ],
              const SizedBox(height: 18),
              LigaActionButton(
                label: game == null
                    ? 'Começar caça-palavras'
                    : 'Novo caça-palavras',
                icon: Icons.grid_on_rounded,
                onPressed: _loading ? null : _newGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClueRow extends StatelessWidget {
  const _ClueRow({required this.clue, required this.word, required this.color});

  final WordClue clue;
  final String? word;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final found = word != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LigaPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderColor: found ? LigaColors.progressGreen : null,
        child: Row(
          children: [
            Icon(
              found ? Icons.check_circle_rounded : Icons.help_rounded,
              color: found ? LigaColors.progressGreen : color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clue.clue,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    found ? word! : '${clue.length} letras',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: found ? 2 : 0,
                      color: found ? LigaColors.ink : LigaColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
