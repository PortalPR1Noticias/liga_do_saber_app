import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_sound.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/minigame.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';
import 'minigame_style.dart';
import 'widgets/crossword_board.dart';

/// Cruzadas da Liga: a criança lê a pista, escolhe a palavra na grade e
/// digita a resposta. Errou duas vezes? O herói dá as primeiras letras.
/// Completar vale 20 XP (10 se precisou de dica).
class CrosswordScreen extends StatefulWidget {
  const CrosswordScreen({super.key, this.subject = MinigameSubject.portugues});

  final MinigameSubject subject;

  @override
  State<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends State<CrosswordScreen> {
  late MinigameSubject _subject = widget.subject;
  final _answer = TextEditingController();
  CrosswordGame? _game;
  int? _selected;
  final _solvedWords = <int, String>{};
  final _solvedLetters = <GridCell, String>{};
  final _hints = <int, String>{};
  String _feedback = '';
  bool _feedbackGood = false;
  ProgressUpdate? _progress;
  String _notice = '';
  bool _loading = false;
  String? _error;

  bool get _finished =>
      _game != null && _solvedWords.length == _game!.clues.length;

  @override
  void dispose() {
    _answer.dispose();
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

  Future<void> _newGame() => _run(() async {
    final game = await AppRepository.instance.newCrossword(_subject);
    if (!mounted) return;
    _answer.clear();
    setState(() {
      _game = game;
      _selected = game.clues.isEmpty ? null : 0;
      _solvedWords.clear();
      _solvedLetters.clear();
      _hints.clear();
      _feedback = '';
      _progress = null;
      _notice = '';
    });
  });

  void _select(int index) {
    if (_selected == index) return;
    _answer.clear();
    setState(() {
      _selected = index;
      _feedback = '';
    });
  }

  /// Vai para a próxima pista que ainda falta.
  void _selectNextOpen() {
    final clues = _game!.clues;
    for (var step = 1; step <= clues.length; step++) {
      final i = ((_selected ?? 0) + step) % clues.length;
      if (!_solvedWords.containsKey(i)) {
        _selected = i;
        return;
      }
    }
  }

  Future<void> _check() async {
    final index = _selected;
    final game = _game;
    if (index == null || game == null) return;
    final clue = game.clues[index];
    final letters = crosswordLetters(_answer.text);
    if (letters.length != clue.length) {
      setState(() {
        _feedbackGood = false;
        _feedback =
            'A palavra tem ${clue.length} letras. Você escreveu '
            '${letters.length}.';
      });
      return;
    }
    await _run(() async {
      final result = await AppRepository.instance.checkCrossword(
        game.id,
        index,
        _answer.text,
      );
      if (!mounted) return;
      LigaSound.play(result.correct ? LigaSfx.acerto : LigaSfx.erro);
      setState(() {
        if (result.correct) {
          _solvedWords[index] = result.word;
          final cells = clue.cells;
          for (var k = 0; k < cells.length && k < result.letters.length; k++) {
            _solvedLetters[cells[k]] = result.letters[k];
          }
          _answer.clear();
          _feedbackGood = true;
          _feedback = 'Isso! ${result.word} está certa.';
          if (!_finished) _selectNextOpen();
        } else {
          if (result.hint.isNotEmpty) _hints[index] = result.hint;
          _feedbackGood = false;
          _feedback = result.hint.isEmpty
              ? 'Ainda não. Leia a pista de novo com calma.'
              : 'Quase! Dica: ${result.hint}';
        }
        if (result.progress != null) _progress = result.progress;
        if (result.notice.isNotEmpty) _notice = result.notice;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final color = _subject.color;
    final textTheme = Theme.of(context).textTheme;
    final selected = _selected;
    final selectedClue = game != null && selected != null
        ? game.clues[selected]
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Cruzadas da Liga')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              PopIn(
                child: LigaFeatureHeader(
                  title: 'Cruzadas da Liga',
                  subtitle: 'Leia a pista, descubra a palavra e cruze tudo!',
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
                          icon: Icons.border_all_rounded,
                          label:
                              '${_solvedWords.length} de ${game.clues.length} · +${game.xp} XP',
                          color: color,
                        ),
                        const SizedBox(height: 8),
                        if (game.title.isNotEmpty)
                          Text(game.title, style: textTheme.titleLarge),
                        const SizedBox(height: 10),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _answer,
                          builder: (context, value, _) => CrosswordBoard(
                            game: game,
                            solvedLetters: _solvedLetters,
                            selected: selected,
                            typing: crosswordLetters(value.text),
                            color: color,
                            onSelect: _select,
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
                    'Escolha a matéria e comece. Completar as cruzadas vale '
                    'até 20 XP!',
                    style: textTheme.bodyLarge,
                  ),
                ),
              if (selectedClue != null && !_finished) ...[
                const SizedBox(height: 14),
                LigaPanel(
                  borderColor: color,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedClue.number} ${selectedClue.direction.label}'
                        ' · ${selectedClue.length} letras',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: LigaColors.shade(color, 0.12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(selectedClue.clue, style: textTheme.bodyLarge),
                      if (_hints[selected] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Dica: ${_hints[selected]}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (_solvedWords.containsKey(selected))
                        Text(
                          'Essa já foi! Escolha outra pista.',
                          style: textTheme.bodyMedium,
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const Key('crosswordAnswer'),
                                controller: _answer,
                                enabled: !_loading,
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: selectedClue.length + 4,
                                decoration: const InputDecoration(
                                  hintText: 'Digite a palavra',
                                  counterText: '',
                                ),
                                onSubmitted: (_) => _check(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              key: const Key('crosswordCheck'),
                              onPressed: _loading ? null : _check,
                              child: const Text('Conferir'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
              if (_feedback.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _feedback,
                  style: TextStyle(
                    color: LigaColors.shade(
                      _feedbackGood
                          ? LigaColors.progressGreen
                          : LigaColors.actionCoral,
                      0.12,
                    ),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              if (game != null) ...[
                for (final direction in CrosswordDirection.values) ...[
                  const SizedBox(height: 16),
                  SectionTitle(
                    direction == CrosswordDirection.across
                        ? 'Horizontais'
                        : 'Verticais',
                    icon: direction == CrosswordDirection.across
                        ? Icons.east_rounded
                        : Icons.south_rounded,
                  ),
                  for (var i = 0; i < game.clues.length; i++)
                    if (game.clues[i].direction == direction)
                      _ClueRow(
                        clue: game.clues[i],
                        word: _solvedWords[i],
                        selected: i == selected,
                        color: color,
                        onTap: () => _select(i),
                      ),
                ],
              ],
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(text: 'Cruzando as palavras...'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaErrorCard(message: _error!)),
              ],
              if (_finished) ...[
                const SizedBox(height: 14),
                Text(
                  'Cruzadas completas! Todas as palavras no lugar!',
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
                label: game == null ? 'Começar cruzadas' : 'Novas cruzadas',
                icon: Icons.border_all_rounded,
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
  const _ClueRow({
    required this.clue,
    required this.word,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final CrosswordClue clue;
  final String? word;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final found = word != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: LigaPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderColor: found
              ? LigaColors.progressGreen
              : selected
              ? color
              : null,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: found ? LigaColors.progressGreen : color,
                child: Text(
                  '${clue.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
      ),
    );
  }
}
