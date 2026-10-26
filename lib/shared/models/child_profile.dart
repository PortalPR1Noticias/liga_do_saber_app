class ChildProfile {
  const ChildProfile({
    required this.nickname,
    required this.schoolYear,
    required this.focusAreas,
    required this.avatarId,
    this.level = 1,
    this.totalXp = 0,
    this.streakDays = 0,
  });

  final String nickname;
  final int schoolYear;
  final List<String> focusAreas;
  final String avatarId;
  final int level;
  final int totalXp;
  final int streakDays;

  /// Meta de XP do nível atual enquanto não existe tabela de níveis real.
  static const levelXpGoal = 7000;

  double get levelProgress => (totalXp % levelXpGoal) / levelXpGoal;

  ChildProfile copyWith({
    String? nickname,
    int? schoolYear,
    List<String>? focusAreas,
    String? avatarId,
    int? level,
    int? totalXp,
    int? streakDays,
  }) {
    return ChildProfile(
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
