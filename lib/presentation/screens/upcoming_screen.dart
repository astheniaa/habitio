import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/utils/time_utils.dart';
import '../localization/app_strings.dart';
import '../state/habit_view_model.dart';
import '../widgets/habit_list_item.dart';
import 'habit_edit_sheet.dart';

// ─── Locale data ─────────────────────────────────────────────────────────────

const _monthNames = [
  '',
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

const _dayShortNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

// ─── Constants ───────────────────────────────────────────────────────────────

const _green = Color(0xFF4CAF50);
const _kCalPages = 10000;
const _rowH = 44.0;
const _maxGridH = 6 * _rowH; // max possible month grid height (6 weeks)

// ─── Pure helpers ─────────────────────────────────────────────────────────────

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

// ═════════════════════════════════════════════════════════════════════════════
// UpcomingScreen
// ═════════════════════════════════════════════════════════════════════════════

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
    _today = TimeUtils.toUtc3Date(TimeUtils.nowUtc3());
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
    final headerDate = _browseMonth ?? _selectedDate;
    final monthLabel =
        '${_monthNames[headerDate.month]} ${headerDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month header ────────────────────────────────────────────────────
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
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        // ── Collapsible calendar ────────────────────────────────────────────
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

        const Divider(height: 1, thickness: 1, color: Colors.white12),

        // ── Habit list ──────────────────────────────────────────────────────
        Expanded(child: _HabitList(selectedDate: _selectedDate)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _CollapsibleCalendar
//
// Single month grid. Collapsed = one visible row (selectedDate's week).
// Expanded = full month. ClipRect + OverflowBox + Transform.translate
// ensure the PageView always gets full height; only the viewport changes.
// ═════════════════════════════════════════════════════════════════════════════

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

  // ── Page helpers ──────────────────────────────────────────────────────────

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

  // ── Animation targets ─────────────────────────────────────────────────────

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

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

    // Start collapsed — show the row containing today
    _heightAnim = const AlwaysStoppedAnimation(_rowH);
    _dyAnim = AlwaysStoppedAnimation(_targetDy(false));
  }

  @override
  void didUpdateWidget(_CollapsibleCalendar old) {
    super.didUpdateWidget(old);
    final selMonth = _firstOfMonth(widget.selectedDate);

    // Expand / collapse
    if (widget.isExpanded != old.isExpanded) {
      if (!widget.isExpanded) {
        _jumpToMonth(selMonth);
      } else {
        if (!_sameMonth(selMonth, _displayMonth)) _jumpToMonth(selMonth);
      }
      _runTransition(widget.isExpanded);
      return;
    }

    // selectedDate changed while collapsed → slide to new row
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

  // ── Gestures ──────────────────────────────────────────────────────────────

  void _onStripSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 300) return;
    final monday = _mondayOf(widget.selectedDate);
    widget.onDaySelected(monday.add(Duration(days: v < 0 ? 7 : -7)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: widget.isExpanded ? null : _onStripSwipe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day-name header (always visible)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
            child: Row(
              children: _dayShortNames
                  .map((n) => Expanded(
                        child: Center(
                          child: Text(n,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Animated month grid
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

  /// Full month grid — always complete, never skips rows.
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
                            color: isSel ? _green : Colors.transparent,
                            border: isToday && !isSel
                                ? Border.all(color: _green, width: 1)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
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

// ═════════════════════════════════════════════════════════════════════════════
// _HabitList
// ═════════════════════════════════════════════════════════════════════════════

class _HabitList extends StatelessWidget {
  final DateTime selectedDate;
  const _HabitList({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitViewModel>(
      builder: (context, vm, _) {
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
                  const Text(
                    AppStrings.emptyUpcoming,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final grouped = <HabitSpecialization, List<Habit>>{};
        for (final h in habits) {
          grouped.putIfAbsent(h.specialization, () => []).add(h);
        }

        final items = <_ListItem>[];
        for (final e in grouped.entries) {
          items.add(_ListItem.header(e.key));
          for (final h in e.value) {
            items.add(_ListItem.habit(h));
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            if (item.isHeader) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  _specLabel(item.spec!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.8,
                  ),
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

  String _specLabel(HabitSpecialization s) => switch (s) {
        HabitSpecialization.sport => AppStrings.sport.toUpperCase(),
        HabitSpecialization.creativity => AppStrings.creativity.toUpperCase(),
        HabitSpecialization.finance => AppStrings.finance.toUpperCase(),
        HabitSpecialization.social => AppStrings.social.toUpperCase(),
        HabitSpecialization.processing => AppStrings.processing.toUpperCase(),
      };
}

// ─── List item union ─────────────────────────────────────────────────────────

class _ListItem {
  final bool isHeader;
  final HabitSpecialization? spec;
  final Habit? habit;

  const _ListItem.header(this.spec)
      : isHeader = true,
        habit = null;

  const _ListItem.habit(this.habit)
      : isHeader = false,
        spec = null;
}
