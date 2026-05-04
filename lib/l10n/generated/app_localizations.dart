import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en')
  ];

  /// No description provided for @todayTab.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get todayTab;

  /// No description provided for @upcomingTab.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящее'**
  String get upcomingTab;

  /// No description provided for @statisticsTab.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get statisticsTab;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get rename;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get edit;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @undo.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get undo;

  /// No description provided for @doneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено'**
  String get doneLabel;

  /// No description provided for @level.
  ///
  /// In ru, this message translates to:
  /// **'Уровень'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In ru, this message translates to:
  /// **'Опыт'**
  String get xp;

  /// No description provided for @editNameTitle.
  ///
  /// In ru, this message translates to:
  /// **'Изменить имя'**
  String get editNameTitle;

  /// No description provided for @editNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get editNameHint;

  /// No description provided for @editNameValidation.
  ///
  /// In ru, this message translates to:
  /// **'Имя не может быть пустым'**
  String get editNameValidation;

  /// No description provided for @emptyToday.
  ///
  /// In ru, this message translates to:
  /// **'На сегодня привычек нет. Добавьте новую!'**
  String get emptyToday;

  /// No description provided for @emptyUpcoming.
  ///
  /// In ru, this message translates to:
  /// **'Нет запланированных привычек'**
  String get emptyUpcoming;

  /// No description provided for @noHabitsInCategory.
  ///
  /// In ru, this message translates to:
  /// **'Нет привычек'**
  String get noHabitsInCategory;

  /// No description provided for @createHabitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новая привычка'**
  String get createHabitTitle;

  /// No description provided for @editHabitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать привычку'**
  String get editHabitTitle;

  /// No description provided for @habitTitleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название привычки'**
  String get habitTitleLabel;

  /// No description provided for @habitTitleHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Утренняя зарядка'**
  String get habitTitleHint;

  /// No description provided for @categoryLabel.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get categoryLabel;

  /// No description provided for @scheduleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get scheduleLabel;

  /// No description provided for @everyDay.
  ///
  /// In ru, this message translates to:
  /// **'Каждый день'**
  String get everyDay;

  /// No description provided for @specificDays.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дни'**
  String get specificDays;

  /// No description provided for @validationTitleRequired.
  ///
  /// In ru, this message translates to:
  /// **'Название обязательно'**
  String get validationTitleRequired;

  /// No description provided for @validationWeekdayRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите хотя бы один день недели'**
  String get validationWeekdayRequired;

  /// No description provided for @validationCategoryRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию'**
  String get validationCategoryRequired;

  /// No description provided for @validationTargetRequired.
  ///
  /// In ru, this message translates to:
  /// **'Цель должна быть положительной'**
  String get validationTargetRequired;

  /// No description provided for @categorySportDefault.
  ///
  /// In ru, this message translates to:
  /// **'Спорт'**
  String get categorySportDefault;

  /// No description provided for @categoryCreativityDefault.
  ///
  /// In ru, this message translates to:
  /// **'Творчество'**
  String get categoryCreativityDefault;

  /// No description provided for @categoryFinanceDefault.
  ///
  /// In ru, this message translates to:
  /// **'Финансы'**
  String get categoryFinanceDefault;

  /// No description provided for @categorySocialDefault.
  ///
  /// In ru, this message translates to:
  /// **'Социализация'**
  String get categorySocialDefault;

  /// No description provided for @categoryProcessingDefault.
  ///
  /// In ru, this message translates to:
  /// **'Процессинг'**
  String get categoryProcessingDefault;

  /// No description provided for @manageCategories.
  ///
  /// In ru, this message translates to:
  /// **'Категории'**
  String get manageCategories;

  /// No description provided for @manageCategoriesAction.
  ///
  /// In ru, this message translates to:
  /// **'Управление категориями'**
  String get manageCategoriesAction;

  /// No description provided for @newCategory.
  ///
  /// In ru, this message translates to:
  /// **'Новая категория'**
  String get newCategory;

  /// No description provided for @renameCategory.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать категорию'**
  String get renameCategory;

  /// No description provided for @categoryNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get categoryNameLabel;

  /// No description provided for @categoryIconLabel.
  ///
  /// In ru, this message translates to:
  /// **'Эмодзи'**
  String get categoryIconLabel;

  /// No description provided for @categoryInUseError.
  ///
  /// In ru, this message translates to:
  /// **'Категория используется в привычках'**
  String get categoryInUseError;

  /// No description provided for @categoryDeleteConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить категорию?'**
  String get categoryDeleteConfirmTitle;

  /// No description provided for @categoryDeleteConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Это действие нельзя отменить.'**
  String get categoryDeleteConfirmBody;

  /// No description provided for @habitTypeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Тип привычки'**
  String get habitTypeLabel;

  /// No description provided for @habitTypeBinary.
  ///
  /// In ru, this message translates to:
  /// **'Простая'**
  String get habitTypeBinary;

  /// No description provided for @habitTypeCounter.
  ///
  /// In ru, this message translates to:
  /// **'Счётчик'**
  String get habitTypeCounter;

  /// No description provided for @habitTypeBinaryHint.
  ///
  /// In ru, this message translates to:
  /// **'Отметить «выполнено»'**
  String get habitTypeBinaryHint;

  /// No description provided for @habitTypeCounterHint.
  ///
  /// In ru, this message translates to:
  /// **'Отслеживать количество'**
  String get habitTypeCounterHint;

  /// No description provided for @targetLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цель'**
  String get targetLabel;

  /// No description provided for @unitLabel.
  ///
  /// In ru, this message translates to:
  /// **'Единица'**
  String get unitLabel;

  /// No description provided for @unitHint.
  ///
  /// In ru, this message translates to:
  /// **'напр. раз, мин, стр.'**
  String get unitHint;

  /// No description provided for @progressOf.
  ///
  /// In ru, this message translates to:
  /// **'{progress} из {target}'**
  String progressOf(int progress, int target);

  /// No description provided for @periodWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get periodMonth;

  /// No description provided for @periodAllTime.
  ///
  /// In ru, this message translates to:
  /// **'Всё время'**
  String get periodAllTime;

  /// No description provided for @completedInPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено'**
  String get completedInPeriod;

  /// No description provided for @activityStreak.
  ///
  /// In ru, this message translates to:
  /// **'Стрик активности'**
  String get activityStreak;

  /// No description provided for @bestStreakLabel.
  ///
  /// In ru, this message translates to:
  /// **'Лучший стрик'**
  String get bestStreakLabel;

  /// No description provided for @currentStreakLabel.
  ///
  /// In ru, this message translates to:
  /// **'Текущий стрик'**
  String get currentStreakLabel;

  /// No description provided for @consolidated.
  ///
  /// In ru, this message translates to:
  /// **'Закреплено'**
  String get consolidated;

  /// No description provided for @consolidationProgress.
  ///
  /// In ru, this message translates to:
  /// **'Закрепление'**
  String get consolidationProgress;

  /// No description provided for @daysShort.
  ///
  /// In ru, this message translates to:
  /// **'дн.'**
  String get daysShort;

  /// No description provided for @frozenWarning.
  ///
  /// In ru, this message translates to:
  /// **'Заморожена! Выполни задание'**
  String get frozenWarning;

  /// No description provided for @freezeNotification.
  ///
  /// In ru, this message translates to:
  /// **'Вчера была пропущена привычка'**
  String get freezeNotification;

  /// No description provided for @completionPercent.
  ///
  /// In ru, this message translates to:
  /// **'Выполнение'**
  String get completionPercent;

  /// No description provided for @totalCompletions.
  ///
  /// In ru, this message translates to:
  /// **'Всего выполнений'**
  String get totalCompletions;

  /// No description provided for @postConsolidationStreak.
  ///
  /// In ru, this message translates to:
  /// **'После закрепления'**
  String get postConsolidationStreak;

  /// No description provided for @activityTitle.
  ///
  /// In ru, this message translates to:
  /// **'Активность'**
  String get activityTitle;

  /// No description provided for @legendCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено'**
  String get legendCompleted;

  /// No description provided for @legendMissed.
  ///
  /// In ru, this message translates to:
  /// **'Пропуск'**
  String get legendMissed;

  /// No description provided for @legendNotScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Не запл.'**
  String get legendNotScheduled;

  /// No description provided for @fromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Из галереи'**
  String get fromGallery;

  /// No description provided for @choosePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать фото'**
  String get choosePhoto;

  /// No description provided for @rpgAvatarsTitle.
  ///
  /// In ru, this message translates to:
  /// **'RPG-аватары'**
  String get rpgAvatarsTitle;

  /// No description provided for @avatarPickerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать аватар'**
  String get avatarPickerTitle;

  /// No description provided for @languageLabel.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get languageLabel;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @levelUpBadge.
  ///
  /// In ru, this message translates to:
  /// **'⬆ LEVEL UP'**
  String get levelUpBadge;

  /// No description provided for @levelUpSub.
  ///
  /// In ru, this message translates to:
  /// **'+1 уровень'**
  String get levelUpSub;

  /// No description provided for @weekdayMon.
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get weekdaySun;

  /// No description provided for @monthJan.
  ///
  /// In ru, this message translates to:
  /// **'Январь'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In ru, this message translates to:
  /// **'Февраль'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In ru, this message translates to:
  /// **'Март'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In ru, this message translates to:
  /// **'Апрель'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In ru, this message translates to:
  /// **'Май'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In ru, this message translates to:
  /// **'Июнь'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In ru, this message translates to:
  /// **'Июль'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In ru, this message translates to:
  /// **'Август'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In ru, this message translates to:
  /// **'Сентябрь'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In ru, this message translates to:
  /// **'Октябрь'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In ru, this message translates to:
  /// **'Ноябрь'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In ru, this message translates to:
  /// **'Декабрь'**
  String get monthDec;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
