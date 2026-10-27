import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child_profile.dart';
import '../models/league_progress.dart';
import '../models/math_challenge.dart';
import '../models/photo_explanation.dart';
import '../models/progress_update.dart';
import '../models/reading_case.dart';
import '../models/responsible_account.dart';
import '../models/writing_feedback.dart';
import 'app_repository.dart';

/// Repositório real: Supabase Auth (e-mail e senha do responsável) e as
/// tabelas das migrations em supabase/migrations.
/// Os módulos com IA chamam as Edge Functions (supabase/functions):
/// `explicar-foto`, `detetive-leitura`, `desafio-matematica` e
/// `oficina-texto`. Todo XP é dado no servidor; o app só lê o progresso.
class SupabaseAppRepository extends AppRepository {
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
    notifyListeners();
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
    final data = await _invoke(
      'explicar-foto',
      {
        'imagem_base64': base64Encode(imageBytes),
        'tipo': _imageType(imageBytes),
      },
      notReady: 'A Foto + IA ainda não foi publicada no Supabase.',
      noProfile: 'Cadastre o perfil da criança antes de enviar fotos.',
    );
    final explanation = PhotoExplanation.fromJson(data);
    _applyProgress(explanation.progress);
    return explanation;
  }

  @override
  Future<ReadingCase> newReadingCase() async {
    return ReadingCase.fromJson(
      await _invoke('detetive-leitura', {'acao': 'novo_caso'}),
    );
  }

  @override
  Future<ReadingCaseResult> answerReadingCase(
    String caseId,
    List<int> answers,
  ) async {
    final result = ReadingCaseResult.fromJson(
      await _invoke('detetive-leitura', {
        'acao': 'responder',
        'caso_id': caseId,
        'respostas': answers,
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<MathChallenge> newMathChallenge(MathTopic topic) async {
    return MathChallenge.fromJson(
      await _invoke('desafio-matematica', {
        'acao': 'novo_desafio',
        'tema': topic.name,
      }),
    );
  }

  @override
  Future<MathAnswerResult> answerMathChallenge(
    String challengeId,
    int choice,
  ) async {
    final result = MathAnswerResult.fromJson(
      await _invoke('desafio-matematica', {
        'acao': 'responder',
        'desafio_id': challengeId,
        'escolha': choice,
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<MathSolution> revealMathSolution(String challengeId) async {
    return MathSolution.fromJson(
      await _invoke('desafio-matematica', {
        'acao': 'passo_a_passo',
        'desafio_id': challengeId,
      }),
    );
  }

  @override
  Future<WritingFeedback> requestWritingFeedback({
    required String theme,
    required WritingPlan plan,
    required String text,
  }) async {
    final feedback = WritingFeedback.fromJson(
      await _invoke('oficina-texto', {
        'acao': 'feedback',
        'tema': theme,
        'planejamento': plan.toJson(),
        'texto': text,
      }),
    );
    _applyProgress(feedback.progress);
    return feedback;
  }

  @override
  Future<RewriteFeedback> submitRewrite({
    required String productionId,
    required String text,
  }) async {
    final feedback = RewriteFeedback.fromJson(
      await _invoke('oficina-texto', {
        'acao': 'reescrita',
        'producao_id': productionId,
        'texto': text,
      }),
    );
    _applyProgress(feedback.progress);
    return feedback;
  }

  @override
  Future<List<DailyMission>> loadDailyMissions() {
    return _guard(() async {
      final missions = await _client
          .from('missoes')
          .select('id, codigo, titulo, descricao, tipo, xp_base, icone')
          .not('codigo', 'is', null)
          .order('ordem');
      final done = <String>{};
      if (_childProfileId != null) {
        final rows = await _client
            .from('progresso_missoes')
            .select('missao_id')
            .eq('perfil_crianca_id', _childProfileId!)
            .eq('dia', _todayInBrazil())
            .eq('status', 'concluida');
        done.addAll(rows.map((r) => r['missao_id'] as String));
      }
      return [
        for (final m in missions)
          DailyMission(
            code: m['codigo'] as String,
            title: m['titulo'] as String,
            description: m['descricao'] as String? ?? '',
            type: m['tipo'] as String,
            xp: m['xp_base'] as int,
            icon: m['icone'] as String?,
            done: done.contains(m['id']),
          ),
      ];
    });
  }

  @override
  Future<List<Achievement>> loadAchievements() {
    return _guard(() async {
      final badges = await _client
          .from('badges')
          .select('id, nome, descricao, icone')
          .order('id');
      final earned = <String>{};
      if (_childProfileId != null) {
        final rows = await _client
            .from('badges_criancas')
            .select('badge_id')
            .eq('perfil_crianca_id', _childProfileId!);
        earned.addAll(rows.map((r) => r['badge_id'] as String));
      }
      final achievements = [
        for (final b in badges)
          Achievement(
            id: b['id'] as String,
            name: b['nome'] as String,
            description: b['descricao'] as String? ?? '',
            icon: b['icone'] as String?,
            earned: earned.contains(b['id']),
          ),
      ];
      // Conquistadas primeiro.
      achievements.sort((a, b) => (b.earned ? 1 : 0) - (a.earned ? 1 : 0));
      return achievements;
    });
  }

  /// Chama uma Edge Function da Liga com o perfil da criança e devolve o
  /// JSON. Erros viram [AppRepositoryException] com a mensagem do servidor.
  Future<Map<String, dynamic>> _invoke(
    String function,
    Map<String, dynamic> body, {
    String notReady = 'Essa parte da Liga ainda não foi publicada.',
    String noProfile = 'Cadastre o perfil da criança primeiro.',
  }) async {
    if (_childProfileId == null) throw AppRepositoryException(noProfile);
    try {
      final response = await _client.functions.invoke(
        function,
        body: {...body, 'perfil_id': _childProfileId},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['erro'] is String) {
        throw AppRepositoryException(details['erro'] as String);
      }
      if (error.status == 404) throw AppRepositoryException(notReady);
      throw const AppRepositoryException(
        'Não consegui falar com a Liga agora. Tente de novo.',
      );
    } on Exception {
      throw const AppRepositoryException(
        'Sem conexão com o servidor. Verifique a internet e tente de novo.',
      );
    }
  }

  void _applyProgress(ProgressUpdate? progress) {
    if (progress == null || _childProfile == null) return;
    _childProfile = _childProfile!.withProgress(progress);
    notifyListeners();
  }

  /// Data de hoje no horário de Brasília (o mesmo dia das missões no banco).
  static String _todayInBrazil() {
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 3));
    return now.toIso8601String().substring(0, 10);
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
    // A sequência só continua valendo se a última atividade foi hoje ou
    // ontem; senão o banco ainda guarda o número antigo.
    final lastActivity = DateTime.tryParse(
      row['ultima_atividade_em'] as String? ?? '',
    );
    final yesterday = DateTime.parse(
      _todayInBrazil(),
    ).subtract(const Duration(days: 1));
    final lastDay = lastActivity == null
        ? null
        : DateTime.parse(
            lastActivity
                .toUtc()
                .subtract(const Duration(hours: 3))
                .toIso8601String()
                .substring(0, 10),
          );
    final streakAlive = lastDay != null && !lastDay.isBefore(yesterday);

    _childProfileId = row['id'] as String;
    _childProfile = ChildProfile(
      nickname: row['apelido'] as String,
      schoolYear: row['ano_escolar'] as int,
      focusAreas: List<String>.from(row['areas_foco'] as List? ?? const []),
      avatarId: row['avatar_id'] as String,
      level: row['nivel'] as int,
      totalXp: row['xp_total'] as int,
      streakDays: streakAlive ? row['sequencia_dias'] as int : 0,
    );
    notifyListeners();
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
          'Rode as migrations do Supabase (pasta supabase/migrations).',
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
