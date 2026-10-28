import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design_system/liga_avatar_3d.dart';
import '../../shared/design_system/liga_game.dart';
import '../../shared/design_system/liga_rewards.dart';
import '../../shared/design_system/liga_widgets.dart';
import '../../shared/models/ranking.dart';
import '../../shared/services/app_repository.dart';

/// Ranking da Liga: hoje, semana, mês e geral, pelo XP de acertos.
///
/// Mostra só o nome da Liga, o nível e o avatar de cada criança. Quem o
/// responsável não liberou não aparece para os outros, mas vê a própria
/// posição.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  static const routeName = '/ranking';

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  RankingPeriod _period = RankingPeriod.semana;
  final _cache = <RankingPeriod, Future<Ranking>>{};

  Future<Ranking> _load(RankingPeriod period) =>
      _cache[period] ??= AppRepository.instance.loadRanking(period);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LigaNightBackground(
        glow: LigaColors.achievementYellow,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    LigaPressable(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: LigaNight.glass,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: LigaColors.ink, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: LigaGameText(
                        'Ranking da Liga',
                        size: 26,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    for (final period in RankingPeriod.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: period == RankingPeriod.values.last ? 0 : 6,
                          ),
                          child: _PeriodTab(
                            key: ValueKey('periodo-${period.key}'),
                            label: period.label,
                            selected: period == _period,
                            onTap: () => setState(() => _period = period),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Ranking>(
                  key: ValueKey(_period),
                  future: _load(_period),
                  builder: (context, snapshot) {
                    final error = snapshot.error;
                    if (error != null) {
                      return ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          LigaErrorCard(
                            message: error is AppRepositoryException
                                ? error.message
                                : 'Não consegui carregar o ranking agora.',
                          ),
                        ],
                      );
                    }
                    final ranking = snapshot.data;
                    if (ranking == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _RankingList(ranking: ranking);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.ranking});

  final Ranking ranking;

  @override
  Widget build(BuildContext context) {
    final top = ranking.top;
    final podium = top.take(3).toList();
    final rest = top.skip(3).toList();
    final me = ranking.me;
    final meListed = top.any((entry) => entry.isMe);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        if (!ranking.participating)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Notice(
              key: const Key('rankingPrivado'),
              icon: Icons.lock_rounded,
              text:
                  'Você ainda não aparece para as outras crianças: o seu '
                  'responsável libera no painel dele. Mas a sua posição '
                  'você vê aqui embaixo!',
            ),
          ),
        if (top.isEmpty)
          _Notice(
            icon: Icons.emoji_events_rounded,
            text: switch (ranking.period) {
              RankingPeriod.dia =>
                'Ninguém pontuou hoje ainda. Acerte um desafio e seja o '
                    'primeiro!',
              _ => 'O ranking ainda está vazio. Acerte desafios para pontuar!',
            },
          )
        else
          _Podium(entries: podium),
        const SizedBox(height: 12),
        for (final entry in rest)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Row(entry: entry),
          ),
        if (me != null && !meListed) ...[
          const SizedBox(height: 4),
          const Text(
            'Sua posição',
            style: TextStyle(
              color: LigaNight.textSoft,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          _Row(key: const Key('minhaPosicao'), entry: me),
        ],
        const SizedBox(height: 14),
        Text(
          'O ranking conta o XP dos acertos'
          '${ranking.period == RankingPeriod.geral ? '' : ' no período'}. '
          'Errou? O herói explica e você tenta de novo: quem aprende é quem '
          'sobe! Aqui aparece só o nome da Liga e o avatar de cada um.',
          style: const TextStyle(
            color: LigaNight.textSoft,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<RankingEntry> entries;

  static const _medals = [
    Color(0xFFFFC233),
    Color(0xFFC9D3E6),
    Color(0xFFE0904F),
  ];

  @override
  Widget build(BuildContext context) {
    // Ordem no pódio: 2º, 1º, 3º.
    final order = [if (entries.length > 1) 1, 0, if (entries.length > 2) 2];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final i in order)
          Expanded(
            child: _PodiumSpot(
              entry: entries[i],
              color: _medals[entries[i].position.clamp(1, 3) - 1],
              height: [96.0, 70.0, 52.0][i],
              avatarSize: i == 0 ? 132 : 108,
            ),
          ),
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.entry,
    required this.color,
    required this.height,
    required this.avatarSize,
  });

  final RankingEntry entry;
  final Color color;
  final double height;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LigaAvatar3D(look: entry.look, size: avatarSize, yaw: -0.3),
        const SizedBox(height: 4),
        Text(
          entry.isMe ? 'Você' : entry.leagueName,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: entry.isMe ? LigaColors.achievementYellow : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
            height: 1.1,
          ),
        ),
        Text(
          '${entry.xp} XP',
          style: const TextStyle(
            color: LigaNight.textSoft,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: LigaColors.ink, width: 3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(color, Colors.white, 0.3)!, color],
            ),
          ),
          child: LigaGameText('${entry.position}º', size: 24),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: entry.isMe ? const Color(0xFF1F6F8B) : LigaNight.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isMe ? LigaColors.achievementYellow : LigaColors.ink,
          width: 2.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: LigaGameText('${entry.position}º', size: 18),
          ),
          LigaAvatar3D(look: entry.look, size: 46, bust: true, yaw: -0.3),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                Text(
                  entry.isMe
                      ? 'Você · Nível ${entry.level}'
                      : 'Nível ${entry.level}',
                  style: const TextStyle(
                    color: LigaNight.textSoft,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          LigaHudChip(
            icon: Icons.star_rounded,
            label: '${entry.xp} XP',
            color: LigaColors.achievementYellow,
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: LigaPressable(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? LigaColors.achievementYellow : LigaNight.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LigaColors.ink, width: 2.5),
            boxShadow: const [
              BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: LigaTheme.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: selected ? LigaColors.ink : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LigaNight.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LigaColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: LigaColors.achievementYellow),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
