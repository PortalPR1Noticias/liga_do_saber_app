import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import '../../shell/presentation/main_shell.dart';

class ChooseAvatarScreen extends StatefulWidget {
  const ChooseAvatarScreen({super.key});

  static const routeName = '/avatar';

  @override
  State<ChooseAvatarScreen> createState() => _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends State<ChooseAvatarScreen> {
  int _selectedIndex = 0;

  static const _avatars = LigaAvatar.all;

  Future<void> _enterLeague() async {
    try {
      await AppRepository.instance.saveAvatar(_avatars[_selectedIndex].id);
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(MainShell.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha o avatar')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Seu visual na Liga',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha o herói que mais combina com você. Dá para trocar depois!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _avatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  // Altura fixa: a proporção 0.9 cortava o card em telas estreitas.
                  mainAxisExtent: 190,
                ),
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final selected = _selectedIndex == index;
                  return LigaPressable(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: selected
                            ? Color.lerp(avatar.color, Colors.white, 0.82)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: selected
                              ? avatar.color
                              : const Color(0xFFE3E9F7),
                          width: selected ? 4 : 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? LigaColors.shade(avatar.color)
                                : LigaColors.ink.withValues(alpha: 0.07),
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      // Encolhe o conteúdo se a fonte do sistema estiver grande.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.12 : 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: LigaAvatarBadge(
                                avatarId: avatar.id,
                                radius: 38,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              avatar.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selected
                                  ? LigaColors.progressGreen
                                  : LigaColors.disabled,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                label: 'Entrar para a Liga',
                icon: Icons.rocket_launch_rounded,
                color: LigaColors.sunsetOrange,
                onPressed: _enterLeague,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
