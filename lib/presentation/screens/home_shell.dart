import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_user_panel.dart';
import 'habit_edit_sheet.dart';
import 'life_screen.dart';
import 'profile_screen.dart';
import 'upcoming_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  // Key to access UpcomingScreen's selected date for FAB
  final GlobalKey<UpcomingScreenState> _upcomingKey =
      GlobalKey<UpcomingScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _tabController.animateTo(index);
  }

  void _onFabPressed() {
    if (_currentIndex == 1) {
      // Upcoming tab — pre-select the day chosen in the calendar strip
      final selectedDate = _upcomingKey.currentState?.selectedDate;
      final weekday = selectedDate?.weekday;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => HabitEditSheet(initialWeekday: weekday),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const HabitEditSheet(),
      );
    }
  }

  static const _scaffoldBg = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => const [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: _scaffoldBg,
            toolbarHeight: 78,
            titleSpacing: 0,
            title: TopUserPanel(),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const LifeScreen(),
            UpcomingScreen(key: _upcomingKey),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _currentIndex == 2 ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: _currentIndex == 2,
          child: FloatingActionButton(
            onPressed: _onFabPressed,
            backgroundColor: const Color(0xFF4CAF50),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
