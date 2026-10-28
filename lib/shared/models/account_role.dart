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
  const TeacherAccount({
    required this.name,
    required this.email,
    this.emailConfirmed = true,
  });

  final String name;
  final String email;

  /// Sem o e-mail confirmado, o painel não mostra nenhuma criança (senão
  /// qualquer um poderia se cadastrar com o e-mail de outro professor).
  final bool emailConfirmed;
}

/// Professor que o responsável liberou para acompanhar uma criança.
class TeacherLink {
  const TeacherLink({
    required this.id,
    required this.teacherEmail,
    required this.childName,
    this.authorizedAt,
  });

  factory TeacherLink.fromJson(Map<String, dynamic> json) {
    return TeacherLink(
      id: json['id'] as String,
      teacherEmail: json['email_professor'] as String,
      childName: json['nome_crianca'] as String,
      authorizedAt: DateTime.tryParse(json['autorizado_em'] as String? ?? ''),
    );
  }

  final String id;
  final String teacherEmail;

  /// Nome com que a criança aparece para o professor.
  final String childName;
  final DateTime? authorizedAt;
}
