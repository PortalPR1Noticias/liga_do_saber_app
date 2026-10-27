import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';

class MathArenaScreen extends StatefulWidget {
  const MathArenaScreen({super.key});

  static const routeName = '/math';

  @override
  State<MathArenaScreen> createState() => _MathArenaScreenState();
}

class _MathArenaScreenState extends State<MathArenaScreen> {
  bool _showSteps = false;
  int? _chosen;

  static const _options = [6, 8, 12];
  static const _answer = 8;

  static const _steps = [
    'São 24 figurinhas para dividir igualmente entre 3 amigos.',
    'Dividir é repartir em partes iguais: 24 ÷ 3.',
    'Pense na tabuada do 3: 3 × 8 = 24.',
    'Então cada amigo fica com 8 figurinhas.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arena Matemática')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Arena Matemática',
                  subtitle: 'Desafios rápidos com explicação passo a passo.',
                  color: LigaColors.primaryBlue,
                  character: LigaCharacter.nico,
                ),
              ),
              const SizedBox(height: 20),
              PopIn(
                delay: const Duration(milliseconds: 120),
                child: LigaPanel(
                  borderColor: LigaColors.primaryBlue.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LigaPill(
                        icon: Icons.bolt_rounded,
                        label: 'Desafio do Nico · +20 XP',
                        color: LigaColors.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Se 24 figurinhas forem divididas entre 3 amigos, quantas ficam para cada um?',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (final option in _options) ...[
                            Expanded(
                              child: _AnswerChip(
                                value: option,
                                state: _chosen != option
                                    ? _AnswerState.idle
                                    : option == _answer
                                    ? _AnswerState.right
                                    : _AnswerState.wrong,
                                onTap: () => setState(() => _chosen = option),
                              ),
                            ),
                            if (option != _options.last)
                              const SizedBox(width: 10),
                          ],
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _chosen == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  _chosen == _answer
                                      ? 'Acertou! Mandou bem!'
                                      : 'Quase! Tente de novo ou veja o passo a passo.',
                                  style: TextStyle(
                                    color: _chosen == _answer
                                        ? LigaColors.shade(
                                            LigaColors.progressGreen,
                                            0.12,
                                          )
                                        : LigaColors.shade(
                                            LigaColors.actionCoral,
                                            0.12,
                                          ),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LigaActionButton(
                label: 'Ver passo a passo',
                icon: Icons.route_rounded,
                color: LigaColors.primaryBlue,
                onPressed: () => setState(() => _showSteps = !_showSteps),
              ),
              if (_showSteps) ...[
                const SizedBox(height: 18),
                for (var i = 0; i < _steps.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: 90 * i),
                    child: _StepBubble(number: i + 1, text: _steps[i]),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _AnswerState { idle, right, wrong }

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.value,
    required this.state,
    required this.onTap,
  });

  final int value;
  final _AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _AnswerState.idle => LigaColors.primaryBlue,
      _AnswerState.right => LigaColors.progressGreen,
      _AnswerState.wrong => LigaColors.actionCoral,
    };
    final filled = state != _AnswerState.idle;
    return LigaPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: LigaColors.shade(color),
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontFamily: LigaTheme.displayFont,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : LigaColors.ink,
          ),
        ),
      ),
    );
  }
}

class _StepBubble extends StatelessWidget {
  const _StepBubble({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LigaColors.achievementYellow,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: LigaColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LigaPanel(
              padding: const EdgeInsets.all(14),
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
