import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_avatars.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/mock_app_repository.dart';
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
    await MockAppRepository.instance.saveAvatar(_avatars[_selectedIndex].id);
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
                'No MVP ainda usamos avatares simbólicos. Depois entram os mascotes e artes finais.',
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
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => _selectedIndex = index),
                    child: LigaPanel(
                      borderColor: selected ? avatar.color : null,
                      // Encolhe o conteúdo se a fonte do sistema estiver grande.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: avatar.color.withValues(
                                alpha: 0.22,
                              ),
                              child: Icon(
                                avatar.icon,
                                color: avatar.color,
                                size: 38,
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
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected
                                  ? LigaColors.progressGreen
                                  : Colors.white54,
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
                icon: Icons.rocket_launch,
                onPressed: _enterLeague,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
