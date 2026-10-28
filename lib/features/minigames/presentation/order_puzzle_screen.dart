import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/design_system/liga_report_button.dart';
import '../../../shared/models/minigame.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';
import 'minigame_style.dart';
import 'widgets/order_puzzle_board.dart';

/// Quebra-cabeça: a IA cria peças (pedaços de frase, números, etapas de um
/// processo) e a criança monta na ordem certa. A cada conferida, as peças no
/// lugar ficam travadas. Montar de primeira vale 20 XP; depois, 10.
class OrderPuzzleScreen extends StatefulWidget {
  const OrderPuzzleScreen({
    super.key,
    this.subject = MinigameSubject.portugues,
  });

  final MinigameSubject subject;

  @override
  State<OrderPuzzleScreen> createState() => _OrderPuzzleScreenState();
}

class _OrderPuzzleScreenState extends State<OrderPuzzleScreen> {
  late MinigameSubject _subject = widget.subject;
  OrderPuzzle? _puzzle;
  List<int> _order = const [];
  List<bool> _locked = const [];
  int _checks = 0;
  bool _solved = false;
  String _explanation = '';
  ProgressUpdate? _progress;
  String _notice = '';
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

  Future<void> _newPuzzle() => _run(() async {
    final puzzle = await AppRepository.instance.newOrderPuzzle(_subject);
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _order = [for (var i = 0; i < puzzle.pieces.length; i++) i];
      _locked = const [];
      _checks = 0;
      _solved = false;
      _explanation = '';
      _progress = null;
      _notice = '';
    });
  });

  Future<void> _check() => _run(() async {
    final result = await AppRepository.instance.checkOrderPuzzle(
      _puzzle!.id,
      _order,
    );
    if (!mounted) return;
    setState(() {
      _checks++;
      _locked = result.rightPlaces;
      _solved = result.solved;
      _explanation = result.explanation;
      if (result.progress != null) _progress = result.progress;
      if (result.notice.isNotEmpty) _notice = result.notice;
    });
  });

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    final color = _subject.color;
    final textTheme = Theme.of(context).textTheme;
    final rightCount = _locked.where((r) => r).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quebra-cabeça'),
        actions: [
          LigaReportAiButton(module: 'minijogo', reference: () => _puzzle?.id),
        ],
      ),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              PopIn(
                child: LigaFeatureHeader(
                  title: 'Quebra-cabeça',
                  subtitle: 'Troque as peças de lugar até tudo fazer sentido.',
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
              if (puzzle != null)
                PopIn(
                  child: LigaPanel(
                    borderColor: color.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigaPill(
                          icon: Icons.extension_rounded,
                          label: 'Quebra-cabeça · +${puzzle.xp} XP',
                          color: color,
                        ),
                        const SizedBox(height: 10),
                        if (puzzle.title.isNotEmpty) ...[
                          Text(puzzle.title, style: textTheme.titleLarge),
                          const SizedBox(height: 4),
                        ],
                        Text(puzzle.instruction, style: textTheme.bodyLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Toque numa peça e depois em outra para trocar.',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        OrderPuzzleBoard(
                          pieces: puzzle.pieces,
                          order: _order,
                          locked: _locked,
                          enabled: !_loading && !_solved,
                          color: color,
                          onChanged: (order) => setState(() => _order = order),
                        ),
                        if (_checks > 0)
                          Text(
                            _solved
                                ? 'Montou! Tudo no lugar!'
                                : '$rightCount de ${_order.length} no lugar. '
                                      'As verdes já estão certas, continue!',
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
                      ],
                    ),
                  ),
                )
              else if (!_loading)
                LigaPanel(
                  borderColor: color.withValues(alpha: 0.5),
                  child: Text(
                    'Frases, números, etapas e linhas do tempo para montar. '
                    'Acertar de primeira vale 20 XP!',
                    style: textTheme.bodyLarge,
                  ),
                ),
              if (_explanation.isNotEmpty) ...[
                const SizedBox(height: 14),
                PopIn(
                  child: LigaSpeechBubble(text: _explanation, color: color),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(text: 'Misturando as peças...'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaErrorCard(message: _error!)),
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
              if (puzzle != null && !_solved)
                LigaActionButton(
                  label: 'Conferir',
                  icon: Icons.check_rounded,
                  color: color,
                  onPressed: _loading ? null : _check,
                ),
              const SizedBox(height: 12),
              LigaActionButton(
                label: puzzle == null
                    ? 'Começar quebra-cabeça'
                    : 'Novo quebra-cabeça',
                icon: Icons.extension_rounded,
                onPressed: _loading ? null : _newPuzzle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
