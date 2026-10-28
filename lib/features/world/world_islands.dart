import 'package:flutter/material.dart';

import '../../shared/design_system/liga_mascots.dart';
import '../math_arena/presentation/math_arena_screen.dart';
import '../mila_archive/presentation/mila_archive_screen.dart';
import '../reading_detective/presentation/reading_detective_screen.dart';
import '../teo_trail/presentation/teo_trail_screen.dart';
import '../writing_workshop/presentation/writing_workshop_screen.dart';
import '../zuri_atelier/presentation/zuri_atelier_screen.dart';
import 'boss/boss_sources.dart';

/// Uma ilha do Mundo da Liga: a trilha de fases de um herói.
///
/// Cada atividade que vale XP numa das [origins] da ilha libera a fase
/// seguinte. Assim só avança quem resolve os desafios de verdade.
class LigaIsland {
  const LigaIsland({
    required this.name,
    required this.character,
    required this.origins,
    required this.routes,
    required this.challenge,
    required this.boss,
    required this.bossIcon,
    required this.bossSource,
  });

  final String name;
  final LigaCharacter character;

  /// Origens de XP (tabela `eventos_xp`) que contam como fase vencida.
  final List<String> origins;

  /// Telas das fases, alternadas: a fase 1 abre a primeira, a 2 a segunda...
  final List<String> routes;

  /// O que a criança pratica nessa ilha, em poucas palavras.
  final String challenge;

  /// Nome do chefão no fim da trilha.
  final String boss;
  final IconData bossIcon;

  /// Cria os ataques do chefão a partir das atividades da ilha.
  final BossSource Function() bossSource;

  /// Id da ilha no banco (`chefoes_vencidos.ilha`): o id do herói.
  String get id => character.id;

  /// Fases da trilha; a última é o chefão.
  static const phases = 10;

  static const all = [
    LigaIsland(
      name: 'Ilha dos Números',
      character: LigaCharacter.nico,
      origins: ['matematica'],
      routes: [MathArenaScreen.routeName],
      challenge: 'Cálculo e lógica com o Nico',
      boss: 'Golem dos Números',
      bossIcon: Icons.calculate_rounded,
      bossSource: NicoBossSource.new,
    ),
    LigaIsland(
      name: 'Floresta das Palavras',
      character: LigaCharacter.luma,
      origins: ['leitura', 'texto', 'texto_reescrita'],
      routes: [
        ReadingDetectiveScreen.routeName,
        WritingWorkshopScreen.routeName,
      ],
      challenge: 'Leitura e escrita com a Luma',
      boss: 'Sombra do Esquecimento',
      bossIcon: Icons.menu_book_rounded,
      bossSource: LumaBossSource.new,
    ),
    LigaIsland(
      name: 'Vale das Descobertas',
      character: LigaCharacter.teo,
      origins: ['expedicao'],
      routes: [TeoTrailScreen.routeName],
      challenge: 'Ciências e Geografia com o Teo',
      boss: 'Tempestade Selvagem',
      bossIcon: Icons.thunderstorm_rounded,
      bossSource: TeoBossSource.new,
    ),
    LigaIsland(
      name: 'Cidade do Tempo',
      character: LigaCharacter.mila,
      origins: ['arquivo'],
      routes: [MilaArchiveScreen.routeName],
      challenge: 'História com a Mila',
      boss: 'Guardião do Tempo',
      bossIcon: Icons.hourglass_bottom_rounded,
      bossSource: MilaBossSource.new,
    ),
    LigaIsland(
      name: 'Fábrica de Ideias',
      character: LigaCharacter.zuri,
      origins: ['atelie', 'projeto'],
      routes: [ZuriAtelierScreen.routeName],
      challenge: 'Criatividade e projetos com o Zuri',
      boss: 'Robô Bagunçado',
      bossIcon: Icons.precision_manufacturing_rounded,
      bossSource: ZuriBossSource.new,
    ),
  ];

  /// Fases vencidas contando o chefão ([bosses] vem de `loadBossWins`).
  int progress(Map<String, int> counts, Map<String, int> bosses) =>
      clearedPhases(counts) + (bosses.containsKey(id) ? 1 : 0);

  /// O chefão já pode ser enfrentado: todas as fases antes dele vencidas.
  bool bossReady(Map<String, int> counts) =>
      clearedPhases(counts) >= phases - 1;

  /// Fases já vencidas, a partir das atividades com XP.
  int clearedPhases(Map<String, int> counts) {
    final done = origins.fold(0, (sum, origin) => sum + (counts[origin] ?? 0));
    // A última fase é o chefão, que conta à parte (chefoes_vencidos).
    return done.clamp(0, phases - 1);
  }

  /// Fase que a criança joga agora (1 a [phases] − 1).
  int currentPhase(Map<String, int> counts) => clearedPhases(counts) + 1;

  /// Tela que abre a fase [phase].
  String routeFor(int phase) => routes[(phase - 1) % routes.length];

  /// Ilha sugerida no botão JOGAR: a que está mais atrasada, para a criança
  /// treinar de tudo um pouco.
  static LigaIsland next(
    Map<String, int> counts, [
    Map<String, int> bosses = const {},
  ]) {
    var best = all.first;
    for (final island in all) {
      if (island.progress(counts, bosses) < best.progress(counts, bosses)) {
        best = island;
      }
    }
    return best;
  }
}
