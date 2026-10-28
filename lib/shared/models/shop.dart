import 'dart:ui';

/// Onde o visual aparece na Base.
enum VisualSlot {
  moldura('Molduras', 'Moldura'),
  aura('Auras', 'Aura'),
  pedestal('Pedestais', 'Pedestal'),
  titulo('Títulos', 'Título');

  const VisualSlot(this.label, this.singular);

  final String label;
  final String singular;

  static VisualSlot? fromName(String name) {
    for (final slot in values) {
      if (slot.name == name) return slot;
    }
    return null;
  }
}

/// Um visual da loja ou da temporada. Ids, preços e níveis são os mesmos de
/// `catalogo_visuais` (migration 0011), que é quem confere de verdade.
class VisualItem {
  const VisualItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.colors,
    this.price,
    this.seasonLevel,
  });

  final String id;
  final VisualSlot slot;
  final String name;

  /// Cores do visual (uma ou mais, para gradiente).
  final List<Color> colors;

  /// Preço em moedas; nulo para prêmio da temporada.
  final int? price;

  /// Nível da temporada que libera o prêmio.
  final int? seasonLevel;

  bool get isSeasonReward => seasonLevel != null;

  static const all = [
    VisualItem(
      id: 'moldura_ouro',
      slot: VisualSlot.moldura,
      name: 'Moldura de Ouro',
      colors: [Color(0xFFFFE680), Color(0xFFFFB800)],
      price: 40,
    ),
    VisualItem(
      id: 'moldura_neon',
      slot: VisualSlot.moldura,
      name: 'Moldura Neon',
      colors: [Color(0xFF3DF5C8), Color(0xFF00B3FF)],
      price: 60,
    ),
    VisualItem(
      id: 'moldura_arco_iris',
      slot: VisualSlot.moldura,
      name: 'Moldura Arco-íris',
      colors: [
        Color(0xFFFF4757),
        Color(0xFFFFB800),
        Color(0xFF2ED573),
        Color(0xFF1E90FF),
        Color(0xFF9B59F5),
      ],
      price: 90,
    ),
    VisualItem(
      id: 'moldura_cometa',
      slot: VisualSlot.moldura,
      name: 'Moldura Cometa',
      colors: [Color(0xFFFFFFFF), Color(0xFF7DD3FF), Color(0xFF5B4BFF)],
      seasonLevel: 20,
    ),
    VisualItem(
      id: 'aura_glacial',
      slot: VisualSlot.aura,
      name: 'Aura Glacial',
      colors: [Color(0xFF9EEBFF), Color(0xFF2FA8FF)],
      price: 50,
    ),
    VisualItem(
      id: 'aura_fogo',
      slot: VisualSlot.aura,
      name: 'Aura de Fogo',
      colors: [Color(0xFFFFD25A), Color(0xFFFF5A1F)],
      price: 80,
    ),
    VisualItem(
      id: 'aura_estelar',
      slot: VisualSlot.aura,
      name: 'Aura Estelar',
      colors: [Color(0xFFF3B8FF), Color(0xFF8A4DFF)],
      price: 120,
    ),
    VisualItem(
      id: 'aura_relampago',
      slot: VisualSlot.aura,
      name: 'Aura Relâmpago',
      colors: [Color(0xFFFFF59E), Color(0xFF00E5FF)],
      seasonLevel: 10,
    ),
    VisualItem(
      id: 'aura_lendaria',
      slot: VisualSlot.aura,
      name: 'Aura Lendária',
      colors: [Color(0xFFFFE680), Color(0xFFFF4FB0), Color(0xFF6A5CFF)],
      seasonLevel: 30,
    ),
    VisualItem(
      id: 'pedestal_pedra',
      slot: VisualSlot.pedestal,
      name: 'Pedestal de Pedra',
      colors: [Color(0xFFB7BCC9), Color(0xFF6E7488)],
      price: 30,
    ),
    VisualItem(
      id: 'pedestal_cristal',
      slot: VisualSlot.pedestal,
      name: 'Pedestal de Cristal',
      colors: [Color(0xFFB9FFF4), Color(0xFF29C7C1)],
      price: 70,
    ),
    VisualItem(
      id: 'pedestal_lava',
      slot: VisualSlot.pedestal,
      name: 'Pedestal de Lava',
      colors: [Color(0xFFFFA24D), Color(0xFFD7263D)],
      price: 100,
    ),
    VisualItem(
      id: 'pedestal_nuvem',
      slot: VisualSlot.pedestal,
      name: 'Pedestal de Nuvem',
      colors: [Color(0xFFFFFFFF), Color(0xFFC7D7FF)],
      seasonLevel: 15,
    ),
    VisualItem(
      id: 'titulo_curioso',
      slot: VisualSlot.titulo,
      name: 'O Curioso',
      colors: [Color(0xFF7DFCD9)],
      price: 20,
    ),
    VisualItem(
      id: 'titulo_mestre_contas',
      slot: VisualSlot.titulo,
      name: 'Mestre das Contas',
      colors: [Color(0xFF6FB6FF)],
      price: 60,
    ),
    VisualItem(
      id: 'titulo_detetive',
      slot: VisualSlot.titulo,
      name: 'Detetive das Palavras',
      colors: [Color(0xFFFF9EC7)],
      price: 60,
    ),
    VisualItem(
      id: 'titulo_explorador',
      slot: VisualSlot.titulo,
      name: 'Explorador do Mundo',
      colors: [Color(0xFF8DF07A)],
      price: 60,
    ),
    VisualItem(
      id: 'titulo_estreante',
      slot: VisualSlot.titulo,
      name: 'Estreante da Temporada',
      colors: [Color(0xFFFFE680)],
      seasonLevel: 5,
    ),
    VisualItem(
      id: 'titulo_campeao',
      slot: VisualSlot.titulo,
      name: 'Campeão da Temporada',
      colors: [Color(0xFFFFB800)],
      seasonLevel: 25,
    ),
  ];

  static VisualItem? byId(String? id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// A temporada do mês: o XP do mês sobe uma trilha de [maxLevel] níveis.
class SeasonState {
  const SeasonState({required this.id, required this.xp, required this.endsAt});

  factory SeasonState.fromJson(Map<String, dynamic> json) => SeasonState(
    id: json['id'] as String? ?? '',
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    endsAt:
        DateTime.tryParse(json['termina_em'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  /// Mês da temporada, `AAAA-MM`.
  final String id;
  final int xp;
  final DateTime endsAt;

  static const maxLevel = 30;

  /// XP por nível (mesma conta de `resgatar_temporada` no banco).
  static const xpPerLevel = 50;

  int get level => (xp ~/ xpPerLevel).clamp(0, maxLevel);

  /// Quanto falta do nível atual para o próximo, de 0 a 1.
  double get levelProgress =>
      level >= maxLevel ? 1 : (xp % xpPerLevel) / xpPerLevel;

  int get daysLeft {
    final left = endsAt.difference(DateTime.now()).inHours / 24;
    return left.ceil().clamp(0, 31);
  }

  static const _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  /// Nome da temporada, como "Temporada de Outubro".
  String get name {
    final month = int.tryParse(id.split('-').last) ?? 0;
    return month >= 1 && month <= 12
        ? 'Temporada de ${_months[month - 1]}'
        : 'Temporada';
  }
}

/// Moedas, visuais da criança e temporada.
class ShopState {
  const ShopState({
    required this.coins,
    required this.owned,
    required this.equipped,
    required this.season,
  });

  factory ShopState.fromJson(Map<String, dynamic> json) {
    final equipped = <VisualSlot, String>{};
    final raw = json['equipados'];
    if (raw is Map) {
      raw.forEach((slot, item) {
        final parsed = VisualSlot.fromName('$slot');
        if (parsed != null && item is String) equipped[parsed] = item;
      });
    }
    return ShopState(
      coins: (json['moedas'] as num?)?.toInt() ?? 0,
      owned: {for (final id in json['itens'] as List? ?? const []) '$id'},
      equipped: equipped,
      season: SeasonState.fromJson(
        Map<String, dynamic>.from(json['temporada'] as Map? ?? const {}),
      ),
    );
  }

  /// Moedas: 1 a cada 10 XP ganho, menos o que já foi gasto.
  final int coins;
  final Set<String> owned;
  final Map<VisualSlot, String> equipped;
  final SeasonState season;

  /// XP que vale uma moeda.
  static const xpPerCoin = 10;

  VisualItem? equippedIn(VisualSlot slot) => VisualItem.byId(equipped[slot]);
}
