import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/db/app_database.dart';
import 'data/repositories/habit_completion_repository_impl.dart';
import 'data/repositories/habit_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/state/habit_view_model.dart';
import 'presentation/state/user_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await AppDatabase.instance.database;

  runApp(const HabitRpgApp());
}

class HabitRpgApp extends StatelessWidget {
  const HabitRpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserViewModel(
            userRepository: UserRepositoryImpl(),
          )..loadUser(),
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
      child: MaterialApp(
        title: 'Habit RPG Tracker',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const HomeShell(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF4CAF50);
    const secondary = Color(0xFF81C784);
    const scaffoldBg = Color(0xFF121212);
    const cardColor = Color(0xFF1E1E1E);

    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
      ),
      cardColor: cardColor,
      cardTheme: const CardThemeData(color: cardColor),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}
