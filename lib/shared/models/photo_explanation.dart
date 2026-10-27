/// Um passo da explicação da Foto + IA.
class ExplanationStep {
  const ExplanationStep({required this.title, required this.explanation});

  final String title;
  final String explanation;
}

/// Explicação que a Edge Function `explicar-foto` devolve para uma foto.
class PhotoExplanation {
  const PhotoExplanation({
    required this.readable,
    required this.subject,
    required this.characterId,
    required this.title,
    required this.statement,
    required this.steps,
    required this.finalAnswer,
    required this.tip,
    required this.closingMessage,
    required this.xp,
  });

  factory PhotoExplanation.fromJson(Map<String, dynamic> json) {
    return PhotoExplanation(
      readable: json['legivel'] as bool? ?? false,
      subject: json['materia'] as String? ?? 'outra',
      characterId: json['personagem'] as String? ?? 'zuri',
      title: json['titulo'] as String? ?? '',
      statement: json['enunciado'] as String? ?? '',
      steps: [
        for (final step in json['passos'] as List? ?? const [])
          ExplanationStep(
            title: (step as Map)['titulo'] as String? ?? '',
            explanation: step['explicacao'] as String? ?? '',
          ),
      ],
      finalAnswer: json['resposta_final'] as String? ?? '',
      tip: json['dica'] as String? ?? '',
      closingMessage: json['mensagem_final'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
    );
  }

  /// `false` quando a foto não era uma atividade ou não dava para ler.
  final bool readable;

  /// Id da matéria, como na tabela `materias` (ou `outra`).
  final String subject;

  /// Id do personagem que explica (nico, luma, teo, mila ou zuri).
  final String characterId;
  final String title;

  /// O que a atividade pede, em poucas palavras.
  final String statement;
  final List<ExplanationStep> steps;
  final String finalAnswer;
  final String tip;
  final String closingMessage;
  final int xp;
}
