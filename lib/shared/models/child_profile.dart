import 'progress_update.dart';

class ChildProfile {
  const ChildProfile({
    required this.nickname,
    required this.schoolYear,
    required this.focusAreas,
    required this.avatarId,
    this.id,
    this.username,
    this.level = 1,
    this.totalXp = 0,
    this.streakDays = 0,
  });

  /// Id em `perfis_criancas` (nulo antes de salvar).
  final String? id;

  /// Usuário do login da criança (nulo enquanto o responsável não criar).
  final String? username;

  final String nickname;
  final int schoolYear;
  final List<String> focusAreas;
  final String avatarId;
  final int level;
  final int totalXp;
  final int streakDays;

  /// XP em que o nível começa: 50 × n × (n − 1). É a mesma conta da
  /// função SQL `nivel_do_xp` (migration 0003).
  static int levelStartXp(int level) => 50 * level * (level - 1);

  /// XP ganho dentro do nível atual.
  int get levelXp => totalXp - levelStartXp(level);

  /// Quanto XP o nível atual pede até o próximo.
  int get levelXpGoal => levelStartXp(level + 1) - levelStartXp(level);

  double get levelProgress => (levelXp / levelXpGoal).clamp(0.0, 1.0);

  /// Perfil com o XP, nível e sequência que o servidor acabou de devolver.
  ChildProfile withProgress(ProgressUpdate progress) => copyWith(
    totalXp: progress.totalXp,
    level: progress.level,
    streakDays: progress.streakDays,
  );

  ChildProfile copyWith({
    String? id,
    String? username,
    String? nickname,
    int? schoolYear,
    List<String>? focusAreas,
    String? avatarId,
    int? level,
    int? totalXp,
    int? streakDays,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      schoolYear: schoolYear ?? this.schoolYear,
      focusAreas: focusAreas ?? this.focusAreas,
      avatarId: avatarId ?? this.avatarId,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}
