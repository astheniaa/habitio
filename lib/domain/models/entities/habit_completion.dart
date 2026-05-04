/// A completion record for a habit on a given calendar day.
///
/// For [HabitType.binary] habits the completion is binary: [completed] tracks
/// the on/off state; [progress] is always 1.
///
/// For [HabitType.counter] habits the row stores incremental progress for
/// the day. [completed] flips to true once [progress] reaches the habit's
/// `targetValue`.
class HabitCompletion {
  final int? id;
  final int habitId;
  final DateTime date;
  final bool completed;
  final int progress; // ≥ 1 for counter habits, 1 for binary

  const HabitCompletion({
    this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.progress = 1,
  });

  HabitCompletion copyWith({
    int? id,
    int? habitId,
    DateTime? date,
    bool? completed,
    int? progress,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String(),
      'completed': completed ? 1 : 0,
      'progress': progress,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: DateTime.parse(map['date'] as String),
      completed: (map['completed'] as int) == 1,
      progress: (map['progress'] as int?) ?? 1,
    );
  }
}
