import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import 'choose_avatar_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  static const routeName = '/child-profile';

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _nicknameController = TextEditingController(text: 'Alex G');
  int _selectedYear = 5;
  final Set<String> _focusAreas = {'Leitura', 'Texto'};

  static const _areaColors = {
    'Leitura': LigaColors.actionCoral,
    'Texto': LigaColors.actionCoral,
    'Matemática': LigaColors.primaryBlue,
    'Ciências': LigaColors.progressGreen,
    'Geografia': LigaColors.progressGreen,
    'História': LigaColors.adventurePurple,
    'Projetos': LigaColors.sunsetOrange,
  };

  bool get _canContinue =>
      _nicknameController.text.trim().isNotEmpty && _focusAreas.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    try {
      await AppRepository.instance.saveChildProfile(
        nickname: _nicknameController.text,
        schoolYear: _selectedYear,
        focusAreas: _focusAreas.toList(),
      );
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamed(ChooseAvatarScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da criança')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const PopIn(
                child: Row(
                  children: [
                    LigaMascot(character: LigaCharacter.luma, size: 84),
                    SizedBox(width: 8),
                    Expanded(
                      child: LigaSpeechBubble(
                        text:
                            'Eba, alguém novo na Liga! Como você quer ser chamado?',
                        color: Color(0x66FF6B8B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Quem vai entrar para a Liga?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Essas informações ajudam a ajustar missões, linguagem e dificuldade.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              LigaPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nicknameController,
                      style: const TextStyle(
                        color: LigaColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Apelido',
                        helperText: 'Use um apelido, não o nome completo.',
                        prefixIcon: Icon(
                          Icons.badge_rounded,
                          color: LigaColors.actionCoral,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Ano escolar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(5, (index) {
                        final year = index + 3;
                        return ChoiceChip(
                          label: Text('$yearº ano'),
                          selected: _selectedYear == year,
                          onSelected: (_) =>
                              setState(() => _selectedYear = year),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Foco inicial',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _areaColors.keys
                          .map(
                            (area) => FilterChip(
                              label: Text(area),
                              selectedColor: _areaColors[area]!.withValues(
                                alpha: 0.3,
                              ),
                              side: BorderSide(
                                color: _areaColors[area]!,
                                width: 2,
                              ),
                              selected: _focusAreas.contains(area),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _focusAreas.add(area);
                                  } else {
                                    _focusAreas.remove(area);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                label: 'Escolher avatar',
                icon: Icons.face_rounded,
                color: LigaColors.adventurePurple,
                onPressed: _canContinue ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
