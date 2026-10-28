import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design_system/liga_game.dart';
import '../../shared/design_system/liga_rewards.dart';
import '../../shared/design_system/liga_sound.dart';
import '../../shared/design_system/liga_visuals.dart';
import '../../shared/design_system/liga_widgets.dart';
import '../../shared/models/avatar.dart';
import '../../shared/models/shop.dart';
import '../../shared/services/app_repository.dart';

/// Loja de visuais e trilha da temporada. Tudo aqui é só aparência: as moedas
/// vêm do XP das respostas certas e nada é vendido por dinheiro.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.season = false});

  static const routeName = '/loja';

  /// Abre direto na aba da temporada.
  final bool season;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ShopState? _shop;
  String? _error;
  bool _busy = false;
  late bool _season = widget.season;
  VisualSlot _slot = VisualSlot.moldura;

  String get _avatarId => AppRepository.instance.childProfile.avatarId;
  AvatarLook get _look => AppRepository.instance.childProfile.look;

  /// Roupas do avatar são vestidas no avatar 3D; os outros visuais vão para
  /// `visuais_equipados`.
  bool _using(ShopState shop, VisualItem item) => item.slot == VisualSlot.roupa
      ? _look.wears(item.id)
      : shop.equipped[item.slot] == item.id;

  Future<void> _wear(VisualItem item, {required bool on}) async {
    final part = item.avatarPart!;
    final look = on ? _look.withPart(part) : _look.without(part.category);
    if (!on && !part.category.optional) return;
    try {
      await AppRepository.instance.saveAvatarLook(look);
      if (mounted) setState(() {});
    } on AppRepositoryException catch (error) {
      if (mounted) _say(error.message);
    }
  }

  @override
  void initState() {
    super.initState();
    _run(AppRepository.instance.loadShop);
  }

  /// Roda uma ação da loja, uma de cada vez, e mostra o aviso se der errado.
  Future<bool> _run(Future<ShopState> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      final shop = await action();
      if (!mounted) return false;
      setState(() {
        _shop = shop;
        _error = null;
      });
      return true;
    } on AppRepositoryException catch (error) {
      if (!mounted) return false;
      if (_shop == null) {
        setState(() => _error = error.message);
      } else {
        _say(error.message);
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _tapItem(VisualItem item) async {
    final shop = _shop!;
    final repository = AppRepository.instance;
    if (shop.owned.contains(item.id)) {
      final using = _using(shop, item);
      if (item.slot == VisualSlot.roupa) {
        await _wear(item, on: !using);
        return;
      }
      await _run(
        () => repository.equipVisual(item.slot, using ? null : item.id),
      );
      return;
    }
    final level = item.seasonLevel;
    if (level != null) {
      if (shop.season.level < level) {
        _say(
          'Chegue ao nível $level da temporada para ganhar. '
          'Cada desafio certo dá XP!',
        );
        return;
      }
      await _get(item, () => repository.claimSeasonReward(item.id));
      return;
    }
    final price = item.price!;
    if (shop.coins < price) {
      _say(
        'Faltam ${price - shop.coins} moedas. '
        'Cada 10 XP de acertos vira 1 moeda!',
      );
      return;
    }
    await _get(item, () => repository.buyVisual(item.id));
  }

  /// Ganha o visual e já coloca no herói.
  Future<void> _get(
    VisualItem item,
    Future<ShopState> Function() action,
  ) async {
    if (!await _run(action)) return;
    LigaSound.play(LigaSfx.bau);
    if (item.slot == VisualSlot.roupa) {
      await _wear(item, on: true);
    } else {
      await _run(() => AppRepository.instance.equipVisual(item.slot, item.id));
    }
    if (mounted) _say('Novo visual: ${item.name}!');
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;
    return Scaffold(
      body: LigaNightBackground(
        glow: LigaColors.achievementYellow,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    LigaPressable(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: LigaNight.glass,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: LigaColors.ink, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LigaGameText(
                        _season ? 'Temporada' : 'Loja da Liga',
                        size: 26,
                        maxLines: 1,
                      ),
                    ),
                    if (shop != null) LigaCoinCounter(coins: shop.coins),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabPill(
                        key: const ValueKey('aba-loja'),
                        label: 'Loja',
                        icon: Icons.storefront_rounded,
                        selected: !_season,
                        onTap: () => setState(() => _season = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TabPill(
                        key: const ValueKey('aba-temporada'),
                        label: 'Temporada',
                        icon: Icons.military_tech_rounded,
                        selected: _season,
                        onTap: () => setState(() => _season = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(14),
                        children: [LigaErrorCard(message: _error!)],
                      )
                    : shop == null
                    ? const Center(child: CircularProgressIndicator())
                    : _season
                    ? _seasonTab(shop)
                    : _shopTab(shop),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shopTab(ShopState shop) {
    final items = VisualItem.all
        .where((item) => item.slot == _slot && !item.isSeasonReward)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
      children: [
        const Text(
          'Cada 10 XP de acertos vira 1 moeda. '
          'Aqui nada é vendido por dinheiro!',
          style: TextStyle(
            color: LigaNight.textSoft,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final slot in VisualSlot.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SlotChip(
                    key: ValueKey('slot-${slot.name}'),
                    label: slot.label,
                    selected: slot == _slot,
                    onTap: () => setState(() => _slot = slot),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items.skip(i).take(2)) ...[
                    Expanded(child: _itemCard(shop, item)),
                    if (item == items[i]) const SizedBox(width: 12),
                  ],
                  if (i + 1 >= items.length) const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _itemCard(ShopState shop, VisualItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: LigaNight.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _using(shop, item)
              ? LigaColors.achievementYellow
              : LigaColors.ink,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          LigaVisualPreview(
            item: item,
            avatarId: _avatarId,
            look: _look,
            size: 84,
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 8),
          _ItemButton(
            item: item,
            shop: shop,
            using: _using(shop, item),
            onTap: () => _tapItem(item),
          ),
        ],
      ),
    );
  }

  Widget _seasonTab(ShopState shop) {
    final season = shop.season;
    final rewards = VisualItem.all.where((item) => item.isSeasonReward).toList()
      ..sort((a, b) => a.seasonLevel!.compareTo(b.seasonLevel!));
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LigaColors.ink, width: 3),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A4BFF), Color(0xFFB23FD8)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LigaGameText(season.name, size: 22),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          LigaGameText(
                            'Nível ${season.level}',
                            size: 30,
                            color: LigaColors.achievementYellow,
                          ),
                          const Text(
                            ' / ${SeasonState.maxLevel}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  LigaHudChip(
                    icon: Icons.schedule_rounded,
                    label: '${season.daysLeft} dias',
                    color: LigaColors.sunsetOrange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: LigaProgressBar(
                  value: season.levelProgress,
                  color: LigaColors.achievementYellow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                season.level >= SeasonState.maxLevel
                    ? 'Temporada completa! Você chegou ao topo.'
                    : 'Cada ${SeasonState.xpPerLevel} XP de acertos no mês '
                          'sobe um nível. Os prêmios ficam com você para '
                          'sempre.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final item in rewards)
          _SeasonStep(
            item: item,
            reached: season.level >= item.seasonLevel!,
            preview: LigaVisualPreview(
              item: item,
              avatarId: _avatarId,
              look: _look,
              size: 64,
            ),
            button: _ItemButton(
              item: item,
              shop: shop,
              using: _using(shop, item),
              onTap: () => _tapItem(item),
            ),
          ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? LigaColors.achievementYellow : LigaNight.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LigaColors.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? LigaColors.ink : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: LigaTheme.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: selected ? LigaColors.ink : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LigaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LigaColors.cyanGlow : const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LigaColors.ink, width: 2.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: selected ? LigaColors.ink : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Botão do cartão: preço, pegar prêmio, usar ou usando.
class _ItemButton extends StatelessWidget {
  const _ItemButton({
    required this.item,
    required this.shop,
    required this.using,
    required this.onTap,
  });

  final VisualItem item;
  final ShopState shop;
  final bool using;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final owned = shop.owned.contains(item.id);
    final level = item.seasonLevel;
    final price = item.price;
    final (String label, Color color, Widget? lead) = using
        ? ('USANDO', LigaColors.achievementYellow, null)
        : owned
        ? ('USAR', LigaColors.progressGreen, null)
        : level != null
        ? shop.season.level >= level
              ? ('PEGAR', LigaColors.actionCoral, null)
              : (
                  'Nível $level',
                  const Color(0xFF5B6390),
                  const Icon(Icons.lock_rounded, size: 16, color: Colors.white)
                      as Widget,
                )
        : (
            '$price',
            shop.coins >= price!
                ? LigaColors.primaryBlue
                : const Color(0xFF5B6390),
            const LigaCoinIcon(size: 18) as Widget,
          );
    final dark = color == LigaColors.achievementYellow;
    return LigaPressable(
      key: ValueKey('item-${item.id}'),
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LigaColors.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(color: LigaColors.ink, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 6)],
            Text(
              label,
              style: TextStyle(
                fontFamily: LigaTheme.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: dark ? LigaColors.ink : Colors.white,
                shadows: dark ? null : ligaOutline(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Um degrau da trilha da temporada com o prêmio daquele nível.
class _SeasonStep extends StatelessWidget {
  const _SeasonStep({
    required this.item,
    required this.reached,
    required this.preview,
    required this.button,
  });

  final VisualItem item;
  final bool reached;
  final Widget preview;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: LigaColors.ink, width: 3),
              color: reached
                  ? LigaColors.achievementYellow
                  : const Color(0xFF5B6390),
            ),
            child: Text(
              '${item.seasonLevel}',
              style: TextStyle(
                fontFamily: LigaTheme.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: reached ? LigaColors.ink : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LigaNight.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LigaColors.ink, width: 2.5),
              ),
              child: Row(
                children: [
                  preview,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          item.slot.singular,
                          style: const TextStyle(
                            color: LigaNight.textSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(alignment: Alignment.centerLeft, child: button),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
