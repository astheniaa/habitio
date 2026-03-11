class HabitCompletion {
  final int? id;
  final int habitId;
  final DateTime date;
  final bool completed;

  const HabitCompletion({
    this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String(),
      'completed': completed ? 1 : 0,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: DateTime.parse(map['date'] as String),
      completed: (map['completed'] as int) == 1,
    );
  }
}
