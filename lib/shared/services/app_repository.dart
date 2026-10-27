import 'dart:typed_data';

import '../models/child_profile.dart';
import '../models/photo_explanation.dart';
import '../models/responsible_account.dart';
import 'mock_app_repository.dart';

/// Resultado do login ou da restauração de sessão.
enum AuthOutcome {
  /// Logado e com perfil de criança: pode ir direto para a Liga.
  readyWithProfile,

  /// Logado, mas ainda sem perfil de criança cadastrado.
  needsChildProfile,

  /// Conta criada, mas o Supabase pediu confirmação do e-mail antes do login.
  needsEmailConfirmation,

  /// Nenhuma sessão ativa.
  signedOut,
}

/// Erro com mensagem pronta para mostrar ao responsável.
class AppRepositoryException implements Exception {
  const AppRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fonte de dados do app. Em produção é o [SupabaseAppRepository]; nos testes
/// fica o [MockAppRepository], que guarda tudo em memória.
abstract class AppRepository {
  static AppRepository instance = MockAppRepository();

  ResponsibleAccount get responsible;

  ChildProfile get childProfile;

  /// Verifica se já existe uma sessão salva no aparelho.
  Future<AuthOutcome> restoreSession();

  Future<AuthOutcome> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthOutcome> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> saveChildProfile({
    required String nickname,
    required int schoolYear,
    required List<String> focusAreas,
  });

  Future<void> saveAvatar(String avatarId);

  /// Manda a foto da atividade para a IA e devolve a explicação passo a passo.
  Future<PhotoExplanation> explainPhoto(Uint8List imageBytes);
}
