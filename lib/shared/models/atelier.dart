import 'progress_update.dart';

/// Minijogos da Oficina do Zuri (as chaves que a Edge Function entende).
enum AtelierGameType {
  cacaPalavras('caca_palavras', 'Caça-palavras'),
  mapaMental('mapa_mental', 'Monte o mapa mental'),
  ordemProjeto('ordem_projeto', 'Quebra-cabeça do projeto');

  const AtelierGameType(this.key, this.label);

  final String key;
  final String label;

  static AtelierGameType fromKey(Object? key) => values.firstWhere(
    (type) => type.key == key,
    orElse: () => AtelierGameType.mapaMental,
  );
}

/// Palavra escondida no caça-palavras. [key] é a forma da grade (maiúsculas
/// sem acento) e [text] é como a palavra aparece na lista.
class HiddenWord {
  const HiddenWord({required this.text, required this.key});

  final String text;
  final String key;
}

/// Linha reta na grade do caça-palavras, de [start] até [end] (linha,
/// coluna).
class GridLine {
  const GridLine(this.start, this.end);

  factory GridLine.fromJson(Map<String, dynamic> json) {
    final start = List<int>.from(json['inicio'] as List);
    final end = List<int>.from(json['fim'] as List);
    return GridLine((start[0], start[1]), (end[0], end[1]));
  }

  final (int, int) start;
  final (int, int) end;

  /// Células da linha, ou vazio se não for reta (horizontal, vertical ou
  /// diagonal).
  List<(int, int)> get cells {
    final rows = end.$1 - start.$1;
    final cols = end.$2 - start.$2;
    if (rows != 0 && cols != 0 && rows.abs() != cols.abs()) return const [];
    final steps = rows.abs() > cols.abs() ? rows.abs() : cols.abs();
    return [
      for (var i = 0; i <= steps; i++)
        (start.$1 + rows.sign * i, start.$2 + cols.sign * i),
    ];
  }

  Map<String, dynamic> toJson() => {
    'inicio': [start.$1, start.$2],
    'fim': [end.$1, end.$2],
  };
}

/// Minijogo criado pela IA na Edge Function `atelie-zuri`. A solução fica no
/// servidor; o app só recebe as peças.
class AtelierGame {
  const AtelierGame({
    required this.id,
    required this.type,
    required this.title,
    required this.intro,
    this.grid = const [],
    this.words = const [],
    this.centralIdea = '',
    this.branches = const [],
    this.pieces = const [],
    this.xp = 20,
  });

  factory AtelierGame.fromJson(Map<String, dynamic> json) {
    return AtelierGame(
      id: json['jogo_id'] as String,
      type: AtelierGameType.fromKey(json['jogo']),
      title: json['titulo'] as String? ?? '',
      intro: json['introducao'] as String? ?? '',
      grid: List<String>.from(json['grade'] as List? ?? const []),
      words: [
        for (final word in json['palavras'] as List? ?? const [])
          HiddenWord(
            text: (word as Map)['texto'] as String? ?? '',
            key: word['chave'] as String? ?? '',
          ),
      ],
      centralIdea: json['ideia_central'] as String? ?? '',
      branches: List<String>.from(json['ramos'] as List? ?? const []),
      pieces: List<String>.from(json['pecas'] as List? ?? const []),
      xp: json['xp_possivel'] as int? ?? 20,
    );
  }

  final String id;
  final AtelierGameType type;
  final String title;
  final String intro;

  /// Caça-palavras: linhas da grade e palavras escondidas.
  final List<String> grid;
  final List<HiddenWord> words;

  /// Monte o mapa mental: centro e títulos dos ramos.
  final String centralIdea;
  final List<String> branches;

  /// Ideias do mapa mental ou etapas do projeto, embaralhadas.
  final List<String> pieces;
  final int xp;
}

/// Solução do jogo e explicação do Zuri (quando resolve ou pede para ver).
class AtelierSolution {
  const AtelierSolution({
    required this.explanation,
    this.wordLines = const [],
    this.branchOfPiece = const [],
    this.stepOfPiece = const [],
  });

  factory AtelierSolution.fromJson(Map<String, dynamic> json) {
    return AtelierSolution(
      explanation: List<String>.from(json['explicacao'] as List? ?? const []),
      wordLines: [
        for (final line in json['posicoes'] as List? ?? const [])
          GridLine.fromJson(Map<String, dynamic>.from(line as Map)),
      ],
      branchOfPiece: List<int>.from(
        json['ramo_de_cada_peca'] as List? ?? const [],
      ),
      stepOfPiece: List<int>.from(
        json['etapa_de_cada_peca'] as List? ?? const [],
      ),
    );
  }

  final List<String> explanation;

  /// Caça-palavras: onde está cada palavra.
  final List<GridLine> wordLines;

  /// Mapa mental: o ramo certo de cada peça.
  final List<int> branchOfPiece;

  /// Quebra-cabeça: a posição certa de cada peça.
  final List<int> stepOfPiece;
}

class AtelierCheckResult {
  const AtelierCheckResult({
    required this.solved,
    required this.correct,
    required this.solution,
    required this.xp,
    this.progress,
    this.notice = '',
  });

  factory AtelierCheckResult.fromJson(Map<String, dynamic> json) {
    return AtelierCheckResult(
      solved: json['resolvido'] as bool? ?? false,
      correct: List<bool>.from(json['certos'] as List? ?? const []),
      solution: AtelierSolution.fromJson(json),
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
      notice: json['aviso'] as String? ?? '',
    );
  }

  final bool solved;

  /// Um por palavra, peça ou posição, na ordem da jogada.
  final List<bool> correct;

  /// Vem preenchida só quando resolveu.
  final AtelierSolution solution;
  final int xp;
  final ProgressUpdate? progress;

  /// Aviso quando o jogo não deu XP porque o limite do dia acabou.
  final String notice;
}

class MindMapBranch {
  const MindMapBranch({required this.title, required this.ideas});

  factory MindMapBranch.fromJson(Map<String, dynamic> json) {
    return MindMapBranch(
      title: json['titulo'] as String? ?? '',
      ideas: List<String>.from(json['ideias'] as List? ?? const []),
    );
  }

  final String title;
  final List<String> ideas;
}

/// Plano do projeto da criança: mapa mental, etapas e um desafio criativo.
class ProjectPlan {
  const ProjectPlan({
    required this.title,
    required this.centralIdea,
    required this.branches,
    required this.steps,
    required this.creativeChallenge,
    required this.xp,
    this.progress,
    this.notice = '',
  });

  factory ProjectPlan.fromJson(Map<String, dynamic> json) {
    return ProjectPlan(
      title: json['titulo'] as String? ?? '',
      centralIdea: json['ideia_central'] as String? ?? '',
      branches: [
        for (final branch in json['ramos'] as List? ?? const [])
          MindMapBranch.fromJson(Map<String, dynamic>.from(branch as Map)),
      ],
      steps: List<String>.from(json['passos'] as List? ?? const []),
      creativeChallenge: json['desafio_criativo'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      progress: ProgressUpdate.fromJson(json['progresso']),
      notice: json['aviso'] as String? ?? '',
    );
  }

  final String title;
  final String centralIdea;
  final List<MindMapBranch> branches;
  final List<String> steps;
  final String creativeChallenge;
  final int xp;
  final ProgressUpdate? progress;

  /// Aviso quando o projeto não deu XP porque o limite do dia acabou.
  final String notice;
}
