import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/design_system/liga_widgets.dart';

/// Quebra-cabeça de ordenar: a criança toca numa peça e depois em outra
/// para trocar as duas de lugar. Depois de conferir, as peças no lugar certo
/// ficam verdes e travadas.
///
/// Serve para frases, sequências numéricas, etapas e linhas do tempo.
class OrderPuzzleBoard extends StatefulWidget {
  const OrderPuzzleBoard({
    super.key,
    required this.pieces,
    required this.order,
    required this.onChanged,
    this.locked = const [],
    this.enabled = true,
    this.color = LigaColors.primaryBlue,
  });

  /// Peças como vieram do servidor.
  final List<String> pieces;

  /// Índices de [pieces] na ordem em que estão na tela.
  final List<int> order;
  final ValueChanged<List<int>> onChanged;

  /// Para cada posição, se a peça ali já está certa (não pode mais sair).
  final List<bool> locked;
  final bool enabled;
  final Color color;

  @override
  State<OrderPuzzleBoard> createState() => _OrderPuzzleBoardState();
}

class _OrderPuzzleBoardState extends State<OrderPuzzleBoard> {
  int? _picked;

  bool _isLocked(int position) =>
      position < widget.locked.length && widget.locked[position];

  void _tap(int position) {
    if (_isLocked(position)) return;
    final picked = _picked;
    if (picked == null) {
      setState(() => _picked = position);
      return;
    }
    setState(() => _picked = null);
    if (picked == position) return;
    final order = [...widget.order];
    final swap = order[picked];
    order[picked] = order[position];
    order[position] = swap;
    widget.onChanged(order);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var p = 0; p < widget.order.length; p++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LigaPressable(
              onTap: widget.enabled && !_isLocked(p) ? () => _tap(p) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _isLocked(p)
                      ? LigaColors.progressGreen
                      : _picked == p
                      ? LigaColors.achievementYellow
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LigaColors.ink, width: 3),
                  boxShadow: const [
                    BoxShadow(color: LigaColors.ink, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: LigaColors.ink, width: 2),
                      ),
                      child: Text(
                        '${p + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          shadows: ligaOutline(1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.pieces[widget.order[p]],
                        style: TextStyle(
                          color: _isLocked(p) ? Colors.white : LigaColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          shadows: _isLocked(p) ? ligaOutline(1.2) : null,
                        ),
                      ),
                    ),
                    Icon(
                      _isLocked(p)
                          ? Icons.lock_rounded
                          : Icons.swap_vert_rounded,
                      color: _isLocked(p) ? Colors.white : LigaColors.inkSoft,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
