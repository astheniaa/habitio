enum HabitScheduleType { everyday, selectedWeekdays }

/// Whether a habit is a simple binary "did it / didn't" toggle, or a counter
/// (track an amount up to a target — e.g. 30 push-ups, 8 glasses of water).
enum HabitType { binary, counter }

class Habit {
  final int? id;
  final String title;
  final int categoryId;
  final HabitScheduleType scheduleType;
  final List<int> weekdays;
  final bool isArchived;
  final bool consolidationBonusAwarded;

  /// Quantitative habit fields. For [HabitType.binary] these are ignored.
  final HabitType habitType;
  final int targetValue; // ≥ 1 for counter; 1 for binary
  final String unit; // free-text, e.g. "раз", "min"

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Habit({
    this.id,
    required this.title,
    required this.categoryId,
    required this.scheduleType,
    this.weekdays = const [],
    this.isArchived = false,
    this.consolidationBonusAwarded = false,
    this.habitType = HabitType.binary,
    this.targetValue = 1,
    this.unit = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isCounter => habitType == HabitType.counter;

  Habit copyWith({
    int? id,
    String? title,
    int? categoryId,
    HabitScheduleType? scheduleType,
    List<int>? weekdays,
    bool? isArchived,
    bool? consolidationBonusAwarded,
    HabitType? habitType,
    int? targetValue,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      scheduleType: scheduleType ?? this.scheduleType,
      weekdays: weekdays ?? this.weekdays,
      isArchived: isArchived ?? this.isArchived,
      consolidationBonusAwarded:
          consolidationBonusAwarded ?? this.consolidationBonusAwarded,
      habitType: habitType ?? this.habitType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category_id': categoryId,
      'schedule_type': scheduleType.index,
      'weekdays': weekdays.join(','),
      'is_archived': isArchived ? 1 : 0,
      'consolidation_bonus_awarded': consolidationBonusAwarded ? 1 : 0,
      'habit_type': habitType.index,
      'target_value': targetValue,
      'unit': unit,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final weekdaysStr = map['weekdays'] as String? ?? '';
    final weekdays = weekdaysStr.isEmpty
        ? <int>[]
        : weekdaysStr.split(',').map(int.parse).toList();
    return Habit(
      id: map['id'] as int?,
      title: map['title'] as String,
      categoryId: map['category_id'] as int,
      scheduleType: HabitScheduleType.values[map['schedule_type'] as int],
      weekdays: weekdays,
      isArchived: (map['is_archived'] as int) == 1,
      consolidationBonusAwarded:
          (map['consolidation_bonus_awarded'] as int?) == 1,
      habitType: HabitType.values[(map['habit_type'] as int?) ?? 0],
      targetValue: (map['target_value'] as int?) ?? 1,
      unit: map['unit'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
