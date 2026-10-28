/// Avaliação de desempenho da criança, da função SQL `avaliacao_desempenho`
/// (migration 0014). Aparece no painel do responsável e no do professor.
class PerformanceReport {
  const PerformanceReport({
    required this.periodDays,
    required this.level,
    required this.totalXp,
    required this.streakDays,
    required this.activeDays,
    required this.activeDaysWeek,
    required this.xpWeek,
    required this.areas,
    required this.exams,
    this.lastActivity,
  });

  factory PerformanceReport.fromJson(Map<String, dynamic> json) {
    return PerformanceReport(
      periodDays: json['periodo_dias'] as int? ?? 30,
      level: json['nivel'] as int? ?? 1,
      totalXp: json['xp_total'] as int? ?? 0,
      streakDays: json['sequencia_dias'] as int? ?? 0,
      lastActivity: DateTime.tryParse(
        json['ultima_atividade_em'] as String? ?? '',
      ),
      activeDays: json['dias_ativos'] as int? ?? 0,
      activeDaysWeek: json['dias_ativos_semana'] as int? ?? 0,
      xpWeek: json['xp_semana'] as int? ?? 0,
      areas: [
        for (final area in json['areas'] as List? ?? const [])
          AreaPerformance.fromJson(Map<String, dynamic>.from(area as Map)),
      ],
      exams: [
        for (final exam in json['provas'] as List? ?? const [])
          ExamPerformance.fromJson(Map<String, dynamic>.from(exam as Map)),
      ],
    );
  }

  final int periodDays;
  final int level;
  final int totalXp;
  final int streakDays;
  final DateTime? lastActivity;

  /// Dias com alguma atividade que deu XP no período e nos últimos 7 dias.
  final int activeDays;
  final int activeDaysWeek;
  final int xpWeek;
  final List<AreaPerformance> areas;

  /// Revanche da prova: as provas reais que o responsável mandou.
  final List<ExamPerformance> exams;

  /// Ritmo da semana, numa frase.
  String get rhythm {
    if (activeDaysWeek >= 4) {
      return 'Ótimo ritmo: praticou em $activeDaysWeek dos últimos 7 dias.';
    }
    if (activeDaysWeek >= 2) {
      return 'Bom começo: praticou em $activeDaysWeek dos últimos 7 dias. '
          'Mais um ou dois dias por semana ajudam a fixar.';
    }
    if (activeDaysWeek == 1) {
      return 'Praticou em 1 dos últimos 7 dias. Vale combinar dias fixos.';
    }
    return 'Não praticou nos últimos 7 dias.';
  }

  /// Áreas em que vai bem.
  List<AreaPerformance> get strengths => [
    for (final area in areas)
      if (area.status == PerformanceStatus.strong) area,
  ];

  /// Áreas que pedem reforço.
  List<AreaPerformance> get needsAttention => [
    for (final area in areas)
      if (area.status == PerformanceStatus.needsPractice) area,
  ];

  /// Acertos nas questões da Revanche (de todas as provas do período).
  double? get examAccuracy {
    final total = exams.fold<int>(0, (sum, exam) => sum + exam.totalQuestions);
    if (total == 0) return null;
    final right = exams.fold<int>(0, (sum, exam) => sum + exam.rightAnswers);
    return right / total;
  }
}

enum PerformanceStatus {
  /// Ainda não abriu nenhuma atividade da área no período.
  noData('Ainda não praticou'),

  /// Poucas atividades para avaliar.
  starting('Começando'),
  strong('Mandando bem'),
  developing('Em evolução'),
  needsPractice('Precisa de reforço'),

  /// Áreas em que só faz sentido contar o uso (Foto da tarefa).
  usage('Uso');

  const PerformanceStatus(this.label);

  final String label;
}

class AreaPerformance {
  const AreaPerformance({
    required this.key,
    required this.name,
    required this.completed,
    required this.completedWeek,
    required this.opened,
    required this.xp,
  });

  factory AreaPerformance.fromJson(Map<String, dynamic> json) {
    return AreaPerformance(
      key: json['area'] as String,
      name: json['nome'] as String,
      completed: json['concluidas'] as int? ?? 0,
      completedWeek: json['concluidas_semana'] as int? ?? 0,
      opened: json['abertas'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
    );
  }

  /// Menos que isso no período ainda não dá para avaliar.
  static const minimumToEvaluate = 3;

  final String key;
  final String name;

  /// Atividades que deram XP (acertou ou concluiu).
  final int completed;
  final int completedWeek;

  /// Atividades abertas (inclui as que não acertou ou abandonou).
  final int opened;
  final int xp;

  /// Aproveitamento: atividades concluídas sobre abertas.
  double? get rate => opened == 0 ? null : (completed / opened).clamp(0.0, 1.0);

  PerformanceStatus get status {
    if (key == 'foto') {
      return opened == 0 ? PerformanceStatus.noData : PerformanceStatus.usage;
    }
    final value = rate;
    if (value == null) return PerformanceStatus.noData;
    if (opened < minimumToEvaluate) return PerformanceStatus.starting;
    if (value >= 0.75) return PerformanceStatus.strong;
    if (value >= 0.5) return PerformanceStatus.developing;
    return PerformanceStatus.needsPractice;
  }
}

class ExamPerformance {
  const ExamPerformance({
    required this.title,
    required this.subject,
    required this.totalQuestions,
    required this.rightAnswers,
    required this.stars,
    required this.won,
    this.sentAt,
  });

  factory ExamPerformance.fromJson(Map<String, dynamic> json) {
    return ExamPerformance(
      title: json['titulo'] as String? ?? 'Prova',
      subject: json['materia'] as String? ?? '',
      totalQuestions: json['total_questoes'] as int? ?? 0,
      rightAnswers: json['questoes_acertadas'] as int? ?? 0,
      stars: json['estrelas'] as int? ?? 0,
      won: json['vencida'] as bool? ?? false,
      sentAt: DateTime.tryParse(json['enviada_em'] as String? ?? ''),
    );
  }

  final String title;
  final String subject;
  final int totalQuestions;
  final int rightAnswers;
  final int stars;
  final bool won;
  final DateTime? sentAt;
}

/// Criança no painel do professor: o nome é o que o responsável escolheu.
class TeacherStudent {
  const TeacherStudent({
    required this.linkId,
    required this.name,
    required this.schoolYear,
    required this.avatarId,
    required this.report,
  });

  factory TeacherStudent.fromJson(Map<String, dynamic> json) {
    return TeacherStudent(
      linkId: json['vinculo_id'] as String,
      name: json['nome'] as String,
      schoolYear: json['ano_escolar'] as int? ?? 5,
      avatarId: json['avatar_id'] as String? ?? 'estrategista',
      report: PerformanceReport.fromJson(
        Map<String, dynamic>.from(json['desempenho'] as Map),
      ),
    );
  }

  final String linkId;
  final String name;
  final int schoolYear;
  final String avatarId;
  final PerformanceReport report;
}
