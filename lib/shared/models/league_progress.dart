/// Missão do dia (tabela `missoes` + `progresso_missoes` de hoje).
class DailyMission {
  const DailyMission({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.xp,
    required this.done,
    this.icon,
  });

  final String code;
  final String title;
  final String description;

  /// Atividade que conclui a missão: leitura, texto_reescrita, matematica ou
  /// foto.
  final String type;
  final int xp;
  final bool done;
  final String? icon;
}

/// Medalha do catálogo, conquistada ou não.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.earned,
    this.icon,
  });

  final String id;
  final String name;
  final String description;
  final bool earned;
  final String? icon;
}
