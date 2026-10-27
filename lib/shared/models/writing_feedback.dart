import 'progress_update.dart';

/// Nota da Luma num critério (clareza, organizacao, pontuacao, criatividade).
class WritingCriterion {
  const WritingCriterion({
    required this.id,
    required this.stars,
    required this.comment,
  });

  final String id;

  /// 1 a 3.
  final int stars;
  final String comment;

  String get label => switch (id) {
    'clareza' => 'Clareza',
    'organizacao' => 'Organização',
    'pontuacao' => 'Pontuação',
    'criatividade' => 'Criatividade',
    _ => id,
  };

  static List<WritingCriterion> listFromJson(Object? json) => [
    for (final c in json as List? ?? const [])
      WritingCriterion(
        id: (c as Map)['criterio'] as String? ?? '',
        stars: ((c['estrelas'] as int?) ?? 1).clamp(1, 3),
        comment: c['comentario'] as String? ?? '',
      ),
  ];
}

/// Planejamento do texto: começo, meio e final.
class WritingPlan {
  const WritingPlan({this.start = '', this.middle = '', this.end = ''});

  final String start;
  final String middle;
  final String end;

  Map<String, String> toJson() => {'comeco': start, 'meio': middle, 'fim': end};
}

/// Feedback da versão 1 (Edge Function `oficina-texto`, ação "feedback").
class WritingFeedback {
  const WritingFeedback({
    required this.productionId,
    required this.appropriate,
    required this.criteria,
    required this.strengths,
    required this.suggestions,
    required this.message,
    required this.xp,
    this.progress,
  });

  factory WritingFeedback.fromJson(Map<String, dynamic> json) {
    return WritingFeedback(
      productionId: json['producao_id'] as String,
      appropriate: json['adequado'] as bool? ?? false,
      criteria: WritingCriterion.listFromJson(json['criterios']),
      strengths: List<String>.from(json['pontos_fortes'] as List? ?? const []),
      suggestions: List<String>.from(json['sugestoes'] as List? ?? const []),
      message: json['mensagem'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final String productionId;

  /// `false` quando não era um texto de verdade: a criança tenta de novo.
  final bool appropriate;
  final List<WritingCriterion> criteria;
  final List<String> strengths;
  final List<String> suggestions;
  final String message;
  final int xp;
  final ProgressUpdate? progress;
}

/// Avaliação da reescrita (ação "reescrita").
class RewriteFeedback {
  const RewriteFeedback({
    required this.appropriate,
    required this.evolution,
    required this.criteria,
    required this.improvements,
    required this.nextStep,
    required this.message,
    required this.xp,
    this.progress,
  });

  factory RewriteFeedback.fromJson(Map<String, dynamic> json) {
    return RewriteFeedback(
      appropriate: json['adequado'] as bool? ?? false,
      evolution: json['evolucao'] as int? ?? 0,
      criteria: WritingCriterion.listFromJson(json['criterios']),
      improvements: List<String>.from(json['melhorias'] as List? ?? const []),
      nextStep: json['proximo_passo'] as String? ?? '',
      message: json['mensagem'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool appropriate;

  /// 0 (não mudou) a 3 (melhorou muito).
  final int evolution;
  final List<WritingCriterion> criteria;
  final List<String> improvements;
  final String nextStep;
  final String message;
  final int xp;
  final ProgressUpdate? progress;
}
