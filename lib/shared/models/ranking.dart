import 'avatar.dart';

/// Períodos do ranking da Liga. A chave é a de `ranking_liga` (migration
/// 0015); dia, semana e mês contam no horário de Brasília.
enum RankingPeriod {
  dia('dia', 'Hoje'),
  semana('semana', 'Semana'),
  mes('mes', 'Mês'),
  geral('geral', 'Geral');

  const RankingPeriod(this.key, this.label);

  final String key;
  final String label;
}

/// Uma linha do ranking: só o nome da Liga e o avatar, nunca o nome real.
class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.leagueName,
    required this.look,
    required this.level,
    required this.xp,
    this.isMe = false,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
    position: (json['posicao'] as num?)?.toInt() ?? 0,
    leagueName: json['nome_liga'] as String? ?? 'Jogador da Liga',
    look: AvatarLook.fromJson(json['avatar_visual']),
    level: (json['nivel'] as num?)?.toInt() ?? 1,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    isMe: json['eu'] as bool? ?? false,
  );

  final int position;
  final String leagueName;
  final AvatarLook look;
  final int level;

  /// XP de acertos no período.
  final int xp;
  final bool isMe;
}

class Ranking {
  const Ranking({
    required this.period,
    required this.top,
    required this.me,
    required this.participating,
    required this.players,
  });

  factory Ranking.fromJson(RankingPeriod period, Map<String, dynamic> json) {
    final me = json['eu'];
    return Ranking(
      period: period,
      top: [
        for (final row in json['top'] as List? ?? const [])
          RankingEntry.fromJson(Map<String, dynamic>.from(row as Map)),
      ],
      me: me is Map
          ? RankingEntry.fromJson(Map<String, dynamic>.from(me))
          : null,
      participating: json['participa'] as bool? ?? false,
      players: (json['participantes'] as num?)?.toInt() ?? 0,
    );
  }

  final RankingPeriod period;

  /// Os primeiros colocados (até 50).
  final List<RankingEntry> top;

  /// A posição da própria criança (mesmo fora do top ou sem participar).
  final RankingEntry? me;

  /// O responsável liberou a criança no ranking (os outros a veem).
  final bool participating;

  /// Quantas crianças aparecem no ranking do período.
  final int players;
}
