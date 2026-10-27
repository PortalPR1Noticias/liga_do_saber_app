import 'dart:typed_data';

import '../models/child_profile.dart';
import '../models/expedition.dart';
import '../models/league_progress.dart';
import '../models/math_challenge.dart';
import '../models/photo_explanation.dart';
import '../models/progress_update.dart';
import '../models/reading_case.dart';
import '../models/responsible_account.dart';
import '../models/writing_feedback.dart';
import 'app_repository.dart';

/// Repositório em memória, usado nos testes e como padrão sem Supabase.
/// Os módulos devolvem sempre o mesmo conteúdo e o XP é somado aqui mesmo.
class MockAppRepository extends AppRepository {
  ResponsibleAccount? _responsible;
  ChildProfile? _childProfile;
  final _missionsDone = <String>{};
  final _badges = <String>{};
  int _mathAttempts = 0;
  bool _mathRevealed = false;
  int _expeditionAttempts = 0;
  bool _expeditionRevealed = false;

  @override
  ResponsibleAccount get responsible {
    return _responsible ??
        const ResponsibleAccount(
          name: 'Responsável',
          email: 'responsavel@ligadosaber.app',
        );
  }

  @override
  ChildProfile get childProfile {
    return _childProfile ??
        const ChildProfile(
          nickname: 'Alex G',
          schoolYear: 5,
          focusAreas: ['Leitura', 'Texto'],
          avatarId: 'estrategista',
          level: 11,
          totalXp: 5840,
          streakDays: 19,
        );
  }

  @override
  Future<AuthOutcome> restoreSession() async => AuthOutcome.signedOut;

  @override
  Future<AuthOutcome> signUp({
    required String name,
    required String email,
    required String password,
    required String acceptedTermsVersion,
  }) async {
    _responsible = ResponsibleAccount(
      name: name.trim().isEmpty ? 'Responsável' : name.trim(),
      email: email.trim().isEmpty
          ? 'responsavel@ligadosaber.app'
          : email.trim(),
    );
    return AuthOutcome.needsChildProfile;
  }

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    return AuthOutcome.readyWithProfile;
  }

  @override
  Future<void> signOut() async {
    _responsible = null;
    _childProfile = null;
    _missionsDone.clear();
    _badges.clear();
  }

  @override
  Future<void> saveChildProfile({
    required String nickname,
    required int schoolYear,
    required List<String> focusAreas,
  }) async {
    final current = childProfile;
    _childProfile = current.copyWith(
      nickname: nickname.trim().isEmpty ? 'Alex G' : nickname.trim(),
      schoolYear: schoolYear,
      focusAreas: focusAreas,
    );
    notifyListeners();
  }

  @override
  Future<void> saveAvatar(String avatarId) async {
    _childProfile = childProfile.copyWith(avatarId: avatarId);
    notifyListeners();
  }

  @override
  Future<PhotoExplanation> explainPhoto(Uint8List imageBytes) async {
    return PhotoExplanation(
      readable: true,
      subject: 'matematica',
      characterId: 'nico',
      title: 'Dividindo figurinhas',
      statement: 'Dividir 24 figurinhas entre 3 amigos.',
      steps: [
        ExplanationStep(
          title: 'Entenda a missão',
          explanation: 'Temos 24 figurinhas e 3 amigos.',
        ),
        ExplanationStep(
          title: 'Escolha a operação',
          explanation: 'Repartir em partes iguais é dividir: 24 ÷ 3.',
        ),
      ],
      finalAnswer: 'Cada amigo fica com 8 figurinhas.',
      tip: 'Confira multiplicando: 8 × 3 = 24.',
      closingMessage: 'Estratégia certeira! Você consegue!',
      xp: 20,
      progress: _grantXp(20, 'foto'),
    );
  }

  static const _missions = [
    DailyMission(
      code: 'caso_leitura',
      title: 'Resolver um caso de leitura',
      description: 'Abra um caso no Detetive da Leitura.',
      type: 'leitura',
      xp: 25,
      done: false,
      icon: 'search',
    ),
    DailyMission(
      code: 'reescrever_texto',
      title: 'Reescrever um texto',
      description: 'Use o feedback da Luma para melhorar um texto.',
      type: 'texto_reescrita',
      xp: 35,
      done: false,
      icon: 'edit',
    ),
    DailyMission(
      code: 'desafio_matematica',
      title: 'Vencer um desafio do Nico',
      description: 'Acerte um desafio na Arena Matemática.',
      type: 'matematica',
      xp: 20,
      done: false,
      icon: 'calculate',
    ),
    DailyMission(
      code: 'foto_tarefa',
      title: 'Enviar foto da tarefa',
      description: 'Mande a foto de uma lição.',
      type: 'foto',
      xp: 15,
      done: false,
      icon: 'camera',
    ),
    DailyMission(
      code: 'expedicao_teo',
      title: 'Desvendar uma expedição do Teo',
      description: 'Resolva uma investigação na Trilha do Teo.',
      type: 'expedicao',
      xp: 20,
      done: false,
      icon: 'explore',
    ),
  ];

  /// Mesma regra da função SQL `conceder_xp`, em versão simplificada.
  ProgressUpdate _grantXp(int xp, String origin) {
    final current = childProfile;
    var bonus = 0;
    String? missionTitle;
    for (final mission in _missions) {
      if (mission.type == origin && _missionsDone.add(mission.code)) {
        bonus = mission.xp;
        missionTitle = mission.title;
      }
    }
    final newBadges = <EarnedBadge>[
      if (missionTitle != null && _badges.add('primeiro_passo'))
        const EarnedBadge(
          id: 'primeiro_passo',
          name: 'Primeiro Passo',
          icon: 'rocket',
        ),
    ];
    final total = current.totalXp + xp + bonus;
    var level = current.level;
    while (ChildProfile.levelStartXp(level + 1) <= total) {
      level++;
    }
    final progress = ProgressUpdate(
      xpGained: xp + bonus,
      totalXp: total,
      level: level,
      leveledUp: level > current.level,
      streakDays: current.streakDays == 0 ? 1 : current.streakDays,
      missionTitle: missionTitle,
      missionXp: bonus,
      newBadges: newBadges,
    );
    _childProfile = current.withProgress(progress);
    notifyListeners();
    return progress;
  }

  @override
  Future<ReadingCase> newReadingCase() async {
    return const ReadingCase(
      id: 'caso-1',
      title: 'O bilhete desaparecido',
      text:
          'Na segunda-feira, a bibliotecária encontrou um bilhete na mesa: '
          '"Volto amanhã para devolver o livro dos planetas". Ao lado havia '
          'um marcador de página com um foguete desenhado. Na terça, Caio '
          'chegou correndo, com o livro dos planetas debaixo do braço.',
      intro: 'Pegue sua lupa: cada resposta tem uma pista no texto!',
      questions: [
        ReadingQuestion(
          skill: 'ideia_principal',
          question: 'Sobre o que é o texto?',
          options: [
            'Um bilhete deixado na biblioteca',
            'Uma viagem ao espaço',
            'Uma aula de matemática',
          ],
        ),
        ReadingQuestion(
          skill: 'inferencia',
          question: 'Quem provavelmente deixou o bilhete?',
          options: ['A bibliotecária', 'Caio', 'Um astronauta'],
        ),
        ReadingQuestion(
          skill: 'localizar',
          question: 'O que estava desenhado no marcador?',
          options: ['Uma estrela', 'Um foguete', 'Um livro'],
        ),
      ],
    );
  }

  @override
  Future<ReadingCaseResult> answerReadingCase(
    String caseId,
    List<int> answers,
  ) async {
    const correct = [0, 1, 1];
    const clues = [
      'a bibliotecária encontrou um bilhete na mesa',
      'Caio chegou correndo, com o livro dos planetas',
      'um marcador de página com um foguete desenhado',
    ];
    final feedback = [
      for (var i = 0; i < correct.length; i++)
        ReadingAnswerFeedback(
          chosen: i < answers.length ? answers[i] : -1,
          correct: correct[i],
          hit: i < answers.length && answers[i] == correct[i],
          clue: clues[i],
          explanation: 'A pista no texto mostra a resposta certa.',
        ),
    ];
    final hits = feedback.where((f) => f.hit).length;
    final xp = hits * 10;
    return ReadingCaseResult(
      answers: feedback,
      hits: hits,
      total: correct.length,
      xp: xp,
      progress: xp > 0 ? _grantXp(xp, 'leitura') : null,
    );
  }

  @override
  Future<MathChallenge> newMathChallenge(MathTopic topic) async {
    _mathAttempts = 0;
    _mathRevealed = false;
    return const MathChallenge(
      id: 'desafio-1',
      title: 'Figurinhas da Liga',
      statement:
          'Se 24 figurinhas forem divididas entre 3 amigos, quantas ficam '
          'para cada um?',
      options: ['6', '8', '12', '21'],
    );
  }

  static const _mathSteps = [
    'São 24 figurinhas para dividir igualmente entre 3 amigos.',
    'Dividir é repartir em partes iguais: 24 ÷ 3.',
    'Pense na tabuada do 3: 3 × 8 = 24.',
    'Então cada amigo fica com 8 figurinhas.',
  ];

  @override
  Future<MathAnswerResult> answerMathChallenge(
    String challengeId,
    int choice,
  ) async {
    final hit = choice == 1;
    final xp = !hit || _mathRevealed ? 0 : (_mathAttempts == 0 ? 20 : 10);
    _mathAttempts++;
    return MathAnswerResult(
      hit: hit,
      tip: hit ? '' : 'Pense na tabuada do 3.',
      steps: hit ? _mathSteps : const [],
      xp: xp,
      progress: xp > 0 ? _grantXp(xp, 'matematica') : null,
    );
  }

  @override
  Future<MathSolution> revealMathSolution(String challengeId) async {
    _mathRevealed = true;
    return const MathSolution(steps: _mathSteps, correct: 1);
  }

  @override
  Future<Expedition> newExpedition(ExpeditionSubject subject) async {
    _expeditionAttempts = 0;
    _expeditionRevealed = false;
    return Expedition(
      id: 'expedicao-1',
      subject: subject,
      title: 'O mistério da poça sumida',
      topic: 'Ciclo da água',
      scene:
          'Depois da chuva, encontrei uma poça enorme no pátio da escola. '
          'Voltei à tarde, com o sol forte, e ela tinha sumido! Para onde '
          'foi essa água?',
      clues: const [
        'O dia ficou quente e ensolarado.',
        'Ninguém secou o pátio.',
      ],
      question: 'O que aconteceu com a água da poça?',
      options: const [
        'Virou terra',
        'Evaporou com o calor do sol',
        'Foi bebida pelos passarinhos',
        'Desapareceu para sempre',
      ],
    );
  }

  static const _expeditionDiscovery = ExpeditionDiscovery(
    steps: [
      'Pista 1: o sol esquentou o pátio e a água.',
      'Água aquecida vira vapor, que é invisível e sobe para o ar.',
      'Esse vapor depois forma as nuvens: é o ciclo da água!',
      'Então a água da poça evaporou com o calor do sol.',
    ],
    funFact: 'A água que você bebe hoje já pode ter passado por uma nuvem!',
    correct: 1,
  );

  @override
  Future<ExpeditionAnswerResult> answerExpedition(
    String expeditionId,
    int choice,
  ) async {
    final hit = choice == 1;
    final xp = !hit || _expeditionRevealed
        ? 0
        : (_expeditionAttempts == 0 ? 20 : 10);
    _expeditionAttempts++;
    return ExpeditionAnswerResult(
      hit: hit,
      tip: hit ? '' : 'Pense no que o calor faz com a água.',
      discovery: hit
          ? _expeditionDiscovery
          : const ExpeditionDiscovery(steps: [], funFact: '', correct: null),
      xp: xp,
      progress: xp > 0 ? _grantXp(xp, 'expedicao') : null,
    );
  }

  @override
  Future<ExpeditionDiscovery> revealExpedition(String expeditionId) async {
    _expeditionRevealed = true;
    return _expeditionDiscovery;
  }

  @override
  Future<WritingFeedback> requestWritingFeedback({
    required String theme,
    required WritingPlan plan,
    required String text,
  }) async {
    return WritingFeedback(
      productionId: 'texto-1',
      appropriate: true,
      criteria: const [
        WritingCriterion(
          id: 'clareza',
          stars: 2,
          comment: 'Dá para entender a ideia.',
        ),
        WritingCriterion(
          id: 'organizacao',
          stars: 2,
          comment: 'Tem começo e meio; capriche no final.',
        ),
        WritingCriterion(
          id: 'pontuacao',
          stars: 1,
          comment: 'Faltam pontos finais.',
        ),
        WritingCriterion(
          id: 'criatividade',
          stars: 3,
          comment: 'Que ideia divertida!',
        ),
      ],
      strengths: const ['Sua história tem uma ideia original.'],
      suggestions: const ['Termine cada frase com ponto final.'],
      message: 'Agora reescreva usando as dicas. Você consegue!',
      xp: 15,
      progress: _grantXp(15, 'texto'),
    );
  }

  @override
  Future<RewriteFeedback> submitRewrite({
    required String productionId,
    required String text,
  }) async {
    return RewriteFeedback(
      appropriate: true,
      evolution: 2,
      criteria: const [
        WritingCriterion(
          id: 'pontuacao',
          stars: 2,
          comment: 'Agora as frases terminam certinho.',
        ),
      ],
      improvements: const ['Você colocou os pontos finais.'],
      nextStep: 'No próximo texto, use parágrafos.',
      message: 'Seu texto evoluiu muito!',
      xp: 26,
      progress: _grantXp(26, 'texto_reescrita'),
    );
  }

  @override
  Future<List<DailyMission>> loadDailyMissions() async {
    return [
      for (final m in _missions)
        DailyMission(
          code: m.code,
          title: m.title,
          description: m.description,
          type: m.type,
          xp: m.xp,
          done: _missionsDone.contains(m.code),
          icon: m.icon,
        ),
    ];
  }

  @override
  Future<List<Achievement>> loadAchievements() async {
    const catalog = [
      (
        'primeiro_passo',
        'Primeiro Passo',
        'Concluiu a primeira missão.',
        'rocket',
      ),
      (
        'detetive_leitura',
        'Detetive da Leitura',
        'Resolveu 5 casos.',
        'search',
      ),
      ('texto_melhorado', 'Texto Melhorado', 'Reescreveu 3 textos.', 'edit'),
      ('estrategista', 'Estrategista', 'Venceu 10 desafios.', 'calculate'),
      (
        'sequencia_fogo',
        'Sequência de Fogo',
        'Estudou 7 dias seguidos.',
        'fire',
      ),
      ('olho_de_aguia', 'Olho de Águia', 'Mandou 5 fotos de lição.', 'camera'),
      (
        'explorador',
        'Explorador da Liga',
        'Desvendou 10 expedições.',
        'explore',
      ),
    ];
    return [
      for (final (id, name, description, icon) in catalog)
        Achievement(
          id: id,
          name: name,
          description: description,
          icon: icon,
          earned: _badges.contains(id),
        ),
    ];
  }

  @override
  Future<void> setAiConsent(bool allowed) async {
    _responsible = ResponsibleAccount(
      name: responsible.name,
      email: responsible.email,
      aiConsent: allowed,
    );
  }

  @override
  Future<Map<String, dynamic>> exportMyData() async {
    final profile = childProfile;
    return {
      'responsavel': {
        'nome': responsible.name,
        'email': responsible.email,
        'autoriza_ia': responsible.aiConsent,
      },
      'perfis_criancas': [
        {
          'apelido': profile.nickname,
          'ano_escolar': profile.schoolYear,
          'xp_total': profile.totalXp,
        },
      ],
    };
  }

  @override
  Future<void> deleteAccount() => signOut();
}
