import 'progress_update.dart';

/// Pergunta de um caso do Detetive da Leitura (sem a resposta certa, que
/// fica no servidor).
class ReadingQuestion {
  const ReadingQuestion({
    required this.skill,
    required this.question,
    required this.options,
  });

  /// ideia_principal, inferencia ou localizar.
  final String skill;
  final String question;
  final List<String> options;

  String get skillLabel => switch (skill) {
    'ideia_principal' => 'Ideia principal',
    'inferencia' => 'Inferência',
    'localizar' => 'Localizar a pista',
    _ => 'Pergunta',
  };
}

/// Caso criado pela IA na Edge Function `detetive-leitura`.
class ReadingCase {
  const ReadingCase({
    required this.id,
    required this.title,
    required this.text,
    required this.intro,
    required this.questions,
    this.xpPerHit = 10,
  });

  factory ReadingCase.fromJson(Map<String, dynamic> json) {
    return ReadingCase(
      id: json['caso_id'] as String,
      title: json['titulo'] as String? ?? '',
      text: json['texto'] as String? ?? '',
      intro: json['mensagem_inicial'] as String? ?? '',
      questions: [
        for (final q in json['perguntas'] as List? ?? const [])
          ReadingQuestion(
            skill: (q as Map)['habilidade'] as String? ?? '',
            question: q['pergunta'] as String? ?? '',
            options: List<String>.from(q['opcoes'] as List? ?? const []),
          ),
      ],
      xpPerHit: json['xp_por_acerto'] as int? ?? 10,
    );
  }

  final String id;
  final String title;
  final String text;
  final String intro;
  final List<ReadingQuestion> questions;
  final int xpPerHit;
}

/// Correção de uma pergunta: a opção certa, a pista no texto e a explicação.
class ReadingAnswerFeedback {
  const ReadingAnswerFeedback({
    required this.chosen,
    required this.correct,
    required this.hit,
    required this.clue,
    required this.explanation,
  });

  final int chosen;
  final int correct;
  final bool hit;
  final String clue;
  final String explanation;
}

class ReadingCaseResult {
  const ReadingCaseResult({
    required this.answers,
    required this.hits,
    required this.total,
    required this.xp,
    this.progress,
  });

  factory ReadingCaseResult.fromJson(Map<String, dynamic> json) {
    return ReadingCaseResult(
      answers: [
        for (final r in json['resultados'] as List? ?? const [])
          ReadingAnswerFeedback(
            chosen: (r as Map)['escolhida'] as int? ?? -1,
            correct: r['correta'] as int? ?? 0,
            hit: r['acertou'] as bool? ?? false,
            clue: r['pista'] as String? ?? '',
            explanation: r['explicacao'] as String? ?? '',
          ),
      ],
      hits: json['acertos'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final List<ReadingAnswerFeedback> answers;
  final int hits;
  final int total;
  final int xp;
  final ProgressUpdate? progress;
}
