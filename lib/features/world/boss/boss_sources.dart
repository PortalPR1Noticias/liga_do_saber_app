import '../../../shared/models/archive_case.dart';
import '../../../shared/models/atelier.dart';
import '../../../shared/models/expedition.dart';
import '../../../shared/models/math_challenge.dart';
import '../../../shared/models/progress_update.dart';
import '../../../shared/services/app_repository.dart';

/// Um ataque do chefão: a pergunta que a criança precisa responder para
/// bloquear o golpe.
class BossAttack {
  const BossAttack({
    required this.prompt,
    required this.options,
    this.contextTitle = '',
    this.context = '',
  });

  final String prompt;
  final List<String> options;

  /// Texto de apoio (o texto do caso, as pistas da expedição, o documento).
  final String contextTitle;
  final String context;
}

/// Resultado de uma resposta: se acertou e a explicação para quem errou.
class BossVerdict {
  const BossVerdict({required this.hit, this.hint = '', this.progress});

  final bool hit;
  final String hint;
  final ProgressUpdate? progress;
}

/// De onde vêm os ataques do chefão. As perguntas são as mesmas das
/// atividades da ilha (geradas pelas Edge Functions de sempre), então cada
/// acerto também conta XP e fase.
sealed class BossSource {
  const BossSource();
}

/// Cada ataque é conferido na hora. Se a criança errar, o herói mostra a
/// dica e ela tenta de novo o mesmo ataque.
abstract class ImmediateBossSource extends BossSource {
  const ImmediateBossSource();

  /// Ataques certos que derrubam o chefão.
  int get rounds;

  Future<BossAttack> nextAttack(int round);

  Future<BossVerdict> answer(int choice);
}

/// Todos os ataques chegam juntos e são conferidos no fim, no golpe final
/// (o servidor só corrige o caso inteiro de uma vez).
abstract class BatchBossSource extends BossSource {
  const BatchBossSource();

  Future<List<BossAttack>> load();

  Future<List<BossVerdict>> grade(List<int> choices);
}

/// Nico: contas e problemas da Arena Matemática.
class NicoBossSource extends ImmediateBossSource {
  NicoBossSource();

  static const _topics = [
    MathTopic.operacoes,
    MathTopic.problemas,
    MathTopic.fracoes,
    MathTopic.logica,
    MathTopic.operacoes,
  ];

  String? _id;

  @override
  int get rounds => _topics.length;

  @override
  Future<BossAttack> nextAttack(int round) async {
    final challenge = await AppRepository.instance.newMathChallenge(
      _topics[round % _topics.length],
    );
    _id = challenge.id;
    return BossAttack(prompt: challenge.statement, options: challenge.options);
  }

  @override
  Future<BossVerdict> answer(int choice) async {
    final result = await AppRepository.instance.answerMathChallenge(
      _id!,
      choice,
    );
    return BossVerdict(
      hit: result.hit,
      hint: result.tip.isNotEmpty ? result.tip : result.steps.join(' '),
      progress: result.progress,
    );
  }
}

/// Teo: investigações de Ciências e Geografia.
class TeoBossSource extends ImmediateBossSource {
  TeoBossSource();

  String? _id;

  @override
  int get rounds => 4;

  @override
  Future<BossAttack> nextAttack(int round) async {
    final expedition = await AppRepository.instance.newExpedition(
      round.isEven ? ExpeditionSubject.ciencias : ExpeditionSubject.geografia,
    );
    _id = expedition.id;
    return BossAttack(
      prompt: expedition.question,
      options: expedition.options,
      contextTitle: expedition.title,
      context: [
        expedition.scene,
        for (final clue in expedition.clues) '• $clue',
      ].where((line) => line.isNotEmpty).join('\n'),
    );
  }

  @override
  Future<BossVerdict> answer(int choice) async {
    final result = await AppRepository.instance.answerExpedition(_id!, choice);
    return BossVerdict(
      hit: result.hit,
      hint: result.tip,
      progress: result.progress,
    );
  }
}

/// Mila: enigmas de documentos históricos.
class MilaBossSource extends ImmediateBossSource {
  MilaBossSource();

  String? _id;

  @override
  int get rounds => 4;

  @override
  Future<BossAttack> nextAttack(int round) async {
    final archive = await AppRepository.instance.newArchiveCase(
      ArchiveMode.documento,
    );
    _id = archive.id;
    return BossAttack(
      prompt: archive.question,
      options: archive.options,
      contextTitle: archive.title,
      context: [
        archive.source,
        if (archive.sourceOrigin.isNotEmpty) '(${archive.sourceOrigin})',
      ].join('\n'),
    );
  }

  @override
  Future<BossVerdict> answer(int choice) async {
    final result = await AppRepository.instance.answerArchiveCase(
      _id!,
      choice: choice,
    );
    return BossVerdict(
      hit: result.hit,
      hint: result.tip,
      progress: result.progress,
    );
  }
}

/// Luma: um caso do Detetive da Leitura. A criança lê o texto, responde as
/// perguntas e o golpe final mostra as pistas de cada resposta.
class LumaBossSource extends BatchBossSource {
  LumaBossSource();

  String? _id;

  @override
  Future<List<BossAttack>> load() async {
    final readingCase = await AppRepository.instance.newReadingCase();
    _id = readingCase.id;
    return [
      for (final question in readingCase.questions)
        BossAttack(
          prompt: question.question,
          options: question.options,
          contextTitle: readingCase.title,
          context: readingCase.text,
        ),
    ];
  }

  @override
  Future<List<BossVerdict>> grade(List<int> choices) async {
    final result = await AppRepository.instance.answerReadingCase(
      _id!,
      choices,
    );
    return [
      for (var i = 0; i < result.answers.length; i++)
        BossVerdict(
          hit: result.answers[i].hit,
          hint: [
            if (result.answers[i].clue.isNotEmpty)
              'Pista no texto: "${result.answers[i].clue}".',
            result.answers[i].explanation,
          ].join(' '),
          progress: i == result.answers.length - 1 ? result.progress : null,
        ),
    ];
  }
}

/// Zuri: monte o mapa mental, colocando cada ideia no ramo certo.
class ZuriBossSource extends BatchBossSource {
  ZuriBossSource();

  AtelierGame? _game;

  @override
  Future<List<BossAttack>> load() async {
    final game = await AppRepository.instance.newAtelierGame(
      AtelierGameType.mapaMental,
    );
    _game = game;
    return [
      for (final piece in game.pieces)
        BossAttack(
          prompt: 'Em qual ramo entra a ideia "$piece"?',
          options: game.branches,
          contextTitle: game.title,
          context: 'Ideia central: ${game.centralIdea}',
        ),
    ];
  }

  @override
  Future<List<BossVerdict>> grade(List<int> choices) async {
    final game = _game!;
    final repository = AppRepository.instance;
    final result = await repository.checkAtelierGame(game.id, choices);
    // Quem errou alguma peça vê onde cada uma entrava (a correção já foi
    // feita, então revelar agora não muda o XP).
    final solution = result.solved
        ? result.solution
        : await repository.revealAtelierGame(game.id);
    return [
      for (var i = 0; i < game.pieces.length; i++)
        BossVerdict(
          hit: i < result.correct.length && result.correct[i],
          hint: i < solution.branchOfPiece.length
              ? '"${game.pieces[i]}" entra no ramo '
                    '"${game.branches[solution.branchOfPiece[i]]}".'
              : solution.explanation.join(' '),
          progress: i == game.pieces.length - 1 ? result.progress : null,
        ),
    ];
  }
}
