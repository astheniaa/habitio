// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get todayTab => 'Today';

  @override
  String get upcomingTab => 'Upcoming';

  @override
  String get statisticsTab => 'Stats';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get edit => 'Edit';

  @override
  String get ok => 'OK';

  @override
  String get undo => 'Undo';

  @override
  String get doneLabel => 'Done';

  @override
  String get level => 'Level';

  @override
  String get xp => 'XP';

  @override
  String get editNameTitle => 'Edit name';

  @override
  String get editNameHint => 'Enter name';

  @override
  String get editNameValidation => 'Name can\'t be empty';

  @override
  String get emptyToday =>
      'Nothing scheduled today. Add a habit to get started.';

  @override
  String get emptyUpcoming => 'No habits scheduled';

  @override
  String get noHabitsInCategory => 'No habits';

  @override
  String get createHabitTitle => 'New habit';

  @override
  String get editHabitTitle => 'Edit habit';

  @override
  String get habitTitleLabel => 'Habit name';

  @override
  String get habitTitleHint => 'e.g. Morning workout';

  @override
  String get categoryLabel => 'Category';

  @override
  String get scheduleLabel => 'Schedule';

  @override
  String get everyDay => 'Every day';

  @override
  String get specificDays => 'Specific days';

  @override
  String get validationTitleRequired => 'Name is required';

  @override
  String get validationWeekdayRequired => 'Select at least one weekday';

  @override
  String get validationCategoryRequired => 'Pick a category';

  @override
  String get validationTargetRequired => 'Target must be positive';

  @override
  String get categorySportDefault => 'Sport';

  @override
  String get categoryCreativityDefault => 'Creativity';

  @override
  String get categoryFinanceDefault => 'Finance';

  @override
  String get categorySocialDefault => 'Social';

  @override
  String get categoryProcessingDefault => 'Processing';

  @override
  String get manageCategories => 'Categories';

  @override
  String get manageCategoriesAction => 'Manage categories';

  @override
  String get newCategory => 'New category';

  @override
  String get renameCategory => 'Rename category';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryIconLabel => 'Emoji';

  @override
  String get categoryInUseError => 'Category is used by existing habits';

  @override
  String get categoryDeleteConfirmTitle => 'Delete category?';

  @override
  String get categoryDeleteConfirmBody => 'This can\'t be undone.';

  @override
  String get habitTypeLabel => 'Habit type';

  @override
  String get habitTypeBinary => 'Simple';

  @override
  String get habitTypeCounter => 'Counter';

  @override
  String get habitTypeBinaryHint => 'Mark complete';

  @override
  String get habitTypeCounterHint => 'Track an amount';

  @override
  String get targetLabel => 'Target';

  @override
  String get unitLabel => 'Unit';

  @override
  String get unitHint => 'e.g. reps, min, pages';

  @override
  String progressOf(int progress, int target) {
    return '$progress of $target';
  }

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodAllTime => 'All time';

  @override
  String get completedInPeriod => 'Completed';

  @override
  String get activityStreak => 'Activity streak';

  @override
  String get bestStreakLabel => 'Best streak';

  @override
  String get currentStreakLabel => 'Current streak';

  @override
  String get consolidated => 'Consolidated';

  @override
  String get consolidationProgress => 'Consolidating';

  @override
  String get daysShort => 'd';

  @override
  String get frozenWarning => 'Frozen — complete to thaw';

  @override
  String get freezeNotification => 'You missed a habit yesterday';

  @override
  String get completionPercent => 'Completion';

  @override
  String get totalCompletions => 'Total completions';

  @override
  String get postConsolidationStreak => 'After consolidation';

  @override
  String get activityTitle => 'Activity';

  @override
  String get legendCompleted => 'Done';

  @override
  String get legendMissed => 'Missed';

  @override
  String get legendNotScheduled => '—';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get rpgAvatarsTitle => 'RPG avatars';

  @override
  String get avatarPickerTitle => 'Choose avatar';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get levelUpBadge => '⬆ LEVEL UP';

  @override
  String get levelUpSub => '+1 level';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';
}
