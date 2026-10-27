import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/models/minigame.dart';

/// Grade de caça-palavras. A criança toca na primeira e na última letra da
/// palavra (ou arrasta de uma até a outra) em linha reta: na horizontal, na
/// vertical ou na diagonal. Quem confere a palavra é quem usa a grade, em
/// [onSelected].
///
/// Serve para qualquer módulo: basta passar as linhas da grade.
class WordSearchBoard extends StatefulWidget {
  const WordSearchBoard({
    super.key,
    required this.rows,
    required this.onSelected,
    this.foundCells = const {},
    this.enabled = true,
    this.color = LigaColors.actionCoral,
  });

  /// Uma string por linha, todas do mesmo tamanho.
  final List<String> rows;
  final void Function(GridCell start, GridCell end) onSelected;

  /// Casas das palavras já encontradas (ficam pintadas).
  final Set<GridCell> foundCells;
  final bool enabled;
  final Color color;

  /// Casas entre [start] e [end], ou vazio se não for uma linha reta.
  static List<GridCell> line(GridCell start, GridCell end) {
    final dr = end.row - start.row;
    final dc = end.col - start.col;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return const [];
    final steps = dr.abs() > dc.abs() ? dr.abs() : dc.abs();
    return [
      for (var k = 0; k <= steps; k++)
        GridCell(start.row + dr.sign * k, start.col + dc.sign * k),
    ];
  }

  @override
  State<WordSearchBoard> createState() => _WordSearchBoardState();
}

class _WordSearchBoardState extends State<WordSearchBoard> {
  GridCell? _start;
  GridCell? _hover;

  int get _cols => widget.rows.isEmpty ? 0 : widget.rows.first.length;

  GridCell? _cellAt(Offset position, double cellSize) {
    final row = (position.dy / cellSize).floor();
    final col = (position.dx / cellSize).floor();
    if (row < 0 || col < 0 || row >= widget.rows.length || col >= _cols) {
      return null;
    }
    return GridCell(row, col);
  }

  void _finish(GridCell end) {
    final start = _start!;
    setState(() {
      _start = null;
      _hover = null;
    });
    if (start != end && WordSearchBoard.line(start, end).isNotEmpty) {
      widget.onSelected(start, end);
    }
  }

  void _tap(GridCell cell) {
    if (_start == null) {
      setState(() {
        _start = cell;
        _hover = cell;
      });
    } else if (_start == cell) {
      setState(() {
        _start = null;
        _hover = null;
      });
    } else {
      _finish(cell);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = _start == null
        ? const <GridCell>{}
        : WordSearchBoard.line(_start!, _hover ?? _start!).toSet();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth / _cols;
        Widget grid = Column(
          children: [
            for (var r = 0; r < widget.rows.length; r++)
              Row(
                children: [
                  for (var c = 0; c < _cols; c++)
                    _LetterCell(
                      key: ValueKey('letra-$r-$c'),
                      letter: widget.rows[r][c],
                      size: cellSize,
                      found: widget.foundCells.contains(GridCell(r, c)),
                      selected: selection.contains(GridCell(r, c)),
                      color: widget.color,
                    ),
                ],
              ),
          ],
        );
        if (!widget.enabled) return grid;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final cell = _cellAt(details.localPosition, cellSize);
            if (cell != null) _tap(cell);
          },
          onPanStart: (details) {
            final cell = _cellAt(details.localPosition, cellSize);
            if (cell == null) return;
            setState(() {
              _start = cell;
              _hover = cell;
            });
          },
          onPanUpdate: (details) {
            final cell = _cellAt(details.localPosition, cellSize);
            if (cell != null && cell != _hover && _start != null) {
              setState(() => _hover = cell);
            }
          },
          onPanEnd: (_) {
            if (_start != null && _hover != null && _hover != _start) {
              _finish(_hover!);
            }
          },
          child: grid,
        );
      },
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    super.key,
    required this.letter,
    required this.size,
    required this.found,
    required this.selected,
    required this.color,
  });

  final String letter;
  final double size;
  final bool found;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? LigaColors.achievementYellow
        : found
        ? color
        : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: size,
      height: size,
      margin: EdgeInsets.zero,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
          color: LigaColors.ink.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: LigaTheme.displayFont,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.52,
          color: found && !selected ? Colors.white : LigaColors.ink,
          shadows: found && !selected ? ligaOutline(1) : null,
        ),
      ),
    );
  }
}
