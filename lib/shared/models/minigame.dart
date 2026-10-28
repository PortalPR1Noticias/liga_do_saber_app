import 'progress_update.dart';

/// Matérias dos Jogos da Liga (as chaves que a Edge Function `minijogo`
/// entende). Cada uma tem o seu personagem guia.
enum MinigameSubject {
  portugues('Português'),
  matematica('Matemática'),
  ciencias('Ciências'),
  geografia('Geografia');

  const MinigameSubject(this.label);

  final String label;
}

/// Uma casa da grade do caça-palavras.
class GridCell {
  const GridCell(this.row, this.col);

  final int row;
  final int col;

  List<int> toJson() => [row, col];

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// Palavra escondida no caça-palavras: a criança vê a pista e o tamanho, e
/// a palavra só aparece quando ela encontra.
class WordClue {
  const WordClue({required this.clue, required this.length});

  final String clue;
  final int length;
}

/// Caça-palavras montado no servidor: a IA escolhe as palavras do tema e
/// a Edge Function esconde na grade (as posições ficam no servidor).
class WordSearchGame {
  const WordSearchGame({
    required this.id,
    required this.subject,
    required this.title,
    required this.rows,
    required this.clues,
    this.xp = 20,
  });

  factory WordSearchGame.fromJson(Map<String, dynamic> json) {
    return WordSearchGame(
      id: json['jogo_id'] as String,
      subject: MinigameSubject.values.byName(
        json['materia'] as String? ?? 'portugues',
      ),
      title: json['titulo'] as String? ?? '',
      rows: List<String>.from(json['linhas'] as List? ?? const []),
      clues: [
        for (final p in json['pistas'] as List? ?? const [])
          WordClue(
            clue: (p as Map)['pista'] as String? ?? '',
            length: p['letras'] as int? ?? 0,
          ),
      ],
      xp: json['xp_possivel'] as int? ?? 20,
    );
  }

  final String id;
  final MinigameSubject subject;
  final String title;

  /// Uma string por linha da grade, todas do mesmo tamanho.
  final List<String> rows;
  final List<WordClue> clues;
  final int xp;
}

/// Resposta ao marcar uma palavra na grade.
class WordSearchCheck {
  const WordSearchCheck({
    required this.found,
    this.index,
    this.word = '',
    this.cells = const [],
    this.finished = false,
    this.xp = 0,
    this.notice = '',
    this.progress,
  });

  factory WordSearchCheck.fromJson(Map<String, dynamic> json) {
    return WordSearchCheck(
      found: json['achou'] as bool? ?? false,
      index: json['indice'] as int?,
      word: json['palavra'] as String? ?? '',
      cells: [
        for (final c in json['casas'] as List? ?? const [])
          GridCell((c as List)[0] as int, c[1] as int),
      ],
      finished: json['terminou'] as bool? ?? false,
      xp: json['xp'] as int? ?? 0,
      notice: json['aviso'] as String? ?? '',
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool found;

  /// Qual pista foi resolvida.
  final int? index;
  final String word;
  final List<GridCell> cells;

  /// Achou todas as palavras.
  final bool finished;
  final int xp;
  final ProgressUpdate? progress;

  /// Aviso do servidor, por exemplo quando o XP de jogos do dia acabou.
  final String notice;
}

/// Quebra-cabeça de ordenar: frases, sequências, etapas ou linhas do tempo.
/// As peças chegam embaralhadas; a ordem certa fica no servidor.
class OrderPuzzle {
  const OrderPuzzle({
    required this.id,
    required this.subject,
    required this.title,
    required this.instruction,
    required this.pieces,
    this.xp = 20,
  });

  factory OrderPuzzle.fromJson(Map<String, dynamic> json) {
    return OrderPuzzle(
      id: json['jogo_id'] as String,
      subject: MinigameSubject.values.byName(
        json['materia'] as String? ?? 'portugues',
      ),
      title: json['titulo'] as String? ?? '',
      instruction: json['instrucao'] as String? ?? '',
      pieces: List<String>.from(json['pecas'] as List? ?? const []),
      xp: json['xp_possivel'] as int? ?? 20,
    );
  }

  final String id;
  final MinigameSubject subject;
  final String title;
  final String instruction;
  final List<String> pieces;
  final int xp;
}

class OrderPuzzleCheck {
  const OrderPuzzleCheck({
    required this.solved,
    required this.rightPlaces,
    this.explanation = '',
    this.xp = 0,
    this.notice = '',
    this.progress,
  });

  factory OrderPuzzleCheck.fromJson(Map<String, dynamic> json) {
    return OrderPuzzleCheck(
      solved: json['resolvido'] as bool? ?? false,
      rightPlaces: List<bool>.from(json['no_lugar'] as List? ?? const []),
      explanation: json['explicacao'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      notice: json['aviso'] as String? ?? '',
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool solved;

  /// Para cada posição, se a peça que está ali é a certa.
  final List<bool> rightPlaces;

  /// Por que essa é a ordem (só quando resolveu).
  final String explanation;
  final int xp;
  final ProgressUpdate? progress;

  /// Aviso do servidor, por exemplo quando o XP de jogos do dia acabou.
  final String notice;
}

/// Temas do Desafio Relâmpago.
enum LightningTopic {
  tabuada('Tabuada'),
  soma('Mais e menos'),
  divisao('Divisão'),
  misturado('Misturado');

  const LightningTopic(this.label);

  final String label;
}

class LightningQuestion {
  const LightningQuestion({required this.text, required this.answer});

  final String text;
  final int answer;
}

/// Rodada de 60 segundos de contas. As contas são geradas no servidor
/// (sem IA), que confere de novo as respostas para dar o XP.
class LightningRound {
  const LightningRound({
    required this.id,
    required this.questions,
    this.seconds = 60,
  });

  factory LightningRound.fromJson(Map<String, dynamic> json) {
    return LightningRound(
      id: json['jogo_id'] as String,
      questions: [
        for (final q in json['contas'] as List? ?? const [])
          LightningQuestion(
            text: (q as Map)['conta'] as String? ?? '',
            answer: q['resposta'] as int? ?? 0,
          ),
      ],
      seconds: json['segundos'] as int? ?? 60,
    );
  }

  final String id;
  final List<LightningQuestion> questions;
  final int seconds;
}

class LightningResult {
  const LightningResult({
    required this.hits,
    required this.answered,
    required this.xp,
    this.notice = '',
    this.progress,
  });

  factory LightningResult.fromJson(Map<String, dynamic> json) {
    return LightningResult(
      hits: json['acertos'] as int? ?? 0,
      answered: json['respondidas'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
      notice: json['aviso'] as String? ?? '',
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final int hits;
  final int answered;
  final int xp;
  final ProgressUpdate? progress;

  /// Aviso do servidor, por exemplo quando o XP de jogos do dia acabou.
  final String notice;
}

/// Direção de uma palavra nas Cruzadas da Liga.
enum CrosswordDirection {
  across('Horizontal'),
  down('Vertical');

  const CrosswordDirection(this.label);

  final String label;
}

/// Pista das Cruzadas: onde a palavra começa, para que lado vai e quantas
/// letras tem. A palavra só chega quando a criança acerta.
class CrosswordClue {
  const CrosswordClue({
    required this.number,
    required this.direction,
    required this.row,
    required this.col,
    required this.length,
    required this.clue,
  });

  factory CrosswordClue.fromJson(Map<String, dynamic> json) {
    return CrosswordClue(
      number: json['numero'] as int? ?? 0,
      direction: json['direcao'] == 'v'
          ? CrosswordDirection.down
          : CrosswordDirection.across,
      row: json['linha'] as int? ?? 0,
      col: json['coluna'] as int? ?? 0,
      length: json['letras'] as int? ?? 0,
      clue: json['pista'] as String? ?? '',
    );
  }

  final int number;
  final CrosswordDirection direction;
  final int row;
  final int col;
  final int length;
  final String clue;

  /// As casas da palavra na grade, da primeira à última letra.
  List<GridCell> get cells => [
    for (var k = 0; k < length; k++)
      direction == CrosswordDirection.across
          ? GridCell(row, col + k)
          : GridCell(row + k, col),
  ];
}

/// Cruzadas da Liga: a IA escolhe palavras do tema com pista e a Edge
/// Function cruza as palavras numa grade (as respostas ficam no servidor).
class CrosswordGame {
  const CrosswordGame({
    required this.id,
    required this.subject,
    required this.title,
    required this.rows,
    required this.cols,
    required this.clues,
    this.xp = 20,
  });

  factory CrosswordGame.fromJson(Map<String, dynamic> json) {
    return CrosswordGame(
      id: json['jogo_id'] as String,
      subject: MinigameSubject.values.byName(
        json['materia'] as String? ?? 'portugues',
      ),
      title: json['titulo'] as String? ?? '',
      rows: json['linhas'] as int? ?? 0,
      cols: json['colunas'] as int? ?? 0,
      clues: [
        for (final p in json['pistas'] as List? ?? const [])
          CrosswordClue.fromJson(Map<String, dynamic>.from(p as Map)),
      ],
      xp: json['xp_possivel'] as int? ?? 20,
    );
  }

  final String id;
  final MinigameSubject subject;
  final String title;
  final int rows;
  final int cols;
  final List<CrosswordClue> clues;
  final int xp;
}

/// Resposta ao conferir uma palavra das Cruzadas.
class CrosswordCheck {
  const CrosswordCheck({
    required this.correct,
    required this.index,
    this.word = '',
    this.letters = '',
    this.hint = '',
    this.finished = false,
    this.xp = 0,
    this.notice = '',
    this.progress,
  });

  factory CrosswordCheck.fromJson(Map<String, dynamic> json) {
    return CrosswordCheck(
      correct: json['certa'] as bool? ?? false,
      index: json['indice'] as int? ?? 0,
      word: json['palavra'] as String? ?? '',
      letters: json['letras'] as String? ?? '',
      hint: json['dica'] as String? ?? '',
      finished: json['terminou'] as bool? ?? false,
      xp: json['xp'] as int? ?? 0,
      notice: json['aviso'] as String? ?? '',
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool correct;
  final int index;

  /// A palavra como se escreve (com acento), para a lista de pistas.
  final String word;

  /// As letras que vão na grade (sem acento).
  final String letters;

  /// Do segundo erro em diante: as primeiras letras da palavra.
  final String hint;
  final bool finished;
  final int xp;
  final ProgressUpdate? progress;

  /// Aviso do servidor, por exemplo quando o XP de jogos do dia acabou.
  final String notice;
}

/// Letras da resposta como entram na grade: maiúsculas, sem acento e sem
/// espaço (a mesma regra do servidor).
String crosswordLetters(String text) {
  const accents = {
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', //
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', //
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I', //
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O', //
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', //
    'Ç': 'C', 'Ñ': 'N',
  };
  final buffer = StringBuffer();
  for (final char in text.toUpperCase().split('')) {
    final plain = accents[char] ?? char;
    if (RegExp('[A-Z]').hasMatch(plain)) buffer.write(plain);
  }
  return buffer.toString();
}
