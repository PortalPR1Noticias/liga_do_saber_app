import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/atelier.dart';

/// Envia a jogada ao servidor e devolve o resultado (ou nulo se deu erro; a
/// tela mostra o erro).
typedef AtelierCheck = Future<AtelierCheckResult?> Function(List<Object> move);

/// Peça de jogo tocável: bloco com contorno grosso, no estilo da Liga.
class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.label,
    required this.color,
    this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onWhite = color == Colors.white;
    return LigaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? LigaColors.achievementYellow : LigaColors.ink,
            width: selected ? 4 : 2.5,
          ),
          boxShadow: const [
            BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: onWhite ? LigaColors.ink : Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: onWhite ? LigaColors.ink : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  shadows: onWhite ? null : ligaOutline(1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Caça-palavras: toque na primeira e na última letra da palavra.

class WordSearchGame extends StatefulWidget {
  const WordSearchGame({
    super.key,
    required this.game,
    required this.onCheck,
    this.solution,
    this.enabled = true,
  });

  final AtelierGame game;
  final AtelierCheck onCheck;
  final AtelierSolution? solution;
  final bool enabled;

  static Key cellKey(int row, int col) => ValueKey('letra-$row-$col');

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  (int, int)? _anchor;
  final _found = <int, GridLine>{};
  String _message = '';

  bool get _finished =>
      widget.solution != null || _found.length == widget.game.words.length;

  Future<void> _tap(int row, int col) async {
    if (_finished || !widget.enabled) return;
    final anchor = _anchor;
    if (anchor == null || anchor == (row, col)) {
      setState(() {
        _anchor = anchor == null ? (row, col) : null;
        _message = '';
      });
      return;
    }
    final line = GridLine(anchor, (row, col));
    final letters = [
      for (final (r, c) in line.cells) widget.game.grid[r][c],
    ].join();
    final reversed = letters.split('').reversed.join();
    final words = widget.game.words;
    final index = [
      for (var w = 0; w < words.length; w++)
        if (!_found.containsKey(w) &&
            letters.length > 1 &&
            (words[w].key == letters || words[w].key == reversed))
          w,
    ].firstOrNull;
    setState(() {
      _anchor = null;
      if (index == null) {
        _message = 'Essa não é uma das palavras. Tente outra linha!';
      } else {
        _found[index] = line;
        _message = 'Achou ${words[index].text}!';
      }
    });
    if (index != null && _found.length == words.length) {
      await widget.onCheck([
        for (final MapEntry(key: w, value: line) in _found.entries)
          {'palavra': w, ...line.toJson()},
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final size = game.grid.length;
    final solutionLines = widget.solution?.wordLines ?? const <GridLine>[];
    final foundCells = {for (final line in _found.values) ...line.cells};
    final solutionCells = {for (final line in solutionLines) ...line.cells};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var w = 0; w < game.words.length; w++)
              _GameTile(
                label: game.words[w].text,
                icon: _found.containsKey(w) ? Icons.check_rounded : null,
                color: _found.containsKey(w)
                    ? LigaColors.progressGreen
                    : Colors.white,
              ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LigaColors.ink, width: 3),
            ),
            padding: const EdgeInsets.all(4),
            child: GridView.count(
              crossAxisCount: size,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var r = 0; r < size; r++)
                  for (var c = 0; c < size; c++)
                    GestureDetector(
                      key: WordSearchGame.cellKey(r, c),
                      onTap: () => _tap(r, c),
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _anchor == (r, c)
                              ? LigaColors.achievementYellow
                              : foundCells.contains((r, c))
                              ? LigaColors.sunsetOrange
                              : solutionCells.contains((r, c))
                              ? LigaColors.progressGreen.withValues(alpha: 0.5)
                              : LigaColors.skyBottom.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FittedBox(
                          child: Text(
                            game.grid[r][c],
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: LigaColors.ink,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _message.isNotEmpty
              ? _message
              : _anchor == null
              ? 'Toque na primeira letra de uma palavra.'
              : 'Agora toque na última letra.',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: LigaColors.ink,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Monte o mapa mental: escolha uma ideia e toque no ramo certo.

class MindMapGame extends StatefulWidget {
  const MindMapGame({
    super.key,
    required this.game,
    required this.onCheck,
    this.solution,
    this.enabled = true,
  });

  final AtelierGame game;
  final AtelierCheck onCheck;
  final AtelierSolution? solution;
  final bool enabled;

  @override
  State<MindMapGame> createState() => _MindMapGameState();
}

class _MindMapGameState extends State<MindMapGame> {
  late final List<int?> _branchOf = List.filled(
    widget.game.pieces.length,
    null,
  );
  final _locked = <int>{};
  final _wrong = <int>{};
  int? _selected;
  bool _solved = false;

  static const _branchColors = [
    LigaColors.primaryBlue,
    LigaColors.adventurePurple,
    LigaColors.cyanGlow,
    LigaColors.actionCoral,
    LigaColors.progressGreen,
  ];

  bool get _finished => _solved || widget.solution != null;

  @override
  void didUpdateWidget(MindMapGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final solution = widget.solution;
    if (solution != null && oldWidget.solution == null) {
      for (var p = 0; p < solution.branchOfPiece.length; p++) {
        _branchOf[p] = solution.branchOfPiece[p];
      }
      _selected = null;
      _wrong.clear();
    }
  }

  void _place(int branch) {
    final piece = _selected;
    if (piece == null || _finished) return;
    setState(() {
      _branchOf[piece] = branch;
      _wrong.remove(piece);
      _selected = null;
    });
  }

  Future<void> _check() async {
    final result = await widget.onCheck([
      for (final branch in _branchOf) branch!,
    ]);
    if (result == null || !mounted) return;
    setState(() {
      _solved = result.solved;
      for (var p = 0; p < result.correct.length; p++) {
        if (result.correct[p]) {
          _locked.add(p);
        } else {
          _wrong.add(p);
          _branchOf[p] = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final textTheme = Theme.of(context).textTheme;
    final loose = [
      for (var p = 0; p < game.pieces.length; p++)
        if (_branchOf[p] == null) p,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _GameTile(
            label: game.centralIdea,
            icon: Icons.hub_rounded,
            color: LigaColors.sunsetOrange,
          ),
        ),
        const SizedBox(height: 12),
        if (loose.isNotEmpty) ...[
          Text(
            _selected == null
                ? 'Toque numa ideia e depois no ramo dela:'
                : 'Agora toque no ramo certo!',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in loose)
                _GameTile(
                  label: game.pieces[p],
                  color: _wrong.contains(p)
                      ? LigaColors.actionCoral
                      : Colors.white,
                  selected: _selected == p,
                  onTap: _finished || !widget.enabled
                      ? null
                      : () => setState(
                          () => _selected = _selected == p ? null : p,
                        ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        for (var b = 0; b < game.branches.length; b++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LigaPressable(
              onTap: _selected == null ? null : () => _place(b),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _branchColors[b % _branchColors.length].withValues(
                    alpha: _selected == null ? 0.18 : 0.32,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _branchColors[b % _branchColors.length],
                    width: 3,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.call_split_rounded,
                          color: _branchColors[b % _branchColors.length],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            game.branches[b],
                            style: textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var p = 0; p < game.pieces.length; p++)
                          if (_branchOf[p] == b)
                            _GameTile(
                              label: game.pieces[p],
                              icon: _locked.contains(p) || _finished
                                  ? Icons.check_rounded
                                  : null,
                              color: _locked.contains(p) || _finished
                                  ? LigaColors.progressGreen
                                  : _branchColors[b % _branchColors.length],
                              onTap:
                                  _locked.contains(p) ||
                                      _finished ||
                                      !widget.enabled
                                  ? null
                                  : () => setState(() => _branchOf[p] = null),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!_finished)
          LigaActionButton(
            label: 'Conferir mapa',
            icon: Icons.fact_check_rounded,
            color: LigaColors.sunsetOrange,
            onPressed: loose.isEmpty && widget.enabled ? _check : null,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quebra-cabeça do projeto: toque nas etapas na ordem certa.

class ProjectOrderGame extends StatefulWidget {
  const ProjectOrderGame({
    super.key,
    required this.game,
    required this.onCheck,
    this.solution,
    this.enabled = true,
  });

  final AtelierGame game;
  final AtelierCheck onCheck;
  final AtelierSolution? solution;
  final bool enabled;

  @override
  State<ProjectOrderGame> createState() => _ProjectOrderGameState();
}

class _ProjectOrderGameState extends State<ProjectOrderGame> {
  /// Peça colocada em cada posição.
  late final List<int?> _slots = List.filled(widget.game.pieces.length, null);
  final _locked = <int>{};
  final _wrong = <int>{};
  bool _solved = false;

  bool get _finished => _solved || widget.solution != null;

  @override
  void didUpdateWidget(ProjectOrderGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final solution = widget.solution;
    if (solution != null && oldWidget.solution == null) {
      for (var p = 0; p < solution.stepOfPiece.length; p++) {
        _slots[solution.stepOfPiece[p]] = p;
      }
      _wrong.clear();
    }
  }

  void _put(int piece) {
    final empty = _slots.indexOf(null);
    if (empty < 0) return;
    setState(() {
      _slots[empty] = piece;
      _wrong.remove(piece);
    });
  }

  Future<void> _check() async {
    final result = await widget.onCheck([for (final piece in _slots) piece!]);
    if (result == null || !mounted) return;
    setState(() {
      _solved = result.solved;
      for (var position = 0; position < result.correct.length; position++) {
        if (result.correct[position]) {
          _locked.add(position);
        } else {
          _wrong.add(_slots[position]!);
          _slots[position] = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final textTheme = Theme.of(context).textTheme;
    final loose = [
      for (var p = 0; p < game.pieces.length; p++)
        if (!_slots.contains(p)) p,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var position = 0; position < _slots.length; position++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: LigaColors.sunsetOrange,
                  child: Text(
                    '${position + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _slots[position] == null
                      ? Container(
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: LigaColors.inkSoft.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                        )
                      : _GameTile(
                          label: game.pieces[_slots[position]!],
                          icon: _locked.contains(position) || _finished
                              ? Icons.check_rounded
                              : null,
                          color: _locked.contains(position) || _finished
                              ? LigaColors.progressGreen
                              : LigaColors.sunsetOrange,
                          onTap:
                              _locked.contains(position) ||
                                  _finished ||
                                  !widget.enabled
                              ? null
                              : () => setState(() => _slots[position] = null),
                        ),
                ),
              ],
            ),
          ),
        if (loose.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Toque na próxima etapa:', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in loose)
                _GameTile(
                  label: game.pieces[p],
                  color: _wrong.contains(p)
                      ? LigaColors.actionCoral
                      : Colors.white,
                  onTap: _finished || !widget.enabled ? null : () => _put(p),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!_finished)
          LigaActionButton(
            label: 'Conferir ordem',
            icon: Icons.fact_check_rounded,
            color: LigaColors.sunsetOrange,
            onPressed: loose.isEmpty && widget.enabled ? _check : null,
          ),
      ],
    );
  }
}
