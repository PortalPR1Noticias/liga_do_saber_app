import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/archive_case.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';

typedef _Cell = (int, int);

/// Arquivo da Mila: minijogos de História criados pela IA para o ano escolar
/// da criança (caça-palavras, linha do tempo e enigma do documento). Vencer
/// de primeira vale 20 XP; depois de errar, 10; depois de revelar, nada.
class MilaArchiveScreen extends StatefulWidget {
  const MilaArchiveScreen({super.key});

  static const routeName = '/mila';

  @override
  State<MilaArchiveScreen> createState() => _MilaArchiveScreenState();
}

class _MilaArchiveScreenState extends State<MilaArchiveScreen> {
  static const _color = LigaColors.adventurePurple;

  ArchiveMode _mode = ArchiveMode.cacaPalavras;
  ArchiveCase? _case;
  ArchiveSolution? _solution;
  ProgressUpdate? _progress;
  bool _solved = false;
  bool _loading = false;
  String? _error;
  String _feedback = '';

  // Caça-palavras: palavras achadas (pela chave) e as casas de cada uma.
  final _found = <String, List<_Cell>>{};
  _Cell? _start;

  // Linha do tempo: posições das fichas na ordem que a criança tocou.
  final _picked = <int>[];

  // Enigma do documento: opções erradas já tentadas e a certa.
  final _wrong = <int>{};
  int? _right;

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

  Future<void> _newCase() => _run(() async {
    final archiveCase = await AppRepository.instance.newArchiveCase(_mode);
    if (!mounted) return;
    setState(() {
      _case = archiveCase;
      _solution = null;
      _progress = null;
      _solved = false;
      _feedback = '';
      _found.clear();
      _start = null;
      _picked.clear();
      _wrong.clear();
      _right = null;
    });
  });

  Future<void> _answer({int? choice, List<int>? order, List<String>? found}) =>
      _run(() async {
        final result = await AppRepository.instance.answerArchiveCase(
          _case!.id,
          choice: choice,
          order: order,
          found: found,
        );
        if (!mounted) return;
        setState(() {
          if (result.hit) {
            _solved = true;
            _right = choice;
            _solution = result.solution;
            _progress = result.progress;
            _feedback = switch (_case!.mode) {
              ArchiveMode.cacaPalavras => 'Achou todas! Olho de historiadora!',
              ArchiveMode.linhaDoTempo => 'Fichas em ordem! Caso resolvido!',
              ArchiveMode.documento => 'Enigma resolvido! Que investigação!',
            };
          } else {
            if (choice != null) _wrong.add(choice);
            _picked.clear();
            final inPlace = result.inPlace;
            _feedback = [
              if (inPlace != null)
                '$inPlace de ${_case!.events.length} fichas no lugar certo.',
              result.tip,
            ].where((part) => part.isNotEmpty).join(' ');
          }
        });
      });

  Future<void> _reveal() => _run(() async {
    final solution = await AppRepository.instance.revealArchiveCase(_case!.id);
    if (!mounted) return;
    setState(() {
      _solution = solution;
      _feedback = '';
      final archiveCase = _case!;
      for (var w = 0; w < solution.positions.length; w++) {
        if (w >= archiveCase.words.length) break;
        final key = archiveCase.words[w].key;
        final [row, col, dRow, dCol] = solution.positions[w];
        _found.putIfAbsent(
          key,
          () => [
            for (var i = 0; i < key.length; i++)
              (row + dRow * i, col + dCol * i),
          ],
        );
      }
    });
  });

  bool get _finished => _solved || _solution != null;

  // --- Caça-palavras ---

  void _tapCell(_Cell cell) {
    if (_finished || _loading) return;
    final start = _start;
    if (start == null || start == cell) {
      setState(() => _start = start == cell ? null : cell);
      return;
    }
    final line = _lineBetween(start, cell);
    setState(() => _start = null);
    if (line == null) return;
    final grid = _case!.grid;
    final letters = line.map((c) => grid[c.$1][c.$2]).join();
    final reversed = letters.split('').reversed.join();
    for (final word in _case!.words) {
      if (_found.containsKey(word.key)) continue;
      if (word.key == letters || word.key == reversed) {
        setState(() {
          _found[word.key] = line;
          _feedback = '';
        });
        if (_found.length == _case!.words.length) {
          _answer(found: _found.keys.toList());
        }
        return;
      }
    }
    setState(() => _feedback = 'Essa não é uma das palavras. Tente de novo!');
  }

  /// Casas entre duas casas na mesma linha, coluna ou diagonal.
  static List<_Cell>? _lineBetween(_Cell a, _Cell b) {
    final dRow = b.$1 - a.$1;
    final dCol = b.$2 - a.$2;
    if (dRow != 0 && dCol != 0 && dRow.abs() != dCol.abs()) return null;
    final length = dRow.abs() > dCol.abs() ? dRow.abs() : dCol.abs();
    return [
      for (var i = 0; i <= length; i++)
        (a.$1 + dRow.sign * i, a.$2 + dCol.sign * i),
    ];
  }

  // --- Linha do tempo ---

  void _pickEvent(int position) {
    if (_finished || _loading) return;
    setState(() {
      if (_picked.contains(position)) {
        _picked.remove(position);
      } else {
        _picked.add(position);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final archiveCase = _case;
    final solution = _solution;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Arquivo da Mila')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Arquivo da Mila',
                  subtitle:
                      'Minijogos de História: palavras, fichas e '
                      'documentos antigos.',
                  color: _color,
                  character: LigaCharacter.mila,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ArchiveMode.values)
                    ChoiceChip(
                      label: Text(mode.label),
                      selected: _mode == mode,
                      onSelected: _loading
                          ? null
                          : (_) => setState(() => _mode = mode),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (archiveCase != null) ...[
                PopIn(
                  child: LigaSceneCard(
                    character: LigaCharacter.mila,
                    color: _color,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigaPill(
                          icon: Icons.history_edu_rounded,
                          label:
                              '${archiveCase.mode.label} · +${archiveCase.xp} XP',
                          color: LigaColors.achievementYellow,
                          solid: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          archiveCase.title,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          archiveCase.intro,
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
                    borderColor: _color.withValues(alpha: 0.5),
                    child: switch (archiveCase.mode) {
                      ArchiveMode.cacaPalavras => _buildWordSearch(archiveCase),
                      ArchiveMode.linhaDoTempo => _buildTimeline(
                        archiveCase,
                        solution,
                      ),
                      ArchiveMode.documento => _buildDocument(
                        archiveCase,
                        solution,
                      ),
                    },
                  ),
                ),
              ] else if (!_loading)
                LigaPanel(
                  borderColor: _color.withValues(alpha: 0.5),
                  child: Text(
                    'Escolha um jogo e a Mila abre uma gaveta do arquivo com '
                    'um desafio de História do seu ano. Vencer de primeira '
                    'vale 20 XP!',
                    style: textTheme.bodyLarge,
                  ),
                ),
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(
                  text: 'A Mila está abrindo o arquivo...',
                ),
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
              if (archiveCase != null && !_finished)
                LigaActionButton(
                  label: 'Revelar a solução',
                  icon: Icons.manage_search_rounded,
                  color: _color,
                  onPressed: _loading ? null : _reveal,
                ),
              if (solution != null) ...[
                for (var i = 0; i < solution.steps.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: 90 * i),
                    child: LigaStepBubble(
                      number: i + 1,
                      text: solution.steps[i],
                    ),
                  ),
                if (solution.funFact.isNotEmpty)
                  PopIn(
                    delay: Duration(milliseconds: 90 * solution.steps.length),
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
                              'Você sabia? ${solution.funFact}',
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
                label: archiveCase == null ? 'Começar jogo' : 'Nova partida',
                icon: Icons.history_edu_rounded,
                onPressed: _loading ? null : _newCase,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackText() {
    if (_feedback.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        _feedback,
        style: TextStyle(
          color: LigaColors.shade(
            _solved ? LigaColors.progressGreen : LigaColors.actionCoral,
            0.12,
          ),
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildWordSearch(ArchiveCase archiveCase) {
    final textTheme = Theme.of(context).textTheme;
    final foundCells = <_Cell>{for (final cells in _found.values) ...cells};
    final grid = archiveCase.grid;
    final size = grid.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toque na primeira e na última letra de cada palavra.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cell = constraints.maxWidth / size;
            return Column(
              children: [
                for (var r = 0; r < size; r++)
                  Row(
                    children: [
                      for (var c = 0; c < grid[r].length; c++)
                        _LetterCell(
                          key: ValueKey('letra-$r-$c'),
                          letter: grid[r][c],
                          size: cell,
                          found: foundCells.contains((r, c)),
                          selected: _start == (r, c),
                          onTap: () => _tapCell((r, c)),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Palavras: ${_found.length} de ${archiveCase.words.length}',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        for (final word in archiveCase.words)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _found.containsKey(word.key)
                      ? Icons.check_circle_rounded
                      : Icons.search_rounded,
                  size: 20,
                  color: _found.containsKey(word.key)
                      ? LigaColors.progressGreen
                      : _color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: word.word,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if (_found.containsKey(word.key) &&
                            word.fact.isNotEmpty)
                          TextSpan(text: ': ${word.fact}'),
                      ],
                    ),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        _feedbackText(),
      ],
    );
  }

  Widget _buildTimeline(ArchiveCase archiveCase, ArchiveSolution? solution) {
    final textTheme = Theme.of(context).textTheme;
    final order = solution?.order;
    final years = solution?.years;
    // Depois de resolver ou revelar, as fichas aparecem em ordem, com o ano.
    final positions = order != null && order.length == archiveCase.events.length
        ? order
        : [for (var i = 0; i < archiveCase.events.length; i++) i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _finished
              ? 'A linha do tempo, da mais antiga à mais recente:'
              : 'Toque nas fichas da mais antiga para a mais recente.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        for (final (index, position) in positions.indexed)
          _TimelineCard(
            key: ValueKey('ficha-$position'),
            text: archiveCase.events[position],
            number: order != null
                ? index + 1
                : (_picked.contains(position)
                      ? _picked.indexOf(position) + 1
                      : null),
            year: years != null && position < years.length
                ? years[position]
                : null,
            done: order != null,
            onTap: () => _pickEvent(position),
          ),
        _feedbackText(),
        if (!_finished) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _picked.isEmpty || _loading
                      ? null
                      : () => setState(_picked.clear),
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _picked.length == archiveCase.events.length && !_loading
                      ? () => _answer(order: List.of(_picked))
                      : null,
                  child: const Text('Conferir ordem'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDocument(ArchiveCase archiveCase, ArchiveSolution? solution) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC9A66B), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _sourceIcon(archiveCase.sourceType),
                    color: const Color(0xFF8A6A33),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _sourceLabel(archiveCase.sourceType),
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF6B4F1F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(archiveCase.source, style: textTheme.bodyLarge),
              if (archiveCase.sourceOrigin.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  archiveCase.sourceOrigin,
                  style: textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(archiveCase.question, style: textTheme.bodyLarge),
        const SizedBox(height: 16),
        for (var o = 0; o < archiveCase.options.length; o++)
          LigaChoiceButton(
            label: archiveCase.options[o],
            state: _right == o || solution?.correct == o
                ? LigaChoiceState.right
                : _wrong.contains(o)
                ? LigaChoiceState.wrong
                : LigaChoiceState.idle,
            onTap: _finished || _loading || _wrong.contains(o)
                ? null
                : () => _answer(choice: o),
          ),
        _feedbackText(),
      ],
    );
  }

  static IconData _sourceIcon(String type) => switch (type) {
    'carta' => Icons.mail_rounded,
    'foto' => Icons.photo_camera_back_rounded,
    'pintura' => Icons.palette_rounded,
    'objeto' => Icons.inventory_2_rounded,
    'jornal' => Icons.newspaper_rounded,
    'mapa' => Icons.map_rounded,
    _ => Icons.description_rounded,
  };

  static String _sourceLabel(String type) => switch (type) {
    'carta' => 'Carta',
    'foto' => 'Foto antiga',
    'pintura' => 'Pintura',
    'objeto' => 'Objeto do museu',
    'jornal' => 'Jornal antigo',
    'mapa' => 'Mapa antigo',
    _ => 'Documento',
  };
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    super.key,
    required this.letter,
    required this.size,
    required this.found,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final double size;
  final bool found;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? LigaColors.achievementYellow
        : found
        ? LigaColors.adventurePurple
        : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.zero,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(
            color: LigaColors.ink.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: LigaTheme.displayFont,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.5,
            color: found && !selected ? Colors.white : LigaColors.ink,
          ),
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    super.key,
    required this.text,
    required this.number,
    required this.year,
    required this.done,
    required this.onTap,
  });

  final String text;
  final int? number;
  final String? year;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = number != null;
    final color = done ? LigaColors.progressGreen : LigaColors.adventurePurple;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LigaPressable(
        onTap: done ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? color : LigaColors.ink.withValues(alpha: 0.3),
              width: active ? 3 : 2,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: active ? color : LigaColors.disabled,
                child: Text(
                  active ? '$number' : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: textTheme.bodyMedium)),
              if (year != null) ...[
                const SizedBox(width: 8),
                LigaPill(
                  icon: Icons.event_rounded,
                  label: year!,
                  color: LigaColors.progressGreen,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
