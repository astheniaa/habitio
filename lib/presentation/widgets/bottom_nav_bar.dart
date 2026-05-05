import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// iOS-style tab bar: outline icon when inactive, filled when active,
/// label below in matching tint. No pill backgrounds or extra chrome.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final items = [
      _NavItem(
        label: loc.todayTab,
        iconOutline: Icons.today_outlined,
        iconFilled: Icons.today,
      ),
      _NavItem(
        label: loc.upcomingTab,
        iconOutline: Icons.calendar_month_outlined,
        iconFilled: Icons.calendar_month,
      ),
      _NavItem(
        label: loc.statisticsTab,
        iconOutline: Icons.insights_outlined,
        iconFilled: Icons.insights,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              final color = isActive ? colors.accent : colors.textTertiary;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.iconFilled : item.iconOutline,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData iconOutline;
  final IconData iconFilled;
  const _NavItem({
    required this.label,
    required this.iconOutline,
    required this.iconFilled,
  });
}
