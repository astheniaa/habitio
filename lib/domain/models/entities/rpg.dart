class UserRpgStats {
  final int level;
  final int currentXp;
  final int xpToNextLevel;

  const UserRpgStats({
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
  });
}

class Boss {
  final int? id;
  final String name;
  final int maxHp;
  final int currentHp;

  const Boss({
    this.id,
    required this.name,
    required this.maxHp,
    required this.currentHp,
  });
}

enum QuestTargetType { completions, streak, level }

class Quest {
  final int? id;
  final String description;
  final QuestTargetType targetType;
  final int? linkedHabitId;
  final int progress;
  final int targetValue;
  final bool isCompleted;

  const Quest({
    this.id,
    required this.description,
    required this.targetType,
    this.linkedHabitId,
    required this.progress,
    required this.targetValue,
    required this.isCompleted,
  });
}
