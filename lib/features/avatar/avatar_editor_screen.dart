import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design_system/liga_avatar_3d.dart';
import '../../shared/design_system/liga_game.dart';
import '../../shared/design_system/liga_sound.dart';
import '../../shared/design_system/liga_visuals.dart';
import '../../shared/design_system/liga_widgets.dart';
import '../../shared/models/avatar.dart';
import '../../shared/models/shop.dart';
import '../../shared/services/app_repository.dart';

/// Abas do editor; cada uma junta uma ou mais categorias.
enum _EditorTab {
  pele('Pele', Icons.face_rounded, [AvatarCategory.pele]),
  cabelo('Cabelo', Icons.content_cut_rounded, [
    AvatarCategory.cabelo,
    AvatarCategory.corCabelo,
  ]),
  rosto('Rosto', Icons.emoji_emotions_rounded, [
    AvatarCategory.olhos,
    AvatarCategory.corOlhos,
    AvatarCategory.boca,
  ]),
  camisa('Camisa', Icons.checkroom_rounded, [AvatarCategory.camisa]),
  calca('Calça', Icons.straighten_rounded, [AvatarCategory.calca]),
  tenis('Tênis', Icons.directions_run_rounded, [AvatarCategory.tenis]),
  chapeu('Chapéu', Icons.school_rounded, [AvatarCategory.chapeu]),
  oculos('Óculos', Icons.visibility_rounded, [AvatarCategory.oculos]),
  costas('Costas', Icons.backpack_rounded, [AvatarCategory.costas]);

  const _EditorTab(this.label, this.icon, this.categories);

  final String label;
  final IconData icon;
  final List<AvatarCategory> categories;
}

/// Categorias que só mudam a cor: viram bolinhas de cor no editor.
const _colorCategories = {
  AvatarCategory.pele,
  AvatarCategory.corCabelo,
  AvatarCategory.corOlhos,
};

/// Peças da cabeça: a miniatura mostra só cabeça e ombros.
const _headCategories = {
  AvatarCategory.cabelo,
  AvatarCategory.olhos,
  AvatarCategory.boca,
  AvatarCategory.chapeu,
  AvatarCategory.oculos,
};

/// Editor do avatar 3D. Pele, cabelo e rosto são livres desde o começo;
/// roupas e acessórios liberam com o nível, a Loja e a temporada.
class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key});

  static const routeName = '/avatar-3d';

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  final _saved = AppRepository.instance.childProfile.look;
  late AvatarLook _look = _saved;
  _EditorTab _tab = _EditorTab.pele;
  ShopState? _shop;
  bool _busy = false;

  int get _level => AppRepository.instance.childProfile.level;
  Set<String> get _owned => _shop?.owned ?? const {};

  @override
  void initState() {
    super.initState();
    AppRepository.instance
        .loadShop()
        .then((shop) {
          if (mounted) setState(() => _shop = shop);
        })
        .catchError((_) {});
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pick(AvatarPart part) async {
    if (part.isUnlocked(level: _level, owned: _owned)) {
      LigaSound.play(LigaSfx.toque);
      setState(() => _look = _look.withPart(part));
      return;
    }
    final price = part.price;
    final season = part.seasonLevel;
    if (price == null && season == null) {
      _say(
        'Chegue ao nível ${part.minLevel} para liberar. '
        'Cada acerto nos desafios dá XP!',
      );
      return;
    }
    final shop = _shop;
    if (shop == null) {
      _say('Abra a Loja da Liga para ganhar essa peça.');
      return;
    }
    if (season != null) {
      if (shop.season.level < season) {
        _say('É prêmio do nível $season da temporada. Continue acertando!');
        return;
      }
      await _get(part, () => AppRepository.instance.claimSeasonReward(part.id));
      return;
    }
    if (shop.coins < price!) {
      _say(
        'Faltam ${price - shop.coins} moedas. '
        'Cada 10 XP de acertos vira 1 moeda!',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comprar ${part.name}?'),
        content: Text('Custa $price moedas. Você tem ${shop.coins}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            key: const Key('confirmarCompra'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _get(part, () => AppRepository.instance.buyVisual(part.id));
  }

  /// Ganha a peça (compra ou temporada) e já veste no avatar.
  Future<void> _get(
    AvatarPart part,
    Future<ShopState> Function() action,
  ) async {
    setState(() => _busy = true);
    try {
      final shop = await action();
      if (!mounted) return;
      LigaSound.play(LigaSfx.bau);
      setState(() {
        _shop = shop;
        _look = _look.withPart(part);
      });
      _say('Nova peça: ${part.name}! Toque em Salvar para usar.');
    } on AppRepositoryException catch (error) {
      if (mounted) _say(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await AppRepository.instance.saveAvatarLook(_look);
      if (!mounted) return;
      LigaSound.play(LigaSfx.acerto);
      Navigator.of(context).pop(true);
    } on AppRepositoryException catch (error) {
      if (mounted) _say(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _shuffle() {
    LigaSound.play(LigaSfx.toque);
    setState(() => _look = AvatarLook.random(level: _level, owned: _owned));
  }

  @override
  Widget build(BuildContext context) {
    final changed = _look != _saved;
    return Scaffold(
      body: LigaNightBackground(
        glow: LigaColors.cyanGlow,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    _SquareButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: LigaGameText('Meu Avatar', size: 26, maxLines: 1),
                    ),
                    if (_shop != null) LigaCoinCounter(coins: _shop!.coins),
                  ],
                ),
              ),
              SizedBox(
                height: 236,
                child: Stack(
                  children: [
                    Center(
                      child: LigaAvatarStage(
                        key: const Key('avatarEditorStage'),
                        look: _look,
                        size: 230,
                        interactive: true,
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 12,
                      child: _SquareButton(
                        key: const Key('sortearAvatar'),
                        icon: Icons.casino_rounded,
                        color: LigaColors.adventurePurple,
                        onTap: _shuffle,
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 2,
                      child: Text(
                        'Arraste para girar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LigaNight.textSoft,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                // Todas as abas montadas (são poucas), para rolar até qualquer
                // uma.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      for (final tab in _EditorTab.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _TabChip(
                            key: ValueKey('aba-avatar-${tab.name}'),
                            tab: tab,
                            selected: tab == _tab,
                            onTap: () => setState(() => _tab = tab),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  children: [
                    for (final category in _tab.categories) ...[
                      if (_tab.categories.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            category.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      _options(category),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: LigaPlayButton(
                  key: const Key('salvarAvatar'),
                  label: 'SALVAR',
                  subtitle: changed ? 'Usar este visual' : 'Nada mudou ainda',
                  color: changed
                      ? LigaColors.progressGreen
                      : const Color(0xFF5B6390),
                  textColor: Colors.white,
                  onPressed: changed && !_busy ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _options(AvatarCategory category) {
    final parts = AvatarPart.of(category);
    final current = _look.parts[category];
    if (_colorCategories.contains(category)) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final part in parts)
            _ColorDot(
              key: ValueKey('peca-${part.id}'),
              part: part,
              selected: current == part.id,
              locked: !part.isUnlocked(level: _level, owned: _owned),
              onTap: () => _pick(part),
            ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (category.optional)
              _PartTile(
                key: ValueKey('peca-sem-${category.key}'),
                width: width,
                label: 'Nada',
                selected: current == null,
                preview: Icon(
                  Icons.block_rounded,
                  color: LigaNight.textSoft,
                  size: width * 0.4,
                ),
                onTap: () => setState(() => _look = _look.without(category)),
              ),
            for (final part in parts)
              _PartTile(
                key: ValueKey('peca-${part.id}'),
                width: width,
                label: part.name,
                selected: current == part.id,
                lockLabel: part.isUnlocked(level: _level, owned: _owned)
                    ? null
                    : part.unlockLabel,
                coins: part.price != null,
                preview: LigaAvatar3D(
                  look: _look.withPart(part),
                  size: width * 0.86,
                  bust: _headCategories.contains(category),
                  yaw: -0.35,
                ),
                onTap: () => _pick(part),
              ),
          ],
        );
      },
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = LigaNight.glass,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LigaColors.ink, width: 2.5),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _EditorTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? LigaColors.ink : Colors.white;
    return LigaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? LigaColors.cyanGlow : const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LigaColors.ink, width: 2.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              tab.label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    super.key,
    required this.part,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final AvatarPart part;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '${part.name}, ${part.unlockLabel}' : part.name,
      child: LigaPressable(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: part.color,
            border: Border.all(
              color: selected ? LigaColors.achievementYellow : LigaColors.ink,
              width: selected ? 5 : 3,
            ),
          ),
          child: locked
              ? Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x99060A28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      Text(
                        'Nv ${part.minLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              : selected
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  shadows: [Shadow(color: LigaColors.ink, blurRadius: 3)],
                )
              : null,
        ),
      ),
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    super.key,
    required this.width,
    required this.label,
    required this.selected,
    required this.preview,
    required this.onTap,
    this.lockLabel,
    this.coins = false,
  });

  final double width;
  final String label;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  /// Como liberar, quando a peça ainda está trancada.
  final String? lockLabel;

  /// A peça trancada é vendida com moedas.
  final bool coins;

  @override
  Widget build(BuildContext context) {
    final locked = lockLabel != null;
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '$label, $lockLabel' : label,
      child: LigaPressable(
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1F6F8B) : LigaNight.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? LigaColors.achievementYellow : LigaColors.ink,
              width: 3,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: width * 0.86,
                child: Opacity(
                  opacity: locked ? 0.45 : 1,
                  child: Center(child: preview),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  height: 1.1,
                ),
              ),
              if (locked) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: coins
                        ? LigaColors.primaryBlue
                        : const Color(0xFF5B6390),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LigaColors.ink, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      coins
                          ? const LigaCoinIcon(size: 12)
                          : const Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          lockLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
