/// Áreas do progresso por matéria (as mesmas chaves de matéria das Edge
/// Functions).
enum LearningArea {
  portugues('Português'),
  matematica('Matemática'),
  ciencias('Ciências'),
  geografia('Geografia'),
  historia('História'),
  criatividade('Criatividade');

  const LearningArea(this.label);

  final String label;

  static LearningArea? fromKey(String? key) {
    for (final area in values) {
      if (area.name == key) return area;
    }
    return null;
  }

  /// Área das origens de XP que têm matéria fixa. Jogos, expedições, fotos
  /// e provas dependem da matéria de cada atividade.
  static LearningArea? fromOrigin(String origin) => switch (origin) {
    'leitura' || 'texto' || 'texto_reescrita' => LearningArea.portugues,
    'matematica' => LearningArea.matematica,
    'arquivo' => LearningArea.historia,
    'atelie' || 'projeto' => LearningArea.criatividade,
    _ => null,
  };

  /// Uma ideia simples para o responsável apoiar em casa.
  String get parentTip => switch (this) {
    LearningArea.portugues =>
      'Leiam juntos um texto curto (uma notícia, uma receita, um gibi) e '
          'pergunte: "como você sabe disso?".',
    LearningArea.matematica =>
      'Use contas do dia a dia, como conferir o troco ou dividir uma pizza, '
          'e peça para explicar como pensou.',
    LearningArea.ciencias =>
      'Observem juntos algo da natureza, como uma planta ou o tempo lá '
          'fora, e conversem sobre o porquê das coisas.',
    LearningArea.geografia =>
      'Olhem juntos um mapa do bairro ou da cidade e tracem um caminho '
          'que a criança conhece.',
    LearningArea.historia =>
      'Peça para contar uma história da família e colocar os '
          'acontecimentos em ordem.',
    LearningArea.criatividade =>
      'Proponham um pequeno projeto em casa, como desenhar uma invenção '
          'ou montar algo com sucata.',
  };
}

/// Uma atividade que deu XP (linha de `eventos_xp`). O bônus das missões do
/// dia tem a origem `missao` e não tem área.
class LearningEvent {
  const LearningEvent({
    required this.origin,
    required this.xp,
    required this.at,
    this.area,
  });

  final String origin;
  final int xp;
  final DateTime at;
  final LearningArea? area;

  bool get isMission => origin == 'missao';
}

/// Uma atividade aberta (caso, desafio, jogo), tenha dado XP ou não. Junto
/// com os [LearningEvent] mostra onde a criança acerta mais e onde trava.
class LearningAttempt {
  const LearningAttempt({required this.area, required this.at});

  final LearningArea area;
  final DateTime at;
}

/// Tudo o que o progresso e o relatório semanal precisam, lido do
/// histórico da criança.
class LearningLog {
  const LearningLog({this.events = const [], this.attempts = const []});

  final List<LearningEvent> events;
  final List<LearningAttempt> attempts;
}

/// Números de uma área num período.
class AreaProgress {
  const AreaProgress({
    required this.area,
    this.xp = 0,
    this.wins = 0,
    this.attempts = 0,
  });

  final LearningArea area;
  final int xp;

  /// Atividades que deram XP (a criança acertou ou concluiu).
  final int wins;

  /// Atividades abertas. Pode ser menor que [wins] em áreas que não
  /// registram tentativas (texto, projeto, prova).
  final int attempts;

  int get activities => wins > attempts ? wins : attempts;

  /// Quanto das atividades abertas virou vitória (0 a 1), ou null quando
  /// ainda tem pouca coisa para dizer.
  double? get successRate {
    if (attempts < 3) return null;
    final rate = wins / attempts;
    return rate > 1 ? 1 : rate;
  }
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

Map<LearningArea, AreaProgress> _byArea(
  Iterable<LearningEvent> events,
  Iterable<LearningAttempt> attempts,
) {
  final xp = <LearningArea, int>{};
  final wins = <LearningArea, int>{};
  final tries = <LearningArea, int>{};
  for (final e in events) {
    final area = e.area;
    if (area == null) continue;
    xp.update(area, (v) => v + e.xp, ifAbsent: () => e.xp);
    wins.update(area, (v) => v + 1, ifAbsent: () => 1);
  }
  for (final a in attempts) {
    tries.update(a.area, (v) => v + 1, ifAbsent: () => 1);
  }
  return {
    for (final area in LearningArea.values)
      area: AreaProgress(
        area: area,
        xp: xp[area] ?? 0,
        wins: wins[area] ?? 0,
        attempts: tries[area] ?? 0,
      ),
  };
}

/// Área com mais atividades (empate: a de mais XP).
LearningArea? _mostPracticed(Map<LearningArea, AreaProgress> areas) {
  AreaProgress? best;
  for (final p in areas.values) {
    if (p.activities == 0) continue;
    if (best == null ||
        p.activities > best.activities ||
        (p.activities == best.activities && p.xp > best.xp)) {
      best = p;
    }
  }
  return best?.area;
}

/// Áreas onde a criança acerta pouco (menos de 60% das atividades abertas),
/// da mais difícil para a menos.
List<LearningArea> _struggling(Map<LearningArea, AreaProgress> areas) {
  final list =
      areas.values
          .where((p) => p.successRate != null && p.successRate! < 0.6)
          .toList()
        ..sort((a, b) => a.successRate!.compareTo(b.successRate!));
  return [for (final p in list) p.area];
}

/// Áreas onde a criança vai bem (75% ou mais), da melhor para a menos.
List<LearningArea> _strong(Map<LearningArea, AreaProgress> areas) {
  final list =
      areas.values
          .where((p) => p.successRate != null && p.successRate! >= 0.75)
          .toList()
        ..sort((a, b) => b.successRate!.compareTo(a.successRate!));
  return [for (final p in list) p.area];
}

/// Progresso por matéria (aba Conquistas): XP de cada área desde o começo,
/// pontos fortes e a praticar dos últimos 30 dias e o XP dos últimos 7 dias.
class SubjectProgress {
  const SubjectProgress({
    required this.areas,
    required this.strengths,
    required this.toPractice,
    required this.lastDays,
  });

  factory SubjectProgress.fromLog(LearningLog log, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final total = _byArea(log.events, const []);
    final monthStart = today.subtract(const Duration(days: 29));
    final month = _byArea(
      log.events.where((e) => !e.at.isBefore(monthStart)),
      log.attempts.where((a) => !a.at.isBefore(monthStart)),
    );

    final strengths = _strong(month);
    if (strengths.isEmpty) {
      // Sem tentativas suficientes: a área com mais XP é o ponto forte.
      final top = _mostPracticed(total);
      if (top != null) strengths.add(top);
    }
    final toPractice = _struggling(
      month,
    ).where((a) => !strengths.contains(a)).toList();
    if (toPractice.isEmpty) {
      // Ninguém travado: sugere uma área da escola que ainda não foi treinada.
      for (final area in const [
        LearningArea.portugues,
        LearningArea.matematica,
        LearningArea.ciencias,
        LearningArea.geografia,
        LearningArea.historia,
      ]) {
        if (month[area]!.activities == 0) {
          toPractice.add(area);
          break;
        }
      }
    }

    final lastDays = <DateTime, int>{
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)): 0,
    };
    for (final e in log.events) {
      final day = _day(e.at);
      if (lastDays.containsKey(day)) lastDays[day] = lastDays[day]! + e.xp;
    }

    return SubjectProgress(
      areas: [for (final area in LearningArea.values) total[area]!]
        ..sort((a, b) => b.xp.compareTo(a.xp)),
      strengths: strengths.take(2).toList(),
      toPractice: toPractice.take(2).toList(),
      lastDays: lastDays,
    );
  }

  /// Todas as áreas, da que tem mais XP para a que tem menos.
  final List<AreaProgress> areas;
  final List<LearningArea> strengths;
  final List<LearningArea> toPractice;

  /// XP de cada um dos últimos 7 dias, do mais antigo para hoje.
  final Map<DateTime, int> lastDays;

  int get weekXp => lastDays.values.fold(0, (sum, xp) => sum + xp);
}

/// Relatório semanal da Área dos responsáveis: curto, sem linguagem
/// técnica, com o que foi bem, o que treinar e uma sugestão de apoio.
class WeeklyReport {
  const WeeklyReport({
    required this.start,
    required this.end,
    required this.activities,
    required this.previousActivities,
    required this.xp,
    required this.missions,
    required this.activeDays,
    required this.minutes,
    required this.areas,
    required this.summary,
    required this.highlights,
    required this.suggestion,
    this.practiceArea,
  });

  /// Os últimos 7 dias (hoje incluído), comparados com os 7 anteriores.
  factory WeeklyReport.fromLog(
    LearningLog log, {
    required String childName,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final start = _day(clock).subtract(const Duration(days: 6));
    final previousStart = start.subtract(const Duration(days: 7));
    bool inWeek(DateTime t) => !t.isBefore(start);
    bool inPrevious(DateTime t) => !t.isBefore(previousStart) && !inWeek(t);

    final events = log.events.where((e) => inWeek(e.at)).toList();
    final attempts = log.attempts.where((a) => inWeek(a.at)).toList();
    final activities = events.where((e) => !e.isMission).length;
    final previousActivities = log.events
        .where((e) => !e.isMission && inPrevious(e.at))
        .length;
    final missions = events.where((e) => e.isMission).length;
    final xp = events.fold(0, (sum, e) => sum + e.xp);
    final areas = _byArea(events.where((e) => !e.isMission), attempts);

    final moments = [
      for (final e in events) e.at,
      for (final a in attempts) a.at,
    ]..sort();
    final activeDays = {for (final t in moments) _day(t)}.length;

    final top = _mostPracticed(areas);
    final strong = _strong(areas);
    final struggling = _struggling(areas);
    final practiceArea = struggling.isNotEmpty ? struggling.first : null;
    final good = strong.isNotEmpty ? strong.first : null;

    final String summary;
    if (activities == 0 && attempts.isEmpty) {
      summary =
          'Nesta semana, $childName ainda não jogou nenhuma missão na Liga.';
    } else {
      final parts = <String>[
        if (top != null)
          'Nesta semana, $childName praticou mais ${top.label}.'
        else
          'Nesta semana, $childName começou novas missões.',
        if (good != null && practiceArea != null)
          'Foi bem em ${good.label}, mas ainda precisa treinar '
              '${practiceArea.label}.'
        else if (good != null)
          'Foi muito bem em ${good.label}.'
        else if (practiceArea != null)
          'Ainda precisa treinar ${practiceArea.label}.',
      ];
      summary = parts.join(' ');
    }

    final highlights = <String>[
      if (activities > 0)
        'Concluiu $activities ${activities == 1 ? 'atividade' : 'atividades'} '
            'e ganhou $xp XP.',
      if (activities > previousActivities && previousActivities > 0)
        'Fez mais atividades que na semana anterior '
            '($activities contra $previousActivities).',
      if (good != null)
        'Acertou bem em ${good.label}: venceu '
            '${areas[good]!.wins.clamp(0, areas[good]!.attempts)} de '
            '${areas[good]!.attempts} desafios.',
      if (missions > 0)
        'Completou $missions ${missions == 1 ? 'missão' : 'missões'} do dia.',
      if (activeDays >= 3) 'Estudou em $activeDays dias diferentes.',
    ];

    final tipArea =
        practiceArea ??
        (top == null
            ? null
            : const [
                LearningArea.portugues,
                LearningArea.matematica,
                LearningArea.ciencias,
              ].firstWhere(
                (a) => areas[a]!.activities == 0,
                orElse: () => top,
              ));
    final suggestion = tipArea == null
        ? 'Combinem um horário curto, de 10 a 15 minutos, para $childName '
              'jogar uma missão por dia. A sequência de dias ajuda a criar o '
              'hábito.'
        : tipArea.parentTip;

    return WeeklyReport(
      start: start,
      end: _day(clock),
      activities: activities,
      previousActivities: previousActivities,
      xp: xp,
      missions: missions,
      activeDays: activeDays,
      minutes: _estimateMinutes(moments),
      areas: [
        for (final p in areas.values)
          if (p.activities > 0) p,
      ]..sort((a, b) => b.activities.compareTo(a.activities)),
      summary: summary,
      highlights: highlights,
      suggestion: suggestion,
      practiceArea: tipArea,
    );
  }

  final DateTime start;
  final DateTime end;
  final int activities;
  final int previousActivities;
  final int xp;
  final int missions;
  final int activeDays;

  /// Tempo de uso educativo estimado pelos horários das atividades.
  final int minutes;

  /// Áreas praticadas na semana, da mais praticada para a menos.
  final List<AreaProgress> areas;
  final String summary;
  final List<String> highlights;
  final String suggestion;

  /// Área da sugestão (a que precisa de treino ou a que ficou de fora).
  final LearningArea? practiceArea;
}

/// Junta as atividades em sessões (intervalo de até 20 minutos entre uma e
/// outra) e soma a duração de cada sessão, com 3 minutos para a última
/// atividade dela.
int _estimateMinutes(List<DateTime> sortedMoments) {
  if (sortedMoments.isEmpty) return 0;
  var total = 0;
  var sessionStart = sortedMoments.first;
  var last = sortedMoments.first;
  for (final t in sortedMoments.skip(1)) {
    if (t.difference(last).inMinutes > 20) {
      total += last.difference(sessionStart).inMinutes + 3;
      sessionStart = t;
    }
    last = t;
  }
  return total + last.difference(sessionStart).inMinutes + 3;
}
