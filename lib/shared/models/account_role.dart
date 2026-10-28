/// Quem está logado no aparelho (migration 0014).
enum AccountRole {
  /// Pai, mãe ou responsável: cria a conta, as crianças e os logins delas.
  responsible,

  /// A criança, com o usuário e a senha que o responsável criou: só joga.
  child,

  /// Professor: vê o desempenho das crianças que os responsáveis liberaram.
  teacher,
}

/// Conta do professor.
class TeacherAccount {
  const TeacherAccount({required this.name, required this.email});

  final String name;
  final String email;
}

/// Professor que o responsável liberou para acompanhar uma criança
/// (migration 0020: o professor entra com o código da liberação).
class TeacherLink {
  const TeacherLink({
    required this.id,
    required this.teacherEmail,
    required this.childName,
    required this.code,
    this.connected = false,
    this.authorizedAt,
  });

  factory TeacherLink.fromJson(Map<String, dynamic> json) {
    return TeacherLink(
      id: json['id'] as String,
      teacherEmail: json['email_professor'] as String,
      childName: json['nome_crianca'] as String,
      code: json['codigo'] as String? ?? '',
      connected: json['professor_auth_user_id'] != null,
      authorizedAt: DateTime.tryParse(json['autorizado_em'] as String? ?? ''),
    );
  }

  final String id;
  final String teacherEmail;

  /// Nome com que a criança aparece para o professor.
  final String childName;

  /// Código que o responsável manda ao professor. Sem a confirmação de
  /// e-mail, é ele que prova que o professor é quem o responsável escolheu.
  final String code;

  /// O professor já usou o código.
  final bool connected;
  final DateTime? authorizedAt;
}
