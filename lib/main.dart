import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/db/app_database.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/habit_completion_repository_impl.dart';
import 'data/repositories/habit_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/state/category_view_model.dart';
import 'presentation/state/habit_view_model.dart';
import 'presentation/state/locale_provider.dart';
import 'presentation/state/user_view_model.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_spacing.dart';
import 'presentation/theme/app_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Pre-load locale override (if any) before building MaterialApp.
  final localeProvider = LocaleProvider();
  await localeProvider.load();

  // Open the database; first-launch seeding picks the device locale.
  await AppDatabase.instance.database;

  runApp(HabitRpgApp(localeProvider: localeProvider));
}

class HabitRpgApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  const HabitRpgApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(
          create: (_) => UserViewModel(
            userRepository: UserRepositoryImpl(),
          )..loadUser(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryViewModel(
            repository: CategoryRepositoryImpl(),
          )..load(),
        ),
        ChangeNotifierProxyProvider<UserViewModel, HabitViewModel>(
          create: (_) => HabitViewModel(
            habitRepository: HabitRepositoryImpl(),
            completionRepository: HabitCompletionRepositoryImpl(),
          )..loadInitialData(),
          update: (_, userVm, habitVm) {
            habitVm!.userViewModel = userVm;
            return habitVm;
          },
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeVm, _) {
          return MaterialApp(
            title: 'Habitio',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            locale: localeVm.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.destructive,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title,
      ),
      cardColor: AppColors.surface,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0.5,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.accent : null),
        side: const BorderSide(color: AppColors.textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: AppText.callout,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.background,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppText.largeTitle,
        titleLarge: AppText.title,
        titleMedium: AppText.headline,
        bodyLarge: AppText.body,
        bodyMedium: AppText.body,
        bodySmall: AppText.caption,
        labelMedium: AppText.callout,
        labelSmall: AppText.footnote,
      ),
    );
  }
}
