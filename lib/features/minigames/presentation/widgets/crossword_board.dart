import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/models/minigame.dart';

/// Grade das Cruzadas da Liga. Mostra o número de cada pista, as letras
/// das palavras já acertadas e, na palavra escolhida, o que a criança está
/// digitando. Tocar numa casa escolhe a palavra dela.
class CrosswordBoard extends StatelessWidget {
  const CrosswordBoard({
    super.key,
    required this.game,
    required this.solvedLetters,
    required this.selected,
    required this.typing,
    required this.color,
    required this.onSelect,
  });

  final CrosswordGame game;

  /// Letra de cada casa das palavras acertadas.
  final Map<GridCell, String> solvedLetters;

  /// Índice da pista escolhida em [CrosswordGame.clues].
  final int? selected;

  /// Letras digitadas para a pista escolhida (sem acento).
  final String typing;
  final Color color;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final numbers = <GridCell, int>{};
    final cluesOf = <GridCell, List<int>>{};
    for (var i = 0; i < game.clues.length; i++) {
      final clue = game.clues[i];
      numbers[GridCell(clue.row, clue.col)] = clue.number;
      for (final cell in clue.cells) {
        cluesOf.putIfAbsent(cell, () => []).add(i);
      }
    }
    final selectedCells = selected == null
        ? const <GridCell>[]
        : game.clues[selected!].cells;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth / game.cols).clamp(18.0, 40.0);
        return Center(
          child: SizedBox(
            width: size * game.cols,
            height: size * game.rows,
            child: Stack(
              children: [
                for (final entry in cluesOf.entries)
                  Positioned(
                    left: entry.key.col * size,
                    top: entry.key.row * size,
                    width: size,
                    height: size,
                    child: _Cell(
                      key: Key(
                        'crosswordCell-${entry.key.row}-${entry.key.col}',
                      ),
                      number: numbers[entry.key],
                      letter: _letterAt(entry.key, selectedCells),
                      solved: solvedLetters.containsKey(entry.key),
                      highlighted: selectedCells.contains(entry.key),
                      color: color,
                      size: size,
                      onTap: () => onSelect(_clueFor(entry.value)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _letterAt(GridCell cell, List<GridCell> selectedCells) {
    final solved = solvedLetters[cell];
    if (solved != null) return solved;
    final k = selectedCells.indexOf(cell);
    return k >= 0 && k < typing.length ? typing[k] : '';
  }

  /// Numa casa de cruzamento, tocar de novo troca para a outra palavra.
  int _clueFor(List<int> clues) {
    if (clues.length > 1 && clues.first == selected) return clues[1];
    return clues.first;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.number,
    required this.letter,
    required this.solved,
    required this.highlighted,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final int? number;
  final String letter;
  final bool solved;
  final bool highlighted;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = solved
        ? LigaColors.progressGreen.withValues(alpha: 0.25)
        : highlighted
        ? color.withValues(alpha: 0.22)
        : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: highlighted ? color : LigaColors.ink,
            width: highlighted ? 2.5 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            if (number != null)
              Positioned(
                left: 2,
                top: 0,
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: size * 0.26,
                    fontWeight: FontWeight.w900,
                    color: LigaColors.inkSoft,
                  ),
                ),
              ),
            Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w900,
                  color: solved ? LigaColors.ink : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
