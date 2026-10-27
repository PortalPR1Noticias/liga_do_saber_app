import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/minigame.dart';
import 'lightning_challenge_screen.dart';
import 'minigame_style.dart';
import 'order_puzzle_screen.dart';
import 'word_search_screen.dart';

/// Jogos da Liga: o conteúdo da escola em formato de jogo (caça-palavras,
/// quebra-cabeça e Desafio Relâmpago), para o tempo de tela virar
/// contraturno escolar.
class MinigamesHubScreen extends StatefulWidget {
  const MinigamesHubScreen({super.key});

  static const routeName = '/games';

  @override
  State<MinigamesHubScreen> createState() => _MinigamesHubScreenState();
}

class _MinigamesHubScreenState extends State<MinigamesHubScreen> {
  MinigameSubject _subject = MinigameSubject.portugues;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jogos da Liga')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const PopIn(
                child: LigaFeatureHeader(
                  title: 'Jogos da Liga',
                  subtitle: 'A matéria da escola virou jogo. Escolha e jogue!',
                  color: LigaColors.adventurePurple,
                  character: LigaCharacter.zuri,
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Matéria', icon: Icons.school_rounded),
              MinigameSubjectPicker(
                value: _subject,
                onChanged: (subject) => setState(() => _subject = subject),
              ),
              const SizedBox(height: 20),
              PopIn(
                delay: const Duration(milliseconds: 80),
                child: MissionCard(
                  title: 'Caça-palavras',
                  subtitle: 'Leia as pistas e ache as palavras na grade.',
                  icon: Icons.grid_on_rounded,
                  color: _subject.color,
                  progress: 0,
                  onTap: () => _open(WordSearchScreen(subject: _subject)),
                ),
              ),
              const SizedBox(height: 14),
              PopIn(
                delay: const Duration(milliseconds: 140),
                child: MissionCard(
                  title: 'Quebra-cabeça',
                  subtitle: 'Monte frases, sequências e etapas na ordem.',
                  icon: Icons.extension_rounded,
                  color: _subject.color,
                  progress: 0,
                  onTap: () => _open(OrderPuzzleScreen(subject: _subject)),
                ),
              ),
              const SizedBox(height: 14),
              PopIn(
                delay: const Duration(milliseconds: 200),
                child: MissionCard(
                  title: 'Desafio Relâmpago',
                  subtitle: '60 segundos de contas com o Nico.',
                  icon: Icons.bolt_rounded,
                  color: LigaColors.sunsetOrange,
                  progress: 0,
                  onTap: () => _open(const LightningChallengeScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
