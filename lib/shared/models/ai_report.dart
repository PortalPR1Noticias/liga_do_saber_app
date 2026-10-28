/// Motivo de uma denúncia de conteúdo da IA (as chaves da tabela
/// `denuncias_ia`).
enum AiReportReason {
  improprio('Conteúdo impróprio ou que me deixou desconfortável'),
  errado('Resposta errada ou confusa'),
  outro('Outro problema');

  const AiReportReason(this.label);

  final String label;
}

/// Uma denúncia feita pelo botão "Avisar um problema".
class AiReport {
  const AiReport({
    required this.module,
    required this.reason,
    this.comment = '',
    this.reference,
  });

  /// Tela de onde veio (`foto`, `leitura`, `matematica`...).
  final String module;
  final AiReportReason reason;
  final String comment;

  /// Id do conteúdo mostrado (caso, desafio, prova...), quando houver.
  final String? reference;
}
