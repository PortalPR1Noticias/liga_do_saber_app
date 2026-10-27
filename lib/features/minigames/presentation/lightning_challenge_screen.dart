import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/minigame.dart';
import '../../../shared/services/app_repository.dart';

/// Desafio Relâmpago do Nico: quantas contas você resolve em 60 segundos?
/// Errar não tira ponto; cada acerto soma XP (até 25 por rodada).
class LightningChallengeScreen extends StatefulWidget {
  const LightningChallengeScreen({super.key});

  @override
  State<LightningChallengeScreen> createState() =>
      _LightningChallengeScreenState();
}

class _LightningChallengeScreenState extends State<LightningChallengeScreen> {
  LightningTopic _topic = LightningTopic.tabuada;
  LightningRound? _round;
  final _answers = <int>[];
  String _typed = '';
  bool? _lastHit;
  int _secondsLeft = 0;
  Timer? _timer;
  LightningResult? _result;
  bool _loading = false;
  String? _error;

  bool get _playing => _round != null && _result == null;

  @override
  void dispose() {
    _timer?.cancel();
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

  Future<void> _start() => _run(() async {
    final round = await AppRepository.instance.newLightningRound(_topic);
    if (!mounted) return;
    setState(() {
      _round = round;
      _answers.clear();
      _typed = '';
      _lastHit = null;
      _result = null;
      _secondsLeft = round.seconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish();
    });
  });

  Future<void> _finish() async {
    _timer?.cancel();
    _timer = null;
    final round = _round;
    if (round == null || _result != null || _loading) return;
    await _run(() async {
      final result = await AppRepository.instance.finishLightningRound(
        round.id,
        List.of(_answers),
      );
      if (mounted) setState(() => _result = result);
    });
  }

  void _press(String key) {
    final round = _round;
    if (!_playing || round == null || _loading) return;
    if (key == 'apagar') {
      if (_typed.isNotEmpty) {
        setState(() => _typed = _typed.substring(0, _typed.length - 1));
      }
      return;
    }
    if (key == 'ok') {
      if (_typed.isEmpty) return;
      final answer = int.parse(_typed);
      final question = round.questions[_answers.length];
      setState(() {
        _answers.add(answer);
        _lastHit = answer == question.answer;
        _typed = '';
      });
      if (_answers.length >= round.questions.length) _finish();
      return;
    }
    if (_typed.length < 4) setState(() => _typed += key);
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final textTheme = Theme.of(context).textTheme;
    final hits = round == null
        ? 0
        : [
            for (var i = 0; i < _answers.length; i++)
              if (_answers[i] == round.questions[i].answer) i,
          ].length;
    return Scaffold(
      appBar: AppBar(title: const Text('Desafio Relâmpago')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Desafio Relâmpago',
                  subtitle: 'Quantas contas você resolve em 60 segundos?',
                  color: LigaColors.sunsetOrange,
                  character: LigaCharacter.nico,
                ),
              ),
              const SizedBox(height: 20),
              if (!_playing)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in LightningTopic.values)
                      ChoiceChip(
                        label: Text(topic.label),
                        selected: _topic == topic,
                        onSelected: _loading
                            ? null
                            : (_) => setState(() => _topic = topic),
                      ),
                  ],
                ),
              if (_playing &&
                  round != null &&
                  _answers.length < round.questions.length)
                PopIn(
                  child: LigaPanel(
                    borderColor: LigaColors.sunsetOrange.withValues(alpha: 0.5),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            LigaPill(
                              icon: Icons.timer_rounded,
                              label: '${_secondsLeft}s',
                              color: _secondsLeft <= 10
                                  ? LigaColors.actionCoral
                                  : LigaColors.sunsetOrange,
                            ),
                            const Spacer(),
                            LigaPill(
                              icon: Icons.bolt_rounded,
                              label: '$hits acertos',
                              color: LigaColors.progressGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LigaProgressBar(
                          value: _secondsLeft / round.seconds,
                          color: LigaColors.sunsetOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${round.questions[_answers.length].text} = ?',
                          style: textTheme.headlineMedium?.copyWith(
                            color: LigaColors.ink,
                            shadows: const [],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 140,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _lastHit == null
                                  ? LigaColors.ink
                                  : _lastHit!
                                  ? LigaColors.progressGreen
                                  : LigaColors.actionCoral,
                              width: 3,
                            ),
                          ),
                          child: Text(
                            _typed.isEmpty ? '_' : _typed,
                            key: const ValueKey('relampago-resposta'),
                            style: textTheme.headlineMedium?.copyWith(
                              color: LigaColors.ink,
                              shadows: const [],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _Keypad(onPressed: _press),
                      ],
                    ),
                  ),
                )
              else if (_result == null && !_loading)
                LigaPanel(
                  borderColor: LigaColors.sunsetOrange.withValues(alpha: 0.5),
                  child: Text(
                    'Escolha o tipo de conta e aperte Começar. Errar não '
                    'tira ponto: cada acerto vale XP!',
                    style: textTheme.bodyLarge,
                  ),
                ),
              if (_result != null)
                PopIn(
                  child: LigaPanel(
                    borderColor: LigaColors.progressGreen.withValues(
                      alpha: 0.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fim da rodada!', style: textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Você acertou ${_result!.hits} de '
                          '${_result!.answered} contas.',
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_loading) ...[
                const SizedBox(height: 14),
                const LigaThinkingCard(text: 'O Nico está preparando...'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaErrorCard(message: _error!)),
              ],
              if (_result != null && _result!.notice.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(_result!.notice, style: textTheme.bodyLarge),
              ],
              if (_result?.progress != null) ...[
                const SizedBox(height: 14),
                PopIn(child: LigaRewardCard(progress: _result!.progress!)),
              ],
              const SizedBox(height: 18),
              if (!_playing)
                LigaActionButton(
                  label: _result == null ? 'Começar' : 'Jogar de novo',
                  icon: Icons.bolt_rounded,
                  color: LigaColors.sunsetOrange,
                  onPressed: _loading ? null : _start,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teclado de números grande, para tocar rápido.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.onPressed});

  final ValueChanged<String> onPressed;

  static const _keys = [
    '1', '2', '3', //
    '4', '5', '6', //
    '7', '8', '9', //
    'apagar', '0', 'ok',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2,
      children: [
        for (final key in _keys)
          LigaPressable(
            key: ValueKey('tecla-$key'),
            onTap: () => onPressed(key),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: key == 'ok'
                    ? LigaColors.progressGreen
                    : key == 'apagar'
                    ? LigaColors.actionCoral
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LigaColors.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
                ],
              ),
              child: key == 'apagar'
                  ? const Icon(Icons.backspace_rounded, color: Colors.white)
                  : key == 'ok'
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : Text(
                      key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: LigaColors.ink,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
