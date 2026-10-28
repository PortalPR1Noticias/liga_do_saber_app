import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_game.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_rewards.dart';
import '../../../shared/design_system/liga_sound.dart';
import '../../../shared/design_system/liga_victory.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import '../world_islands.dart';
import 'boss_sources.dart';

enum _Stage { intro, loading, fighting, grading, won, lost, error }

/// Batalha contra o chefão no fim de uma ilha. Cada pergunta é um ataque:
/// acertar tira vida do chefão; errar custa um coração e o herói da ilha
/// explica o raciocínio antes de a criança tentar de novo.
class BossBattleScreen extends StatefulWidget {
  const BossBattleScreen({super.key, required this.island});

  final LigaIsland island;

  /// Abre a batalha; devolve `true` quando a criança vence.
  static Future<bool?> open(BuildContext context, LigaIsland island) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BossBattleScreen(island: island)),
    );
  }

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends State<BossBattleScreen> {
  static const _maxHearts = 3;

  late BossSource _source;
  _Stage _stage = _Stage.intro;
  String _error = '';

  /// Vida do chefão, de 0 a 1.
  double _hp = 1;
  int _hearts = _maxHearts;
  int _combo = 0;
  int _mistakes = 0;
  int _hitTick = 0;

  // Ataque atual.
  int _round = 0;
  BossAttack? _attack;
  final _wrong = <int>{};
  int? _right;
  String _hint = '';
  bool _answering = false;

  // Batalha em lote (Luma e Zuri).
  List<BossAttack> _attacks = const [];
  final _choices = <int>[];
  List<BossVerdict> _verdicts = const [];

  int _stars = 0;
  bool _firstWin = false;

  LigaIsland get _island => widget.island;
  LigaCharacter get _hero => _island.character;

  @override
  void initState() {
    super.initState();
    _source = _island.bossSource();
  }

  /// Pausa curta entre os golpes (some nos testes, sem animações).
  Future<void> _beat(int ms) {
    if (!LigaMotion.of(context)) return Future.value();
    return Future.delayed(Duration(milliseconds: ms));
  }

  Future<void> _start() async {
    setState(() {
      _source = _island.bossSource();
      _stage = _Stage.loading;
      _hp = 1;
      _hearts = _maxHearts;
      _combo = 0;
      _mistakes = 0;
      _round = 0;
      _choices.clear();
      _verdicts = const [];
      _attacks = const [];
    });
    final source = _source;
    try {
      switch (source) {
        case ImmediateBossSource():
          await _loadAttack(source);
        case BatchBossSource():
          final attacks = await source.load();
          if (!mounted) return;
          setState(() {
            _attacks = attacks;
            _attack = attacks.first;
            _stage = _Stage.fighting;
          });
      }
    } on AppRepositoryException catch (error) {
      _fail(error.message);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.error;
      _error = message;
    });
  }

  Future<void> _loadAttack(ImmediateBossSource source) async {
    setState(() {
      _stage = _Stage.loading;
      _wrong.clear();
      _right = null;
      _hint = '';
    });
    final attack = await source.nextAttack(_round);
    if (!mounted) return;
    setState(() {
      _attack = attack;
      _stage = _Stage.fighting;
    });
  }

  Future<void> _choose(int choice) async {
    final source = _source;
    switch (source) {
      case ImmediateBossSource():
        await _answerNow(source, choice);
      case BatchBossSource():
        await _collect(source, choice);
    }
  }

  Future<void> _answerNow(ImmediateBossSource source, int choice) async {
    setState(() => _answering = true);
    try {
      final verdict = await source.answer(choice);
      if (!mounted) return;
      if (verdict.hit) {
        setState(() {
          _right = choice;
          _combo++;
          _hitTick++;
          _hp = math.max(0, _hp - 1 / source.rounds);
          _hint = '';
        });
        await _beat(900);
        if (!mounted) return;
        _round++;
        if (_round >= source.rounds) {
          await _win(_mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1));
        } else {
          await _loadAttack(source);
        }
      } else {
        setState(() {
          _wrong.add(choice);
          _combo = 0;
          _mistakes++;
          _hearts--;
          _hint = verdict.hint.isEmpty
              ? 'Releia com calma: a resposta está nos detalhes.'
              : verdict.hint;
        });
        if (_hearts <= 0) {
          await _beat(1400);
          if (mounted) setState(() => _stage = _Stage.lost);
        }
      }
    } on AppRepositoryException catch (error) {
      _fail(error.message);
    } finally {
      if (mounted) setState(() => _answering = false);
    }
  }

  Future<void> _collect(BatchBossSource source, int choice) async {
    setState(() {
      _choices.add(choice);
      _right = choice;
    });
    await _beat(350);
    if (!mounted) return;
    if (_choices.length < _attacks.length) {
      setState(() {
        _round = _choices.length;
        _attack = _attacks[_round];
        _right = null;
      });
      return;
    }
    setState(() => _stage = _Stage.grading);
    try {
      final verdicts = await source.grade(List.of(_choices));
      if (!mounted) return;
      setState(() => _verdicts = verdicts);
      // O golpe final: cada resposta certa acerta o chefão.
      for (final verdict in verdicts) {
        await _beat(450);
        if (!mounted) return;
        if (verdict.hit) {
          LigaSound.play(LigaSfx.acerto);
          setState(() {
            _hitTick++;
            _hp = math.max(0, _hp - 1 / verdicts.length);
          });
        } else {
          LigaSound.play(LigaSfx.erro);
          setState(() => _mistakes++);
        }
      }
      final hits = verdicts.where((v) => v.hit).length;
      final needed = (verdicts.length * 0.6).ceil();
      if (hits >= needed) {
        await _win(
          hits == verdicts.length ? 3 : (hits / verdicts.length >= 0.8 ? 2 : 1),
        );
      } else {
        setState(() => _stage = _Stage.lost);
      }
    } on AppRepositoryException catch (error) {
      _fail(error.message);
    }
  }

  Future<void> _win(int stars) async {
    setState(() {
      _hp = 0;
      _stars = stars;
      _stage = _Stage.won;
    });
    try {
      final progress = await AppRepository.instance.registerBossWin(
        _island.id,
        stars,
      );
      if (!mounted) return;
      setState(() => _firstWin = progress != null && progress.xpGained > 0);
      if (progress != null) LigaVictory.maybeShow(context, progress);
    } on AppRepositoryException catch (error) {
      _fail(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LigaNight.deep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _hero.scene,
            fit: BoxFit.cover,
            color: const Color(0xB3200414),
            colorBlendMode: BlendMode.multiply,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x55FF4757), Color(0xE60A0F2E)],
                stops: [0, 0.55],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _TopBar(
                  boss: _island.boss,
                  hp: _hp,
                  hearts: _source is ImmediateBossSource ? _hearts : null,
                  progressLabel:
                      _source is BatchBossSource && _attacks.isNotEmpty
                      ? 'Pergunta ${math.min(_choices.length + 1, _attacks.length)}'
                            ' de ${_attacks.length}'
                      : null,
                  onClose: () =>
                      Navigator.of(context).pop(_stage == _Stage.won),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _BossFigure(
                        color: _bossColor,
                        icon: _island.bossIcon,
                        hitTick: _hitTick,
                        defeated: _stage == _Stage.won,
                      ),
                      if (_combo >= 2 && _stage == _Stage.fighting)
                        Positioned(
                          left: 0,
                          top: 10,
                          child: Transform.rotate(
                            angle: -0.15,
                            child: LigaGameText(
                              'COMBO x$_combo',
                              size: 22,
                              color: LigaColors.sunsetOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ..._body(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _bossColor => switch (_hero) {
    LigaCharacter.nico => const Color(0xFF8A93A8),
    LigaCharacter.luma => const Color(0xFF6B4FA0),
    LigaCharacter.teo => const Color(0xFF3F6E8C),
    LigaCharacter.mila => const Color(0xFFA0784F),
    LigaCharacter.zuri => const Color(0xFFB0603A),
  };

  List<Widget> _body() {
    switch (_stage) {
      case _Stage.intro:
        return [
          LigaGameText(_island.boss, size: 30, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          _HeroSays(
            hero: _hero,
            text: _source is ImmediateBossSource
                ? 'Cada pergunta é um ataque do chefão. Acerte para revidar! '
                      'Se errar, eu te explico e você tenta de novo. '
                      'Você tem $_maxHearts corações.'
                : 'Responda todas as perguntas para juntar as pistas. No fim, '
                      'cada resposta certa vira um golpe no chefão!',
          ),
          const SizedBox(height: 18),
          LigaPlayButton(
            label: 'LUTAR!',
            color: const Color(0xFFFF4757),
            textColor: Colors.white,
            onPressed: _start,
          ),
        ];
      case _Stage.loading:
        return [
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          LigaGameText(
            '${_island.boss} prepara um ataque...',
            size: 18,
            textAlign: TextAlign.center,
          ),
        ];
      case _Stage.grading:
        return [
          const SizedBox(height: 10),
          const LigaGameText(
            'GOLPE FINAL!',
            size: 30,
            color: LigaColors.achievementYellow,
            textAlign: TextAlign.center,
          ),
          if (_verdicts.isEmpty) ...[
            const SizedBox(height: 14),
            const Center(child: CircularProgressIndicator()),
          ],
        ];
      case _Stage.fighting:
        return _fight();
      case _Stage.won:
        return [
          const LigaGameText(
            'CHEFÃO VENCIDO!',
            size: 30,
            color: LigaColors.achievementYellow,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var s = 0; s < 3; s++)
                Icon(
                  Icons.star_rounded,
                  size: 48,
                  color: s < _stars
                      ? LigaColors.achievementYellow
                      : const Color(0x55FFFFFF),
                  shadows: ligaOutline(1.5),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _HeroSays(
            hero: _hero,
            text: _stars == 3
                ? 'Sem nenhum erro! Você domina essa ilha.'
                : 'Você venceu! Para ganhar 3 estrelas, enfrente o chefão de '
                      'novo sem errar.',
          ),
          if (_firstWin) ...[
            const SizedBox(height: 8),
            const Center(child: LigaGameText('+50 XP de bônus', size: 18)),
          ],
          ..._recap(),
          const SizedBox(height: 18),
          LigaPlayButton(
            label: 'VOLTAR AO MAPA',
            color: LigaColors.primaryBlue,
            textColor: Colors.white,
            height: 64,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ];
      case _Stage.lost:
        return [
          LigaGameText(
            '${_island.boss} venceu desta vez',
            size: 24,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _HeroSays(
            hero: _hero,
            text:
                'Faz parte! Veja as dicas, treine mais uma fase e volte. '
                'Cada erro é uma pista do que estudar.',
          ),
          ..._recap(),
          const SizedBox(height: 18),
          LigaPlayButton(
            label: 'TENTAR DE NOVO',
            color: const Color(0xFFFF4757),
            textColor: Colors.white,
            height: 64,
            onPressed: _start,
          ),
          const SizedBox(height: 12),
          LigaActionButton(
            label: 'Voltar ao mapa',
            icon: Icons.map_rounded,
            color: LigaColors.primaryBlue,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ];
      case _Stage.error:
        return [
          LigaErrorCard(message: _error),
          const SizedBox(height: 14),
          LigaActionButton(
            label: 'Tentar de novo',
            icon: Icons.refresh_rounded,
            onPressed: _start,
          ),
        ];
    }
  }

  List<Widget> _fight() {
    final attack = _attack!;
    final batch = _source is BatchBossSource;
    return [
      if (attack.context.isNotEmpty)
        LigaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (attack.contextTitle.isNotEmpty) ...[
                Text(
                  attack.contextTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
              ],
              Text(
                attack.context,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LigaColors.ink, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAAFF4757),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F3), Color(0xFFFFD0D6)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              batch ? 'Junte a pista:' : 'Bloqueie o ataque!',
              style: const TextStyle(
                color: Color(0xFFD12C45),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              attack.prompt,
              style: const TextStyle(
                color: LigaColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
      if (_hint.isNotEmpty) ...[
        const SizedBox(height: 12),
        _HeroSays(
          hero: _hero,
          text: _hint,
          title: 'Dica d${_article(_hero)} ${_hero.displayName}',
        ),
      ],
      const SizedBox(height: 14),
      for (var o = 0; o < attack.options.length; o++)
        LigaChoiceButton(
          key: ValueKey('ataque-$_round-$o'),
          label: attack.options[o],
          color: _hero.color,
          state: _right == o
              ? (batch ? LigaChoiceState.selected : LigaChoiceState.right)
              : _wrong.contains(o)
              ? LigaChoiceState.wrong
              : LigaChoiceState.idle,
          onTap: _answering || _right != null || _wrong.contains(o)
              ? null
              : () => _choose(o),
        ),
    ];
  }

  /// O que a criança errou, com a explicação de cada uma.
  List<Widget> _recap() {
    final misses = [
      for (var i = 0; i < _verdicts.length; i++)
        if (!_verdicts[i].hit && _verdicts[i].hint.isNotEmpty)
          (i < _attacks.length ? _attacks[i].prompt : '', _verdicts[i].hint),
    ];
    if (misses.isEmpty) return const [];
    return [
      const SizedBox(height: 14),
      const LigaGameText('Para revisar', size: 18),
      const SizedBox(height: 8),
      for (final (prompt, hint) in misses)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LigaPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prompt, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(hint, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
    ];
  }

  static String _article(LigaCharacter hero) =>
      hero == LigaCharacter.luma || hero == LigaCharacter.mila ? 'a' : 'o';
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.boss,
    required this.hp,
    required this.hearts,
    required this.progressLabel,
    required this.onClose,
  });

  final String boss;
  final double hp;
  final int? hearts;
  final String? progressLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Sair da batalha',
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LigaNight.glass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LigaColors.ink, width: 2.5),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: LigaGameText(boss, size: 16, maxLines: 1)),
                  Text(
                    '${(hp * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0x73000000),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: LigaColors.ink, width: 2.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 350),
                      widthFactor: hp.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFF9AA8), Color(0xFFFF4757)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (hearts != null)
                Row(
                  children: [
                    for (var h = 0; h < 3; h++)
                      Icon(
                        Icons.favorite_rounded,
                        size: 20,
                        color: h < hearts!
                            ? LigaColors.actionCoral
                            : const Color(0xFF4A3A5A),
                      ),
                  ],
                )
              else if (progressLabel != null)
                Text(
                  progressLabel!,
                  style: const TextStyle(
                    color: LigaNight.textSoft,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// O herói da ilha falando com a criança.
class _HeroSays extends StatelessWidget {
  const _HeroSays({required this.hero, required this.text, this.title = ''});

  final LigaCharacter hero;
  final String text;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LigaPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LigaPortrait(character: hero, size: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      color: LigaColors.shade(hero.color, 0.1),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O chefão em blocos, com olhos brilhando. Treme quando leva um golpe.
class _BossFigure extends StatefulWidget {
  const _BossFigure({
    required this.color,
    required this.icon,
    required this.hitTick,
    required this.defeated,
  });

  final Color color;
  final IconData icon;
  final int hitTick;
  final bool defeated;

  @override
  State<_BossFigure> createState() => _BossFigureState();
}

class _BossFigureState extends State<_BossFigure>
    with SingleTickerProviderStateMixin {
  late final _hit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(_BossFigure old) {
    super.didUpdateWidget(old);
    if (old.hitTick != widget.hitTick && LigaMotion.of(context)) {
      _hit.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hit.dispose();
    super.dispose();
  }

  Widget _block(double w, double h, {Widget? child}) {
    final face = widget.color;
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LigaColors.ink, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(face, Colors.white, 0.25)!, face],
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eye = Container(
      width: 14,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFFF4757), blurRadius: 10, spreadRadius: 2),
        ],
      ),
    );
    final figure = SizedBox(
      width: 150,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 54,
            child: Transform.rotate(angle: 0.2, child: _block(28, 66)),
          ),
          Positioned(
            right: 0,
            top: 54,
            child: Transform.rotate(angle: -0.2, child: _block(28, 66)),
          ),
          Positioned(left: 38, top: 118, child: _block(32, 40)),
          Positioned(right: 38, top: 118, child: _block(32, 40)),
          Positioned(
            left: 26,
            top: 50,
            child: _block(
              98,
              72,
              child: Icon(
                widget.icon,
                size: 36,
                color: LigaColors.cyanGlow,
                shadows: const [
                  Shadow(color: LigaColors.cyanGlow, blurRadius: 12),
                ],
              ),
            ),
          ),
          Positioned(
            left: 42,
            top: 0,
            child: _block(
              66,
              54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [eye, eye],
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _hit,
      builder: (context, child) {
        final t = _hit.value;
        final shake = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Opacity(
          opacity: widget.defeated ? 0.35 : 1,
          child: Transform.translate(
            offset: Offset(shake, 0),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: t > 0 && t < 0.4 ? 0.6 : 0),
                BlendMode.srcATop,
              ),
              child: child,
            ),
          ),
        );
      },
      child: LigaBob(
        distance: 5,
        duration: const Duration(milliseconds: 1100),
        child: figure,
      ),
    );
  }
}
