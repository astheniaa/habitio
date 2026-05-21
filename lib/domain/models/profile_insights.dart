/// Discriminated insight types surfaced on the profile screen.
///
/// Each variant carries enough payload for the presentation layer to
/// localize the message without re-running the math.
sealed class ProfileInsight {
  const ProfileInsight();
}

class StreakInsight extends ProfileInsight {
  final int days; // 0 ⇒ "no streak yet"
  const StreakInsight(this.days);
}

class StrongCategoryInsight extends ProfileInsight {
  final String categoryName;
  final int percent;
  const StrongCategoryInsight(this.categoryName, this.percent);
}

class WeakCategoryInsight extends ProfileInsight {
  final String categoryName;
  final int percent;
  const WeakCategoryInsight(this.categoryName, this.percent);
}

class StrongDayInsight extends ProfileInsight {
  /// 1-7 (Mon..Sun) — same as DateTime.weekday
  final int weekday;
  const StrongDayInsight(this.weekday);
}

class WeakDayInsight extends ProfileInsight {
  final int weekday;
  const WeakDayInsight(this.weekday);
}

class TrendInsight extends ProfileInsight {
  /// Positive ⇒ up, negative ⇒ down. Magnitude is a percent (0-200).
  final int deltaPercent;
  const TrendInsight(this.deltaPercent);
}

class WelcomeInsight extends ProfileInsight {
  const WelcomeInsight();
}

/// Per-category progress over a recent window (default 14 days).
class CategoryProgress {
  final int categoryId;
  final String name;
  final String icon;
  final int completed;
  final int scheduled;

  /// `[0, 1]`, or null if no scheduled days in the window.
  final double? ratio;

  const CategoryProgress({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.completed,
    required this.scheduled,
    required this.ratio,
  });
}

/// Compact "today" snapshot.
class TodaySnapshot {
  final int completed;
  final int scheduled;

  const TodaySnapshot({required this.completed, required this.scheduled});

  bool get isEmpty => scheduled == 0;
}

/// Aggregated payload for the profile screen.
class ProfileInsightsResult {
  final int currentStreak;
  final int bestStreak;
  final TodaySnapshot today;
  final List<CategoryProgress> categories;
  final List<ProfileInsight> insights;

  const ProfileInsightsResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.today,
    required this.categories,
    required this.insights,
  });
}
