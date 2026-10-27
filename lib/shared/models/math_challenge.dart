import 'progress_update.dart';

/// Temas da Arena Matemática (as chaves que a Edge Function entende).
enum MathTopic {
  operacoes('Operações'),
  fracoes('Frações'),
  problemas('Problemas'),
  logica('Lógica');

  const MathTopic(this.label);

  final String label;
}

/// Desafio criado pela IA na Edge Function `desafio-matematica` (a resposta
/// certa fica no servidor).
class MathChallenge {
  const MathChallenge({
    required this.id,
    required this.title,
    required this.statement,
    required this.options,
    this.xp = 20,
  });

  factory MathChallenge.fromJson(Map<String, dynamic> json) {
    return MathChallenge(
      id: json['desafio_id'] as String,
      title: json['titulo'] as String? ?? '',
      statement: json['enunciado'] as String? ?? '',
      options: List<String>.from(json['opcoes'] as List? ?? const []),
      xp: json['xp_possivel'] as int? ?? 20,
    );
  }

  final String id;
  final String title;
  final String statement;
  final List<String> options;
  final int xp;
}

class MathAnswerResult {
  const MathAnswerResult({
    required this.hit,
    required this.tip,
    required this.steps,
    required this.xp,
    this.progress,
  });

  factory MathAnswerResult.fromJson(Map<String, dynamic> json) {
    return MathAnswerResult(
      hit: json['acertou'] as bool? ?? false,
      tip: json['dica'] as String? ?? '',
      steps: List<String>.from(json['passos'] as List? ?? const []),
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool hit;

  /// Dica para tentar de novo (só quando errou).
  final String tip;

  /// Passo a passo (só quando acertou).
  final List<String> steps;
  final int xp;
  final ProgressUpdate? progress;
}

class MathSolution {
  const MathSolution({required this.steps, required this.correct});

  factory MathSolution.fromJson(Map<String, dynamic> json) {
    return MathSolution(
      steps: List<String>.from(json['passos'] as List? ?? const []),
      correct: json['correta'] as int? ?? 0,
    );
  }

  final List<String> steps;
  final int correct;
}
