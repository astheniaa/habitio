import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/category.dart';
import '../../domain/models/entities/habit.dart';
import '../../domain/utils/time_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/category_view_model.dart';
import '../state/habit_view_model.dart';
import '../theme/app_colors.dart';
import '../widgets/habit_list_item.dart';
import 'habit_edit_sheet.dart';

const _kCalPages = 10000;
const _rowH = 44.0;
const _maxGridH = 6 * _rowH;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

DateTime _mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime _gridStart(DateTime month) =>
    _mondayOf(DateTime(month.year, month.month, 1));

int _numRows(DateTime month) {
  final fw = DateTime(month.year, month.month, 1).weekday;
  final days = DateTime(month.year, month.month + 1, 0).day;
  return ((fw - 1 + days) / 7).ceil();
}

int _rowIndex(DateTime date, DateTime month) {
  final start = _gridStart(month);
  return DateTime(date.year, date.month, date.day).difference(start).inDays ~/
      7;
}

String _localizedMonth(int month, AppLocalizations loc) {
  switch (month) {
    case 1:
      return loc.monthJan;
    case 2:
      return loc.monthFeb;
    case 3:
      return loc.monthMar;
    case 4:
      return loc.monthApr;
    case 5:
      return loc.monthMay;
    case 6:
      return loc.monthJun;
    case 7:
      return loc.monthJul;
    case 8:
      return loc.monthAug;
    case 9:
      return loc.monthSep;
    case 10:
      return loc.monthOct;
    case 11:
      return loc.monthNov;
    case 12:
      return loc.monthDec;
  }
  return '';
}

List<String> _localizedWeekdayShortNames(AppLocalizations loc) => [
      loc.weekdayMon,
      loc.weekdayTue,
      loc.weekdayWed,
      loc.weekdayThu,
      loc.weekdayFri,
      loc.weekdaySat,
      loc.weekdaySun,
    ];

// ════════════════════════════════════════════════════════════════════════════
// UpcomingScreen
// ════════════════════════════════════════════════════════════════════════════

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => UpcomingScreenState();
}

class UpcomingScreenState extends State<UpcomingScreen>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;
  late DateTime _today;
  bool _isExpanded = false;
  DateTime? _browseMonth;

  DateTime get selectedDate => _selectedDate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _today = TimeUtils.toDate(TimeUtils.now());
    _selectedDate = _today;
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _browseMonth = null;
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) _browseMonth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc = AppLocalizations.of(context)!;
    final headerDate = _browseMonth ?? _selectedDate;
    final monthLabel =
        '${_localizedMonth(headerDate.month, loc)} ${headerDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ),

        _CollapsibleCalendar(
          selectedDate: _selectedDate,
          today: _today,
          isExpanded: _isExpanded,
          onDaySelected: _onDaySelected,
          onDisplayMonthChanged: (m) =>
              setState(() => _browseMonth = _firstOfMonth(m)),
          onCollapseRequest: () => setState(() {
            _isExpanded = false;
            _browseMonth = null;
          }),
        ),

        const Divider(height: 1, thickness: 0.5, color: AppColors.divider),

        Expanded(child: _HabitList(selectedDate: _selectedDate)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _CollapsibleCalendar
// ════════════════════════════════════════════════════════════════════════════

class _CollapsibleCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime today;
  final bool isExpanded;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onDisplayMonthChanged;
  final VoidCallback onCollapseRequest;

  const _CollapsibleCalendar({
    required this.selectedDate,
    required this.today,
    required this.isExpanded,
    required this.onDaySelected,
    required this.onDisplayMonthChanged,
    required this.onCollapseRequest,
  });

  @override
  State<_CollapsibleCalendar> createState() => _CollapsibleCalendarState();
}

class _CollapsibleCalendarState extends State<_CollapsibleCalendar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late Animation<double> _heightAnim;
  late Animation<double> _dyAnim;

  late final PageController _pageController;
  late final DateTime _baseMonthPage0;
  late DateTime _displayMonth;
  int _currentPage = _kCalPages;
  bool _programmaticScroll = false;

  int _pageFor(DateTime month) {
    final base = _baseMonthPage0.year * 12 + _baseMonthPage0.month - 1;
    return month.year * 12 + month.month - 1 - base;
  }

  DateTime _monthForPage(int page) {
    final total =
        _baseMonthPage0.year * 12 + _baseMonthPage0.month - 1 + page;
    return DateTime(total ~/ 12, total % 12 + 1, 1);
  }

  void _jumpToMonth(DateTime month) {
    final m = _firstOfMonth(month);
    if (_sameMonth(m, _displayMonth)) return;
    _displayMonth = m;
    final target = _pageFor(m);
    if (_currentPage == target) return;
    _programmaticScroll = true;
    _currentPage = target;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(target);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _programmaticScroll = false;
    });
  }

  double _targetH(bool expanded) =>
      expanded ? _maxGridH : _rowH;

  double _targetDy(bool expanded) =>
      expanded ? 0.0 : -_rowIndex(widget.selectedDate, _displayMonth) * _rowH;

  void _runTransition(bool expanding) {
    _heightAnim = Tween<double>(
      begin: _heightAnim.value,
      end: _targetH(expanding),
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _dyAnim = Tween<double>(
      begin: _dyAnim.value,
      end: _targetDy(expanding),
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _animCtrl.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _displayMonth = _firstOfMonth(widget.selectedDate);

    final totalMonths = widget.selectedDate.year * 12 +
        widget.selectedDate.month -
        1 -
        _kCalPages;
    _baseMonthPage0 = DateTime(totalMonths ~/ 12, totalMonths % 12 + 1, 1);
    _pageController = PageController(initialPage: _kCalPages);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnim = const AlwaysStoppedAnimation(_rowH);
    _dyAnim = AlwaysStoppedAnimation(_targetDy(false));
  }

  @override
  void didUpdateWidget(_CollapsibleCalendar old) {
    super.didUpdateWidget(old);
    final selMonth = _firstOfMonth(widget.selectedDate);

    if (widget.isExpanded != old.isExpanded) {
      if (!widget.isExpanded) {
        _jumpToMonth(selMonth);
      } else {
        if (!_sameMonth(selMonth, _displayMonth)) _jumpToMonth(selMonth);
      }
      _runTransition(widget.isExpanded);
      return;
    }

    if (!widget.isExpanded && !_sameDay(widget.selectedDate, old.selectedDate)) {
      if (!_sameMonth(selMonth, _displayMonth)) _jumpToMonth(selMonth);
      _runTransition(false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onStripSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 300) return;
    final monday = _mondayOf(widget.selectedDate);
    widget.onDaySelected(monday.add(Duration(days: v < 0 ? 7 : -7)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final dayLabels = _localizedWeekdayShortNames(loc);
    return GestureDetector(
      onHorizontalDragEnd: widget.isExpanded ? null : _onStripSwipe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
            child: Row(
              children: dayLabels
                  .map((n) => Expanded(
                        child: Center(
                          child: Text(n,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
          ),

          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, pageView) {
              return SizedBox(
                height: _heightAnim.value,
                child: ClipRect(
                  child: OverflowBox(
                    maxHeight: _maxGridH,
                    minHeight: 0,
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: Offset(0.0, _dyAnim.value),
                      child: pageView,
                    ),
                  ),
                ),
              );
            },
            child: SizedBox(
              height: _maxGridH,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                physics: widget.isExpanded
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (page) {
                  _currentPage = page;
                  final m = _monthForPage(page);
                  if (!_programmaticScroll) {
                    setState(() => _displayMonth = m);
                    widget.onDisplayMonthChanged(m);
                  }
                },
                itemBuilder: (_, page) =>
                    _buildFullGrid(_monthForPage(page)),
              ),
            ),
          ),

          if (widget.isExpanded) const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFullGrid(DateTime month) {
    final start = _gridStart(month);
    final numRows = _numRows(month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(numRows, (week) {
          return Row(
            children: List.generate(7, (day) {
              final date = start.add(Duration(days: week * 7 + day));
              final inMonth = date.month == month.month;
              final isSel = _sameDay(date, widget.selectedDate);
              final isToday = _sameDay(date, widget.today);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onDaySelected(date);
                    if (!inMonth) {
                      final target = _pageFor(_firstOfMonth(date));
                      if (target != _currentPage) {
                        _programmaticScroll = true;
                        _currentPage = target;
                        _displayMonth = _firstOfMonth(date);
                        _pageController.animateToPage(
                          target,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ).then((_) {
                          if (mounted) _programmaticScroll = false;
                        });
                        widget.onDisplayMonthChanged(date);
                      }
                    }
                  },
                  child: Opacity(
                    opacity: inMonth ? 1.0 : 0.4,
                    child: SizedBox(
                      height: _rowH,
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSel ? AppColors.accent : Colors.transparent,
                            border: isToday && !isSel
                                ? Border.all(color: AppColors.accent, width: 1)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 15,
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _HabitList — grouped by category
// ════════════════════════════════════════════════════════════════════════════

class _HabitList extends StatelessWidget {
  final DateTime selectedDate;
  const _HabitList({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer2<HabitViewModel, CategoryViewModel>(
      builder: (context, vm, catVm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = vm.habitsForDate(selectedDate);

        if (habits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 48,
                      color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    loc.emptyUpcoming,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        // Group by category
        final byCat = <int, List<Habit>>{};
        for (final h in habits) {
          byCat.putIfAbsent(h.categoryId, () => []).add(h);
        }

        // Build list items in category sort order
        final items = <_ListItem>[];
        for (final cat in catVm.categories) {
          final cathabits = byCat[cat.id];
          if (cathabits == null || cathabits.isEmpty) continue;
          items.add(_ListItem.header(cat));
          for (final h in cathabits) {
            items.add(_ListItem.habit(h));
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            if (item.isHeader) {
              final c = item.category!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(c.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      c.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              );
            }
            final habit = item.habit!;
            final done = vm.isHabitCompletedOnDate(habit, selectedDate);
            return HabitListItem(
              habit: habit,
              isCompletedToday: done,
              onToggleCompleted: () =>
                  vm.toggleHabitCompletionOnDate(habit, selectedDate),
              onEdit: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => HabitEditSheet(habit: habit),
              ),
            );
          },
        );
      },
    );
  }
}

class _ListItem {
  final bool isHeader;
  final Category? category;
  final Habit? habit;

  const _ListItem.header(this.category)
      : isHeader = true,
        habit = null;

  const _ListItem.habit(this.habit)
      : isHeader = false,
        category = null;
}
