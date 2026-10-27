import 'progress_update.dart';

/// Prova ou tarefa (o que o responsável escolheu ao enviar).
enum PracticeExamKind {
  prova('Prova'),
  tarefa('Tarefa');

  const PracticeExamKind(this.label);

  final String label;
}

/// Prova ou tarefa que o responsável enviou para a Revanche da prova
/// (tabela `provas_treino`, migration 0009). As questões e as respostas
/// ficam no servidor; aqui vem só o resumo.
class PracticeExamSummary {
  const PracticeExamSummary({
    required this.id,
    required this.kind,
    required this.title,
    required this.subject,
    required this.characterId,
    required this.topics,
    required this.parentNote,
    required this.totalQuestions,
    required this.solvedQuestions,
    required this.stars,
    required this.won,
    required this.createdAt,
  });

  factory PracticeExamSummary.fromJson(Map<String, dynamic> json) {
    return PracticeExamSummary(
      id: json['id'] as String,
      kind: json['tipo'] == 'tarefa'
          ? PracticeExamKind.tarefa
          : PracticeExamKind.prova,
      title: json['titulo'] as String? ?? '',
      subject: json['materia'] as String? ?? 'outra',
      characterId: json['personagem'] as String? ?? 'zuri',
      topics: List<String>.from(json['conteudos'] as List? ?? const []),
      parentNote: json['resumo_responsavel'] as String? ?? '',
      totalQuestions: json['total_questoes'] as int? ?? 0,
      solvedQuestions: json['questoes_acertadas'] as int? ?? 0,
      stars: json['estrelas'] as int? ?? 0,
      won: json['vencida_em'] != null,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final PracticeExamKind kind;
  final String title;

  /// Chave da matéria (matematica, portugues, ciencias...).
  final String subject;

  /// Herói que guia o treino (nico, luma, teo, mila, zuri).
  final String characterId;
  final List<String> topics;

  /// Recado da IA para o responsável: o que caiu e o que reforçar.
  final String parentNote;
  final int totalQuestions;
  final int solvedQuestions;

  /// De 0 a 3, pelos acertos de primeira (só depois de vencer).
  final int stars;
  final bool won;
  final DateTime createdAt;

  double get progress =>
      totalQuestions == 0 ? 0 : solvedQuestions / totalQuestions;
}

/// Questão de treino, sem a resposta certa.
class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.topic,
    required this.statement,
    required this.options,
    this.fromExam = false,
    this.missedInExam = false,
    this.solved = false,
    this.attempts = 0,
    this.explained = false,
  });

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    return PracticeQuestion(
      id: json['id'] as String,
      topic: json['conteudo'] as String? ?? '',
      statement: json['enunciado'] as String? ?? '',
      options: List<String>.from(json['opcoes'] as List? ?? const []),
      fromExam: json['origem'] == 'da_prova',
      missedInExam: json['errou_na_prova'] as bool? ?? false,
      solved: json['acertou'] as bool? ?? false,
      attempts: json['tentativas'] as int? ?? 0,
      explained: json['explicada'] as bool? ?? false,
    );
  }

  final String id;
  final String topic;
  final String statement;
  final List<String> options;

  /// Veio da própria prova (as outras são parecidas, para treinar).
  final bool fromExam;

  /// A criança errou (ou deixou em branco) essa questão na prova.
  final bool missedInExam;
  final bool solved;
  final int attempts;

  /// O herói já explicou: acertar agora não vale XP.
  final bool explained;
}

/// Questões de uma prova, para a criança jogar.
class PracticeExamRound {
  const PracticeExamRound({
    required this.examId,
    required this.questions,
    required this.won,
  });

  factory PracticeExamRound.fromJson(Map<String, dynamic> json) {
    return PracticeExamRound(
      examId: json['prova_id'] as String,
      questions: [
        for (final q in json['questoes'] as List? ?? const [])
          PracticeQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
      ],
      won: json['vencida'] as bool? ?? false,
    );
  }

  final String examId;
  final List<PracticeQuestion> questions;
  final bool won;
}

class PracticeAnswerResult {
  const PracticeAnswerResult({
    required this.hit,
    required this.tip,
    required this.explanation,
    required this.correct,
    required this.explained,
    required this.solvedQuestions,
    required this.won,
    required this.stars,
    required this.xp,
    this.progress,
  });

  factory PracticeAnswerResult.fromJson(Map<String, dynamic> json) {
    return PracticeAnswerResult(
      hit: json['acertou'] as bool? ?? false,
      tip: json['dica'] as String? ?? '',
      explanation: List<String>.from(json['explicacao'] as List? ?? const []),
      correct: json['correta'] as int?,
      explained: json['explicada'] as bool? ?? false,
      solvedQuestions: json['acertadas'] as int? ?? 0,
      won: json['vencida'] as bool? ?? false,
      stars: json['estrelas'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool hit;

  /// Pista para tentar de novo (no primeiro erro).
  final String tip;

  /// Passo a passo do herói (quando acertou ou no segundo erro).
  final List<String> explanation;

  /// Opção certa (só junto com a explicação).
  final int? correct;

  /// Errou duas vezes: o herói explicou e a questão volta no fim da fila.
  final bool explained;
  final int solvedQuestions;

  /// A criança acertou todas as questões da prova.
  final bool won;

  /// Estrelas da prova vencida agora (0 se ainda não venceu).
  final int stars;
  final int xp;
  final ProgressUpdate? progress;
}
