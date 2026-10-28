import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account_role.dart';
import '../models/archive_case.dart';
import '../models/atelier.dart';
import '../models/child_profile.dart';
import '../models/league_progress.dart';
import '../models/expedition.dart';
import '../models/math_challenge.dart';
import '../models/minigame.dart';
import '../models/performance_report.dart';
import '../models/photo_explanation.dart';
import '../models/practice_exam.dart';
import '../models/progress_update.dart';
import '../models/reading_case.dart';
import '../models/responsible_account.dart';
import '../models/writing_feedback.dart';
import 'app_repository.dart';

/// Repositório real: Supabase Auth (e-mail e senha do responsável) e as
/// tabelas das migrations em supabase/migrations. O consentimento, a cópia
/// dos dados e a exclusão da conta (LGPD) vêm da migration 0004.
/// Os módulos com IA chamam as Edge Functions (supabase/functions):
/// `explicar-foto`, `detetive-leitura`, `desafio-matematica` e
/// `oficina-texto`. Todo XP é dado no servidor; o app só lê o progresso.
class SupabaseAppRepository extends AppRepository {
  SupabaseAppRepository(this._client);

  final SupabaseClient _client;

  /// Domínio do e-mail interno do login da criança (Edge Function
  /// `contas-liga`): a criança só digita o usuário.
  static const childEmailDomain = 'crianca.ligadosaber.app';

  AccountRole _role = AccountRole.responsible;
  String? _responsibleId;
  String? _childProfileId;
  ResponsibleAccount? _responsible;
  ChildProfile? _childProfile;
  List<ChildProfile> _children = const [];
  TeacherAccount? _teacher;

  @override
  AccountRole get role => _role;

  @override
  List<ChildProfile> get children => _children;

  @override
  TeacherAccount get teacher {
    return _teacher ??
        TeacherAccount(
          name: 'Professor',
          email: _client.auth.currentUser?.email ?? '',
        );
  }

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
    required String acceptedTermsVersion,
  }) {
    return _guard(() async {
      // O aceite vai nos metadados porque, com confirmação de e-mail, a linha
      // em `responsaveis` só é criada no primeiro login.
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nome': name.trim(), 'termos_versao': acceptedTermsVersion},
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
  Future<AuthOutcome> signInChild({
    required String username,
    required String password,
  }) {
    return _guard(() async {
      try {
        await _client.auth.signInWithPassword(
          email: '${username.trim().toLowerCase()}@$childEmailDomain',
          password: password,
        );
      } on AuthException catch (error) {
        if (error.code == 'invalid_credentials') {
          throw const AppRepositoryException('Usuário ou senha incorretos.');
        }
        rethrow;
      }
      return _loadAccount();
    });
  }

  @override
  Future<AuthOutcome> signUpTeacher({
    required String name,
    required String email,
    required String password,
    required String acceptedTermsVersion,
  }) {
    return _guard(() async {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nome': name.trim(),
          'papel': 'professor',
          'termos_versao': acceptedTermsVersion,
        },
      );
      if (response.session == null) return AuthOutcome.needsEmailConfirmation;
      return _loadAccount();
    });
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _clearAccount();
    notifyListeners();
  }

  void _clearAccount() {
    _role = AccountRole.responsible;
    _responsibleId = null;
    _childProfileId = null;
    _responsible = null;
    _childProfile = null;
    _children = const [];
    _teacher = null;
  }

  @override
  void selectChild(String? profileId) {
    final child = profileId == null
        ? null
        : _children.where((c) => c.id == profileId).firstOrNull;
    _childProfileId = child?.id;
    _childProfile = child;
    notifyListeners();
  }

  @override
  Future<void> createChildLogin({
    required String username,
    required String password,
  }) async {
    final data = await _invoke('contas-liga', {
      'acao': 'criar_login_crianca',
      'usuario': username.trim().toLowerCase(),
      'senha': password,
    }, notReady: 'O login da criança ainda não foi publicado no Supabase.');
    _updateChild(_childProfile!.copyWith(username: data['usuario'] as String));
  }

  @override
  Future<void> changeChildPassword(String password) async {
    await _invoke('contas-liga', {
      'acao': 'trocar_senha_crianca',
      'senha': password,
    }, notReady: 'O login da criança ainda não foi publicado no Supabase.');
  }

  @override
  Future<List<TeacherLink>> loadTeacherLinks() {
    return _guard(() async {
      if (_childProfileId == null) return const [];
      final rows = await _client
          .from('professores_criancas')
          .select()
          .eq('perfil_crianca_id', _childProfileId!)
          .order('autorizado_em');
      return [for (final row in rows) TeacherLink.fromJson(row)];
    });
  }

  @override
  Future<void> addTeacherLink({
    required String teacherEmail,
    required String childName,
  }) {
    return _guard(() async {
      if (_childProfileId == null) {
        throw const AppRepositoryException('Escolha a criança primeiro.');
      }
      try {
        await _client.from('professores_criancas').insert({
          'perfil_crianca_id': _childProfileId,
          'email_professor': teacherEmail.trim().toLowerCase(),
          'nome_crianca': childName.trim(),
        });
      } on PostgrestException catch (error) {
        if (error.code == '23505') {
          throw const AppRepositoryException(
            'Esse professor já acompanha essa criança.',
          );
        }
        rethrow;
      }
    });
  }

  @override
  Future<void> removeTeacherLink(String linkId) {
    return _guard(() async {
      await _client.from('professores_criancas').delete().eq('id', linkId);
    });
  }

  @override
  Future<PerformanceReport> loadPerformance() {
    return _guard(() async {
      if (_childProfileId == null) {
        throw const AppRepositoryException('Escolha a criança primeiro.');
      }
      final data = await _client.rpc(
        'avaliacao_desempenho',
        params: {'p_perfil': _childProfileId, 'p_dias': 30},
      );
      return PerformanceReport.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  @override
  Future<List<TeacherStudent>> loadTeacherPanel() {
    return _guard(() async {
      final data = await _client.rpc(
        'painel_professor',
        params: {'p_dias': 30},
      );
      return [
        for (final row in data as List)
          TeacherStudent.fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    });
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
        _children = [..._children, _childFromRow(row)];
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
      noConsent:
          'Peça para um adulto liberar a Foto + IA na Área dos responsáveis.',
    );
    final explanation = PhotoExplanation.fromJson(data);
    _applyProgress(explanation.progress);
    return explanation;
  }

  static const _practiceColumns =
      'id, tipo, titulo, materia, personagem, conteudos, resumo_responsavel, '
      'total_questoes, questoes_acertadas, estrelas, vencida_em, created_at';

  @override
  Future<PracticeExamSummary> uploadPracticeExam({
    required List<Uint8List> photos,
    required PracticeExamKind kind,
    String note = '',
  }) async {
    return PracticeExamSummary.fromJson(
      await _invoke(
        'revanche-prova',
        {
          'acao': 'enviar',
          'material': kind.name,
          'observacao': note,
          'imagens': [
            for (final photo in photos)
              {'base64': base64Encode(photo), 'tipo': _imageType(photo)},
          ],
        },
        notReady: 'A Revanche da prova ainda não foi publicada no Supabase.',
        noConsent:
            'Ligue a autorização de IA acima para enviar provas e tarefas.',
      ),
    );
  }

  @override
  Future<List<PracticeExamSummary>> loadPracticeExams() {
    return _guard(() async {
      if (_childProfileId == null) return const [];
      final rows = await _client
          .from('provas_treino')
          .select(_practiceColumns)
          .eq('perfil_crianca_id', _childProfileId!)
          .order('created_at', ascending: false)
          .limit(30);
      return [for (final row in rows) PracticeExamSummary.fromJson(row)];
    });
  }

  @override
  Future<PracticeExamRound> openPracticeExam(String examId) async {
    return PracticeExamRound.fromJson(
      await _invoke('revanche-prova', {'acao': 'abrir', 'prova_id': examId}),
    );
  }

  @override
  Future<PracticeAnswerResult> answerPracticeQuestion(
    String examId,
    String questionId,
    int choice,
  ) async {
    final result = PracticeAnswerResult.fromJson(
      await _invoke('revanche-prova', {
        'acao': 'responder',
        'prova_id': examId,
        'questao_id': questionId,
        'escolha': choice,
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<void> deletePracticeExam(String examId) {
    return _guard(() async {
      await _client.from('provas_treino').delete().eq('id', examId);
    });
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
  Future<Expedition> newExpedition(ExpeditionSubject subject) async {
    return Expedition.fromJson(
      await _invoke('expedicao-teo', {
        'acao': 'nova_expedicao',
        'materia': subject.name,
      }),
    );
  }

  @override
  Future<ExpeditionAnswerResult> answerExpedition(
    String expeditionId,
    int choice,
  ) async {
    final result = ExpeditionAnswerResult.fromJson(
      await _invoke('expedicao-teo', {
        'acao': 'responder',
        'expedicao_id': expeditionId,
        'escolha': choice,
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<ExpeditionDiscovery> revealExpedition(String expeditionId) async {
    return ExpeditionDiscovery.fromJson(
      await _invoke('expedicao-teo', {
        'acao': 'revelar',
        'expedicao_id': expeditionId,
      }),
    );
  }

  @override
  Future<ArchiveCase> newArchiveCase(ArchiveMode mode) async {
    return ArchiveCase.fromJson(
      await _invoke('arquivo-mila', {'acao': 'novo_caso', 'modo': mode.key}),
    );
  }

  @override
  Future<ArchiveAnswerResult> answerArchiveCase(
    String caseId, {
    int? choice,
    List<int>? order,
    List<String>? found,
  }) async {
    final result = ArchiveAnswerResult.fromJson(
      await _invoke('arquivo-mila', {
        'acao': 'responder',
        'caso_id': caseId,
        'escolha': ?choice,
        'ordem': ?order,
        'encontradas': ?found,
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<ArchiveSolution> revealArchiveCase(String caseId) async {
    return ArchiveSolution.fromJson(
      await _invoke('arquivo-mila', {'acao': 'revelar', 'caso_id': caseId}),
    );
  }

  @override
  Future<AtelierGame> newAtelierGame(AtelierGameType type) async {
    return AtelierGame.fromJson(
      await _invoke('atelie-zuri', {'acao': 'novo_jogo', 'jogo': type.key}),
    );
  }

  @override
  Future<AtelierCheckResult> checkAtelierGame(
    String gameId,
    List<Object> move,
  ) async {
    final result = AtelierCheckResult.fromJson(
      await _invoke('atelie-zuri', {
        'acao': 'conferir',
        'jogo_id': gameId,
        'jogada': move,
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<AtelierSolution> revealAtelierGame(String gameId) async {
    return AtelierSolution.fromJson(
      await _invoke('atelie-zuri', {'acao': 'revelar', 'jogo_id': gameId}),
    );
  }

  @override
  Future<ProjectPlan> planProject(String theme) async {
    final plan = ProjectPlan.fromJson(
      await _invoke(
        'atelie-zuri',
        {'acao': 'planejar_projeto', 'tema': theme},
        noConsent:
            'Peça para um adulto liberar os projetos com IA na Área dos '
            'responsáveis.',
      ),
    );
    _applyProgress(plan.progress);
    return plan;
  }

  @override
  Future<WordSearchGame> newWordSearch(MinigameSubject subject) async {
    return WordSearchGame.fromJson(
      await _invoke('minijogo', {
        'acao': 'novo',
        'jogo': 'caca_palavras',
        'materia': subject.name,
      }),
    );
  }

  @override
  Future<WordSearchCheck> checkWordSearch(
    String gameId,
    GridCell start,
    GridCell end,
  ) async {
    final result = WordSearchCheck.fromJson(
      await _invoke('minijogo', {
        'acao': 'conferir_palavra',
        'jogo_id': gameId,
        'inicio': start.toJson(),
        'fim': end.toJson(),
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<OrderPuzzle> newOrderPuzzle(MinigameSubject subject) async {
    return OrderPuzzle.fromJson(
      await _invoke('minijogo', {
        'acao': 'novo',
        'jogo': 'quebra_cabeca',
        'materia': subject.name,
      }),
    );
  }

  @override
  Future<OrderPuzzleCheck> checkOrderPuzzle(
    String gameId,
    List<int> order,
  ) async {
    final result = OrderPuzzleCheck.fromJson(
      await _invoke('minijogo', {
        'acao': 'conferir_ordem',
        'jogo_id': gameId,
        'ordem': order,
      }),
    );
    _applyProgress(result.progress);
    return result;
  }

  @override
  Future<LightningRound> newLightningRound(LightningTopic topic) async {
    return LightningRound.fromJson(
      await _invoke('minijogo', {
        'acao': 'novo',
        'jogo': 'relampago',
        'tema': topic.name,
      }),
    );
  }

  @override
  Future<LightningResult> finishLightningRound(
    String roundId,
    List<int> answers,
  ) async {
    final result = LightningResult.fromJson(
      await _invoke('minijogo', {
        'acao': 'fechar_relampago',
        'jogo_id': roundId,
        'respostas': answers,
      }),
    );
    _applyProgress(result.progress);
    return result;
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
      }, noConsent: _writingNoConsent),
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
      }, noConsent: _writingNoConsent),
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

  static const _writingNoConsent =
      'Peça para um adulto liberar a Oficina de Texto na Área dos '
      'responsáveis.';

  /// Chama uma Edge Function da Liga com o perfil da criança e devolve o
  /// JSON. Erros viram [AppRepositoryException] com a mensagem do servidor.
  Future<Map<String, dynamic>> _invoke(
    String function,
    Map<String, dynamic> body, {
    String notReady = 'Essa parte da Liga ainda não foi publicada.',
    String noProfile = 'Cadastre o perfil da criança primeiro.',

    /// Quando não é nulo, o módulo manda dados da criança (foto ou texto) para
    /// a OpenAI e precisa da autorização do responsável (LGPD art. 14).
    String? noConsent,
  }) async {
    if (_childProfileId == null) throw AppRepositoryException(noProfile);
    if (noConsent != null && !responsible.aiConsent) {
      throw AppRepositoryException(noConsent);
    }
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

  /// Descobre quem entrou e carrega a conta: a criança (login criado pela
  /// Edge Function `contas-liga`, com `app_metadata.papel`), o professor
  /// (tabela `professores`) ou o responsável e as crianças dele.
  Future<AuthOutcome> _loadAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppRepositoryException('Sua sessão expirou. Entre de novo.');
    }
    _clearAccount();
    if (user.appMetadata['papel'] == 'crianca') return _loadChildAccount();

    Map<String, dynamic>? teacher;
    try {
      teacher = await _client
          .from('professores')
          .select()
          .eq('auth_user_id', user.id)
          .maybeSingle();
    } on PostgrestException catch (error) {
      // Sem a migration 0014 ainda não existem professores: o responsável
      // continua entrando normalmente.
      if (!_missingInDatabase.contains(error.code)) rethrow;
    }
    if (teacher == null && user.userMetadata?['papel'] == 'professor') {
      teacher = await _client
          .from('professores')
          .insert({
            'auth_user_id': user.id,
            'nome': (user.userMetadata?['nome'] as String?) ?? 'Professor',
            'email': user.email ?? '',
            'termos_versao': user.userMetadata?['termos_versao'] as String?,
          })
          .select()
          .single();
    }
    if (teacher != null) {
      _role = AccountRole.teacher;
      _teacher = TeacherAccount(
        name: teacher['nome'] as String,
        email: teacher['email'] as String,
        emailConfirmed: user.emailConfirmedAt != null,
      );
      notifyListeners();
      return AuthOutcome.readyAsTeacher;
    }

    final responsibleId = await _ensureResponsible();
    final rows = await _client
        .from('perfis_criancas')
        .select()
        .eq('responsavel_id', responsibleId)
        .order('created_at');
    _children = [for (final row in rows) _childFromRow(row)];
    if (rows.isEmpty) {
      _childProfileId = null;
      _childProfile = null;
      return AuthOutcome.needsChildProfile;
    }
    _setChildProfile(rows.first);
    return AuthOutcome.readyAsParent;
  }

  Future<AuthOutcome> _loadChildAccount() async {
    final data = await _client.rpc('minha_conta_crianca');
    if (data is! Map) {
      // O responsável apagou o perfil: o login não serve mais.
      await _client.auth.signOut(scope: SignOutScope.local);
      throw const AppRepositoryException(
        'Esse login não está mais ligado a uma criança. Fale com o responsável.',
      );
    }
    _role = AccountRole.child;
    _responsible = ResponsibleAccount(
      name: 'Responsável',
      email: '',
      aiConsent: data['autoriza_ia'] as bool? ?? false,
    );
    _setChildProfile(Map<String, dynamic>.from(data['perfil'] as Map));
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
          'termos_versao': user.userMetadata?['termos_versao'] as String?,
        })
        .select()
        .single();
    _responsibleId = row['id'] as String;
    _setResponsible(row);
    return _responsibleId!;
  }

  void _setResponsible(Map<String, dynamic> row) {
    _responsible = ResponsibleAccount(
      name: row['nome'] as String,
      email: row['email'] as String,
      aiConsent: row['autoriza_ia'] as bool? ?? false,
    );
  }

  void _setChildProfile(Map<String, dynamic> row) {
    final child = _childFromRow(row);
    _childProfileId = child.id;
    _updateChild(child);
  }

  /// Troca a criança escolhida e a mesma criança na lista do responsável.
  void _updateChild(ChildProfile child) {
    _childProfile = child;
    _children = [for (final c in _children) c.id == child.id ? child : c];
    notifyListeners();
  }

  ChildProfile _childFromRow(Map<String, dynamic> row) {
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

    return ChildProfile(
      id: row['id'] as String,
      username: row['usuario'] as String?,
      nickname: row['apelido'] as String,
      schoolYear: row['ano_escolar'] as int,
      focusAreas: List<String>.from(row['areas_foco'] as List? ?? const []),
      avatarId: row['avatar_id'] as String,
      level: row['nivel'] as int,
      totalXp: row['xp_total'] as int,
      streakDays: streakAlive ? row['sequencia_dias'] as int : 0,
    );
  }

  @override
  Future<Map<String, int>> loadActivityCounts() {
    return _guard(() async {
      final counts = <String, int>{};
      if (_childProfileId == null) return counts;
      // Cada linha é uma atividade que deu XP; o bônus da missão do dia
      // ('missao') não conta como fase.
      final rows = await _client
          .from('eventos_xp')
          .select('origem')
          .eq('perfil_crianca_id', _childProfileId!)
          .neq('origem', 'missao');
      for (final row in rows) {
        final origin = row['origem'] as String;
        counts.update(origin, (n) => n + 1, ifAbsent: () => 1);
      }
      return counts;
    });
  }

  @override
  Future<void> setAiConsent(bool allowed) {
    return _guard(() async {
      final responsibleId = _responsibleId ?? await _ensureResponsible();
      final row = await _client
          .from('responsaveis')
          .update({'autoriza_ia': allowed})
          .eq('id', responsibleId)
          .select()
          .single();
      _setResponsible(row);
    });
  }

  @override
  Future<Map<String, dynamic>> exportMyData() {
    return _guard(() async {
      final data = await _client.rpc('exportar_meus_dados');
      return Map<String, dynamic>.from(data as Map);
    });
  }

  @override
  Future<void> deleteAccount() {
    return _guard(() async {
      await _client.rpc('excluir_minha_conta');
      // O usuário já não existe no servidor: só limpa a sessão do aparelho.
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } on Exception {
        // A sessão local some de qualquer jeito.
      }
      _clearAccount();
    });
  }

  /// Tabela, coluna ou função que ainda não existe no banco.
  static const _missingInDatabase = {
    '42P01',
    '42703',
    'PGRST202',
    'PGRST204',
    'PGRST205',
  };

  /// Converte erros do Supabase em mensagens em português.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppRepositoryException {
      rethrow;
    } on AuthException catch (error) {
      throw AppRepositoryException(_authMessage(error));
    } on PostgrestException catch (error) {
      if (_missingInDatabase.contains(error.code)) {
        throw const AppRepositoryException(
          'O banco está desatualizado. '
          'Rode as migrations de supabase/migrations no Supabase.',
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
