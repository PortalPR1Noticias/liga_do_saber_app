import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/mock_app_repository.dart';
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
    await MockAppRepository.instance.saveChildProfile(
      nickname: _nicknameController.text,
      schoolYear: _selectedYear,
      focusAreas: _focusAreas.toList(),
    );
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nome ou apelido',
                        labelStyle: const TextStyle(color: Color(0xFFD8E2FF)),
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: LigaColors.cyanGlow,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
                      children: ['Leitura', 'Texto', 'Matemática', 'Ciências']
                          .map(
                            (area) => FilterChip(
                              label: Text(area),
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
                icon: Icons.face_6_outlined,
                onPressed: _canContinue ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
