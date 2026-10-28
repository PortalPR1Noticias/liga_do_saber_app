import 'dart:math' as math;
import 'dart:ui';

/// Partes do avatar da criança. A chave é a mesma do JSON salvo em
/// `perfis_criancas.avatar_visual` e da tabela `pecas_avatar` (migration
/// 0015).
enum AvatarCategory {
  pele('pele', 'Pele'),
  cabelo('cabelo', 'Cabelo'),
  corCabelo('cor_cabelo', 'Cor do cabelo'),
  olhos('olhos', 'Olhos'),
  corOlhos('cor_olhos', 'Cor dos olhos'),
  boca('boca', 'Boca'),
  camisa('camisa', 'Camisa'),
  calca('calca', 'Calça'),
  tenis('tenis', 'Tênis'),
  chapeu('chapeu', 'Na cabeça', optional: true),
  oculos('oculos', 'Óculos', optional: true),
  costas('costas', 'Costas', optional: true);

  const AvatarCategory(this.key, this.label, {this.optional = false});

  final String key;
  final String label;

  /// Pode ficar sem nada (chapéu, óculos e costas).
  final bool optional;

  static AvatarCategory? fromKey(String key) {
    for (final category in values) {
      if (category.key == key) return category;
    }
    return null;
  }
}

/// Uma peça do avatar. Pele, cabelo, olhos e boca são sempre livres, para a
/// criança poder ficar parecida com ela desde o começo; roupas e acessórios
/// liberam com o nível, com moedas da Loja ou com a temporada.
///
/// Ids, níveis, preços e níveis da temporada são os mesmos de `pecas_avatar`
/// e `catalogo_visuais` (migration 0015), que é quem confere de verdade.
class AvatarPart {
  const AvatarPart(
    this.id,
    this.category,
    this.name, {
    required this.colors,
    this.style = '',
    this.minLevel = 1,
    this.price,
    this.seasonLevel,
  });

  final String id;
  final AvatarCategory category;
  final String name;

  /// Cor principal e, quando tem, a cor do detalhe.
  final List<Color> colors;

  /// Formato da peça (por exemplo `bone`, `shorts`, `rabo`).
  final String style;

  /// Nível da criança que libera a peça (1 = livre desde o começo).
  final int minLevel;

  /// Preço em moedas na Loja da Liga.
  final int? price;

  /// Nível da temporada que dá a peça de prêmio.
  final int? seasonLevel;

  Color get color => colors.first;
  Color get detail => colors.length > 1 ? colors[1] : colors.first;

  /// Peça que vem da Loja ou da temporada (fica em `compras_visuais`).
  bool get fromShop => price != null || seasonLevel != null;

  /// A criança já pode usar: nível alcançado ou peça ganha na Loja.
  bool isUnlocked({required int level, required Set<String> owned}) =>
      fromShop ? owned.contains(id) : level >= minLevel;

  /// Texto curto de como liberar.
  String get unlockLabel => price != null
      ? '$price moedas'
      : seasonLevel != null
      ? 'Temporada nível $seasonLevel'
      : 'Nível $minLevel';

  static const _white = Color(0xFFFFFFFF);
  static const _navy = Color(0xFF1B2A5E);

  static const all = <AvatarPart>[
    // Pele: oito tons, todos livres.
    AvatarPart(
      'pele_1',
      AvatarCategory.pele,
      'Tom 1',
      colors: [Color(0xFFFFE3CC)],
    ),
    AvatarPart(
      'pele_2',
      AvatarCategory.pele,
      'Tom 2',
      colors: [Color(0xFFF7CDA8)],
    ),
    AvatarPart(
      'pele_3',
      AvatarCategory.pele,
      'Tom 3',
      colors: [Color(0xFFE9B489)],
    ),
    AvatarPart(
      'pele_4',
      AvatarCategory.pele,
      'Tom 4',
      colors: [Color(0xFFD49A69)],
    ),
    AvatarPart(
      'pele_5',
      AvatarCategory.pele,
      'Tom 5',
      colors: [Color(0xFFBA7E4C)],
    ),
    AvatarPart(
      'pele_6',
      AvatarCategory.pele,
      'Tom 6',
      colors: [Color(0xFF9B6337)],
    ),
    AvatarPart(
      'pele_7',
      AvatarCategory.pele,
      'Tom 7',
      colors: [Color(0xFF7A4A27)],
    ),
    AvatarPart(
      'pele_8',
      AvatarCategory.pele,
      'Tom 8',
      colors: [Color(0xFF5A351A)],
    ),

    // Cabelo: todos os formatos livres.
    AvatarPart(
      'cabelo_curto',
      AvatarCategory.cabelo,
      'Curtinho',
      colors: [_navy],
      style: 'curto',
    ),
    AvatarPart(
      'cabelo_ondulado',
      AvatarCategory.cabelo,
      'Ondulado longo',
      colors: [_navy],
      style: 'ondulado',
    ),
    AvatarPart(
      'cabelo_franja',
      AvatarCategory.cabelo,
      'Franja',
      colors: [_navy],
      style: 'franja',
    ),
    AvatarPart(
      'cabelo_longo_franja',
      AvatarCategory.cabelo,
      'Longo com franja',
      colors: [_navy],
      style: 'longo_franja',
    ),
    AvatarPart(
      'cabelo_espetado',
      AvatarCategory.cabelo,
      'Espetado',
      colors: [_navy],
      style: 'espetado',
    ),
    AvatarPart(
      'cabelo_chanel',
      AvatarCategory.cabelo,
      'Chanel',
      colors: [_navy],
      style: 'chanel',
    ),
    AvatarPart(
      'cabelo_cacheado',
      AvatarCategory.cabelo,
      'Cacheado',
      colors: [_navy],
      style: 'cacheado',
    ),
    AvatarPart(
      'cabelo_rabo_alto',
      AvatarCategory.cabelo,
      'Rabo alto',
      colors: [_navy],
      style: 'rabo_alto',
    ),
    AvatarPart(
      'cabelo_black',
      AvatarCategory.cabelo,
      'Black power',
      colors: [_navy],
      style: 'black',
    ),
    AvatarPart(
      'cabelo_coque_duplo',
      AvatarCategory.cabelo,
      'Coque duplo',
      colors: [_navy],
      style: 'coque_duplo',
    ),
    AvatarPart(
      'cabelo_longo',
      AvatarCategory.cabelo,
      'Longo',
      colors: [_navy],
      style: 'longo',
    ),
    AvatarPart(
      'cabelo_tranca_lateral',
      AvatarCategory.cabelo,
      'Trança de lado',
      colors: [_navy],
      style: 'tranca_lateral',
    ),
    AvatarPart(
      'cabelo_rabo',
      AvatarCategory.cabelo,
      'Rabo de cavalo',
      colors: [_navy],
      style: 'rabo',
    ),
    AvatarPart(
      'cabelo_coque',
      AvatarCategory.cabelo,
      'Coque',
      colors: [_navy],
      style: 'coque',
    ),
    AvatarPart(
      'cabelo_trancas',
      AvatarCategory.cabelo,
      'Trancinhas',
      colors: [_navy],
      style: 'trancas',
    ),
    AvatarPart(
      'cabelo_chiquinha',
      AvatarCategory.cabelo,
      'Maria-chiquinha',
      colors: [_navy],
      style: 'chiquinha',
    ),
    AvatarPart(
      'cabelo_careca',
      AvatarCategory.cabelo,
      'Sem cabelo',
      colors: [_navy],
      style: 'careca',
    ),

    // Cor do cabelo: naturais livres, coloridas pelo nível.
    AvatarPart(
      'cor_preto',
      AvatarCategory.corCabelo,
      'Preto',
      colors: [Color(0xFF221C1C)],
    ),
    AvatarPart(
      'cor_castanho_claro',
      AvatarCategory.corCabelo,
      'Castanho-claro',
      colors: [Color(0xFF9A6A3E)],
    ),
    AvatarPart(
      'cor_castanho_escuro',
      AvatarCategory.corCabelo,
      'Castanho-escuro',
      colors: [Color(0xFF3E2617)],
    ),
    AvatarPart(
      'cor_loiro_claro',
      AvatarCategory.corCabelo,
      'Loiro-claro',
      colors: [Color(0xFFF3DE9C)],
    ),
    AvatarPart(
      'cor_castanho',
      AvatarCategory.corCabelo,
      'Castanho',
      colors: [Color(0xFF6E4427)],
    ),
    AvatarPart(
      'cor_loiro',
      AvatarCategory.corCabelo,
      'Loiro',
      colors: [Color(0xFFE6C068)],
    ),
    AvatarPart(
      'cor_ruivo',
      AvatarCategory.corCabelo,
      'Ruivo',
      colors: [Color(0xFFC4532B)],
    ),
    AvatarPart(
      'cor_lilas',
      AvatarCategory.corCabelo,
      'Lilás',
      colors: [Color(0xFFC59CFF)],
      minLevel: 2,
    ),
    AvatarPart(
      'cor_azul',
      AvatarCategory.corCabelo,
      'Azul',
      colors: [Color(0xFF2F7BFF)],
      minLevel: 3,
    ),
    AvatarPart(
      'cor_rosa',
      AvatarCategory.corCabelo,
      'Rosa',
      colors: [Color(0xFFFF6FB5)],
      minLevel: 4,
    ),
    AvatarPart(
      'cor_roxo',
      AvatarCategory.corCabelo,
      'Roxo',
      colors: [Color(0xFF8E4DFF)],
      minLevel: 6,
    ),
    AvatarPart(
      'cor_verde',
      AvatarCategory.corCabelo,
      'Verde neon',
      colors: [Color(0xFF3EE07A)],
      minLevel: 8,
    ),

    // Olhos e cor dos olhos: livres.
    AvatarPart(
      'olhos_redondos',
      AvatarCategory.olhos,
      'Redondos',
      colors: [_navy],
      style: 'redondos',
    ),
    AvatarPart(
      'olhos_cilios',
      AvatarCategory.olhos,
      'Com cílios',
      colors: [_navy],
      style: 'cilios',
    ),
    AvatarPart(
      'olhos_grandes',
      AvatarCategory.olhos,
      'Brilhantes',
      colors: [_navy],
      style: 'grandes',
    ),
    AvatarPart(
      'olhos_cilios_grandes',
      AvatarCategory.olhos,
      'Brilhantes com cílios',
      colors: [_navy],
      style: 'cilios_grandes',
    ),
    AvatarPart(
      'olhos_felizes',
      AvatarCategory.olhos,
      'Felizes',
      colors: [_navy],
      style: 'felizes',
    ),
    AvatarPart(
      'olhos_piscadinha',
      AvatarCategory.olhos,
      'Piscadinha',
      colors: [_navy],
      style: 'piscadinha',
    ),
    AvatarPart(
      'olhos_determinados',
      AvatarCategory.olhos,
      'Determinados',
      colors: [_navy],
      style: 'determinados',
    ),
    AvatarPart(
      'iris_castanho',
      AvatarCategory.corOlhos,
      'Castanhos',
      colors: [Color(0xFF5A3418)],
    ),
    AvatarPart(
      'iris_preto',
      AvatarCategory.corOlhos,
      'Pretos',
      colors: [Color(0xFF1C1A22)],
    ),
    AvatarPart(
      'iris_mel',
      AvatarCategory.corOlhos,
      'Mel',
      colors: [Color(0xFFB07A2A)],
    ),
    AvatarPart(
      'iris_verde',
      AvatarCategory.corOlhos,
      'Verdes',
      colors: [Color(0xFF3C8A4E)],
    ),
    AvatarPart(
      'iris_azul',
      AvatarCategory.corOlhos,
      'Azuis',
      colors: [Color(0xFF2F78C8)],
    ),

    // Boca: livre.
    AvatarPart(
      'boca_sorriso',
      AvatarCategory.boca,
      'Sorriso',
      colors: [_navy],
      style: 'sorriso',
    ),
    AvatarPart(
      'boca_doce',
      AvatarCategory.boca,
      'Sorriso doce',
      colors: [Color(0xFFD9506F)],
      style: 'doce',
    ),
    AvatarPart(
      'boca_sorrisao',
      AvatarCategory.boca,
      'Sorrisão',
      colors: [_navy],
      style: 'sorrisao',
    ),
    AvatarPart(
      'boca_brilho',
      AvatarCategory.boca,
      'Brilho rosa',
      colors: [Color(0xFFE85C8A)],
      style: 'brilho',
    ),
    AvatarPart(
      'boca_tranquila',
      AvatarCategory.boca,
      'Tranquila',
      colors: [_navy],
      style: 'tranquila',
    ),
    AvatarPart(
      'boca_surpresa',
      AvatarCategory.boca,
      'Surpresa',
      colors: [_navy],
      style: 'surpresa',
    ),

    // Roupa: camisetas, blusas e vestidos. Tudo livre para qualquer criança.
    AvatarPart(
      'camiseta_azul',
      AvatarCategory.camisa,
      'Camiseta azul',
      colors: [Color(0xFF2F80ED), _white],
      style: 'camiseta',
    ),
    AvatarPart(
      'camiseta_lilas',
      AvatarCategory.camisa,
      'Camiseta lilás',
      colors: [Color(0xFFB48CF2), _white],
      style: 'camiseta',
    ),
    AvatarPart(
      'camiseta_vermelha',
      AvatarCategory.camisa,
      'Camiseta vermelha',
      colors: [Color(0xFFE84545), _white],
      style: 'camiseta',
    ),
    AvatarPart(
      'blusa_coracao',
      AvatarCategory.camisa,
      'Blusa coração',
      colors: [Color(0xFFFFFFFF), Color(0xFFFF5C8A)],
      style: 'coracao',
    ),
    AvatarPart(
      'camiseta_verde',
      AvatarCategory.camisa,
      'Camiseta verde',
      colors: [Color(0xFF27AE60), _white],
      style: 'camiseta',
    ),
    AvatarPart(
      'blusa_babado',
      AvatarCategory.camisa,
      'Blusa de babado',
      colors: [Color(0xFFFFB3D1), _white],
      style: 'babado',
    ),
    AvatarPart(
      'camiseta_amarela',
      AvatarCategory.camisa,
      'Camiseta amarela',
      colors: [Color(0xFFF2C94C), _white],
      style: 'camiseta',
    ),
    AvatarPart(
      'vestido_rosa',
      AvatarCategory.camisa,
      'Vestido rosa',
      colors: [Color(0xFFFF7EB6), _white],
      style: 'vestido',
    ),
    AvatarPart(
      'camiseta_rosa',
      AvatarCategory.camisa,
      'Camiseta rosa',
      colors: [Color(0xFFFF7EB6), _white],
      style: 'camiseta',
    ),
    AvatarPart(
      'vestido_floral',
      AvatarCategory.camisa,
      'Vestido floral',
      colors: [Color(0xFF7FD6C2), Color(0xFFFFE066)],
      style: 'floral',
    ),
    AvatarPart(
      'vestido_amarelo',
      AvatarCategory.camisa,
      'Vestido amarelo',
      colors: [Color(0xFFFFD45C), _white],
      style: 'vestido',
    ),
    AvatarPart(
      'camiseta_liga',
      AvatarCategory.camisa,
      'Camiseta da Liga',
      colors: [Color(0xFF1B2A5E), Color(0xFFFFC233)],
      style: 'liga',
      minLevel: 2,
    ),
    AvatarPart(
      'moletom_rosa',
      AvatarCategory.camisa,
      'Moletom rosa',
      colors: [Color(0xFFFF8FC0), Color(0xFFFFE3EF)],
      style: 'moletom',
      minLevel: 2,
    ),
    AvatarPart(
      'camisa_listrada',
      AvatarCategory.camisa,
      'Listrada',
      colors: [_white, Color(0xFF2F80ED)],
      style: 'listrada',
      minLevel: 3,
    ),
    AvatarPart(
      'vestido_estrelas',
      AvatarCategory.camisa,
      'Vestido de estrelas',
      colors: [Color(0xFF6C4BD8), Color(0xFFFFE066)],
      style: 'estrelas',
      minLevel: 3,
    ),
    AvatarPart(
      'moletom_roxo',
      AvatarCategory.camisa,
      'Moletom roxo',
      colors: [Color(0xFF8E5BE8), Color(0xFFE3D4FF)],
      style: 'moletom',
      minLevel: 4,
    ),
    AvatarPart(
      'jaqueta_explorador',
      AvatarCategory.camisa,
      'Jaqueta de explorador',
      colors: [Color(0xFF9B7447), Color(0xFF4E7D3A)],
      style: 'jaqueta',
      minLevel: 6,
    ),
    AvatarPart(
      'uniforme_heroi',
      AvatarCategory.camisa,
      'Uniforme de herói',
      colors: [Color(0xFF1E6FE8), Color(0xFFFFC233)],
      style: 'heroi',
      minLevel: 9,
    ),
    AvatarPart(
      'vestido_princesa',
      AvatarCategory.camisa,
      'Vestido de princesa',
      colors: [Color(0xFFE9A6FF), Color(0xFFFFD45C)],
      style: 'princesa',
      price: 100,
    ),
    AvatarPart(
      'camisa_galaxia',
      AvatarCategory.camisa,
      'Camisa Galáxia',
      colors: [Color(0xFF3A2A8C), _white],
      style: 'galaxia',
      price: 80,
    ),
    AvatarPart(
      'jaqueta_neon',
      AvatarCategory.camisa,
      'Jaqueta Neon',
      colors: [Color(0xFF14E3C5), Color(0xFFFF4FB0)],
      style: 'jaqueta',
      price: 120,
    ),
    AvatarPart(
      'armadura_dourada',
      AvatarCategory.camisa,
      'Armadura Dourada',
      colors: [Color(0xFFFFC94A), Color(0xFFB8860B)],
      style: 'armadura',
      seasonLevel: 22,
    ),

    // Calças, saias, leggings e shorts.
    AvatarPart(
      'calca_jeans',
      AvatarCategory.calca,
      'Calça jeans',
      colors: [Color(0xFF3D5A98)],
      style: 'calca',
    ),
    AvatarPart(
      'saia_jeans',
      AvatarCategory.calca,
      'Saia jeans',
      colors: [Color(0xFF5B7BC0)],
      style: 'saia',
    ),
    AvatarPart(
      'calca_preta',
      AvatarCategory.calca,
      'Calça preta',
      colors: [Color(0xFF2B2B36)],
      style: 'calca',
    ),
    AvatarPart(
      'legging_rosa',
      AvatarCategory.calca,
      'Legging rosa',
      colors: [Color(0xFFFF8FC0)],
      style: 'calca',
    ),
    AvatarPart(
      'shorts_vermelho',
      AvatarCategory.calca,
      'Shorts vermelho',
      colors: [Color(0xFFD64040)],
      style: 'shorts',
    ),
    AvatarPart(
      'legging_lilas',
      AvatarCategory.calca,
      'Legging lilás',
      colors: [Color(0xFFB48CF2)],
      style: 'calca',
    ),
    AvatarPart(
      'saia_rosa',
      AvatarCategory.calca,
      'Saia rosa',
      colors: [Color(0xFFFF8FC8)],
      style: 'saia',
    ),
    AvatarPart(
      'shorts_jeans',
      AvatarCategory.calca,
      'Shorts jeans',
      colors: [Color(0xFF5B7BC0)],
      style: 'shorts',
    ),
    AvatarPart(
      'saia_xadrez',
      AvatarCategory.calca,
      'Saia xadrez',
      colors: [Color(0xFFE84545), Color(0xFF1B2A5E)],
      style: 'xadrez',
      minLevel: 2,
    ),
    AvatarPart(
      'bermuda_cargo',
      AvatarCategory.calca,
      'Bermuda cargo',
      colors: [Color(0xFF6E7B3C)],
      style: 'shorts',
      minLevel: 3,
    ),
    AvatarPart(
      'saia_tule',
      AvatarCategory.calca,
      'Saia de tule',
      colors: [Color(0xFFFFB3D1), _white],
      style: 'tule',
      minLevel: 4,
    ),
    AvatarPart(
      'calca_esportiva',
      AvatarCategory.calca,
      'Calça esportiva',
      colors: [Color(0xFF1B2A5E), _white],
      style: 'esportiva',
      minLevel: 5,
    ),
    AvatarPart(
      'calca_espacial',
      AvatarCategory.calca,
      'Calça espacial',
      colors: [Color(0xFFC9D3E6), Color(0xFF5B6CFF)],
      style: 'esportiva',
      price: 70,
    ),

    // Tênis, sapatilhas e botas.
    AvatarPart(
      'tenis_branco',
      AvatarCategory.tenis,
      'Tênis branco',
      colors: [Color(0xFFF4F6FA), Color(0xFF9AA5BE)],
      style: 'tenis',
    ),
    AvatarPart(
      'sapatilha_rosa',
      AvatarCategory.tenis,
      'Sapatilha rosa',
      colors: [Color(0xFFFF8FC0), Color(0xFFFFE3EF)],
      style: 'sapatilha',
    ),
    AvatarPart(
      'tenis_preto',
      AvatarCategory.tenis,
      'Tênis preto',
      colors: [Color(0xFF2B2B36), _white],
      style: 'tenis',
    ),
    AvatarPart(
      'sapatilha_dourada',
      AvatarCategory.tenis,
      'Sapatilha dourada',
      colors: [Color(0xFFFFC94A), _white],
      style: 'sapatilha',
    ),
    AvatarPart(
      'tenis_azul',
      AvatarCategory.tenis,
      'Tênis azul',
      colors: [Color(0xFF2F80ED), _white],
      style: 'tenis',
    ),
    AvatarPart(
      'tenis_rosa',
      AvatarCategory.tenis,
      'Tênis rosa',
      colors: [Color(0xFFFF8FC0), _white],
      style: 'tenis',
    ),
    AvatarPart(
      'tenis_lilas',
      AvatarCategory.tenis,
      'Tênis lilás',
      colors: [Color(0xFFB48CF2), _white],
      style: 'tenis',
    ),
    AvatarPart(
      'tenis_vermelho',
      AvatarCategory.tenis,
      'Tênis vermelho',
      colors: [Color(0xFFE84545), _white],
      style: 'tenis',
      minLevel: 2,
    ),
    AvatarPart(
      'tenis_brilho',
      AvatarCategory.tenis,
      'Tênis de brilho',
      colors: [Color(0xFFE9A6FF), Color(0xFFFFFFFF)],
      style: 'brilho',
      minLevel: 3,
    ),
    AvatarPart(
      'botas_explorador',
      AvatarCategory.tenis,
      'Botas de explorador',
      colors: [Color(0xFF7A5230), Color(0xFF3B2716)],
      style: 'bota',
      minLevel: 6,
    ),
    AvatarPart(
      'tenis_neon',
      AvatarCategory.tenis,
      'Tênis Neon',
      colors: [Color(0xFF3EF0B0), Color(0xFFFF4FB0)],
      style: 'tenis',
      price: 60,
    ),
    AvatarPart(
      'botas_cano_alto',
      AvatarCategory.tenis,
      'Botas de cano alto',
      colors: [Color(0xFF8E4DFF), Color(0xFF3A2A8C)],
      style: 'bota_alta',
      price: 70,
    ),
    AvatarPart(
      'tenis_dourado',
      AvatarCategory.tenis,
      'Tênis Dourado',
      colors: [Color(0xFFFFC94A), _white],
      style: 'tenis',
      seasonLevel: 12,
    ),

    // Na cabeça: bonés, laços, tiaras e coroas.
    AvatarPart(
      'laco_rosa',
      AvatarCategory.chapeu,
      'Laço rosa',
      colors: [Color(0xFFFF5C9E), Color(0xFFFFB3D1)],
      style: 'laco',
    ),
    AvatarPart(
      'laco_vermelho',
      AvatarCategory.chapeu,
      'Laço vermelho',
      colors: [Color(0xFFE84545), Color(0xFFFF9E9E)],
      style: 'laco',
    ),
    AvatarPart(
      'tiara_rosa',
      AvatarCategory.chapeu,
      'Tiara rosa',
      colors: [Color(0xFFFF7EB6), Color(0xFFFFFFFF)],
      style: 'tiara',
    ),
    AvatarPart(
      'presilhas_estrela',
      AvatarCategory.chapeu,
      'Presilhas de estrela',
      colors: [Color(0xFFFFD45C), Color(0xFFFF7EB6)],
      style: 'presilhas',
    ),
    AvatarPart(
      'bone_azul',
      AvatarCategory.chapeu,
      'Boné azul',
      colors: [Color(0xFF2F80ED), _white],
      style: 'bone',
      minLevel: 2,
    ),
    AvatarPart(
      'tiara_flores',
      AvatarCategory.chapeu,
      'Tiara de flores',
      colors: [Color(0xFF7FD6C2), Color(0xFFFF7EB6)],
      style: 'flores',
      minLevel: 2,
    ),
    AvatarPart(
      'gorro_listrado',
      AvatarCategory.chapeu,
      'Gorro listrado',
      colors: [Color(0xFFE84545), _white],
      style: 'gorro',
      minLevel: 4,
    ),
    AvatarPart(
      'coroa_flores',
      AvatarCategory.chapeu,
      'Coroa de flores',
      colors: [Color(0xFF5DBB63), Color(0xFFFFE066)],
      style: 'coroa_flores',
      minLevel: 5,
    ),
    AvatarPart(
      'chapeu_explorador',
      AvatarCategory.chapeu,
      'Chapéu de explorador',
      colors: [Color(0xFFC9A46A), Color(0xFF6B4A26)],
      style: 'explorador',
      minLevel: 7,
    ),
    AvatarPart(
      'orelhas_gato',
      AvatarCategory.chapeu,
      'Orelhas de gato',
      colors: [Color(0xFF2B2B36), Color(0xFFFF9EC7)],
      style: 'orelhas',
      price: 60,
    ),
    AvatarPart(
      'fone_gamer',
      AvatarCategory.chapeu,
      'Fone gamer',
      colors: [Color(0xFF2B2B36), Color(0xFF3EF0B0)],
      style: 'fone',
      price: 90,
    ),
    AvatarPart(
      'coroa',
      AvatarCategory.chapeu,
      'Coroa',
      colors: [Color(0xFFFFC94A), Color(0xFFE84545)],
      style: 'coroa',
      seasonLevel: 18,
    ),
    AvatarPart(
      'orelhas_coelho',
      AvatarCategory.chapeu,
      'Orelhas de coelho',
      colors: [Color(0xFFFFFFFF), Color(0xFFFFB3D1)],
      style: 'coelho',
      price: 70,
    ),

    // Óculos (os de grau são livres: muita criança usa).
    AvatarPart(
      'oculos_grau',
      AvatarCategory.oculos,
      'Óculos de grau',
      colors: [Color(0xFF1C1A22)],
      style: 'grau',
    ),
    AvatarPart(
      'oculos_gatinho',
      AvatarCategory.oculos,
      'Óculos gatinho',
      colors: [Color(0xFFFF5C9E)],
      style: 'gatinho',
    ),
    AvatarPart(
      'oculos_redondos',
      AvatarCategory.oculos,
      'Óculos redondos',
      colors: [Color(0xFFC9963A)],
      style: 'redondos',
    ),
    AvatarPart(
      'oculos_coracao',
      AvatarCategory.oculos,
      'Óculos de coração',
      colors: [Color(0xFFFF5C9E), Color(0xFFFF9EC7)],
      style: 'coracao',
      minLevel: 4,
    ),
    AvatarPart(
      'oculos_escuros',
      AvatarCategory.oculos,
      'Óculos escuros',
      colors: [Color(0xFF1C1A22)],
      style: 'escuros',
      minLevel: 5,
    ),
    AvatarPart(
      'visor_futurista',
      AvatarCategory.oculos,
      'Visor futurista',
      colors: [Color(0xFF3DF5E8), Color(0xFF2E3BFF)],
      style: 'visor',
      price: 100,
    ),

    // Costas.
    AvatarPart(
      'bolsa_transversal',
      AvatarCategory.costas,
      'Bolsinha',
      colors: [Color(0xFFFF7EB6), Color(0xFFFFD45C)],
      style: 'bolsa',
    ),
    AvatarPart(
      'mochila',
      AvatarCategory.costas,
      'Mochila',
      colors: [Color(0xFFFF8A1F), Color(0xFF1B2A5E)],
      style: 'mochila',
      minLevel: 3,
    ),
    AvatarPart(
      'capa_estrelas',
      AvatarCategory.costas,
      'Capa de estrelas',
      colors: [Color(0xFF8E4DFF), Color(0xFFFFE066)],
      style: 'capa',
      minLevel: 6,
    ),
    AvatarPart(
      'capa_heroi',
      AvatarCategory.costas,
      'Capa de herói',
      colors: [Color(0xFFE84545), Color(0xFFFFC233)],
      style: 'capa',
      minLevel: 8,
    ),
    AvatarPart(
      'jetpack',
      AvatarCategory.costas,
      'Jetpack',
      colors: [Color(0xFFB7BCC9), Color(0xFFFF8A1F)],
      style: 'jetpack',
      price: 150,
    ),
    AvatarPart(
      'asas_borboleta',
      AvatarCategory.costas,
      'Asas de borboleta',
      colors: [Color(0xFFFF9EC7), Color(0xFF8E4DFF)],
      style: 'borboleta',
      price: 130,
    ),
    AvatarPart(
      'asas_luz',
      AvatarCategory.costas,
      'Asas de luz',
      colors: [Color(0xFFFFFFFF), Color(0xFF9EE7FF)],
      style: 'asas',
      seasonLevel: 28,
    ),
  ];

  static final Map<String, AvatarPart> _byId = {
    for (final part in all) part.id: part,
  };

  static AvatarPart? byId(String? id) => _byId[id];

  static List<AvatarPart> of(AvatarCategory category) => [
    for (final part in all)
      if (part.category == category) part,
  ];
}

/// O visual completo do avatar: uma peça por categoria (chapéu, óculos e
/// costas podem ficar vazios).
class AvatarLook {
  const AvatarLook(this.parts);

  /// Visual inicial, antes da criança mexer.
  static const initial = AvatarLook({
    AvatarCategory.pele: 'pele_3',
    AvatarCategory.cabelo: 'cabelo_curto',
    AvatarCategory.corCabelo: 'cor_castanho_escuro',
    AvatarCategory.olhos: 'olhos_redondos',
    AvatarCategory.corOlhos: 'iris_castanho',
    AvatarCategory.boca: 'boca_sorriso',
    AvatarCategory.camisa: 'camiseta_azul',
    AvatarCategory.calca: 'calca_jeans',
    AvatarCategory.tenis: 'tenis_branco',
  });

  /// Lê o JSON salvo; peça desconhecida ou de outra categoria vira a padrão.
  factory AvatarLook.fromJson(Object? json) {
    if (json is! Map) return initial;
    final parts = <AvatarCategory, String>{};
    for (final category in AvatarCategory.values) {
      final part = AvatarPart.byId(json[category.key] as String?);
      if (part != null && part.category == category) {
        parts[category] = part.id;
      } else if (!category.optional) {
        parts[category] = initial.parts[category]!;
      }
    }
    return AvatarLook(parts);
  }

  final Map<AvatarCategory, String> parts;

  /// A peça da categoria (nula só nas opcionais vazias).
  AvatarPart? operator [](AvatarCategory category) =>
      AvatarPart.byId(parts[category]) ??
      (category.optional ? null : AvatarPart.byId(initial.parts[category]));

  bool wears(String partId) => parts.containsValue(partId);

  AvatarLook withPart(AvatarPart part) =>
      AvatarLook({...parts, part.category: part.id});

  AvatarLook without(AvatarCategory category) =>
      AvatarLook({...parts}..remove(category));

  Map<String, String> toJson() => {
    for (final entry in parts.entries) entry.key.key: entry.value,
  };

  /// Um visual sorteado entre as peças que a criança já tem.
  static AvatarLook random({
    required int level,
    required Set<String> owned,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final parts = <AvatarCategory, String>{};
    for (final category in AvatarCategory.values) {
      final options = [
        for (final part in AvatarPart.of(category))
          if (part.isUnlocked(level: level, owned: owned)) part,
      ];
      if (options.isEmpty) continue;
      if (category.optional && rng.nextInt(3) == 0) continue;
      parts[category] = options[rng.nextInt(options.length)].id;
    }
    return AvatarLook.fromJson({
      for (final entry in parts.entries) entry.key.key: entry.value,
    });
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarLook &&
      other.parts.length == parts.length &&
      parts.entries.every((entry) => other.parts[entry.key] == entry.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    parts.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

/// Nome que aparece no ranking: bicho + qualidade + número, sempre montado
/// destas listas (nunca texto livre), para não expor o nome da criança.
/// As mesmas listas estão em `nome_liga_valido` (migration 0015).
class LeagueName {
  static const animals = [
    'Coruja',
    'Tigre',
    'Raposa',
    'Dragão',
    'Lobo',
    'Falcão',
    'Panda',
    'Tubarão',
    'Golfinho',
    'Pinguim',
    'Cometa',
    'Foguete',
    'Robô',
    'Trovão',
    'Fênix',
    'Leão',
    'Onça',
    'Arara',
    'Tucano',
    'Capivara',
  ];

  static const qualities = [
    'Veloz',
    'Brilhante',
    'Feliz',
    'Valente',
    'Sagaz',
    'Incrível',
    'Genial',
    'Audaz',
    'Estelar',
    'Lunar',
    'Solar',
    'Radiante',
    'Leal',
    'Ágil',
    'Gentil',
  ];

  static String compose(String animal, String quality, int number) =>
      '$animal $quality $number';

  static String random([math.Random? random]) {
    final rng = random ?? math.Random();
    return compose(
      animals[rng.nextInt(animals.length)],
      qualities[rng.nextInt(qualities.length)],
      rng.nextInt(99) + 1,
    );
  }

  /// Separa o nome em bicho, qualidade e número (nulo se não for válido).
  static (String, String, int)? parse(String name) {
    final pieces = name.split(' ');
    if (pieces.length != 3) return null;
    final number = int.tryParse(pieces[2]);
    if (!animals.contains(pieces[0]) ||
        !qualities.contains(pieces[1]) ||
        number == null ||
        '$number' != pieces[2] ||
        number < 1 ||
        number > 99) {
      return null;
    }
    return (pieces[0], pieces[1], number);
  }

  static bool isValid(String name) => parse(name) != null;
}
