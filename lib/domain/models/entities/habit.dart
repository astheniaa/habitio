enum HabitSpecialization { sport, creativity, finance, social, processing }

enum HabitScheduleType { everyday, selectedWeekdays }

class Habit {
  final int? id;
  final String title;
  final HabitSpecialization specialization;
  final HabitScheduleType scheduleType;
  final List<int> weekdays;
  final bool isArchived;
  final bool consolidationBonusAwarded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Habit({
    this.id,
    required this.title,
    required this.specialization,
    required this.scheduleType,
    this.weekdays = const [],
    this.isArchived = false,
    this.consolidationBonusAwarded = false,
    this.createdAt,
    this.updatedAt,
  });

  Habit copyWith({
    int? id,
    String? title,
    HabitSpecialization? specialization,
    HabitScheduleType? scheduleType,
    List<int>? weekdays,
    bool? isArchived,
    bool? consolidationBonusAwarded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      specialization: specialization ?? this.specialization,
      scheduleType: scheduleType ?? this.scheduleType,
      weekdays: weekdays ?? this.weekdays,
      isArchived: isArchived ?? this.isArchived,
      consolidationBonusAwarded:
          consolidationBonusAwarded ?? this.consolidationBonusAwarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'specialization': specialization.index,
      'schedule_type': scheduleType.index,
      'weekdays': weekdays.join(','),
      'is_archived': isArchived ? 1 : 0,
      'consolidation_bonus_awarded': consolidationBonusAwarded ? 1 : 0,
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
      specialization:
          HabitSpecialization.values[map['specialization'] as int],
      scheduleType: HabitScheduleType.values[map['schedule_type'] as int],
      weekdays: weekdays,
      isArchived: (map['is_archived'] as int) == 1,
      consolidationBonusAwarded:
          (map['consolidation_bonus_awarded'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
