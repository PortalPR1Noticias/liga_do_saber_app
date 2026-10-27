import 'package:flutter/foundation.dart';

import '../models/child_profile.dart';
import '../models/league_progress.dart';
import '../models/math_challenge.dart';
import '../models/photo_explanation.dart';
import '../models/reading_case.dart';
import '../models/writing_feedback.dart';
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
///
/// Avisa os ouvintes quando o perfil muda (XP, nível, sequência), para o
/// cabeçalho da Liga se atualizar ao voltar de uma atividade.
abstract class AppRepository extends ChangeNotifier {
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

  /// Detetive da Leitura: a Luma cria um caso novo (texto + 3 perguntas).
  Future<ReadingCase> newReadingCase();

  /// Confere as respostas (índice da opção escolhida em cada pergunta).
  Future<ReadingCaseResult> answerReadingCase(String caseId, List<int> answers);

  /// Arena Matemática: o Nico cria um desafio do tema escolhido.
  Future<MathChallenge> newMathChallenge(MathTopic topic);

  Future<MathAnswerResult> answerMathChallenge(String challengeId, int choice);

  /// Mostra a resolução (depois disso o desafio não vale mais XP).
  Future<MathSolution> revealMathSolution(String challengeId);

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

  /// Missões do dia, com as que já foram concluídas hoje.
  Future<List<DailyMission>> loadDailyMissions();

  /// Todas as medalhas, marcando as que a criança já conquistou.
  Future<List<Achievement>> loadAchievements();
}
