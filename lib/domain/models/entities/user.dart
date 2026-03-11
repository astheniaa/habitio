class User {
  final int id;
  final String name;
  final int level;
  final int currentXp;
  final int xpToNextLevel;

  const User({
    required this.id,
    required this.name,
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
  });

  User copyWith({
    int? id,
    String? name,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'current_xp': currentXp,
      'xp_to_next_level': xpToNextLevel,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String,
      level: map['level'] as int,
      currentXp: map['current_xp'] as int,
      xpToNextLevel: map['xp_to_next_level'] as int,
    );
  }

  static User get defaultUser => const User(
        id: 1,
        name: 'Герой',
        level: 1,
        currentXp: 0,
        xpToNextLevel: 100,
      );
}
