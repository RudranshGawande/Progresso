import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/widgets/dashboard_header.dart';
import 'package:progresso/widgets/stat_card.dart';
import 'package:progresso/widgets/weekly_chart.dart';
import 'package:progresso/widgets/recent_sessions.dart';
import 'package:progresso/widgets/active_goals.dart';
import 'package:progresso/widgets/focus_intensity.dart';
import 'package:progresso/widgets/focus_session_dialog.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/widgets/responsive.dart';
import 'package:progresso/widgets/cta_banner.dart';

class DashboardScreen extends StatelessWidget {
  final Function(Goal)? onGoalTap;
  final Function(Goal, GoalTask, FocusSession)? onSessionTap;
  final VoidCallback? onViewAllGoals;

  const DashboardScreen({
    super.key,
    this.onGoalTap,
    this.onSessionTap,
    this.onViewAllGoals,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GoalService(),
      builder: (context, _) {
        final goals = GoalService().goals;
        return Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stat cards ──────────────────────────────────
                      _buildStatCards(context, goals),

                      const SizedBox(height: 32),

                      // ── Weekly chart + Recent sessions ───────────────
                      _buildMainGrid(context, goals),

                      const SizedBox(height: 32),

                      // ── Active goals + Focus intensity ───────────────
                      _buildSecondaryGrid(context, goals),

                      const SizedBox(height: 32),

                      // ── CTA Banner ───────────────────────────────────
                      CTABanner(
                        onAction: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Focus Session',
                            barrierColor: Colors.black.withOpacity(0.6),
                            pageBuilder: (context, _, __) => FocusSessionDialog(
                              goals: goals,
                            ),
                            transitionBuilder: (context, anim1, anim2, child) {
                              return BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: FadeTransition(
                                  opacity: anim1,
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCards(BuildContext context, List<Goal> goals) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    // Calculations
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    double totalHours = 0;
    double totalHoursThisWeek = 0;
    double totalHoursLastWeek = 0;

    int completedGoals = 0;
    num totalFocusScore = 0;
    num focusScoreThisWeek = 0;
    num focusScoreLastWeek = 0;
    int sessionCount = 0;
    int sessionCountThisWeek = 0;
    int sessionCountLastWeek = 0;
    
    int maxStreak = 0;
    double dailyGoalCurrent = 0.0;
    double dailyGoalTarget = 6.0;

    for (var goal in goals) {
      totalHours += goal.totalTimeSpent.inMinutes / 60.0;
      if (goal.status == GoalStatus.completed) completedGoals++;
      maxStreak = maxStreak > goal.currentStreak ? maxStreak : goal.currentStreak;
      
      for (var task in goal.tasks) {
        for (final FocusSession session in task.sessions) {
          totalFocusScore += session.focusScore;
          sessionCount++;

          final sessionDate = DateTime(session.timestamp.year, session.timestamp.month, session.timestamp.day);
          final hours = session.duration.inMinutes / 60.0;

          if (sessionDate == today) {
             dailyGoalCurrent += hours;
          }

          if (sessionDate.isAfter(startOfThisWeek.subtract(const Duration(days: 1))) && sessionDate.isBefore(today.add(const Duration(days: 1)))) {
            totalHoursThisWeek += hours;
            focusScoreThisWeek += session.focusScore;
            sessionCountThisWeek++;
          } else if (sessionDate.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) && sessionDate.isBefore(startOfThisWeek)) {
            totalHoursLastWeek += hours;
            focusScoreLastWeek += session.focusScore;
            sessionCountLastWeek++;
          }
        }
      }
    }

    double avgFocusScore = sessionCount > 0 ? totalFocusScore / sessionCount : 0;
    double avgFocusThisWeek = sessionCountThisWeek > 0 ? focusScoreThisWeek / sessionCountThisWeek : 0;
    double avgFocusLastWeek = sessionCountLastWeek > 0 ? focusScoreLastWeek / sessionCountLastWeek : 0;
    
    double hoursTrend = totalHoursLastWeek > 0 ? ((totalHoursThisWeek - totalHoursLastWeek) / totalHoursLastWeek) * 100 : 0;
    double focusTrend = avgFocusLastWeek > 0 ? ((avgFocusThisWeek - avgFocusLastWeek) / avgFocusLastWeek) * 100 : 0;
    // For visual match, if there's no data, we retain the requested placeholder visual trends
    final hoursTrendText = '${hoursTrend >= 0 ? '+' : ''}${hoursTrend.toInt()}%';
    final focusTrendText = '${focusTrend >= 0 ? '+' : ''}${focusTrend.toInt()}%';
    
    // Determine trend colors
    final hoursTrendColor = hoursTrend >= 0 ? AppColors.emerald500 : AppColors.rose500;
    final hoursTrendIcon = hoursTrend >= 0 ? Icons.trending_up : Icons.trending_down;
    final focusTrendColor = focusTrend >= 0 ? AppColors.emerald500 : AppColors.rose500;
    final focusTrendIcon = focusTrend >= 0 ? Icons.trending_up : Icons.trending_down;

    double dailyGoalProgress = dailyGoalTarget > 0 ? (dailyGoalCurrent / dailyGoalTarget).clamp(0.0, 1.0) : 0.0;

    String formatValue(double val) {
      if (val == val.floorToDouble()) return val.toInt().toString();
      return val.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }

    final cards = [
      StatCard(
        icon: Icons.schedule,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primary.withOpacity(0.1),
        trend: hoursTrendText,
        trendColor: hoursTrendColor,
        trendIcon: hoursTrendIcon,
        metric: 'Total Hours Worked',
        value: '${formatValue(totalHours)}h',
      ),
      StatCard(
        icon: Icons.track_changes,
        iconColor: AppColors.blue500,
        iconBgColor: AppColors.blue500.withOpacity(0.1),
        trend: focusTrendText,
        trendColor: focusTrendColor,
        trendIcon: focusTrendIcon,
        metric: 'Focus Score',
        value: '${avgFocusScore.toInt()}%',
      ),
      StatCard(
        icon: Icons.radio_button_checked,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primary.withOpacity(0.1),
        trend: 'Today',
        trendColor: AppColors.slate500,
        metric: 'Daily Goal',
        value: '${formatValue(dailyGoalCurrent)}h',
        targetLabel: '/ ${dailyGoalTarget.toInt()}h target',
        progress: dailyGoalProgress,
      ),
      StatCard(
        icon: Icons.local_fire_department,
        iconColor: AppColors.rose500,
        iconBgColor: AppColors.rose500.withOpacity(0.1),
        trend: maxStreak == 0 ? 'Start' : (maxStreak < 3 ? '-1' : '+1'),
        trendColor: AppColors.rose500,
        trendIcon: maxStreak < 3 ? Icons.trending_down : Icons.trending_up,
        metric: 'Current Streak',
        value: '$maxStreak Days',
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: c,
        )).toList(),
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 24),
        Expanded(child: cards[1]),
        const SizedBox(width: 24),
        Expanded(child: cards[2]),
        const SizedBox(width: 24),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildMainGrid(BuildContext context, List<Goal> goals) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          const WeeklyProgressChart(),
          const SizedBox(height: 32),
          RecentSessionsPanel(
            onGoalTap: onGoalTap,
            onSessionTap: onSessionTap,
            onViewAll: onViewAllGoals,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(flex: 2, child: WeeklyProgressChart()),
        const SizedBox(width: 32),
        Expanded(
          child: RecentSessionsPanel(
            onGoalTap: onGoalTap,
            onSessionTap: onSessionTap,
            onViewAll: onViewAllGoals,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryGrid(BuildContext context, List<Goal> goals) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          ActiveGoalsPanel(
            onGoalTap: onGoalTap,
            onViewAll: onViewAllGoals,
          ),
          const SizedBox(height: 32),
          const FocusIntensityPanel(),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ActiveGoalsPanel(
              onGoalTap: onGoalTap,
              onViewAll: onViewAllGoals,
            ),
          ),
          const SizedBox(width: 32),
          const Expanded(child: FocusIntensityPanel()),
        ],
      ),
    );
  }
}
