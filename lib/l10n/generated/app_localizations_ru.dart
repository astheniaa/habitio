// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get todayTab => 'Сегодня';

  @override
  String get upcomingTab => 'Предстоящее';

  @override
  String get statisticsTab => 'Статистика';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get create => 'Создать';

  @override
  String get rename => 'Переименовать';

  @override
  String get edit => 'Изменить';

  @override
  String get ok => 'OK';

  @override
  String get undo => 'Отменить';

  @override
  String get doneLabel => 'Выполнено';

  @override
  String get level => 'Уровень';

  @override
  String get xp => 'Опыт';

  @override
  String get editNameTitle => 'Изменить имя';

  @override
  String get editNameHint => 'Введите имя';

  @override
  String get editNameValidation => 'Имя не может быть пустым';

  @override
  String get emptyToday => 'На сегодня привычек нет. Добавьте новую!';

  @override
  String get emptyUpcoming => 'Нет запланированных привычек';

  @override
  String get noHabitsInCategory => 'Нет привычек';

  @override
  String get createHabitTitle => 'Новая привычка';

  @override
  String get editHabitTitle => 'Редактировать привычку';

  @override
  String get habitTitleLabel => 'Название привычки';

  @override
  String get habitTitleHint => 'Например: Утренняя зарядка';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get scheduleLabel => 'Расписание';

  @override
  String get everyDay => 'Каждый день';

  @override
  String get specificDays => 'Выбрать дни';

  @override
  String get validationTitleRequired => 'Название обязательно';

  @override
  String get validationWeekdayRequired => 'Выберите хотя бы один день недели';

  @override
  String get validationCategoryRequired => 'Выберите категорию';

  @override
  String get validationTargetRequired => 'Цель должна быть положительной';

  @override
  String get categorySportDefault => 'Спорт';

  @override
  String get categoryCreativityDefault => 'Творчество';

  @override
  String get categoryFinanceDefault => 'Финансы';

  @override
  String get categorySocialDefault => 'Социализация';

  @override
  String get categoryProcessingDefault => 'Процессинг';

  @override
  String get manageCategories => 'Категории';

  @override
  String get manageCategoriesAction => 'Управление категориями';

  @override
  String get newCategory => 'Новая категория';

  @override
  String get renameCategory => 'Переименовать категорию';

  @override
  String get categoryNameLabel => 'Название';

  @override
  String get categoryIconLabel => 'Эмодзи';

  @override
  String get categoryInUseError => 'Категория используется в привычках';

  @override
  String get categoryDeleteConfirmTitle => 'Удалить категорию?';

  @override
  String get categoryDeleteConfirmBody => 'Это действие нельзя отменить.';

  @override
  String get habitTypeLabel => 'Тип привычки';

  @override
  String get habitTypeBinary => 'Простая';

  @override
  String get habitTypeCounter => 'Счётчик';

  @override
  String get habitTypeBinaryHint => 'Отметить «выполнено»';

  @override
  String get habitTypeCounterHint => 'Отслеживать количество';

  @override
  String get targetLabel => 'Цель';

  @override
  String get unitLabel => 'Единица';

  @override
  String get unitHint => 'напр. раз, мин, стр.';

  @override
  String progressOf(int progress, int target) {
    return '$progress из $target';
  }

  @override
  String get periodWeek => 'Неделя';

  @override
  String get periodMonth => 'Месяц';

  @override
  String get periodAllTime => 'Всё время';

  @override
  String get completedInPeriod => 'Выполнено';

  @override
  String get activityStreak => 'Стрик активности';

  @override
  String get bestStreakLabel => 'Лучший стрик';

  @override
  String get currentStreakLabel => 'Текущий стрик';

  @override
  String get consolidated => 'Закреплено';

  @override
  String get consolidationProgress => 'Закрепление';

  @override
  String get daysShort => 'дн.';

  @override
  String get frozenWarning => 'Заморожена! Выполни задание';

  @override
  String get freezeNotification => 'Вчера была пропущена привычка';

  @override
  String get completionPercent => 'Выполнение';

  @override
  String get totalCompletions => 'Всего выполнений';

  @override
  String get postConsolidationStreak => 'После закрепления';

  @override
  String get activityTitle => 'Активность';

  @override
  String get legendCompleted => 'Выполнено';

  @override
  String get legendMissed => 'Пропуск';

  @override
  String get legendNotScheduled => 'Не запл.';

  @override
  String get fromGallery => 'Из галереи';

  @override
  String get choosePhoto => 'Выбрать фото';

  @override
  String get rpgAvatarsTitle => 'RPG-аватары';

  @override
  String get avatarPickerTitle => 'Выбрать аватар';

  @override
  String get languageLabel => 'Язык';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get levelUpBadge => '⬆ LEVEL UP';

  @override
  String get levelUpSub => '+1 уровень';

  @override
  String get weekdayMon => 'Пн';

  @override
  String get weekdayTue => 'Вт';

  @override
  String get weekdayWed => 'Ср';

  @override
  String get weekdayThu => 'Чт';

  @override
  String get weekdayFri => 'Пт';

  @override
  String get weekdaySat => 'Сб';

  @override
  String get weekdaySun => 'Вс';

  @override
  String get monthJan => 'Январь';

  @override
  String get monthFeb => 'Февраль';

  @override
  String get monthMar => 'Март';

  @override
  String get monthApr => 'Апрель';

  @override
  String get monthMay => 'Май';

  @override
  String get monthJun => 'Июнь';

  @override
  String get monthJul => 'Июль';

  @override
  String get monthAug => 'Август';

  @override
  String get monthSep => 'Сентябрь';

  @override
  String get monthOct => 'Октябрь';

  @override
  String get monthNov => 'Ноябрь';

  @override
  String get monthDec => 'Декабрь';
}
