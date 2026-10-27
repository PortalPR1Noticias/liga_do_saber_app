import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child_profile.dart';
import '../models/photo_explanation.dart';
import '../models/responsible_account.dart';
import 'app_repository.dart';

/// Repositório real: Supabase Auth (e-mail e senha do responsável) e as
/// tabelas `responsaveis` e `perfis_criancas` das migrations 0001 e 0002.
/// A Foto + IA chama a Edge Function `explicar-foto` (supabase/functions).
class SupabaseAppRepository implements AppRepository {
  SupabaseAppRepository(this._client);

  final SupabaseClient _client;

  String? _responsibleId;
  String? _childProfileId;
  ResponsibleAccount? _responsible;
  ChildProfile? _childProfile;

  @override
  ResponsibleAccount get responsible {
    return _responsible ??
        ResponsibleAccount(
          name: 'Responsável',
          email: _client.auth.currentUser?.email ?? '',
        );
  }

  @override
  ChildProfile get childProfile {
    return _childProfile ??
        const ChildProfile(
          nickname: 'Explorador',
          schoolYear: 5,
          focusAreas: [],
          avatarId: 'estrategista',
        );
  }

  @override
  Future<AuthOutcome> restoreSession() async {
    if (_client.auth.currentSession == null) return AuthOutcome.signedOut;
    return _guard(_loadAccount);
  }

  @override
  Future<AuthOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nome': name.trim()},
      );
      // Com "Confirm email" ligado no Supabase, não vem sessão: o cadastro do
      // responsável é concluído no primeiro login, depois da confirmação.
      if (response.session == null) return AuthOutcome.needsEmailConfirmation;
      return _loadAccount();
    });
  }

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _loadAccount();
    });
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _responsibleId = null;
    _childProfileId = null;
    _responsible = null;
    _childProfile = null;
  }

  @override
  Future<void> saveChildProfile({
    required String nickname,
    required int schoolYear,
    required List<String> focusAreas,
  }) {
    return _guard(() async {
      final responsibleId = _responsibleId ?? await _ensureResponsible();
      final values = {
        'apelido': nickname.trim().isEmpty ? 'Explorador' : nickname.trim(),
        'ano_escolar': schoolYear,
        'areas_foco': focusAreas,
      };
      final Map<String, dynamic> row;
      if (_childProfileId == null) {
        row = await _client
            .from('perfis_criancas')
            .insert({...values, 'responsavel_id': responsibleId})
            .select()
            .single();
      } else {
        row = await _client
            .from('perfis_criancas')
            .update(values)
            .eq('id', _childProfileId!)
            .select()
            .single();
      }
      _setChildProfile(row);
    });
  }

  @override
  Future<void> saveAvatar(String avatarId) {
    return _guard(() async {
      if (_childProfileId == null) {
        throw const AppRepositoryException(
          'Cadastre o perfil da criança antes de escolher o avatar.',
        );
      }
      final row = await _client
          .from('perfis_criancas')
          .update({'avatar_id': avatarId})
          .eq('id', _childProfileId!)
          .select()
          .single();
      _setChildProfile(row);
    });
  }

  @override
  Future<PhotoExplanation> explainPhoto(Uint8List imageBytes) async {
    if (_childProfileId == null) {
      throw const AppRepositoryException(
        'Cadastre o perfil da criança antes de enviar fotos.',
      );
    }
    try {
      final response = await _client.functions.invoke(
        'explicar-foto',
        body: {
          'perfil_id': _childProfileId,
          'imagem_base64': base64Encode(imageBytes),
          'tipo': _imageType(imageBytes),
        },
      );
      return PhotoExplanation.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['erro'] is String) {
        throw AppRepositoryException(details['erro'] as String);
      }
      if (error.status == 404) {
        throw const AppRepositoryException(
          'A Foto + IA ainda não foi publicada no Supabase.',
        );
      }
      throw const AppRepositoryException(
        'Não consegui analisar a foto agora. Tente de novo.',
      );
    } on Exception {
      throw const AppRepositoryException(
        'Sem conexão com o servidor. Verifique a internet e tente de novo.',
      );
    }
  }

  /// Descobre o formato pela assinatura do arquivo (o image_picker devolve
  /// JPEG na maioria dos aparelhos, mas a galeria pode ter PNG ou WEBP).
  static String _imageType(Uint8List bytes) {
    if (bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50) {
      return 'image/png';
    }
    if (bytes.length > 11 &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  /// Carrega (ou cria) o responsável e o primeiro perfil de criança dele.
  Future<AuthOutcome> _loadAccount() async {
    final responsibleId = await _ensureResponsible();
    final rows = await _client
        .from('perfis_criancas')
        .select()
        .eq('responsavel_id', responsibleId)
        .order('created_at')
        .limit(1);
    if (rows.isEmpty) {
      _childProfileId = null;
      _childProfile = null;
      return AuthOutcome.needsChildProfile;
    }
    _setChildProfile(rows.first);
    return AuthOutcome.readyWithProfile;
  }

  Future<String> _ensureResponsible() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppRepositoryException('Sua sessão expirou. Entre de novo.');
    }
    var row = await _client
        .from('responsaveis')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();
    row ??= await _client
        .from('responsaveis')
        .insert({
          'auth_user_id': user.id,
          'nome': (user.userMetadata?['nome'] as String?) ?? 'Responsável',
          'email': user.email ?? '',
        })
        .select()
        .single();
    _responsibleId = row['id'] as String;
    _responsible = ResponsibleAccount(
      name: row['nome'] as String,
      email: row['email'] as String,
    );
    return _responsibleId!;
  }

  void _setChildProfile(Map<String, dynamic> row) {
    _childProfileId = row['id'] as String;
    _childProfile = ChildProfile(
      nickname: row['apelido'] as String,
      schoolYear: row['ano_escolar'] as int,
      focusAreas: List<String>.from(row['areas_foco'] as List? ?? const []),
      avatarId: row['avatar_id'] as String,
      level: row['nivel'] as int,
      totalXp: row['xp_total'] as int,
      streakDays: row['sequencia_dias'] as int,
    );
  }

  /// Converte erros do Supabase em mensagens em português.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppRepositoryException {
      rethrow;
    } on AuthException catch (error) {
      throw AppRepositoryException(_authMessage(error));
    } on PostgrestException catch (error) {
      if (error.code == '42P01' || error.code == 'PGRST205') {
        throw const AppRepositoryException(
          'O banco ainda não tem as tabelas da Liga. '
          'Rode as migrations 0001 e 0002 no Supabase.',
        );
      }
      throw AppRepositoryException(
        'Não foi possível salvar os dados (${error.message}).',
      );
    } on Exception {
      throw const AppRepositoryException(
        'Sem conexão com o servidor. Verifique a internet e tente de novo.',
      );
    }
  }

  static String _authMessage(AuthException error) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'E-mail ou senha incorretos.';
      case 'email_not_confirmed':
        return 'Confirme seu e-mail pelo link que enviamos e depois entre.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Já existe uma conta com esse e-mail. Use a opção Entrar.';
      case 'weak_password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Muitas tentativas seguidas. Espere um pouco e tente de novo.';
      default:
        return 'Não foi possível entrar (${error.message}).';
    }
  }
}
