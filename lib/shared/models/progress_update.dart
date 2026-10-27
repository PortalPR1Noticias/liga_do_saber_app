/// Medalha conquistada agora (vem junto com o XP).
class EarnedBadge {
  const EarnedBadge({required this.id, required this.name, this.icon});

  final String id;
  final String name;

  /// Nome do ícone na tabela `badges` (search, edit, fire, camera...).
  final String? icon;
}

/// O que mudou no progresso depois de uma atividade: devolvido pela função
/// SQL `conceder_xp` através das Edge Functions.
class ProgressUpdate {
  const ProgressUpdate({
    required this.xpGained,
    required this.totalXp,
    required this.level,
    required this.leveledUp,
    required this.streakDays,
    this.missionTitle,
    this.missionXp = 0,
    this.newBadges = const [],
  });

  /// Lê o JSON de `conceder_xp`; `null` quando a atividade não deu XP.
  static ProgressUpdate? fromJson(Object? json) {
    if (json is! Map) return null;
    final mission = json['missao_concluida'];
    return ProgressUpdate(
      xpGained: json['xp_ganho'] as int? ?? 0,
      totalXp: json['xp_total'] as int? ?? 0,
      level: json['nivel'] as int? ?? 1,
      leveledUp: json['subiu_nivel'] as bool? ?? false,
      streakDays: json['sequencia_dias'] as int? ?? 0,
      missionTitle: mission is Map ? mission['titulo'] as String? : null,
      missionXp: mission is Map ? mission['xp'] as int? ?? 0 : 0,
      newBadges: [
        for (final badge in json['medalhas_novas'] as List? ?? const [])
          EarnedBadge(
            id: (badge as Map)['id'] as String,
            name: badge['nome'] as String? ?? '',
            icon: badge['icone'] as String?,
          ),
      ],
    );
  }

  /// XP da atividade mais o bônus da missão do dia.
  final int xpGained;
  final int totalXp;
  final int level;
  final bool leveledUp;
  final int streakDays;

  /// Missão do dia que essa atividade concluiu, se alguma.
  final String? missionTitle;
  final int missionXp;
  final List<EarnedBadge> newBadges;
}
