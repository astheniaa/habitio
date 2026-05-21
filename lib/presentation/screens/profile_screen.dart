import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/user.dart';
import '../../domain/models/profile_insights.dart';
import '../../domain/usecases/compute_profile_insights.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/category_view_model.dart';
import '../state/habit_view_model.dart';
import '../state/locale_provider.dart';
import '../state/theme_provider.dart';
import '../state/user_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/avatar_picker_sheet.dart';
import 'category_manager_screen.dart';

/// Personal progress dashboard. Reachable from the top-bar avatar.
///
/// Deliberately *not* gamified — the level/XP/RPG signals stay in the
/// always-visible top bar. This screen is about the user's relationship
/// with their habits over the last two weeks, with light motivation.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const ProfileScreen());

  static final _useCase = ComputeProfileInsightsUseCase();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(loc.profileTitle),
      ),
      body: Consumer3<UserViewModel, HabitViewModel, CategoryViewModel>(
        builder: (context, userVm, habitVm, catVm, _) {
          final user = userVm.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = _useCase.call(
            habits: habitVm.habits,
            completions: habitVm.completions,
            categories: catVm.categories,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AvatarBlock(user: user),
                const SizedBox(height: AppSpacing.xl),
                _StatsRow(result: result),
                const SizedBox(height: AppSpacing.xl),
                _SkillsSection(progress: result.categories),
                const SizedBox(height: AppSpacing.xl),
                if (result.insights.isNotEmpty) ...[
                  _InsightsSection(insights: result.insights),
                  const SizedBox(height: AppSpacing.xl),
                ],
                _TodaySection(today: result.today),
                const SizedBox(height: AppSpacing.xl),
                const _SettingsSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Avatar block
// ════════════════════════════════════════════════════════════════════════════

class _AvatarBlock extends StatelessWidget {
  final User user;
  const _AvatarBlock({required this.user});

  static const double _avatarSize = 112;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openAvatarPicker(context),
            child: _AvatarPlaceholder(user: user, size: _avatarSize),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onLongPress: () => _editName(context, user),
            child: Text(
              user.name,
              style: AppText.title.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            loc.profileTapToCustomize,
            style: AppText.footnote.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  void _openAvatarPicker(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  void _editName(BuildContext context, User user) {
    HapticFeedback.mediumImpact();
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.editNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: loc.editNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              ctx.read<UserViewModel>().updateName(name);
              Navigator.of(ctx).pop();
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final User user;
  final double size;
  const _AvatarPlaceholder({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasPhoto =
        user.avatarPath != null && user.avatarPath!.isNotEmpty;
    final hasEmoji =
        user.avatarRpgId != null && user.avatarRpgId!.isNotEmpty;

    Widget content;
    if (hasPhoto) {
      content = Image.file(
        File(user.avatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _neutralPlaceholder(colors),
      );
    } else if (hasEmoji) {
      content = Center(
        child: Text(
          user.avatarRpgId!,
          style: TextStyle(fontSize: size * 0.5),
        ),
      );
    } else {
      content = _neutralPlaceholder(colors);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.divider, width: 1),
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _neutralPlaceholder(AppPalette palette) {
    // Plain silhouette — final character art comes later.
    return Container(
      color: palette.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.42,
        color: palette.textTertiary,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Stats row
// ════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final ProfileInsightsResult result;
  const _StatsRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              value: '${result.currentStreak}',
              suffix: loc.daysShort,
              label: loc.profileStatCurrentStreak,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatTile(
              value:
                  '${result.today.completed}/${result.today.scheduled}',
              label: loc.profileStatCompletedToday,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatTile(
              value: '${result.bestStreak}',
              suffix: loc.daysShort,
              label: loc.profileStatBestStreak,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String? suffix;
  final String label;
  const _StatTile({required this.value, this.suffix, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: colors.textPrimary,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 3),
                Text(
                  suffix!,
                  style: AppText.caption
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.footnote.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Skills section
// ════════════════════════════════════════════════════════════════════════════

class _SkillsSection extends StatelessWidget {
  final List<CategoryProgress> progress;
  const _SkillsSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    final visible =
        progress.where((p) => p.scheduled > 0).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: loc.profileSkillsTitle,
            subtitle: loc.profileSkillsSubtitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                loc.profileSkillsEmpty,
                style: AppText.body.copyWith(color: colors.textSecondary),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < visible.length; i++) ...[
                    _SkillRow(progress: visible[i]),
                    if (i < visible.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.lg),
                        child: Divider(height: 0.5),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final CategoryProgress progress;
  const _SkillRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ratio = progress.ratio ?? 0;
    final percent = (ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceElevated,
            ),
            child: Text(progress.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress.name,
                        style: AppText.callout
                            .copyWith(color: colors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: AppText.callout.copyWith(
                        color: colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: colors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation(colors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Insights section
// ════════════════════════════════════════════════════════════════════════════

class _InsightsSection extends StatelessWidget {
  final List<ProfileInsight> insights;
  const _InsightsSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.profileInsightsTitle),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              children: insights
                  .map((i) => _InsightLine(insight: i))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  final ProfileInsight insight;
  const _InsightLine({required this.insight});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    final (icon, message) = _resolve(insight, loc);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.body.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String) _resolve(ProfileInsight ins, AppLocalizations loc) {
    return switch (ins) {
      WelcomeInsight() => (
          Icons.waving_hand_outlined,
          loc.insightWelcome,
        ),
      StreakInsight(:final days) when days <= 0 => (
          Icons.local_fire_department_outlined,
          loc.insightNoStreak,
        ),
      StreakInsight(:final days) => (
          Icons.local_fire_department_outlined,
          loc.insightStreak(days),
        ),
      StrongCategoryInsight(:final categoryName, :final percent) => (
          Icons.trending_up_rounded,
          loc.insightStrongCategory(categoryName, percent),
        ),
      WeakCategoryInsight(:final categoryName, :final percent) => (
          Icons.priority_high_rounded,
          loc.insightWeakCategory(categoryName, percent),
        ),
      StrongDayInsight(:final weekday) => (
          Icons.calendar_today_outlined,
          loc.insightStrongDay(_weekdayName(weekday, loc)),
        ),
      WeakDayInsight(:final weekday) => (
          Icons.calendar_today_outlined,
          loc.insightWeakDay(_weekdayName(weekday, loc)),
        ),
      TrendInsight(:final deltaPercent) when deltaPercent >= 0 => (
          Icons.north_east_rounded,
          loc.insightTrendUp(deltaPercent),
        ),
      TrendInsight(:final deltaPercent) => (
          Icons.south_east_rounded,
          loc.insightTrendDown(-deltaPercent),
        ),
    };
  }

  String _weekdayName(int wd, AppLocalizations loc) {
    switch (wd) {
      case 1:
        return loc.weekdayMon;
      case 2:
        return loc.weekdayTue;
      case 3:
        return loc.weekdayWed;
      case 4:
        return loc.weekdayThu;
      case 5:
        return loc.weekdayFri;
      case 6:
        return loc.weekdaySat;
      case 7:
        return loc.weekdaySun;
    }
    return '';
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Today section
// ════════════════════════════════════════════════════════════════════════════

class _TodaySection extends StatelessWidget {
  final TodaySnapshot today;
  const _TodaySection({required this.today});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    final ratio = today.scheduled == 0
        ? 0.0
        : today.completed / today.scheduled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.profileRecentTitle),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (today.isEmpty)
                  Text(
                    loc.profileRecentEmpty,
                    style:
                        AppText.body.copyWith(color: colors.textSecondary),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          loc.profileRecentDoneOf(
                              today.completed, today.scheduled),
                          style: AppText.body
                              .copyWith(color: colors.textPrimary),
                        ),
                      ),
                      Text(
                        '${(ratio * 100).round()}%',
                        style: AppText.body.copyWith(
                          color: colors.textSecondary,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: colors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation(colors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Settings section (theme + language + categories)
// ════════════════════════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.profileSettingsTitle),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                _SettingsRow(
                  label: loc.profileThemeLabel,
                  trailing: const _ThemeToggle(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.md),
                  child: Divider(height: 0.5),
                ),
                _SettingsRow(
                  label: loc.languageLabel,
                  trailing: const _LanguageToggle(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.md),
                  child: Divider(height: 0.5),
                ),
                _SettingsLink(
                  label: loc.profileManageCategories,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CategoryManagerScreen(),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  const _SettingsRow({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(color: colors.textPrimary),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SettingsLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.body.copyWith(color: colors.textPrimary),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final themeVm = context.watch<ThemeProvider>();

    Widget tab(bool night, String label) {
      final active = themeVm.isNight == night;
      return Expanded(
        child: GestureDetector(
          onTap: () => context.read<ThemeProvider>().setNight(night),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: active ? colors.surfaceElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          tab(false, loc.profileThemeDay),
          tab(true, loc.profileThemeNight),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final localeVm = context.watch<LocaleProvider>();
    final code = localeVm.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;

    Widget tab(String langCode, String label) {
      final active = code == langCode;
      return Expanded(
        child: GestureDetector(
          onTap: () =>
              context.read<LocaleProvider>().setLocale(Locale(langCode)),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: active ? colors.surfaceElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          tab('ru', loc.languageRussian),
          tab('en', loc.languageEnglish),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Section header
// ════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.sectionLabel
                .copyWith(color: colors.textSecondary),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              subtitle!,
              style: AppText.footnote.copyWith(color: colors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
