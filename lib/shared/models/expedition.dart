import 'progress_update.dart';

/// Matérias da Trilha do Teo (as chaves que a Edge Function entende).
enum ExpeditionSubject {
  ciencias('Ciências'),
  geografia('Geografia');

  const ExpeditionSubject(this.label);

  final String label;
}

/// Investigação criada pela IA na Edge Function `expedicao-teo` (a resposta
/// certa fica no servidor).
class Expedition {
  const Expedition({
    required this.id,
    required this.subject,
    required this.title,
    required this.topic,
    required this.scene,
    required this.clues,
    required this.question,
    required this.options,
    this.xp = 20,
  });

  factory Expedition.fromJson(Map<String, dynamic> json) {
    return Expedition(
      id: json['expedicao_id'] as String,
      subject: ExpeditionSubject.values.firstWhere(
        (s) => s.name == json['materia'],
        orElse: () => ExpeditionSubject.ciencias,
      ),
      title: json['titulo'] as String? ?? '',
      topic: json['tema'] as String? ?? '',
      scene: json['cena'] as String? ?? '',
      clues: List<String>.from(json['pistas'] as List? ?? const []),
      question: json['pergunta'] as String? ?? '',
      options: List<String>.from(json['opcoes'] as List? ?? const []),
      xp: json['xp_possivel'] as int? ?? 20,
    );
  }

  final String id;
  final ExpeditionSubject subject;
  final String title;

  /// Assunto da BNCC trabalhado (por exemplo "Ciclo da água").
  final String topic;

  /// O mistério que o Teo encontrou.
  final String scene;
  final List<String> clues;
  final String question;
  final List<String> options;
  final int xp;
}

/// Explicação do Teo, mostrada quando a criança acerta ou pede para revelar.
class ExpeditionDiscovery {
  const ExpeditionDiscovery({
    required this.steps,
    required this.funFact,
    required this.correct,
  });

  factory ExpeditionDiscovery.fromJson(Map<String, dynamic> json) {
    return ExpeditionDiscovery(
      steps: List<String>.from(json['descoberta'] as List? ?? const []),
      funFact: json['curiosidade'] as String? ?? '',
      correct: json['correta'] as int?,
    );
  }

  final List<String> steps;
  final String funFact;
  final int? correct;
}

class ExpeditionAnswerResult {
  const ExpeditionAnswerResult({
    required this.hit,
    required this.tip,
    required this.discovery,
    required this.xp,
    this.progress,
  });

  factory ExpeditionAnswerResult.fromJson(Map<String, dynamic> json) {
    return ExpeditionAnswerResult(
      hit: json['acertou'] as bool? ?? false,
      tip: json['dica'] as String? ?? '',
      discovery: ExpeditionDiscovery.fromJson(json),
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool hit;

  /// Pista extra para tentar de novo (só quando errou).
  final String tip;

  /// Explicação (vazia quando errou).
  final ExpeditionDiscovery discovery;
  final int xp;
  final ProgressUpdate? progress;
}
