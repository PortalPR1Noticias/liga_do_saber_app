class ResponsibleAccount {
  const ResponsibleAccount({
    required this.name,
    required this.email,
    this.aiConsent = false,
  });

  final String name;
  final String email;

  /// O responsável autorizou mandar fotos e textos da criança para a IA
  /// (coluna `responsaveis.autoriza_ia`, LGPD art. 14).
  final bool aiConsent;
}
