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
import 'presentation/state/theme_provider.dart';
import 'presentation/state/user_view_model.dart';
import 'presentation/theme/app_palette.dart';
import 'presentation/theme/app_spacing.dart';
import 'presentation/theme/app_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Pre-load user preferences before building MaterialApp.
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  SystemChrome.setSystemUIOverlayStyle(_systemUiStyle(themeProvider.palette));

  // Open the database; first-launch seeding picks the device locale.
  await AppDatabase.instance.database;

  runApp(HabitRpgApp(
    localeProvider: localeProvider,
    themeProvider: themeProvider,
  ));
}

class HabitRpgApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;

  const HabitRpgApp({
    super.key,
    required this.localeProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
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
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeVm, themeVm, _) {
          return MaterialApp(
            title: 'Habitio',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(AppPalette.light()),
            darkTheme: _buildTheme(AppPalette.dark()),
            themeMode: themeVm.themeMode,
            locale: localeVm.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: _systemUiStyle(themeVm.palette),
              child: child ?? const SizedBox.shrink(),
            ),
            home: const HomeShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(AppPalette palette) {
    final colorScheme = palette.isDark
        ? ColorScheme.dark(
            primary: palette.accent,
            secondary: palette.accent,
            surface: palette.surface,
            error: palette.destructive,
            onSurface: palette.textPrimary,
          )
        : ColorScheme.light(
            primary: palette.accent,
            secondary: palette.accent,
            surface: palette.surface,
            error: palette.destructive,
            onSurface: palette.textPrimary,
          );

    final textTheme = TextTheme(
      headlineLarge: AppText.largeTitle.copyWith(color: palette.textPrimary),
      titleLarge: AppText.title.copyWith(color: palette.textPrimary),
      titleMedium: AppText.headline.copyWith(color: palette.textPrimary),
      bodyLarge: AppText.body.copyWith(color: palette.textPrimary),
      bodyMedium: AppText.body.copyWith(color: palette.textPrimary),
      bodySmall: AppText.caption.copyWith(color: palette.textSecondary),
      labelMedium: AppText.callout.copyWith(color: palette.textPrimary),
      labelSmall: AppText.footnote.copyWith(color: palette.textTertiary),
    );

    final base = palette.isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      colorScheme: colorScheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title.copyWith(color: palette.textPrimary),
        systemOverlayStyle: _systemUiStyle(palette),
      ),
      cardColor: palette.surface,
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 0.5,
        space: 0.5,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? palette.accent : null),
        side: BorderSide(color: palette.textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface,
        contentTextStyle: AppText.callout.copyWith(
          color: palette.textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.background,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.accent,
        selectionColor: palette.accentMuted,
        selectionHandleColor: palette.accent,
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(color: palette.textPrimary),
    );
  }
}

SystemUiOverlayStyle _systemUiStyle(AppPalette palette) {
  final iconBrightness = palette.isDark ? Brightness.light : Brightness.dark;
  final statusBrightness = palette.isDark ? Brightness.dark : Brightness.light;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: statusBrightness,
    systemNavigationBarColor: palette.background,
    systemNavigationBarIconBrightness: iconBrightness,
  );
}
