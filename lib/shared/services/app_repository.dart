import 'package:flutter/foundation.dart';

import '../models/ai_report.dart';
import '../models/account_role.dart';
import '../models/atelier.dart';
import '../models/avatar.dart';
import '../models/archive_case.dart';
import '../models/child_profile.dart';
import '../models/expedition.dart';
import '../models/league_progress.dart';
import '../models/learning_report.dart';
import '../models/math_challenge.dart';
import '../models/minigame.dart';
import '../models/performance_report.dart';
import '../models/photo_explanation.dart';
import '../models/progress_update.dart';
import '../models/ranking.dart';
import '../models/practice_exam.dart';
import '../models/reading_case.dart';
import '../models/shop.dart';
import '../models/writing_feedback.dart';
import '../models/responsible_account.dart';
import 'mock_app_repository.dart';

/// Resultado do login ou da restauração de sessão.
enum AuthOutcome {
  /// A criança entrou com o login dela: vai direto para os jogos.
  readyWithProfile,

  /// O responsável entrou e já tem criança cadastrada: painel do responsável.
  readyAsParent,

  /// O professor entrou: painel do professor.
  readyAsTeacher,

  /// Responsável logado, mas ainda sem perfil de criança cadastrado.
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
///
/// Avisa os ouvintes quando o perfil muda (XP, nível, sequência), para o
/// cabeçalho da Liga se atualizar ao voltar de uma atividade.
abstract class AppRepository extends ChangeNotifier {
  static AppRepository instance = MockAppRepository();

  /// Quem está logado (responsável, criança ou professor).
  AccountRole get role;

  ResponsibleAccount get responsible;

  /// A criança logada ou, no painel do responsável, a criança escolhida.
  ChildProfile get childProfile;

  /// Todas as crianças do responsável (vazio para criança e professor).
  List<ChildProfile> get children;

  TeacherAccount get teacher;

  /// Verifica se já existe uma sessão salva no aparelho.
  Future<AuthOutcome> restoreSession();

  /// Login da criança, com o usuário e a senha que o responsável criou.
  Future<AuthOutcome> signInChild({
    required String username,
    required String password,
  });

  /// Conta do professor.
  Future<AuthOutcome> signUpTeacher({
    required String name,
    required String email,
    required String password,
    required String acceptedTermsVersion,
  });

  /// O responsável escolhe com qual criança vai mexer; `null` prepara uma
  /// criança nova (o próximo [saveChildProfile] cria outro perfil).
  void selectChild(String? profileId);

  /// O responsável cria o usuário e a senha da criança escolhida.
  Future<void> createChildLogin({
    required String username,
    required String password,
  });

  /// O responsável troca a senha da criança escolhida.
  Future<void> changeChildPassword(String password);

  /// Professores que o responsável liberou para a criança escolhida.
  Future<List<TeacherLink>> loadTeacherLinks();

  /// Libera um professor (pelo e-mail dele) para ver o desempenho da criança
  /// escolhida, com o nome que vai aparecer para ele.
  Future<void> addTeacherLink({
    required String teacherEmail,
    required String childName,
  });

  Future<void> removeTeacherLink(String linkId);

  /// Avaliação de desempenho da criança escolhida (painel do responsável).
  Future<PerformanceReport> loadPerformance();

  /// Painel do professor: crianças liberadas, com o desempenho de cada uma.
  Future<List<TeacherStudent>> loadTeacherPanel();

  /// O professor digita o código que o responsável mandou e passa a ver a
  /// criança. Devolve o nome com que ela aparece para ele.
  Future<String> redeemTeacherCode(String code);

  Future<AuthOutcome> signUp({
    required String name,
    required String email,
    required String password,
    required String acceptedTermsVersion,
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

  /// Revanche da prova: o responsável manda fotos (até 10) e/ou um PDF de
  /// uma prova ou tarefa já feita e a IA cria questões de treino. Os
  /// arquivos vão para a OpenAI, então precisa da autorização do responsável.
  Future<PracticeExamSummary> uploadPracticeExam({
    List<Uint8List> photos = const [],
    PracticeExamPdf? pdf,
    required PracticeExamKind kind,
    String note = '',
  });

  /// Áudio em MP3 da explicação com a voz do herói (Edge Function
  /// `voz-heroi`). Só o texto da explicação vai para a OpenAI.
  Future<Uint8List> heroVoice({
    required String characterId,
    required String text,
  });

  /// Provas e tarefas enviadas para a criança treinar, das mais novas.
  Future<List<PracticeExamSummary>> loadPracticeExams();

  /// Questões de uma prova (sem as respostas).
  Future<PracticeExamRound> openPracticeExam(String examId);

  Future<PracticeAnswerResult> answerPracticeQuestion(
    String examId,
    String questionId,
    int choice,
  );

  /// O responsável apaga uma prova enviada (e o treino dela).
  Future<void> deletePracticeExam(String examId);

  /// Detetive da Leitura: a Luma cria um caso novo (texto + 3 perguntas).
  Future<ReadingCase> newReadingCase();

  /// Confere as respostas (índice da opção escolhida em cada pergunta).
  Future<ReadingCaseResult> answerReadingCase(String caseId, List<int> answers);

  /// Arena Matemática: o Nico cria um desafio do tema escolhido.
  Future<MathChallenge> newMathChallenge(MathTopic topic);

  Future<MathAnswerResult> answerMathChallenge(String challengeId, int choice);

  /// Mostra a resolução (depois disso o desafio não vale mais XP).
  Future<MathSolution> revealMathSolution(String challengeId);

  /// Trilha do Teo: o Teo cria uma investigação de Ciências ou Geografia.
  Future<Expedition> newExpedition(ExpeditionSubject subject);

  Future<ExpeditionAnswerResult> answerExpedition(
    String expeditionId,
    int choice,
  );

  /// Mostra a descoberta (depois disso a expedição não vale mais XP).
  Future<ExpeditionDiscovery> revealExpedition(String expeditionId);

  /// Oficina do Zuri: o Zuri cria um minijogo (caça-palavras, mapa mental ou
  /// quebra-cabeça do projeto).
  Future<AtelierGame> newAtelierGame(AtelierGameType type);

  /// Confere a jogada: no caça-palavras, uma lista de
  /// `{palavra, inicio, fim}`; no mapa mental, o ramo de cada peça; no
  /// quebra-cabeça, as peças na ordem montada.
  Future<AtelierCheckResult> checkAtelierGame(String gameId, List<Object> move);

  /// Mostra a solução (depois disso o jogo não vale mais XP).
  Future<AtelierSolution> revealAtelierGame(String gameId);

  /// Oficina do Zuri: mapa mental e etapas do projeto que a criança escreveu.
  /// O tema vai para a OpenAI, então precisa da autorização do responsável.
  Future<ProjectPlan> planProject(String theme);

  /// Arquivo da Mila: a Mila cria uma partida de um minijogo de História
  /// (caça-palavras, linha do tempo ou enigma do documento).
  Future<ArchiveCase> newArchiveCase(ArchiveMode mode);

  /// Responde uma partida: `found` (chaves das palavras achadas) no
  /// caça-palavras; `order` (posições das fichas, da mais antiga à mais
  /// recente) na linha do tempo; `choice` no enigma do documento.
  Future<ArchiveAnswerResult> answerArchiveCase(
    String caseId, {
    int? choice,
    List<int>? order,
    List<String>? found,
  });

  /// Mostra a explicação (depois disso o caso não vale mais XP).
  Future<ArchiveSolution> revealArchiveCase(String caseId);

  /// Oficina de Texto: feedback da Luma sobre a primeira versão.
  Future<WritingFeedback> requestWritingFeedback({
    required String theme,
    required WritingPlan plan,
    required String text,
  });

  /// Oficina de Texto: avaliação da reescrita, com XP pela evolução.
  Future<RewriteFeedback> submitRewrite({
    required String productionId,
    required String text,
  });

  /// Jogos da Liga: caça-palavras com palavras do tema escolhido.
  Future<WordSearchGame> newWordSearch(MinigameSubject subject);

  /// Confere a palavra marcada do [start] ao [end] na grade.
  Future<WordSearchCheck> checkWordSearch(
    String gameId,
    GridCell start,
    GridCell end,
  );

  /// Jogos da Liga: quebra-cabeça de colocar as peças na ordem certa.
  Future<OrderPuzzle> newOrderPuzzle(MinigameSubject subject);

  /// Confere a ordem (índices das peças como vieram em [OrderPuzzle.pieces]).
  Future<OrderPuzzleCheck> checkOrderPuzzle(String gameId, List<int> order);

  /// Jogos da Liga: Desafio Relâmpago, 60 segundos de contas.
  Future<LightningRound> newLightningRound(LightningTopic topic);

  /// Fecha a rodada com as respostas dadas (na ordem das contas).
  Future<LightningResult> finishLightningRound(
    String roundId,
    List<int> answers,
  );

  /// Cruzadas da Liga: palavras cruzadas com palavras do tema escolhido.
  Future<CrosswordGame> newCrossword(MinigameSubject subject);

  /// Confere a palavra digitada para a pista [index] de [CrosswordGame.clues].
  Future<CrosswordCheck> checkCrossword(
    String gameId,
    int index,
    String answer,
  );

  /// Missões do dia, com as que já foram concluídas hoje.
  Future<List<DailyMission>> loadDailyMissions();

  /// Todas as medalhas, marcando as que a criança já conquistou.
  Future<List<Achievement>> loadAchievements();

  /// Quantas atividades já valeram XP em cada origem (`matematica`,
  /// `leitura`, `arquivo`...). É o que avança as fases do Mundo da Liga.
  Future<Map<String, int>> loadActivityCounts();

  /// Histórico de atividades com a matéria de cada uma: base do progresso
  /// por matéria e do relatório semanal dos responsáveis.
  Future<LearningLog> loadLearningLog();

  /// Botão "Avisar um problema": guarda a denúncia de uma resposta da IA
  /// para a equipe revisar (exigência do Google Play para conteúdo de IA).
  Future<void> reportAiContent(AiReport report);

  /// Chefões já vencidos: id da ilha (nico, luma...) → melhor nota, de 1 a
  /// 3 estrelas.
  Future<Map<String, int>> loadBossWins();

  /// Registra a vitória contra o chefão da ilha. Devolve o XP ganho (bônus
  /// só na primeira vitória de cada ilha).
  Future<ProgressUpdate?> registerBossWin(String island, int stars);

  /// Moedas, visuais da criança e a temporada do mês.
  Future<ShopState> loadShop();

  /// Compra um visual com moedas (que vêm só de XP).
  Future<ShopState> buyVisual(String itemId);

  /// Ganha o prêmio da temporada, se o nível do mês já chegou nele.
  Future<ShopState> claimSeasonReward(String itemId);

  /// Usa um visual que a criança já tem, ou tira o do [slot] (null).
  Future<ShopState> equipVisual(VisualSlot slot, String? itemId);

  /// Salva o visual do avatar 3D. O servidor confere se cada peça já foi
  /// liberada (nível, Loja ou temporada).
  Future<void> saveAvatarLook(AvatarLook look);

  /// Editor de perfil: apelido, herói parceiro e nome do ranking. A criança
  /// pode mudar com o login dela.
  Future<void> saveGameProfile({
    required String nickname,
    required String avatarId,
    required String leagueName,
  });

  /// Ranking da Liga no período, pelo XP de acertos.
  Future<Ranking> loadRanking(RankingPeriod period);

  /// O responsável libera (ou tira) a criança [profileId] do ranking.
  Future<void> setRankingVisible(String profileId, bool visible);

  /// Liga ou desliga a autorização do responsável para a Foto + IA.
  Future<void> setAiConsent(bool allowed);

  /// Cópia de todos os dados da conta, em JSON (LGPD art. 18).
  Future<Map<String, dynamic>> exportMyData();

  /// Apaga a conta do responsável e todos os dados das crianças.
  Future<void> deleteAccount();
}
