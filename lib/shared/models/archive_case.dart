import 'progress_update.dart';

/// Minijogos do Arquivo da Mila (com as chaves que a Edge Function entende).
enum ArchiveMode {
  cacaPalavras('caca_palavras', 'Caça-palavras'),
  linhaDoTempo('linha_do_tempo', 'Linha do tempo'),
  documento('documento', 'Enigma do documento');

  const ArchiveMode(this.key, this.label);

  final String key;
  final String label;
}

/// Palavra escondida no caça-palavras. `key` é como ela aparece na grade
/// (maiúsculas, sem acento).
class ArchiveWord {
  const ArchiveWord({required this.word, required this.key, this.fact = ''});

  factory ArchiveWord.fromJson(Map<String, dynamic> json) {
    return ArchiveWord(
      word: json['palavra'] as String? ?? '',
      key: json['chave'] as String? ?? '',
      fact: json['fato'] as String? ?? '',
    );
  }

  final String word;
  final String key;

  /// O que a palavra tem a ver com o tema (aparece quando ela é achada).
  final String fact;
}

/// Caso criado pela IA na Edge Function `arquivo-mila` (a resposta certa e
/// os anos ficam no servidor).
class ArchiveCase {
  const ArchiveCase({
    required this.id,
    required this.mode,
    required this.title,
    required this.topic,
    required this.intro,
    this.sourceType = '',
    this.source = '',
    this.sourceOrigin = '',
    this.question = '',
    this.options = const [],
    this.events = const [],
    this.grid = const [],
    this.words = const [],
    this.xp = 20,
  });

  factory ArchiveCase.fromJson(Map<String, dynamic> json) {
    return ArchiveCase(
      id: json['caso_id'] as String,
      mode: ArchiveMode.values.firstWhere(
        (m) => m.key == json['modo'],
        orElse: () => ArchiveMode.documento,
      ),
      title: json['titulo'] as String? ?? '',
      topic: json['tema'] as String? ?? '',
      intro: json['introducao'] as String? ?? '',
      sourceType: json['fonte_tipo'] as String? ?? '',
      source: json['fonte'] as String? ?? '',
      sourceOrigin: json['origem_da_fonte'] as String? ?? '',
      question: json['pergunta'] as String? ?? '',
      options: List<String>.from(json['opcoes'] as List? ?? const []),
      events: List<String>.from(json['eventos'] as List? ?? const []),
      grid: List<String>.from(json['grade'] as List? ?? const []),
      words: [
        for (final word in json['palavras'] as List? ?? const [])
          ArchiveWord.fromJson(Map<String, dynamic>.from(word as Map)),
      ],
      xp: json['xp_possivel'] as int? ?? 20,
    );
  }

  final String id;
  final ArchiveMode mode;
  final String title;

  /// Assunto da BNCC trabalhado (por exemplo "Brasil Império").
  final String topic;

  /// O que a Mila achou no arquivo.
  final String intro;

  /// Documento: carta, foto, pintura, objeto, jornal ou mapa.
  final String sourceType;

  /// Documento: o texto da fonte ou a descrição do que se vê.
  final String source;

  /// Documento: de onde e de quando a fonte vem.
  final String sourceOrigin;
  final String question;
  final List<String> options;

  /// Linha do tempo: as fichas embaralhadas.
  final List<String> events;

  /// Caça-palavras: as linhas da grade de letras.
  final List<String> grid;
  final List<ArchiveWord> words;
  final int xp;
}

/// Explicação da Mila, mostrada quando a criança acerta ou pede para revelar.
class ArchiveSolution {
  const ArchiveSolution({
    required this.steps,
    required this.funFact,
    this.correct,
    this.order,
    this.years,
    this.positions = const [],
  });

  factory ArchiveSolution.fromJson(Map<String, dynamic> json) {
    return ArchiveSolution(
      steps: List<String>.from(json['explicacao'] as List? ?? const []),
      funFact: json['curiosidade'] as String? ?? '',
      correct: json['correta'] as int?,
      order: (json['ordem_correta'] as List?)?.cast<int>(),
      years: (json['anos'] as List?)?.cast<String>(),
      positions: [
        for (final position in json['posicoes'] as List? ?? const [])
          List<int>.from(position as List),
      ],
    );
  }

  final List<String> steps;
  final String funFact;

  /// Documento: a opção certa.
  final int? correct;

  /// Linha do tempo: posições das fichas, da mais antiga à mais recente.
  final List<int>? order;

  /// Linha do tempo: o ano de cada ficha, na ordem em que aparecem.
  final List<String>? years;

  /// Caça-palavras: [linha, coluna, passo na linha, passo na coluna] da
  /// primeira letra de cada palavra, na ordem da lista.
  final List<List<int>> positions;
}

class ArchiveAnswerResult {
  const ArchiveAnswerResult({
    required this.hit,
    required this.tip,
    required this.solution,
    required this.xp,
    this.inPlace,
    this.notice = '',
    this.progress,
  });

  factory ArchiveAnswerResult.fromJson(Map<String, dynamic> json) {
    return ArchiveAnswerResult(
      hit: json['acertou'] as bool? ?? false,
      tip: json['dica'] as String? ?? '',
      inPlace: json['no_lugar'] as int?,
      solution: ArchiveSolution.fromJson(json),
      xp: json['xp'] as int? ?? 0,
      notice: json['aviso'] as String? ?? '',
      progress: ProgressUpdate.fromJson(json['progresso']),
    );
  }

  final bool hit;

  /// Pista extra para tentar de novo (só quando errou).
  final String tip;

  /// Linha do tempo: quantas fichas ficaram no lugar certo.
  final int? inPlace;

  /// Explicação (vazia quando errou).
  final ArchiveSolution solution;
  final int xp;

  /// Aviso quando a vitória não deu XP porque o limite do dia acabou.
  final String notice;
  final ProgressUpdate? progress;
}
